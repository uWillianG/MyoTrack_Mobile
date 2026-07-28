// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'workout_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_WorkoutPlan _$WorkoutPlanFromJson(Map<String, dynamic> json) => _WorkoutPlan(
  id: json['id'] as String,
  name: json['name'] as String,
  split: json['split'] as String,
  goal: json['goal'] as String,
  version: (json['version'] as num?)?.toInt() ?? 1,
  createdAt: json['createdAt'] as String?,
  reviewStatus: json['reviewStatus'] as String? ?? 'NotReviewed',
  reviewNote: json['reviewNote'] as String?,
  reviewedAt: json['reviewedAt'] as String?,
  days:
      (json['days'] as List<dynamic>?)
          ?.map((e) => WorkoutDay.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
);

Map<String, dynamic> _$WorkoutPlanToJson(_WorkoutPlan instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'split': instance.split,
      'goal': instance.goal,
      'version': instance.version,
      'createdAt': instance.createdAt,
      'reviewStatus': instance.reviewStatus,
      'reviewNote': instance.reviewNote,
      'reviewedAt': instance.reviewedAt,
      'days': instance.days,
    };

_WorkoutDay _$WorkoutDayFromJson(Map<String, dynamic> json) => _WorkoutDay(
  id: json['id'] as String,
  order: (json['order'] as num).toInt(),
  label: json['label'] as String,
  exercises:
      (json['exercises'] as List<dynamic>?)
          ?.map((e) => WorkoutExercise.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
);

Map<String, dynamic> _$WorkoutDayToJson(_WorkoutDay instance) =>
    <String, dynamic>{
      'id': instance.id,
      'order': instance.order,
      'label': instance.label,
      'exercises': instance.exercises,
    };

_WorkoutExercise _$WorkoutExerciseFromJson(Map<String, dynamic> json) =>
    _WorkoutExercise(
      id: json['id'] as String,
      exerciseId: (json['exerciseId'] as num?)?.toInt(),
      exerciseName: json['exerciseName'] as String,
      muscleGroup: json['muscleGroup'] as String? ?? '',
      tutorialVideoUrl: json['tutorialVideoUrl'] as String?,
      sets: (json['sets'] as num?)?.toInt() ?? 3,
      repsMin: (json['repsMin'] as num?)?.toInt() ?? 8,
      repsMax: (json['repsMax'] as num?)?.toInt() ?? 12,
      restSeconds: (json['restSeconds'] as num?)?.toInt() ?? 90,
      notes: json['notes'] as String?,
    );

Map<String, dynamic> _$WorkoutExerciseToJson(_WorkoutExercise instance) =>
    <String, dynamic>{
      'id': instance.id,
      'exerciseId': instance.exerciseId,
      'exerciseName': instance.exerciseName,
      'muscleGroup': instance.muscleGroup,
      'tutorialVideoUrl': instance.tutorialVideoUrl,
      'sets': instance.sets,
      'repsMin': instance.repsMin,
      'repsMax': instance.repsMax,
      'restSeconds': instance.restSeconds,
      'notes': instance.notes,
    };

_WorkoutPlanSummary _$WorkoutPlanSummaryFromJson(Map<String, dynamic> json) =>
    _WorkoutPlanSummary(
      id: json['id'] as String,
      name: json['name'] as String,
      split: json['split'] as String,
      status: json['status'] as String? ?? 'Active',
      version: (json['version'] as num?)?.toInt() ?? 1,
      createdAt: json['createdAt'] as String?,
    );

Map<String, dynamic> _$WorkoutPlanSummaryToJson(_WorkoutPlanSummary instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'split': instance.split,
      'status': instance.status,
      'version': instance.version,
      'createdAt': instance.createdAt,
    };
