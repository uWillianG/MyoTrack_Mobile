// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'report_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_WeeklyMetrics _$WeeklyMetricsFromJson(Map<String, dynamic> json) =>
    _WeeklyMetrics(
      weekStart: json['weekStart'] as String?,
      sessions: (json['sessions'] as num?)?.toInt() ?? 0,
      totalSets: (json['totalSets'] as num?)?.toInt() ?? 0,
      totalVolumeKg: json['totalVolumeKg'] as num? ?? 0,
      volumeChangePercent: json['volumeChangePercent'] as num?,
      topExercise: json['topExercise'] as String?,
      topExerciseVolumeKg: json['topExerciseVolumeKg'] as num?,
      weightStartKg: json['weightStartKg'] as num?,
      weightEndKg: json['weightEndKg'] as num?,
      weightChangeKg: json['weightChangeKg'] as num?,
      mealsLogged: (json['mealsLogged'] as num?)?.toInt() ?? 0,
      daysWithMealLogged: (json['daysWithMealLogged'] as num?)?.toInt() ?? 0,
      avgKcalPerLoggedDay: json['avgKcalPerLoggedDay'] as num?,
    );

Map<String, dynamic> _$WeeklyMetricsToJson(_WeeklyMetrics instance) =>
    <String, dynamic>{
      'weekStart': instance.weekStart,
      'sessions': instance.sessions,
      'totalSets': instance.totalSets,
      'totalVolumeKg': instance.totalVolumeKg,
      'volumeChangePercent': instance.volumeChangePercent,
      'topExercise': instance.topExercise,
      'topExerciseVolumeKg': instance.topExerciseVolumeKg,
      'weightStartKg': instance.weightStartKg,
      'weightEndKg': instance.weightEndKg,
      'weightChangeKg': instance.weightChangeKg,
      'mealsLogged': instance.mealsLogged,
      'daysWithMealLogged': instance.daysWithMealLogged,
      'avgKcalPerLoggedDay': instance.avgKcalPerLoggedDay,
    };

_WeeklyNarrative _$WeeklyNarrativeFromJson(Map<String, dynamic> json) =>
    _WeeklyNarrative(
      summary: json['summary'] as String? ?? '',
      highlights:
          (json['highlights'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      recommendations:
          (json['recommendations'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
    );

Map<String, dynamic> _$WeeklyNarrativeToJson(_WeeklyNarrative instance) =>
    <String, dynamic>{
      'summary': instance.summary,
      'highlights': instance.highlights,
      'recommendations': instance.recommendations,
    };

_WeeklyReport _$WeeklyReportFromJson(Map<String, dynamic> json) =>
    _WeeklyReport(
      id: json['id'] as String,
      weekStart: json['weekStart'] as String?,
      metrics: json['metrics'] == null
          ? const WeeklyMetrics()
          : WeeklyMetrics.fromJson(json['metrics'] as Map<String, dynamic>),
      narrative: json['narrative'] == null
          ? null
          : WeeklyNarrative.fromJson(json['narrative'] as Map<String, dynamic>),
      createdAt: json['createdAt'] as String?,
    );

Map<String, dynamic> _$WeeklyReportToJson(_WeeklyReport instance) =>
    <String, dynamic>{
      'id': instance.id,
      'weekStart': instance.weekStart,
      'metrics': instance.metrics,
      'narrative': instance.narrative,
      'createdAt': instance.createdAt,
    };
