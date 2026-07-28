/// Pede ao sistema operacional que esvazie a fila de escrita quando der.
///
/// Fica em arquivo próprio para quebrar o ciclo: a [SyncQueue] depende desta interface, e a
/// implementação de verdade (`WorkManagerSync`) depende da fila para fazer o trabalho.
///
/// É interface pelo mesmo motivo do alarme do descanso: teste de unidade não tem WorkManager
/// do outro lado do canal de plataforma.
abstract class SyncScheduler {
  /// Agenda um esvaziamento assim que houver rede.
  Future<void> requestFlush();
}

/// Não faz nada. Padrão em teste e nas plataformas sem WorkManager.
class NoopSyncScheduler implements SyncScheduler {
  const NoopSyncScheduler();

  @override
  Future<void> requestFlush() async {}
}
