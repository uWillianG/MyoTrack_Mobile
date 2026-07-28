import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/api_exception.dart';
import '../../core/providers.dart';
import 'data/auth_models.dart';
import 'data/auth_repository.dart';
import 'data/social_sign_in.dart';

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepository(ref.watch(apiClientProvider)),
);

final socialSignInProvider = Provider<SocialSignIn>((ref) => SocialSignIn());

/// Quais botões de login mostrar. Falha de rede aqui não pode travar a tela: o
/// login por e-mail e senha continua funcionando, então o padrão é "só o básico".
final authProvidersProvider = FutureProvider<AuthProviders>((ref) async {
  try {
    return await ref.watch(authRepositoryProvider).providers();
  } on ApiException {
    return const AuthProviders();
  }
});

/// Estado da tela de login.
class AuthState {
  const AuthState({this.loading = false, this.error, this.info});

  final bool loading;

  /// Mensagem de erro em pt-BR — vinda do backend quando ele mandou uma.
  final String? error;

  /// Mensagem neutra (ex.: confirmação do e-mail de redefinição).
  final String? info;

  AuthState copyWith({bool? loading, String? error, String? info}) =>
      AuthState(loading: loading ?? this.loading, error: error, info: info);

  static const idle = AuthState();
}

class AuthController extends StateNotifier<AuthState> {
  AuthController(this._ref) : super(AuthState.idle);

  final Ref _ref;

  AuthRepository get _repo => _ref.read(authRepositoryProvider);
  SocialSignIn get _social => _ref.read(socialSignInProvider);

  Future<bool> login({required String email, required String password}) =>
      _run(() => _repo.login(email: email, password: password));

  Future<bool> register({
    required String email,
    required String password,
    String? displayName,
  }) => _run(
    () => _repo.register(
      email: email,
      password: password,
      displayName: displayName,
    ),
  );

  Future<bool> signInWithGoogle() => _runSocial(() async {
    final idToken = await _social.google();
    await _repo.signInWithGoogle(idToken);
  });

  Future<bool> signInWithApple() => _runSocial(() async {
    final credential = await _social.apple();
    await _repo.signInWithApple(
      idToken: credential.idToken,
      displayName: credential.displayName,
    );
  });

  Future<void> forgotPassword(String email) async {
    state = const AuthState(loading: true);
    try {
      final message = await _repo.forgotPassword(email);
      state = AuthState(info: message);
    } on ApiException catch (e) {
      state = AuthState(error: e.message);
    }
  }

  /// Troca a senha usando o link do e-mail. Devolve se deu certo.
  ///
  /// Não autentica em seguida de propósito: o link chega por e-mail, e uma caixa de entrada
  /// aberta em outro aparelho abriria a sessão sem que ninguém digitasse a senha nova. O
  /// backend responde a mesma coisa e a SPA faz igual — manda para o login.
  Future<bool> resetPassword({
    required String userId,
    required String token,
    required String password,
  }) async {
    state = const AuthState(loading: true);
    try {
      final message = await _repo.resetPassword(
        userId: userId,
        token: token,
        password: password,
      );
      state = AuthState(info: message);
      return true;
    } on ApiException catch (e) {
      state = AuthState(error: e.message);
      return false;
    }
  }

  void clearMessages() => state = AuthState(loading: state.loading);

  /// Executa e converte o resultado em estado de tela; devolve se autenticou.
  Future<bool> _run(Future<void> Function() action) async {
    state = const AuthState(loading: true);
    try {
      await action();
      // Invalidar faz o go_router reavaliar a guarda e navegar para a home.
      _ref.invalidate(authStateProvider);
      state = AuthState.idle;
      return true;
    } on ApiException catch (e) {
      state = AuthState(error: e.message);
      return false;
    }
  }

  Future<bool> _runSocial(Future<void> Function() action) async {
    state = const AuthState(loading: true);
    try {
      await action();
      _ref.invalidate(authStateProvider);
      state = AuthState.idle;
      return true;
    } on SignInCancelled {
      // Desistir do login não é erro — volta ao repouso, sem mensagem vermelha.
      state = AuthState.idle;
      return false;
    } on SocialSignInException catch (e) {
      state = AuthState(error: e.message);
      return false;
    } on ApiException catch (e) {
      state = AuthState(error: e.message);
      return false;
    }
  }
}

final authControllerProvider = StateNotifierProvider<AuthController, AuthState>(
  (ref) => AuthController(ref),
);
