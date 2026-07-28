import 'package:freezed_annotation/freezed_annotation.dart';

part 'video_models.freezed.dart';
part 'video_models.g.dart';

/// Exercício que o serviço de visão sabe avaliar — `GET /api/videos/exercises`.
///
/// A lista vem do servidor em vez de embutida no app: um exercício novo no serviço passa a
/// aparecer sem publicar versão nova nas lojas.
@freezed
abstract class VideoExerciseOption with _$VideoExerciseOption {
  const factory VideoExerciseOption({
    required String slug,
    required String label,
  }) = _VideoExerciseOption;

  factory VideoExerciseOption.fromJson(Map<String, dynamic> json) =>
      _$VideoExerciseOptionFromJson(json);
}

/// Onde a execução saiu do padrão, com os instantes em que isso aconteceu.
@freezed
abstract class VideoIssue with _$VideoIssue {
  const factory VideoIssue({
    @Default('') String code,
    @Default('') String message,
    @Default([]) List<double> timestampsSec,
  }) = _VideoIssue;

  factory VideoIssue.fromJson(Map<String, dynamic> json) =>
      _$VideoIssueFromJson(json);
}

/// O que já está correto. Existe para o retorno não ser só uma lista de erros — quem grava a
/// série também precisa saber o que não deve mudar.
@freezed
abstract class VideoCorrectPoint with _$VideoCorrectPoint {
  const factory VideoCorrectPoint({
    @Default('') String code,
    @Default('') String message,
  }) = _VideoCorrectPoint;

  factory VideoCorrectPoint.fromJson(Map<String, dynamic> json) =>
      _$VideoCorrectPointFromJson(json);
}

@freezed
abstract class VideoResult with _$VideoResult {
  const factory VideoResult({
    @Default([]) List<VideoIssue> issues,
    @Default([]) List<VideoCorrectPoint> correctPoints,

    /// Métricas brutas do serviço (ângulos, duração, cobertura da pose). Ficam como mapa
    /// porque as heurísticas evoluem, e um campo novo não deve exigir versão nova do app.
    @Default({}) Map<String, dynamic> metrics,

    /// Preenchido quando não deu para avaliar — vídeo tremido, corpo cortado, luz ruim.
    String? notEvaluableReason,
  }) = _VideoResult;

  factory VideoResult.fromJson(Map<String, dynamic> json) =>
      _$VideoResultFromJson(json);
}

/// Análise de execução por vídeo — `GET /api/videos`.
@freezed
abstract class VideoAnalysis with _$VideoAnalysis {
  const factory VideoAnalysis({
    required String id,
    String? analysisJobId,
    @Default('') String analyzedExercise,

    /// 0–100, ou null quando a pose não pôde ser avaliada com confiança. Null **não** é zero:
    /// zero seria uma execução péssima, que é uma afirmação bem diferente.
    int? score,
    @Default(0) int repCount,
    @Default(VideoResult()) VideoResult result,

    /// URLs temporárias; null depois de a retenção apagar a mídia.
    String? videoUrl,
    String? overlayVideoUrl,
    String? createdAt,
  }) = _VideoAnalysis;

  factory VideoAnalysis.fromJson(Map<String, dynamic> json) =>
      _$VideoAnalysisFromJson(json);
}

/// Resposta de `POST /api/videos/upload-url`.
@freezed
abstract class VideoUploadTicket with _$VideoUploadTicket {
  const factory VideoUploadTicket({
    required String mediaKey,
    required String uploadUrl,
    @Default(0) int expiresInSeconds,
  }) = _VideoUploadTicket;

  factory VideoUploadTicket.fromJson(Map<String, dynamic> json) =>
      _$VideoUploadTicketFromJson(json);
}
