import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/jobs/generation_controller.dart';
import '../../core/jobs/job_status.dart';
import '../../core/providers.dart';
import 'data/video_models.dart';
import 'data/video_repository.dart';

final videoRepositoryProvider = Provider<VideoRepository>(
  (ref) => VideoRepository(ref.watch(apiClientProvider)),
);

/// Exercícios avaliáveis, vindos do servidor.
final videoExercisesProvider = FutureProvider<List<VideoExerciseOption>>(
  (ref) => ref.watch(videoRepositoryProvider).exercises(),
);

final videoHistoryProvider = FutureProvider<List<VideoAnalysis>>(
  (ref) => ref.watch(videoRepositoryProvider).recent(),
);

/// Duração máxima aceita na gravação.
///
/// Algumas repetições bastam para avaliar a execução, e cada segundo a mais é upload em rede
/// móvel e tempo de processamento quadro a quadro do outro lado.
const Duration maxVideoDuration = Duration(seconds: 30);

/// Conduz uma análise: escolher o vídeo, subir para o storage, enfileirar e esperar.
class VideoAnalysisController extends JobGenerationController {
  File? _file;
  String _contentType = 'video/mp4';
  String _exercise = '';

  double _uploadProgress = 0;
  double get uploadProgress => _uploadProgress;

  /// Última análise concluída — é a que a lista mostra aberta.
  VideoAnalysis? _result;
  VideoAnalysis? get result => _result;

  /// Grava ou escolhe o vídeo e dispara a análise. Devolve false se o usuário desistiu.
  Future<bool> analyzeFrom(ImageSource source, String exerciseSlug) async {
    final picked = await ref
        .read(imagePickerProvider)
        .pickVideo(source: source, maxDuration: maxVideoDuration);
    if (picked == null) {
      return false;
    }

    _file = File(picked.path);
    _contentType = _contentTypeFor(picked.path);
    _exercise = exerciseSlug;
    _uploadProgress = 0;
    _result = null;

    await start();
    return true;
  }

  /// O backend só aceita MP4 e MOV; a câmera do iPhone entrega MOV.
  static String _contentTypeFor(String path) =>
      path.toLowerCase().endsWith('.mov') ? 'video/quicktime' : 'video/mp4';

  @override
  Future<String> enqueue() async {
    final file = _file;
    if (file == null) {
      throw StateError('Nenhum vídeo preparado para envio.');
    }

    final repository = ref.read(videoRepositoryProvider);

    // Três chamadas, nesta ordem: a API reserva a chave, o arquivo sobe direto no storage, e
    // só então a análise entra na fila. Enfileirar antes criaria um job apontando para um
    // objeto que talvez nunca chegue.
    final ticket = await repository.requestUpload(_contentType);

    await repository.uploadTo(
      ticket,
      file,
      contentType: _contentType,
      onProgress: (sent, total) {
        if (total > 0) {
          _uploadProgress = sent / total;
        }
      },
    );

    return repository.analyze(mediaKey: ticket.mediaKey, exercise: _exercise);
  }

  @override
  Future<void> reload() async {
    ref.invalidate(videoHistoryProvider);
    // A análise recém-criada é a mais recente do usuário — a lista já vem ordenada do servidor,
    // e pegá-la daqui evita um endpoint só para "o resultado deste job".
    final recent = await ref.read(videoHistoryProvider.future);
    _result = recent.isEmpty ? null : recent.first;
    // O arquivo local não serve mais: o que a tela mostra vem do servidor.
    _file = null;
  }

  /// A única espera do app que legitimamente dura minutos.
  ///
  /// O serviço de visão estima a pose quadro a quadro com teto próprio de 10 minutos, e só
  /// depois disso vem a chamada de IA que escreve a devolutiva. Os três minutos que servem
  /// para as outras telas desistiriam no meio de um trabalho que ainda ia entregar. Catorze
  /// fica logo abaixo dos quinze em que o servidor fecha o stream, para que quem dá a notícia
  /// seja esta tela e não um stream cortado.
  @override
  Duration get deadline => const Duration(minutes: 14);

  @override
  String get startingLabel => 'Enviando o vídeo…';

  @override
  String get genericFailure =>
      'Não foi possível analisar o vídeo. Tente novamente.';

  @override
  String stepLabel(JobState state) => switch (state) {
    JobState.pending => 'Na fila…',
    // Quadro a quadro leva minutos; dizer o que está acontecendo evita a impressão de travado.
    JobState.processing => 'Analisando sua execução…',
    _ => 'Finalizando…',
  };
}

final videoAnalysisProvider =
    NotifierProvider<VideoAnalysisController, GenerationState>(
      VideoAnalysisController.new,
    );
