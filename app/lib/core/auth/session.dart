import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../db/local_database.dart';
import '../notifications/push_registration.dart';
import '../providers.dart';

/// Fecha a sessão: desliga o push, descarta os tokens, apaga o que é do usuário neste
/// aparelho e faz a guarda do router levar ao login.
///
/// **Mora em core e não numa feature porque dois caminhos diferentes precisam dela e não
/// podem divergir**: o "Sair da conta" e a exclusão de conta. Um encerramento pela metade não
/// dá erro — ele só deixa rastro da pessoa anterior no aparelho, e é assim que ninguém repara.
///
/// A ordem das quatro etapas não é arbitrária:
///
/// 1. **Desregistrar o push antes de tudo**, porque a chamada precisa ir autenticada. Depois
///    de limpar os tokens ela iria anônima e o servidor a recusaria — e o aparelho seguiria
///    recebendo "seu relatório está pronto" de quem saiu, na tela de bloqueio de quem entrar
///    depois.
/// 2. **Descartar os tokens**, que é o que define "não há sessão".
/// 3. **Apagar o banco local**, pelo motivo descrito em [LocalDatabase.wipe].
/// 4. **Invalidar os providers que leem o token**, e não só o de autenticação. Eles são
///    `FutureProvider` sem `autoDispose`: sem invalidar, o e-mail e os papéis da pessoa
///    anterior sobrevivem à troca de conta em memória, e o cabeçalho da aba Conta abre a
///    sessão nova com o e-mail e as iniciais de quem saiu.
class SessionCloser {
  SessionCloser(this._ref);

  final Ref _ref;

  /// [notifyServer] fica falso na exclusão de conta: o servidor já apagou os registros de push
  /// junto com o resto, e a chamada iria com o token de uma conta que não existe mais — um 404
  /// engolido em silêncio, mas ainda assim uma ida à rede segurando a tela.
  Future<void> close({bool notifyServer = true}) async {
    if (notifyServer) {
      // A própria `unregister` já engole falha de rede: sair da conta não pode depender de o
      // servidor estar de pé.
      await _ref.read(deviceRegistrarProvider).unregister();
    }

    await _ref.read(tokenStoreProvider).clear();
    await _ref.read(localDatabaseProvider).wipe();

    _ref
      ..invalidate(authStateProvider)
      ..invalidate(userEmailProvider)
      ..invalidate(userRolesProvider);
  }
}

final sessionCloserProvider = Provider<SessionCloser>(SessionCloser.new);
