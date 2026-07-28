// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'progress_controller.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_LastSet _$LastSetFromJson(Map<String, dynamic> json) => _LastSet(
  reps: (json['reps'] as num?)?.toInt() ?? 0,
  loadKg: json['loadKg'] as num? ?? 0,
);

Map<String, dynamic> _$LastSetToJson(_LastSet instance) => <String, dynamic>{
  'reps': instance.reps,
  'loadKg': instance.loadKg,
};

_ProgressSuggestion _$ProgressSuggestionFromJson(Map<String, dynamic> json) =>
    _ProgressSuggestion(
      workoutDayId: json['workoutDayId'] as String?,
      dayLabel: json['dayLabel'] as String?,
      exerciseId: (json['exerciseId'] as num?)?.toInt(),
      exerciseName: json['exerciseName'] as String? ?? '',
      sets: (json['sets'] as num?)?.toInt() ?? 0,
      repsMin: (json['repsMin'] as num?)?.toInt() ?? 0,
      repsMax: (json['repsMax'] as num?)?.toInt() ?? 0,
      lastSessionDate: json['lastSessionDate'] as String?,
      lastSets:
          (json['lastSets'] as List<dynamic>?)
              ?.map((e) => LastSet.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      action: json['action'] as String? ?? 'Start',
      nextLoadKg: json['nextLoadKg'] as num?,
      targetReps: (json['targetReps'] as num?)?.toInt() ?? 0,
      incrementKg: json['incrementKg'] as num?,
    );

Map<String, dynamic> _$ProgressSuggestionToJson(_ProgressSuggestion instance) =>
    <String, dynamic>{
      'workoutDayId': instance.workoutDayId,
      'dayLabel': instance.dayLabel,
      'exerciseId': instance.exerciseId,
      'exerciseName': instance.exerciseName,
      'sets': instance.sets,
      'repsMin': instance.repsMin,
      'repsMax': instance.repsMax,
      'lastSessionDate': instance.lastSessionDate,
      'lastSets': instance.lastSets,
      'action': instance.action,
      'nextLoadKg': instance.nextLoadKg,
      'targetReps': instance.targetReps,
      'incrementKg': instance.incrementKg,
    };
