import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../auth/token_store.dart';
import '../env.dart';
import 'api_exception.dart';
import 'auth_interceptor.dart';

/// Cliente HTTP do app. Encapsula o Dio para que as camadas de cima nunca vejam
/// `DioException` — só {@link ApiException}, que já carrega a mensagem em pt-BR do backend.
class ApiClient {
  ApiClient({required TokenStore tokenStore, Dio? dio, Dio? refreshDio})
    : _tokens = tokenStore,
      _dio = dio ?? Dio(_baseOptions()),
      _refreshDio = refreshDio ?? Dio(_baseOptions()) {
    _dio.interceptors.add(
      AuthInterceptor(
        tokenStore: _tokens,
        refreshClient: _refreshDio,
        onSessionExpired: () async => _onSessionExpired?.call(),
      ),
    );

    if (kDebugMode) {
      _dio.interceptors.add(
        LogInterceptor(requestBody: false, responseBody: false, request: false),
      );
    }
  }

  static BaseOptions _baseOptions() => BaseOptions(
    baseUrl: Env.apiBaseUrl,
    connectTimeout: Env.connectTimeout,
    receiveTimeout: Env.receiveTimeout,
    contentType: Headers.jsonContentType,
    // Não lançar em 4xx: o tratamento vira ApiException num lugar só.
    validateStatus: (status) => status != null && status < 400,
  );

  final TokenStore _tokens;
  final Dio _dio;
  final Dio _refreshDio;

  Future<void> Function()? _onSessionExpired;

  /// Chamado quando a renovação falha — a camada de navegação leva ao login.
  set onSessionExpired(Future<void> Function() callback) =>
      _onSessionExpired = callback;

  Dio get raw => _dio;
  TokenStore get tokens => _tokens;

  Future<T> get<T>(String path, {Map<String, dynamic>? query}) =>
      _run(() => _dio.get<T>(path, queryParameters: query));

  Future<T> post<T>(String path, {Object? body}) =>
      _run(() => _dio.post<T>(path, data: body));

  Future<T> put<T>(String path, {Object? body}) =>
      _run(() => _dio.put<T>(path, data: body));

  Future<T> delete<T>(String path) => _run(() => _dio.delete<T>(path));

  /// Upload multipart (foto de refeição). Timeout maior que o das chamadas comuns.
  Future<T> upload<T>(
    String path,
    FormData form, {
    void Function(int sent, int total)? onProgress,
  }) => _run(
    () => _dio.post<T>(
      path,
      data: form,
      options: Options(
        contentType: 'multipart/form-data',
        sendTimeout: Env.uploadTimeout,
        receiveTimeout: Env.uploadTimeout,
      ),
      onSendProgress: onProgress,
    ),
  );

  /// PUT direto no storage por URL pré-assinada (vídeo de exercício).
  ///
  /// Usa o cliente **sem** o interceptor de autenticação de propósito: a URL já carrega a
  /// assinatura, e mandar o `Authorization` do MyoTrack junto faz o MinIO recusar.
  Future<void> putPresigned(
    String presignedUrl,
    Stream<List<int>> data, {
    required int length,
    required String contentType,
    void Function(int sent, int total)? onProgress,
  }) async {
    try {
      await _refreshDio.put<void>(
        presignedUrl,
        data: data,
        options: Options(
          headers: {
            Headers.contentLengthHeader: length,
            Headers.contentTypeHeader: contentType,
          },
          sendTimeout: Env.uploadTimeout,
          receiveTimeout: Env.uploadTimeout,
        ),
        onSendProgress: onProgress,
      );
    } on DioException catch (e) {
      throw ApiException.from(e);
    }
  }

  Future<T> _run<T>(Future<Response<T>> Function() request) async {
    try {
      final response = await request();
      return response.data as T;
    } on DioException catch (e) {
      throw ApiException.from(e);
    }
  }
}
