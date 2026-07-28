import 'package:freezed_annotation/freezed_annotation.dart';

part 'auth_models.freezed.dart';
part 'auth_models.g.dart';

/// Quais formas de login esta instalação oferece — `GET /api/auth/providers`.
///
/// A tela consulta antes de desenhar: sem credenciais do Google configuradas no servidor, o
/// botão não aparece, em vez de aparecer e falhar no toque.
@freezed
abstract class AuthProviders with _$AuthProviders {
  const factory AuthProviders({
    @Default(false) bool google,
    @Default(false) bool apple,
    @Default(false) bool passwordReset,
  }) = _AuthProviders;

  factory AuthProviders.fromJson(Map<String, dynamic> json) =>
      _$AuthProvidersFromJson(json);
}

@freezed
abstract class RegisterRequest with _$RegisterRequest {
  const factory RegisterRequest({
    required String email,
    required String password,
    String? displayName,
  }) = _RegisterRequest;

  factory RegisterRequest.fromJson(Map<String, dynamic> json) =>
      _$RegisterRequestFromJson(json);
}

@freezed
abstract class LoginRequest with _$LoginRequest {
  const factory LoginRequest({
    required String email,
    required String password,
  }) = _LoginRequest;

  factory LoginRequest.fromJson(Map<String, dynamic> json) =>
      _$LoginRequestFromJson(json);
}

/// Login social do Android — o ID token do Credential Manager.
@freezed
abstract class GoogleIdTokenRequest with _$GoogleIdTokenRequest {
  const factory GoogleIdTokenRequest({required String idToken}) =
      _GoogleIdTokenRequest;

  factory GoogleIdTokenRequest.fromJson(Map<String, dynamic> json) =>
      _$GoogleIdTokenRequestFromJson(json);
}

/// Sign in with Apple.
///
/// O [displayName] vai separado do token porque a Apple não põe o nome no JWT: ele vem à parte
/// e **só na primeira autorização**. Se não for enviado agora, não há como recuperá-lo depois.
@freezed
abstract class AppleIdTokenRequest with _$AppleIdTokenRequest {
  const factory AppleIdTokenRequest({
    required String idToken,
    String? displayName,
  }) = _AppleIdTokenRequest;

  factory AppleIdTokenRequest.fromJson(Map<String, dynamic> json) =>
      _$AppleIdTokenRequestFromJson(json);
}

@freezed
abstract class ForgotPasswordRequest with _$ForgotPasswordRequest {
  const factory ForgotPasswordRequest({required String email}) =
      _ForgotPasswordRequest;

  factory ForgotPasswordRequest.fromJson(Map<String, dynamic> json) =>
      _$ForgotPasswordRequestFromJson(json);
}

@freezed
abstract class ResetPasswordRequest with _$ResetPasswordRequest {
  const factory ResetPasswordRequest({
    required String userId,
    required String token,
    required String password,
  }) = _ResetPasswordRequest;

  factory ResetPasswordRequest.fromJson(Map<String, dynamic> json) =>
      _$ResetPasswordRequestFromJson(json);
}
