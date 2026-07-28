// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auth_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_AuthProviders _$AuthProvidersFromJson(Map<String, dynamic> json) =>
    _AuthProviders(
      google: json['google'] as bool? ?? false,
      apple: json['apple'] as bool? ?? false,
      passwordReset: json['passwordReset'] as bool? ?? false,
    );

Map<String, dynamic> _$AuthProvidersToJson(_AuthProviders instance) =>
    <String, dynamic>{
      'google': instance.google,
      'apple': instance.apple,
      'passwordReset': instance.passwordReset,
    };

_RegisterRequest _$RegisterRequestFromJson(Map<String, dynamic> json) =>
    _RegisterRequest(
      email: json['email'] as String,
      password: json['password'] as String,
      displayName: json['displayName'] as String?,
    );

Map<String, dynamic> _$RegisterRequestToJson(_RegisterRequest instance) =>
    <String, dynamic>{
      'email': instance.email,
      'password': instance.password,
      'displayName': instance.displayName,
    };

_LoginRequest _$LoginRequestFromJson(Map<String, dynamic> json) =>
    _LoginRequest(
      email: json['email'] as String,
      password: json['password'] as String,
    );

Map<String, dynamic> _$LoginRequestToJson(_LoginRequest instance) =>
    <String, dynamic>{'email': instance.email, 'password': instance.password};

_GoogleIdTokenRequest _$GoogleIdTokenRequestFromJson(
  Map<String, dynamic> json,
) => _GoogleIdTokenRequest(idToken: json['idToken'] as String);

Map<String, dynamic> _$GoogleIdTokenRequestToJson(
  _GoogleIdTokenRequest instance,
) => <String, dynamic>{'idToken': instance.idToken};

_AppleIdTokenRequest _$AppleIdTokenRequestFromJson(Map<String, dynamic> json) =>
    _AppleIdTokenRequest(
      idToken: json['idToken'] as String,
      displayName: json['displayName'] as String?,
    );

Map<String, dynamic> _$AppleIdTokenRequestToJson(
  _AppleIdTokenRequest instance,
) => <String, dynamic>{
  'idToken': instance.idToken,
  'displayName': instance.displayName,
};

_ForgotPasswordRequest _$ForgotPasswordRequestFromJson(
  Map<String, dynamic> json,
) => _ForgotPasswordRequest(email: json['email'] as String);

Map<String, dynamic> _$ForgotPasswordRequestToJson(
  _ForgotPasswordRequest instance,
) => <String, dynamic>{'email': instance.email};

_ResetPasswordRequest _$ResetPasswordRequestFromJson(
  Map<String, dynamic> json,
) => _ResetPasswordRequest(
  userId: json['userId'] as String,
  token: json['token'] as String,
  password: json['password'] as String,
);

Map<String, dynamic> _$ResetPasswordRequestToJson(
  _ResetPasswordRequest instance,
) => <String, dynamic>{
  'userId': instance.userId,
  'token': instance.token,
  'password': instance.password,
};
