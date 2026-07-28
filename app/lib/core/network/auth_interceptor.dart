import 'dart:async';

import 'package:dio/dio.dart';

import '../auth/token_store.dart';

/// Anexa o access token e, no 401, renova a sessão e repete a requisição.
///
/// Porte de `api()` da SPA (`frontend/src/lib/api.ts:44-60`), com duas diferenças que só
/// aparecem no celular:
///
/// 1. **Renovação única.** A tela inicial dispara várias requisições em paralelo; se todas
///    receberem 401 ao mesmo tempo, cada uma tentaria renovar. Como o backend **rotaciona**
///    o refresh token (o usado é revogado em `AuthController.refresh`), a segunda chamada
///    usaria um token já morto e derrubaria a sessão. Aqui a primeira renovação vira um
///    `Future` compartilhado e as demais esperam por ele.
/// 2. **Fila de espera.** As requisições que falharam durante a renovação são repetidas
///    depois, em vez de erro na tela.
class AuthInterceptor extends QueuedInterceptor {
  AuthInterceptor({
    required TokenStore tokenStore,
    required Dio refreshClient,
    required Future<void> Function() onSessionExpired,
  }) : _tokens = tokenStore,
       _plainDio = refreshClient,
       _notifyExpired = onSessionExpired;

  final TokenStore _tokens;

  /// Cliente separado, **sem este interceptor**: renovar usando o Dio principal
  /// entraria em recursão se o próprio refresh respondesse 401.
  final Dio _plainDio;

  final Future<void> Function() _notifyExpired;

  Future<bool>? _refreshInFlight;

  /// Endpoints que nunca levam token nem tentam renovar.
  static bool _isAuthEndpoint(String path) =>
      path.contains('/api/auth/') && !path.contains('/api/auth/me');

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (!_isAuthEndpoint(options.path)) {
      final tokens = await _tokens.read();
      if (tokens != null) {
        options.headers['Authorization'] = 'Bearer ${tokens.accessToken}';
      }
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final response = err.response;
    final isUnauthorized = response?.statusCode == 401;

    if (!isUnauthorized ||
        _isAuthEndpoint(err.requestOptions.path) ||
        err.requestOptions.extra['retriedAfterRefresh'] == true) {
      return handler.next(err);
    }

    // Alguém já renovou enquanto esta requisição estava no ar? Então é só repetir.
    //
    // Como esta é uma QueuedInterceptor, os 401 chegam em fila: quando a segunda
    // requisição do lote é tratada, a renovação da primeira já terminou e o
    // `_refreshInFlight` voltou a ser nulo. Sem esta comparação, cada 401 do lote
    // dispararia sua própria renovação — três chamadas de `/api/auth/refresh` e três
    // rotações de refresh token para uma sessão só.
    if (await _tokenAlreadyRotated(err.requestOptions)) {
      return _resolveRetry(err, handler);
    }

    final renewed = await _refreshOnce();
    if (!renewed) {
      await _notifyExpired();
      return handler.next(err);
    }

    return _resolveRetry(err, handler);
  }

  Future<void> _resolveRetry(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    try {
      handler.resolve(await _retry(err.requestOptions));
    } on DioException catch (e) {
      handler.next(e);
    }
  }

  /// O token guardado hoje é diferente do que esta requisição usou?
  Future<bool> _tokenAlreadyRotated(RequestOptions options) async {
    final current = await _tokens.read();
    if (current == null) {
      return false;
    }
    return options.headers['Authorization'] != 'Bearer ${current.accessToken}';
  }

  /// Garante uma renovação por vez; as chamadas concorrentes aguardam a mesma.
  Future<bool> _refreshOnce() {
    return _refreshInFlight ??= _performRefresh().whenComplete(() {
      _refreshInFlight = null;
    });
  }

  Future<bool> _performRefresh() async {
    final current = await _tokens.read();
    if (current == null) {
      return false;
    }

    try {
      final response = await _plainDio.post<Map<String, dynamic>>(
        '/api/auth/refresh',
        data: {'refreshToken': current.refreshToken},
      );
      final data = response.data;
      if (data == null) {
        return false;
      }
      await _tokens.write(AuthTokens.fromJson(data));
      return true;
    } on DioException {
      // Refresh inválido ou expirado: a sessão acabou de verdade.
      await _tokens.clear();
      return false;
    }
  }

  Future<Response<dynamic>> _retry(RequestOptions options) async {
    final tokens = await _tokens.read();
    return _plainDio.fetch<dynamic>(
      options.copyWith(
        headers: {
          ...options.headers,
          if (tokens != null) 'Authorization': 'Bearer ${tokens.accessToken}',
        },
        // Marca para não entrar em laço se o retry também responder 401.
        extra: {...options.extra, 'retriedAfterRefresh': true},
      ),
    );
  }
}
