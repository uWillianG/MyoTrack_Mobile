import 'dart:typed_data';

import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/jobs/generation_controller.dart';
import '../../core/jobs/job_status.dart';
import '../../core/providers.dart';
import 'data/meal_models.dart';
import 'data/meal_repository.dart';

final mealRepositoryProvider = Provider<MealRepository>(
  (ref) => MealRepository(ref.watch(apiClientProvider)),
);

/// Histórico de refeições analisadas.
final mealHistoryProvider = FutureProvider<List<MealAnalysis>>(
  (ref) => ref.watch(mealRepositoryProvider).recent(),
);

/// Prepara a foto para envio: reduz e recomprime.
///
/// Fica fora do controller para poder ser testado sem plugin de câmera.
class PhotoPreparation {
  const PhotoPreparation({
    required this.bytes,
    required this.fileName,
    required this.contentType,
  });

  final Uint8List bytes;
  final String fileName;
  final String contentType;
}

/// Lado maior da imagem enviada.
///
/// 1600 px é bem mais do que o modelo precisa para reconhecer um prato, e derruba uma foto de
/// 12 MP de vários MB para algumas centenas de KB. O limite do servidor é 10 MB, mas o que
/// manda aqui não é o limite: é o Wi-Fi da praça de alimentação.
const int _maxDimension = 1600;

/// Qualidade JPEG. Abaixo de 80 aparecem artefatos de bloco que atrapalham a leitura de
/// texturas — e é textura que distingue arroz de purê.
const int _jpegQuality = 80;

Future<PhotoPreparation> prepareForUpload(XFile photo) async {
  final compressed = await FlutterImageCompress.compressWithFile(
    photo.path,
    minWidth: _maxDimension,
    minHeight: _maxDimension,
    quality: _jpegQuality,
    // HEIC da câmera do iPhone sai daqui como JPEG, que é o que o backend prefere.
    format: CompressFormat.jpeg,
  );

  if (compressed != null) {
    return PhotoPreparation(
      bytes: compressed,
      fileName: 'refeicao.jpg',
      contentType: 'image/jpeg',
    );
  }

  // A compressão falha em formatos que o codec nativo não abre. Subir o original é melhor do
  // que desistir: o backend aceita HEIC, PNG e WEBP, e a validação de tamanho pega o resto.
  return PhotoPreparation(
    bytes: await photo.readAsBytes(),
    fileName: photo.name,
    contentType: photo.mimeType ?? 'image/jpeg',
  );
}

/// Conduz uma análise: escolher a foto, subir, esperar o job e carregar o resultado.
class MealAnalysisController extends JobGenerationController {
  Uint8List? _photo;
  String _fileName = 'refeicao.jpg';
  String _contentType = 'image/jpeg';

  /// Última análise concluída — é o que a tela mostra depois do envio.
  MealAnalysis? _result;
  MealAnalysis? get result => _result;

  /// Fração já enviada, para a barra de progresso do upload.
  double _uploadProgress = 0;
  double get uploadProgress => _uploadProgress;

  /// Tira ou escolhe a foto e dispara a análise. Devolve false se o usuário desistiu.
  Future<bool> analyzeFrom(ImageSource source) async {
    final picked = await ref
        .read(imagePickerProvider)
        .pickImage(
          source: source,
          // Uma primeira redução já na origem: em aparelho antigo, decodificar 12 MP para
          // comprimir depois é o que estoura a memória.
          maxWidth: 2400,
          maxHeight: 2400,
        );
    if (picked == null) {
      return false;
    }

    final prepared = await prepareForUpload(picked);
    _photo = prepared.bytes;
    _fileName = prepared.fileName;
    _contentType = prepared.contentType;
    _result = null;
    _uploadProgress = 0;

    await start();
    return true;
  }

  @override
  Future<String> enqueue() async {
    final photo = _photo;
    if (photo == null) {
      throw StateError('Nenhuma foto preparada para envio.');
    }

    return ref
        .read(mealRepositoryProvider)
        .analyze(
          photo: photo,
          fileName: _fileName,
          contentType: _contentType,
          onProgress: (sent, total) {
            if (total > 0) {
              _uploadProgress = sent / total;
            }
          },
        );
  }

  @override
  Future<void> reload() async {
    // A análise recém-criada é a mais recente do usuário. Pegá-la da listagem evita um
    // endpoint só para "o resultado deste job".
    final recent = await ref.read(mealRepositoryProvider).recent(limit: 1);
    _result = recent.isEmpty ? null : recent.first;

    ref.invalidate(mealHistoryProvider);
    // A foto some da tela junto com o resultado; guardá-la manteria vários MB vivos.
    _photo = null;
  }

  @override
  String get startingLabel => 'Enviando a foto…';

  @override
  String get genericFailure =>
      'Não foi possível analisar a foto. Tente novamente.';

  @override
  String stepLabel(JobState state) => switch (state) {
    JobState.pending => 'Na fila…',
    JobState.processing => 'Identificando os alimentos…',
    _ => 'Finalizando…',
  };

  /// Aplica a correção do usuário e devolve a análise recalculada pelo servidor.
  Future<MealAnalysis> adjust(String id, MealAdjustRequest request) async {
    final updated = await ref.read(mealRepositoryProvider).adjust(id, request);
    if (_result?.id == id) {
      _result = updated;
    }
    ref.invalidate(mealHistoryProvider);
    return updated;
  }
}

final mealAnalysisProvider =
    NotifierProvider<MealAnalysisController, GenerationState>(
      MealAnalysisController.new,
    );
