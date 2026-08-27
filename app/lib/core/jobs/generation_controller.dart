import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../network/api_exception.dart';
import '../providers.dart';
import 'job_status.dart';

/// Estado de uma operação assíncrona de IA vista pela tela.
class GenerationState {
  const GenerationState({
    this.running = false,
    this.step,
    this.phase,
    this.error,
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

  static const idle = GenerationState();
}

/// Base dos controllers que disparam um job de IA e esperam o resultado.
///
/// O fluxo é sempre o mesmo — enfileirar, acompanhar pelo [JobWatcher], recarregar o que
/// mudou — e se repete em treino, dieta, análise de refeição, análise de vídeo, coach e
/// relatório semanal. Escrever seis vezes seria seis oportunidades de esquecer o
/// `invalidate` ou de tratar a falha de um jeito diferente em cada tela.
abstract class JobGenerationController extends Notifier<GenerationState> {
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
    state = GenerationState(running: true, step: startingLabel);

    try {
      final jobId = await enqueue();

      JobStatus? last;
      await for (final status in ref.read(jobWatcherProvider).watch(jobId)) {
        last = status;
        state = GenerationState(
          running: true,
          step: stepLabel(status.state),
          phase: status.state,
        );
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
      state = GenerationState(error: e.message);
    } catch (_) {
      state = GenerationState(error: genericFailure);
    }
  }

  /// Some com o erro depois de ele virar snackbar, para não reaparecer no próximo rebuild.
  void dismissError() => state = GenerationState.idle;
}
