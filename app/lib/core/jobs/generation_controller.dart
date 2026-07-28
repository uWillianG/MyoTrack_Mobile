import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../network/api_exception.dart';
import '../providers.dart';
import 'job_status.dart';

/// Estado de uma operação assíncrona de IA vista pela tela.
class GenerationState {
  const GenerationState({this.running = false, this.step, this.error});

  final bool running;

  /// Texto de progresso — muda quando o worker pega o job.
  final String? step;
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
        state = GenerationState(running: true, step: stepLabel(status.state));
      }

      if (last == null || !last.succeeded) {
        state = GenerationState(error: last?.lastError ?? genericFailure);
        return;
      }

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
