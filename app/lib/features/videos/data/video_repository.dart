import 'dart:io';

import '../../../core/network/api_client.dart';
import 'video_models.dart';

/// Fala com `/api/video-analyses`.
///
/// O envio é em dois passos — pedir a URL assinada e subir direto no storage — porque vídeo de
/// série passa de dezenas de MB: atravessá-lo pela API ocuparia uma thread do servidor por
/// minutos e faria o upload competir com todo o resto do tráfego.
class VideoRepository {
  VideoRepository(this._api);

  final ApiClient _api;

  Future<List<VideoExerciseOption>> exercises() async {
    final json = await _api.get<List<dynamic>>(
      '/api/video-analyses/supported-exercises',
    );
    return json
        .map((e) => VideoExerciseOption.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<VideoUploadTicket> requestUpload(String contentType) async {
    final json = await _api.post<Map<String, dynamic>>(
      '/api/video-analyses/presign',
      body: {'contentType': contentType},
    );
    return VideoUploadTicket.fromJson(json);
  }

  /// Sobe o arquivo direto no storage, pela URL assinada.
  ///
  /// Vai como stream e não como bytes: um vídeo de 150 MB carregado inteiro na memória derruba
  /// o app em aparelho modesto, que é justamente onde as pessoas gravam a série.
  Future<void> uploadTo(
    VideoUploadTicket ticket,
    File file, {
    required String contentType,
    void Function(int sent, int total)? onProgress,
  }) async {
    await _api.putPresigned(
      ticket.uploadUrl,
      file.openRead(),
      length: await file.length(),
      contentType: contentType,
      onProgress: onProgress,
    );
  }

  /// Confirma o envio e enfileira a análise. Devolve o `jobId`.
  Future<String> analyze({
    required String mediaKey,
    required String exercise,
  }) async {
    final json = await _api.post<Map<String, dynamic>>(
      '/api/video-analyses',
      body: {'mediaKey': mediaKey, 'exercise': exercise},
    );
    return json['jobId'] as String;
  }

  Future<List<VideoAnalysis>> recent({int limit = 20}) async {
    final json = await _api.get<List<dynamic>>(
      '/api/video-analyses',
      query: {'limit': limit},
    );
    return json
        .map((e) => VideoAnalysis.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
