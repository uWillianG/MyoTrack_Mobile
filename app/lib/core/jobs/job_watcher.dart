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
///
/// **A espera tem prazo, e ele vale para os dois caminhos.** Ver [maxWait].
class JobWatcher {
  JobWatcher(this._api);

  final ApiClient _api;

  static const Duration pollInterval = Duration(seconds: 2);

  /// Quanto se acompanha um job antes de desistir — **SSE e polling somados**.
  ///
  /// Havia um teto aqui desde o começo, mas ele era só do polling: 60 tentativas × 2 s,
  /// herdadas da SPA. **O SSE passava por baixo dele.** Com o stream de pé, o `await for` só
  /// termina quando o servidor fecha, e o servidor segura a conexão por 15 minutos
  /// (`JobsController.STREAM_DEADLINE`) — então um job que ninguém pega, porque o Worker
  /// está fora do ar ou a fila parou, deixava a tela girando esses 15 minutos antes de a
  /// primeira consulta de polling sequer acontecer. É o que se via como "a estimativa de
  /// refeição trava": o app não estava lento, estava esperando por prazo nenhum.
  ///
  /// Três minutos porque é o que cabe na frente de quem espera **e** ainda cobre a chamada
  /// mais lenta que pode dar certo: no Worker, uma tentativa de IA tem teto de 45 s e a
  /// repetição por falha passageira leva o pior caso a pouco mais de um minuto e meio. Quem
  /// legitimamente demora mais que isso diz o seu próprio prazo — ver
  /// `JobGenerationController.deadline` e a análise de vídeo, que é a exceção.
  static const Duration maxWait = Duration(minutes: 3);

  /// Emite o estado do job até um estado terminal ou até [within] se esgotar, e então fecha.
  ///
  /// A UI escuta e mostra progresso; o último evento diz se deu certo. Estourado o prazo, o
  /// stream termina em erro — ver [_gaveUpMessage] para o que ele diz.
  Stream<JobStatus> watch(String jobId, {Duration within = maxWait}) async* {
    final deadline = DateTime.now().add(within);
    var terminou = false;

    // O `await for` aqui não é estilo: com `yield* _streamViaSse(...)` o erro do stream
    // interno vai direto para quem escuta e **não passa** pelo `catch` abaixo, então o
    // polling nunca assumia. O sintoma era a falha do SSE virar erro na tela — "Não foi
    // possível analisar a foto" — enquanto o job terminava bem no servidor. Consumir evento
    // a evento traz o erro para dentro deste escopo, que é onde ele pode ser tratado.
    try {
      await for (final status in _until(_streamViaSse(jobId), deadline)) {
        yield status;
        terminou = status.isTerminal;
      }
    } catch (_) {
      // Queda do SSE não é erro do job — só significa que este caminho não está
      // disponível. O polling assume sem que a UI precise saber.
    }

    if (terminou) {
      return;
    }

    // Repetir um estado que o SSE já emitiu antes de cair é inofensivo: a tela só troca o
    // rótulo de progresso, e o consumidor decide pelo último evento.
    yield* _poll(jobId, deadline);
  }

  /// Conveniência para quem só quer o resultado final.
  Future<JobStatus> await_(String jobId, {Duration within = maxWait}) async =>
      watch(jobId, within: within).last;

  /// [source] cortado no instante [deadline], tenha ele emitido alguma coisa ou não.
  ///
  /// `Stream.timeout` não serve aqui: ele mede o **silêncio entre eventos**, e o silêncio do
  /// SSE é legítimo — o servidor só manda evento quando o estado muda, e entre "pegou o job"
  /// e "terminou" pode não haver nada a dizer por um minuto inteiro. O que precisa acabar não
  /// é o silêncio, é a espera inteira.
  ///
  /// Cancelar a inscrição fecha a conexão do SSE de verdade. Sem isso, desistir na tela
  /// deixaria um socket aberto por trás dela até o servidor cansar.
  static Stream<T> _until<T>(Stream<T> source, DateTime deadline) {
    final remaining = deadline.difference(DateTime.now());
    if (remaining <= Duration.zero) {
      return Stream<T>.empty();
    }

    final controller = StreamController<T>();
    StreamSubscription<T>? subscription;
    Timer? timer;

    void encerrar() {
      timer?.cancel();
      timer = null;
      subscription?.cancel();
      subscription = null;
      if (!controller.isClosed) {
        controller.close();
      }
    }

    subscription = source.listen(
      controller.add,
      onError: controller.addError,
      onDone: encerrar,
    );
    timer = Timer(remaining, encerrar);
    controller.onCancel = encerrar;

    return controller.stream;
  }

  Stream<JobStatus> _streamViaSse(String jobId) async* {
    // Nada de `access_token` na query. O backend aceita o token ali em /api/jobs/** por
    // causa do EventSource do browser, que não manda header — mas o Dio manda, e o
    // AuthInterceptor já põe o `Authorization` nesta requisição também. Mandar os dois faz o
    // Spring Security recusar com 400 "Found multiple bearer tokens in the request" antes de
    // o resolver poder escolher um, e ainda escrevia o JWT inteiro no logcat pela URL.
    final response = await _api.raw.get<ResponseBody>(
      '/api/jobs/$jobId/stream',
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

    // Stream fechou sem estado terminal (worker reiniciou, proxy cortou, o prazo acabou):
    // termina em silêncio e deixa o polling fechar a conta. Quem chama já decide pelo último
    // estado que chegou, então a exceção que existia aqui não dizia nada que `terminou`
    // continuar falso não dissesse — e tinha um custo: cancelada a espera, este gerador ainda
    // corria até o fim do `await for` e lançava para uma inscrição que já não existe, o que
    // sai como erro assíncrono sem dono.
  }

  /// Consulta até um estado terminal ou até [deadline]. **Consulta ao menos uma vez.**
  ///
  /// A primeira consulta não é opcional, e é o que salva o caso de o prazo ter interrompido
  /// o SSE: ela é a última chance de descobrir que o job terminou no segundo em que a espera
  /// acabou, e é dela que sai o estado que decide a mensagem de desistência.
  Stream<JobStatus> _poll(String jobId, DateTime deadline) async* {
    JobStatus? last;

    while (true) {
      final json = await _api.get<Map<String, dynamic>>('/api/jobs/$jobId');
      final status = JobStatus.fromJson(json);
      last = status;
      yield status;

      if (status.isTerminal) {
        return;
      }
      if (DateTime.now().add(pollInterval).isAfter(deadline)) {
        break;
      }
      await Future<void>.delayed(pollInterval);
    }

    throw ApiException(_gaveUpMessage(last));
  }

  /// A notícia de que se desistiu, dita pelo último estado conhecido.
  ///
  /// **Um job que nunca saiu de `pending` não demorou: ninguém o pegou.** São duas avarias
  /// diferentes com o mesmo sintoma na tela, e o conselho que cada uma pede é o oposto do
  /// outro — insistir contra uma fila parada só gasta a cota do dia, que é contada por job
  /// enfileirado e não por resultado entregue. Dizer qual das duas é também poupa o
  /// diagnóstico que já foi feito duas vezes olhando para o app quando o problema estava na
  /// fila.
  static String _gaveUpMessage(JobStatus? last) =>
      last == null || last.state == JobState.pending
      ? 'O pedido entrou na fila e nada começou a processá-lo. '
            'Tente de novo em alguns minutos.'
      : 'A operação demorou mais do que o esperado. Tente novamente.';
}
