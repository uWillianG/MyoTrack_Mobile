// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'video_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_VideoExerciseOption _$VideoExerciseOptionFromJson(Map<String, dynamic> json) =>
    _VideoExerciseOption(
      slug: json['slug'] as String,
      label: json['label'] as String,
    );

Map<String, dynamic> _$VideoExerciseOptionToJson(
  _VideoExerciseOption instance,
) => <String, dynamic>{'slug': instance.slug, 'label': instance.label};

_VideoIssue _$VideoIssueFromJson(Map<String, dynamic> json) => _VideoIssue(
  code: json['code'] as String? ?? '',
  message: json['message'] as String? ?? '',
  timestampsSec:
      (json['timestampsSec'] as List<dynamic>?)
          ?.map((e) => (e as num).toDouble())
          .toList() ??
      const [],
);

Map<String, dynamic> _$VideoIssueToJson(_VideoIssue instance) =>
    <String, dynamic>{
      'code': instance.code,
      'message': instance.message,
      'timestampsSec': instance.timestampsSec,
    };

_VideoCorrectPoint _$VideoCorrectPointFromJson(Map<String, dynamic> json) =>
    _VideoCorrectPoint(
      code: json['code'] as String? ?? '',
      message: json['message'] as String? ?? '',
    );

Map<String, dynamic> _$VideoCorrectPointToJson(_VideoCorrectPoint instance) =>
    <String, dynamic>{'code': instance.code, 'message': instance.message};

_VideoResult _$VideoResultFromJson(Map<String, dynamic> json) => _VideoResult(
  issues:
      (json['issues'] as List<dynamic>?)
          ?.map((e) => VideoIssue.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
  correctPoints:
      (json['correctPoints'] as List<dynamic>?)
          ?.map((e) => VideoCorrectPoint.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
  metrics: json['metrics'] as Map<String, dynamic>? ?? const {},
  notEvaluableReason: json['notEvaluableReason'] as String?,
);

Map<String, dynamic> _$VideoResultToJson(_VideoResult instance) =>
    <String, dynamic>{
      'issues': instance.issues,
      'correctPoints': instance.correctPoints,
      'metrics': instance.metrics,
      'notEvaluableReason': instance.notEvaluableReason,
    };

_VideoAnalysis _$VideoAnalysisFromJson(Map<String, dynamic> json) =>
    _VideoAnalysis(
      id: json['id'] as String,
      analysisJobId: json['analysisJobId'] as String?,
      analyzedExercise: json['analyzedExercise'] as String? ?? '',
      score: (json['score'] as num?)?.toInt(),
      repCount: (json['repCount'] as num?)?.toInt() ?? 0,
      result: json['result'] == null
          ? const VideoResult()
          : VideoResult.fromJson(json['result'] as Map<String, dynamic>),
      videoUrl: json['videoUrl'] as String?,
      overlayVideoUrl: json['overlayVideoUrl'] as String?,
      createdAt: json['createdAt'] as String?,
    );

Map<String, dynamic> _$VideoAnalysisToJson(_VideoAnalysis instance) =>
    <String, dynamic>{
      'id': instance.id,
      'analysisJobId': instance.analysisJobId,
      'analyzedExercise': instance.analyzedExercise,
      'score': instance.score,
      'repCount': instance.repCount,
      'result': instance.result,
      'videoUrl': instance.videoUrl,
      'overlayVideoUrl': instance.overlayVideoUrl,
      'createdAt': instance.createdAt,
    };

_VideoUploadTicket _$VideoUploadTicketFromJson(Map<String, dynamic> json) =>
    _VideoUploadTicket(
      mediaKey: json['mediaKey'] as String,
      uploadUrl: json['uploadUrl'] as String,
      expiresInSeconds: (json['expiresInSeconds'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$VideoUploadTicketToJson(_VideoUploadTicket instance) =>
    <String, dynamic>{
      'mediaKey': instance.mediaKey,
      'uploadUrl': instance.uploadUrl,
      'expiresInSeconds': instance.expiresInSeconds,
    };
