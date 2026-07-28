import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/api_client.dart';
import '../../core/providers.dart';

/// Direitos do titular (LGPD) — `/api/privacy`.
class PrivacyRepository {
  PrivacyRepository(this._api);

  final ApiClient _api;

  /// Apaga a conta e todos os dados, definitivamente.
  ///
  /// A [confirmation] é a senha da conta — ou, para quem entrou com Google ou Apple, o
  /// próprio e-mail: essas contas não têm senha, e sem essa alternativa o titular ficaria
  /// sem como exercer o direito de eliminação. Quem decide qual das duas serve é o servidor.
  Future<void> deleteAccount(String confirmation) => _api.delete<void>(
    '/api/privacy/account',
    body: {'password': confirmation},
  );
}

final privacyRepositoryProvider = Provider<PrivacyRepository>(
  (ref) => PrivacyRepository(ref.watch(apiClientProvider)),
);

/// Estado da tela de exclusão.
class DeleteAccountState {
  const DeleteAccountState({this.deleting = false, this.error});

  final bool deleting;
  final String? error;

  static const idle = DeleteAccountState();
}

class DeleteAccountController extends Notifier<DeleteAccountState> {
  @override
  DeleteAccountState build() => DeleteAccountState.idle;

  /// Devolve se a conta foi apagada.
  ///
  /// Em caso de sucesso a sessão é descartada aqui mesmo: os tokens continuariam válidos até
  /// expirar, e um app aberto com sessão de uma conta que não existe mais só produziria 404
  /// em cada tela.
  Future<bool> delete(String confirmation) async {
    if (state.deleting) {
      return false;
    }
    state = const DeleteAccountState(deleting: true);

    try {
      await ref.read(privacyRepositoryProvider).deleteAccount(confirmation);

      await ref.read(tokenStoreProvider).clear();
      // Invalidar faz a guarda do go_router reavaliar e levar ao login sozinha.
      ref.invalidate(authStateProvider);

      state = DeleteAccountState.idle;
      return true;
    } catch (error) {
      state = DeleteAccountState(
        deleting: false,
        // A mensagem do servidor é a que orienta: ela distingue "senha incorreta" de
        // "digite o e-mail da sua conta", e o app não tem como saber qual dos dois é o caso.
        error: '$error',
      );
      return false;
    }
  }
}

final deleteAccountProvider =
    NotifierProvider<DeleteAccountController, DeleteAccountState>(
      DeleteAccountController.new,
    );
