import 'dart:io';

import 'package:workmanager/workmanager.dart';

import '../auth/token_store.dart';
import '../db/local_database.dart';
import '../network/api_client.dart';
import 'sync_queue.dart';
import 'sync_scheduler.dart';

/// Nome da tarefa entregue ao callback. Só existe uma, então não há despacho por nome.
const String _flushTaskName = 'myotrack.flush';

/// Uma agenda recorrente (a rede de segurança) e uma avulsa (a pressa de subir agora).
const String _periodicTaskId = 'myotrack.sync.periodic';
const String _oneOffTaskId = 'myotrack.sync.now';

/// Ponto de entrada do isolate de background.
///
/// Precisa ser função de topo e ter `@pragma('vm:entry-point')`: quem a chama é o sistema
/// operacional, com o app fechado, e sem a anotação o compilador a remove por parecer código
/// morto — o sintoma é a tarefa "rodar" sem nunca executar nada.
@pragma('vm:entry-point')
void syncCallbackDispatcher() {
  Workmanager().executeTask((_, _) => flushPendingWrites());
}

/// Sobe o que estiver pendente. Devolve se a fila ficou vazia.
///
/// Roda num isolate próprio, sem nada do app: providers, estado e navegação vivem no isolate
/// principal e não existem aqui. Por isso monta o cliente e o banco do zero.
Future<bool> flushPendingWrites() async {
  // O app pode estar aberto e com o mesmo arquivo SQLite em uso. As escritas aqui são curtas
  // e o próprio SQLite serializa os acessos; o banco é fechado no fim para não deixar o
  // arquivo travado depois que o isolate morre.
  final database = LocalDatabase();

  try {
    final queue = SyncQueue(ApiClient(tokenStore: TokenStore()), database);
    await queue.flush();

    // Sobrou pendência: devolver false faz o WorkManager tentar de novo com backoff, em vez
    // de dar a tarefa por cumprida e esperar a próxima janela.
    return await queue.pendingCount() == 0;
  } catch (_) {
    // Qualquer coisa inesperada aqui é falha de tarefa, não crash do app: o isolate não tem
    // tela para mostrar erro, e o que interessa é que o sistema reagende.
    return false;
  } finally {
    await database.close();
  }
}

/// Agendamento pelo WorkManager (Android) / BGTaskScheduler (iOS).
class WorkManagerSync implements SyncScheduler {
  const WorkManagerSync();

  /// Fora de Android e iOS não há agendador — e `Platform` nem responde na web.
  static bool get isSupported => Platform.isAndroid || Platform.isIOS;

  /// Registra o callback e a agenda recorrente. Chamada uma vez, na partida do app.
  static Future<void> initialize() async {
    if (!isSupported) {
      return;
    }

    await Workmanager().initialize(syncCallbackDispatcher);

    // A recorrente é a rede de segurança para quem registrou treino offline e não abriu mais
    // o app. Uma hora é bem mais do que o mínimo de 15 minutos do Android de propósito: a
    // urgência real fica com a tarefa avulsa, disparada quando algo entra na fila.
    await Workmanager().registerPeriodicTask(
      _periodicTaskId,
      _flushTaskName,
      frequency: const Duration(hours: 1),
      constraints: Constraints(networkType: NetworkType.connected),
      // keep: reabrir o app não pode reiniciar a contagem, ou a tarefa nunca venceria em
      // quem abre o app toda hora.
      existingWorkPolicy: ExistingPeriodicWorkPolicy.keep,
      backoffPolicy: BackoffPolicy.exponential,
    );
  }

  @override
  Future<void> requestFlush() async {
    if (!isSupported) {
      return;
    }

    await Workmanager().registerOneOffTask(
      _oneOffTaskId,
      _flushTaskName,
      // É esta restrição que faz o trabalho: o sistema segura a tarefa e a solta sozinho
      // quando a conexão volta, sem o app precisar ficar vigiando a rede.
      constraints: Constraints(networkType: NetworkType.connected),
      // keep: várias séries registradas seguidas no subsolo enfileiram uma tarefa só.
      existingWorkPolicy: ExistingWorkPolicy.keep,
      backoffPolicy: BackoffPolicy.exponential,
      backoffPolicyDelay: const Duration(minutes: 1),
    );
  }
}
