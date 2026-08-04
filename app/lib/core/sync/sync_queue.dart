import 'dart:convert';

import '../db/local_database.dart';
import '../network/api_client.dart';
import '../network/api_exception.dart';
import 'sync_scheduler.dart';

/// Resultado de uma escrita que aceita ficar pendente.
enum WriteOutcome {
  /// Chegou ao servidor.
  sent,

  /// Sem rede: ficou guardada e sobe na próxima sincronização.
  queued,
}

/// Escrita offline-first: tenta enviar, e guarda localmente se a rede não colaborar.
///
/// O caso que motiva tudo isto é concreto: **a academia é onde o app mais é usado e onde
/// menos há sinal**. Perder as séries de um treino porque o subsolo não pega é o tipo de
/// falha que faz alguém desinstalar.
///
/// Não há checagem prévia de conectividade de propósito. Wi-Fi conectado sem internet, portal
/// cativo e rede móvel com 1 barra são todos "conectado" para o sistema e falham na hora do
/// envio. Tentar e reagir ao erro é mais confiável do que perguntar antes.
class SyncQueue {
  SyncQueue(this._api, this._db, {SyncScheduler? scheduler})
    : _scheduler = scheduler ?? const NoopSyncScheduler();

  final ApiClient _api;
  final LocalDatabase _db;
  final SyncScheduler _scheduler;

  /// Envia; se a rede falhar, guarda e devolve [WriteOutcome.queued].
  ///
  /// Erros do servidor (4xx) **são propagados**: um corpo que ele recusou hoje vai recusar
  /// amanhã, e enfileirar isso entupiria a fila para sempre.
  Future<WriteOutcome> submit(
    String endpoint,
    Map<String, dynamic> body,
  ) async {
    // Antes de mandar o novo, esvazia o que ficou para trás — assim a ordem cronológica
    // dos registros no servidor bate com a ordem em que o usuário os criou.
    await flush();

    try {
      await _api.post<dynamic>(endpoint, body: body);
      return WriteOutcome.sent;
    } on ApiException catch (e) {
      if (!e.isRetryable) {
        rethrow;
      }
      await _db.enqueue(endpoint, jsonEncode(body));
      // Pede ao sistema que acorde o app quando a rede voltar. Sem isto a fila só andaria na
      // próxima escrita — quem registrou o treino no subsolo e guardou o celular ficaria com
      // tudo parado no aparelho por tempo indeterminado.
      await _scheduler.requestFlush();
      return WriteOutcome.queued;
    }
  }

  /// Tenta enviar tudo que está pendente. Devolve quantas escritas subiram.
  ///
  /// Para no primeiro erro de rede: se a conexão caiu, as seguintes também falhariam, e
  /// insistir só gastaria bateria.
  Future<int> flush() async {
    var sent = 0;

    for (final write in await _db.pending()) {
      try {
        await _api.post<dynamic>(
          write.endpoint,
          body: jsonDecode(write.payload),
        );
        await _db.removePending(write.id);
        sent++;
      } on ApiException catch (e) {
        if (e.isRetryable) {
          break;
        }
        // 401 não é conteúdo recusado, é sessão: o token venceu e a renovação não pegou. A
        // escrita continua válida e sobe assim que houver login. Descartar aqui perderia um
        // treino inteiro por token vencido — e na sincronização em background isso
        // aconteceria sem ninguém ver.
        if (e.isUnauthorized) {
          await _db.recordAttempt(write.id, e.message);
          break;
        }
        // O servidor recusou o conteúdo, e vai recusar de novo: manter na fila bloquearia
        // todas as escritas seguintes, e o usuário perderia tudo que registrasse depois sem
        // perceber. Sai da fila — mas não some. Vai para as recusadas, com payload e motivo,
        // para que o app possa dizer o que não subiu em vez de o registro evaporar.
        await _db.discardPending(write, e.message);
      }
    }

    return sent;
  }

  Future<int> pendingCount() => _db.countPending();

  Stream<int> watchPendingCount() => _db.watchPendingCount();

  /// O que o servidor recusou e não vai voltar a tentar.
  Future<List<DiscardedWrite>> discarded() => _db.discarded();

  Future<void> clearDiscarded() => _db.clearDiscarded();
}
