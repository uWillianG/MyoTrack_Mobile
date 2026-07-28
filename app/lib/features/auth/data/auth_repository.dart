import '../../../core/auth/token_store.dart';
import '../../../core/network/api_client.dart';
import 'auth_models.dart';

/// Fala com `/api/auth`. Toda chamada que devolve um par de tokens já o persiste — nenhuma
/// tela precisa lembrar de fazer isso, e esquecer significaria "login bem-sucedido que não
/// autentica".
class AuthRepository {
  AuthRepository(this._api);

  final ApiClient _api;

  TokenStore get _tokens => _api.tokens;

  Future<AuthProviders> providers() async {
    final json = await _api.get<Map<String, dynamic>>('/api/auth/providers');
    return AuthProviders.fromJson(json);
  }

  Future<void> register({
    required String email,
    required String password,
    String? displayName,
  }) => _authenticate(
    '/api/auth/register',
    RegisterRequest(
      email: email,
      password: password,
      displayName: displayName,
    ).toJson(),
  );

  Future<void> login({required String email, required String password}) =>
      _authenticate(
        '/api/auth/login',
        LoginRequest(email: email, password: password).toJson(),
      );

  Future<void> signInWithGoogle(String idToken) => _authenticate(
    '/api/auth/google/id-token',
    GoogleIdTokenRequest(idToken: idToken).toJson(),
  );

  Future<void> signInWithApple({
    required String idToken,
    String? displayName,
  }) => _authenticate(
    '/api/auth/apple/id-token',
    AppleIdTokenRequest(idToken: idToken, displayName: displayName).toJson(),
  );

  /// Troca o código de uso único do fluxo web pelo par de tokens.
  ///
  /// Só é usado no caminho de contingência: se o login nativo falhar, o app abre o fluxo do
  /// navegador e volta por deep link com este código.
  Future<void> exchangeOAuthCode(String code) =>
      _authenticate('/api/auth/google/exchange', {'code': code});

  /// Dispara o e-mail de redefinição.
  ///
  /// A resposta é sempre a mesma, exista ou não a conta — a tela não deve tentar deduzir nada
  /// dela, sob pena de virar um verificador de quem tem cadastro.
  Future<String> forgotPassword(String email) async {
    final json = await _api.post<Map<String, dynamic>>(
      '/api/auth/forgot-password',
      body: ForgotPasswordRequest(email: email).toJson(),
    );
    return json['message'] as String? ??
        'Se houver uma conta com esse e-mail, o link de redefinição foi enviado.';
  }

  Future<String> resetPassword({
    required String userId,
    required String token,
    required String password,
  }) async {
    final json = await _api.post<Map<String, dynamic>>(
      '/api/auth/reset-password',
      body: ResetPasswordRequest(
        userId: userId,
        token: token,
        password: password,
      ).toJson(),
    );
    return json['message'] as String? ?? 'Senha redefinida.';
  }

  Future<void> logout() => _tokens.clear();

  Future<void> _authenticate(String path, Map<String, dynamic> body) async {
    final json = await _api.post<Map<String, dynamic>>(path, body: body);
    await _tokens.write(AuthTokens.fromJson(json));
  }
}
