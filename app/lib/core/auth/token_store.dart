import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Par de tokens devolvido por `/api/auth/*`.
class AuthTokens {
  const AuthTokens({required this.accessToken, required this.refreshToken});

  final String accessToken;
  final String refreshToken;

  factory AuthTokens.fromJson(Map<String, dynamic> json) => AuthTokens(
    accessToken: json['accessToken'] as String,
    refreshToken: json['refreshToken'] as String,
  );
}

/// Guarda a sessão no armazenamento seguro da plataforma — Keychain no iOS,
/// EncryptedSharedPreferences no Android.
///
/// Equivale ao `localStorage` da SPA (`frontend/src/lib/api.ts:1-21`), mas cifrado: no
/// celular o app fica instalado por meses e um token em texto claro sobrevive a backups.
class TokenStore {
  TokenStore({FlutterSecureStorage? storage})
    : _storage =
          storage ??
          const FlutterSecureStorage(
            aOptions: AndroidOptions(encryptedSharedPreferences: true),
            iOptions: IOSOptions(
              accessibility: KeychainAccessibility.first_unlock,
            ),
          );

  static const _accessKey = 'myotrack.accessToken';
  static const _refreshKey = 'myotrack.refreshToken';

  final FlutterSecureStorage _storage;

  /// Cache em memória: o interceptor lê o access token a cada requisição, e ir ao
  /// Keychain toda vez custa caro.
  AuthTokens? _cached;

  Future<AuthTokens?> read() async {
    if (_cached != null) {
      return _cached;
    }
    final access = await _storage.read(key: _accessKey);
    final refresh = await _storage.read(key: _refreshKey);
    if (access == null || refresh == null) {
      return null;
    }
    return _cached = AuthTokens(accessToken: access, refreshToken: refresh);
  }

  Future<void> write(AuthTokens tokens) async {
    _cached = tokens;
    await _storage.write(key: _accessKey, value: tokens.accessToken);
    await _storage.write(key: _refreshKey, value: tokens.refreshToken);
  }

  Future<void> clear() async {
    _cached = null;
    await _storage.delete(key: _accessKey);
    await _storage.delete(key: _refreshKey);
  }

  Future<bool> get isAuthenticated async => (await read()) != null;

  /// Papéis vindos do JWT — porte de `getRoles()` (`api.ts:128-138`).
  ///
  /// Lê os dois nomes de claim: o curto (`role`) do backend Java e o URI longo que o
  /// ASP.NET Identity emitia, para funcionar com token emitido por qualquer um dos dois
  /// durante a transição.
  Future<List<String>> roles() async {
    final tokens = await read();
    if (tokens == null) {
      return const [];
    }
    return rolesFromAccessToken(tokens.accessToken);
  }

  /// E-mail do usuário atual, tirado do JWT. Null quando não há sessão.
  ///
  /// Vem do token e não de `/api/profile` porque o uso é decorativo — as iniciais no avatar
  /// da barra superior — e uma chamada de rede para desenhar duas letras deixaria o avatar
  /// piscando vazio a cada abertura.
  Future<String?> email() async {
    final tokens = await read();
    return tokens == null ? null : emailFromAccessToken(tokens.accessToken);
  }

  static String? emailFromAccessToken(String accessToken) {
    final claim = _payload(accessToken)?['email'];
    return claim is String && claim.isNotEmpty ? claim : null;
  }

  static const _dotNetRoleClaim =
      'http://schemas.microsoft.com/ws/2008/06/identity/claims/role';

  /// Decodifica o payload do JWT sem validar a assinatura.
  ///
  /// Isso é seguro aqui porque o resultado só decide o que **mostrar** na interface (o
  /// item de menu da revisão). Toda autorização de verdade acontece no servidor, que
  /// valida a assinatura — um token adulterado no cliente não abre nenhuma porta.
  static List<String> rolesFromAccessToken(String accessToken) {
    final payload = _payload(accessToken);
    final claim = payload?['role'] ?? payload?[_dotNetRoleClaim];
    if (claim == null) {
      return const [];
    }
    // O claim vem como string quando há um papel só e como lista quando há vários.
    if (claim is String) {
      return [claim];
    }
    if (claim is List) {
      return claim.whereType<String>().toList();
    }
    return const [];
  }

  /// Token malformado devolve null em vez de estourar: um JWT truncado no armazenamento
  /// não pode impedir o app de abrir.
  static Map<String, dynamic>? _payload(String accessToken) {
    try {
      final parts = accessToken.split('.');
      if (parts.length != 3) {
        return null;
      }
      return json.decode(
            utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))),
          )
          as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }
}
