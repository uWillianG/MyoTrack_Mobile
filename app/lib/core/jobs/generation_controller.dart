import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../network/api_exception.dart';
import '../providers.dart';
import 'job_status.dart';
import 'job_watcher.dart';

/// Estado de uma operação assíncrona de IA vista pela tela.
class GenerationState {
  const GenerationState({
    this.running = false,
    this.step,
    this.phase,
    this.error,
    this.limitReached = false,
  });

  final bool running;

  /// Texto de progresso — muda quando o worker pega o job.
  final String? step;

  /// A fase crua do job, quando ela já é conhecida. Null entre o toque em enviar e a
  /// primeira resposta do servidor, que é quando ainda não há job para ter fase.
  ///
  /// Existe ao lado de [step] porque rótulo é para ler e fase é para decidir: a tela do coach
  /// só narra o que o worker está fazendo depois que ele **de fato** pegou o job, e comparar
  /// o texto de [step] para descobrir isso quebraria na primeira vez que alguém reescrevesse
  /// a frase.
  final JobState? phase;

  final String? error;

  /// O erro é a cota diária de IA, e não uma falha.
  ///
  /// Existe ao lado de [error] pela mesma razão que [phase] existe ao lado de [step]: **rótulo
  /// é para ler, condição é para decidir.** A frase vem pronta do servidor — é ele quem sabe o
  /// limite configurado no ambiente — e procurar "Assine o Pro" dentro dela para descobrir que
  /// foi cota quebraria na primeira vez que alguém reescrevesse o texto lá.
  ///
  /// O que a tela faz com isto é oferecer o caminho da assinatura em vez de um aviso que some
  /// sozinho: o servidor nomeia um destino, e até aqui nenhuma tela o oferecia.
  final bool limitReached;

  static const idle = GenerationState();
}

/// Base dos controllers que disparam um job de IA e esperam o resultado.
///
/// O fluxo é sempre o mesmo — enfileirar, acompanhar pelo [JobWatcher], recarregar o que
/// mudou — e se repete em treino, dieta, análise de refeição, análise de vídeo, coach e
/// relatório semanal. Escrever seis vezes seria seis oportunidades de esquecer o
/// `invalidate` ou de tratar a falha de um jeito diferente em cada tela.
abstract class JobGenerationController extends Notifier<GenerationState> {
  /// A execução em curso, identificada por objeto.
  ///
  /// Trocá-la de identidade é como [cancel] avisa um [start] que ainda está esperando que o
  /// resultado a caminho não interessa mais. Um `bool` não serviria: entre cancelar e tentar
  /// de novo há duas execuções vivas por um instante, e a que voltar por último não pode
  /// escrever por cima da tela da outra.
  Object? _run;

  StreamSubscription<JobStatus>? _watching;
  Completer<JobStatus?>? _finished;

  /// Quanto **esta** tela aceita esperar pelo job.
  ///
  /// O padrão do [JobWatcher] serve para todo mundo aqui. A análise de vídeo é a exceção e
  /// diz o seu próprio prazo: ela processa o vídeo quadro a quadro antes de chegar à IA, e
  /// desistir no prazo dos outros mataria um trabalho que ainda ia entregar.
  Duration get deadline => JobWatcher.maxWait;

  @override
  GenerationState build() => GenerationState.idle;

  /// Chama o endpoint que enfileira e devolve o `jobId`.
  Future<String> enqueue();

  /// Recarrega o que o job produziu. Só roda depois do estado terminal de sucesso.
  Future<void> reload();

  /// O retrato final do job, entregue logo antes de [reload].
  ///
  /// Quase todo job aqui **grava** o que produziu — o plano de treino, a análise da foto, a
  /// resposta do coach — e o [reload] vai buscar isso no servidor pelo caminho normal; o
  /// `resultJson` só carrega o id do que foi criado, e ninguém precisa dele.
  ///
  /// A estimativa de refeição por texto é a exceção, e é uma exceção de propósito: ela não
  /// persiste nada, porque o valor dela está em ser conferida e editada antes de virar caloria
  /// contada. O produto inteiro dela **é** o `resultJson`, e sem este gancho o único jeito de
  /// alcançá-lo seria escrever um segundo acompanhador de job ao lado deste — que é como as
  /// seis telas divergiriam de novo.
  ///
  /// Vazio por padrão: quem não precisa não fica sabendo que existe.
  void onResult(JobStatus status) {}

  /// Mensagem mostrada em cada etapa. Sobrescreva para adaptar ao domínio.
  String stepLabel(JobState state) => switch (state) {
    JobState.pending => 'Na fila…',
    JobState.processing => 'Processando…',
    _ => 'Finalizando…',
  };

  String get startingLabel => 'Enviando…';

  String get genericFailure => 'A operação falhou. Tente novamente.';

  Future<void> start() async {
    if (state.running) {
      return;
    }

    final run = Object();
    _run = run;
    state = GenerationState(running: true, step: startingLabel);

    try {
      final jobId = await enqueue();
      final last = await _follow(
        run,
        ref.read(jobWatcherProvider).watch(jobId, within: deadline),
      );

      // Cancelado enquanto se esperava. Quem cancelou já disse o que a tela mostra, e o que
      // chegou depois não é mais assunto dela.
      if (!identical(_run, run)) {
        return;
      }

      if (last == null || !last.succeeded) {
        state = GenerationState(error: last?.lastError ?? genericFailure);
        return;
      }

      onResult(last);
      // Só agora o resultado existe no servidor; recarregar antes traria o anterior.
      await reload();
      state = GenerationState.idle;
    } on ApiException catch (e) {
      if (identical(_run, run)) {
        // 429 é a cota do dia, e é a única recusa desta base que tem uma saída a oferecer.
        // Marcá-la aqui vale para os seis fluxos de IA de uma vez — nenhum controller precisa
        // saber que a assinatura existe.
        state = GenerationState(
          error: e.message,
          limitReached: e.isRateLimited,
        );
      }
    } catch (_) {
      if (identical(_run, run)) {
        state = GenerationState(error: genericFailure);
      }
    } finally {
      if (identical(_run, run)) {
        _run = null;
        _release();
      }
    }
  }

  /// Acompanha o job até o fim e devolve o último retrato — null quando não veio nenhum ou
  /// quando [cancel] interrompeu.
  ///
  /// Inscrição explícita em vez do `await for` que estava aqui: **cancelar exige a mão na
  /// inscrição**, e o `await for` não a entrega. Sem ela, "cancelar" seria só deixar de
  /// olhar — a conexão do SSE continuaria aberta por trás da tela até o servidor fechá-la, e
  /// a próxima tentativa começaria com a anterior ainda pendurada na rede.
  Future<JobStatus?> _follow(Object run, Stream<JobStatus> statuses) {
    if (!identical(_run, run)) {
      return Future<JobStatus?>.value();
    }

    final finished = Completer<JobStatus?>();
    JobStatus? last;

    _finished = finished;
    _watching = statuses.listen(
      (status) {
        last = status;
        state = GenerationState(
          running: true,
          step: stepLabel(status.state),
          phase: status.state,
        );
      },
      onError: (Object error, StackTrace stack) {
        _release();
        if (!finished.isCompleted) {
          finished.completeError(error, stack);
        }
      },
      onDone: () {
        _release();
        if (!finished.isCompleted) {
          finished.complete(last);
        }
      },
      cancelOnError: true,
    );

    return finished.future;
  }

  void _release() {
    _watching = null;
    _finished = null;
  }

  /// Desiste da espera e devolve a tela a quem está nela.
  ///
  /// **O job não é interrompido no servidor** — não há como, e nem seria certo: ele pode
  /// estar a um segundo de terminar. O que se larga é a espera. Quem cancelar e pedir de novo
  /// enfileira um segundo job, e é por isso que cancelar é um gesto do usuário e não um
  /// automatismo: a cota do dia conta pedido, não resposta.
  void cancel() {
    if (!state.running) {
      return;
    }

    _run = null;
    final watching = _watching;
    final finished = _finished;
    _release();

    watching?.cancel();
    // Cancelar a inscrição não dispara `onDone`: sem completar isto à mão, o `start` que
    // espera por ela ficaria pendurado para sempre.
    if (finished != null && !finished.isCompleted) {
      finished.complete();
    }

    state = GenerationState.idle;
  }

  /// Some com o erro depois de ele virar snackbar, para não reaparecer no próximo rebuild.
  void dismissError() => state = GenerationState.idle;
}
