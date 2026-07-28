import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';

import '../network/api_client.dart';
import '../network/api_exception.dart';
import 'job_status.dart';

/// Acompanha um job assíncrono de IA até ele terminar.
///
/// Porte de `watchJob`/`pollJob` da SPA (`frontend/src/lib/api.ts:87-125`). Seis
/// funcionalidades dependem disto — geração de treino e de dieta, análise de refeição e de
/// vídeo, coach e relatório semanal —, por isso existe uma vez só.
///
/// Tenta primeiro **SSE** (`/api/jobs/{id}/stream`), que entrega o resultado assim que o
/// worker termina. Se o stream falhar — proxy que não repassa `text/event-stream`, rede
/// móvel instável, servidor sem suporte —, cai para **polling a cada 2 s**. O usuário não
/// percebe a diferença; o SSE só economiza bateria e latência.
class JobWatcher {
  JobWatcher(this._api);

  final ApiClient _api;

  static const Duration pollInterval = Duration(seconds: 2);

  /// 60 tentativas × 2 s = 2 minutos, o mesmo teto da SPA.
  static const int maxPollAttempts = 60;

  /// Emite o estado do job até um estado terminal, e então fecha.
  ///
  /// A UI escuta e mostra progresso; o último evento diz se deu certo.
  Stream<JobStatus> watch(String jobId) async* {
    try {
      yield* _streamViaSse(jobId);
      return;
    } catch (_) {
      // Queda do SSE não é erro do job — só significa que este caminho não está
      // disponível. O polling assume sem que a UI precise saber.
    }

    yield* _poll(jobId);
  }

  /// Conveniência para quem só quer o resultado final.
  Future<JobStatus> await_(String jobId) async => watch(jobId).last;

  Stream<JobStatus> _streamViaSse(String jobId) async* {
    final tokens = await _api.tokens.read();
    if (tokens == null) {
      throw ApiException('Sessão expirada.', statusCode: 401);
    }

    // O token vai na query porque nem o EventSource do browser nem os clientes SSE
    // enviam headers customizados. O backend só aceita isso em /api/jobs/** —
    // ver JobStreamBearerTokenResolver no Java.
    final response = await _api.raw.get<ResponseBody>(
      '/api/jobs/$jobId/stream',
      queryParameters: {'access_token': tokens.accessToken},
      options: Options(
        responseType: ResponseType.stream,
        headers: {'Accept': 'text/event-stream'},
        // Um stream aberto não deve estourar o timeout de resposta comum.
        receiveTimeout: Duration.zero,
      ),
    );

    final body = response.data;
    if (body == null) {
      throw ApiException('Stream de job indisponível.');
    }

    // O SSE quebra o corpo em linhas `data: {...}`, separadas por linha em branco.
    final lines = utf8.decoder
        .bind(body.stream.map((chunk) => chunk.toList()))
        .transform(const LineSplitter());

    await for (final line in lines) {
      if (!line.startsWith('data:')) {
        continue;
      }
      final payload = line.substring(5).trim();
      if (payload.isEmpty) {
        continue;
      }

      final decoded = json.decode(payload) as Map<String, dynamic>;
      // O backend manda {"error": ...} quando o job não existe ou não é do usuário.
      if (decoded['error'] != null) {
        throw ApiException('Análise não encontrada.', statusCode: 404);
      }

      final status = JobStatus.fromJson(decoded);
      yield status;
      if (status.isTerminal) {
        return;
      }
    }

    // Stream fechou sem estado terminal (worker reiniciou, proxy cortou):
    // deixa o polling terminar o trabalho.
    throw ApiException('Stream encerrado antes da conclusão.');
  }

  Stream<JobStatus> _poll(String jobId) async* {
    for (var attempt = 0; attempt < maxPollAttempts; attempt++) {
      final json = await _api.get<Map<String, dynamic>>('/api/jobs/$jobId');
      final status = JobStatus.fromJson(json);
      yield status;

      if (status.isTerminal) {
        return;
      }
      await Future<void>.delayed(pollInterval);
    }

    throw ApiException(
      'A geração demorou mais do que o esperado. Tente novamente.',
    );
  }
}
