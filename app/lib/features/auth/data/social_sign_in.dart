import 'dart:io';

import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../../../core/env.dart';

/// O usuário fechou a janela de login sem concluir. Não é erro — a tela apenas volta ao
/// estado anterior, sem mensagem vermelha.
class SignInCancelled implements Exception {
  const SignInCancelled();
}

/// Falha real no provedor de login social.
class SocialSignInException implements Exception {
  const SocialSignInException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Obtém as credenciais do Google e da Apple no aparelho.
///
/// Devolve apenas o que o backend precisa para validar. O app **nunca** decide que o login
/// deu certo: quem valida a assinatura do token e emite a sessão do MyoTrack é o servidor.
class SocialSignIn {
  SocialSignIn({GoogleSignIn? google})
    : _google =
          google ??
          GoogleSignIn(
            // Sem o serverClientId o Google não emite ID token — e é justamente o ID
            // token que o backend valida. Ver Env.googleServerClientId.
            serverClientId: Env.isGoogleSignInConfigured
                ? Env.googleServerClientId
                : null,
            // `email` já vem por padrão; `profile` traz o nome para preencher a conta nova.
            scopes: const ['email', 'profile'],
          );

  final GoogleSignIn _google;

  /// Só faz sentido oferecer Sign in with Apple no iOS.
  ///
  /// O plugin também funciona no Android via fluxo web, mas exige um Services ID e um
  /// redirect configurados — e no Android o Google já cobre o caso.
  static bool get isAppleAvailable => !Platform.isAndroid;

  /// ID token do Google, para trocar em `POST /api/auth/google/id-token`.
  Future<String> google() async {
    final GoogleSignInAccount? account;
    try {
      account = await _google.signIn();
    } on Exception catch (e) {
      throw SocialSignInException('Não foi possível entrar com o Google. ($e)');
    }

    if (account == null) {
      throw const SignInCancelled();
    }

    final auth = await account.authentication;
    final idToken = auth.idToken;
    if (idToken == null || idToken.isEmpty) {
      // Acontece quando o serverClientId não está configurado no app: sem ele o Google
      // devolve só o access token, que o backend não aceita.
      throw const SocialSignInException(
        'O Google não devolveu um token de identidade. Verifique a configuração do app.',
      );
    }
    return idToken;
  }

  /// Credencial da Apple: o identity token e, **apenas na primeira autorização**, o nome.
  Future<AppleCredential> apple() async {
    final AuthorizationCredentialAppleID credential;
    try {
      credential = await SignInWithApple.getAppleIDCredential(
        scopes: const [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );
    } on SignInWithAppleAuthorizationException catch (e) {
      if (e.code == AuthorizationErrorCode.canceled) {
        throw const SignInCancelled();
      }
      throw SocialSignInException(
        'Não foi possível entrar com a Apple. (${e.code})',
      );
    } on Exception catch (e) {
      throw SocialSignInException('Não foi possível entrar com a Apple. ($e)');
    }

    final idToken = credential.identityToken;
    if (idToken == null || idToken.isEmpty) {
      throw const SocialSignInException(
        'A Apple não devolveu um token de identidade.',
      );
    }

    return AppleCredential(
      idToken: idToken,
      displayName: _joinName(credential.givenName, credential.familyName),
    );
  }

  Future<void> signOut() async {
    // Sem isso, o próximo login reusa a conta anterior sem perguntar — ruim em aparelho
    // compartilhado e péssimo para quem quer trocar de conta.
    try {
      await _google.signOut();
    } on Exception {
      // Falha ao desconectar não pode impedir o logout do MyoTrack, que já aconteceu.
    }
  }

  static String? _joinName(String? given, String? family) {
    final parts = [
      given,
      family,
    ].where((p) => p != null && p.trim().isNotEmpty);
    return parts.isEmpty ? null : parts.map((p) => p!.trim()).join(' ');
  }
}

/// Resultado do Sign in with Apple.
///
/// O [displayName] vem preenchido **uma única vez na vida da conta** — na primeira
/// autorização. Nos logins seguintes a Apple devolve null, e o servidor já terá gravado.
class AppleCredential {
  const AppleCredential({required this.idToken, this.displayName});

  final String idToken;
  final String? displayName;
}
