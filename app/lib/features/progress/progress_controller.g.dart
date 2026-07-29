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

_WeeklyVolume _$WeeklyVolumeFromJson(Map<String, dynamic> json) =>
    _WeeklyVolume(
      weekStart: DateTime.parse(json['weekStart'] as String),
      volumeKg: json['volumeKg'] as num? ?? 0,
      sessions: (json['sessions'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$WeeklyVolumeToJson(_WeeklyVolume instance) =>
    <String, dynamic>{
      'weekStart': instance.weekStart.toIso8601String(),
      'volumeKg': instance.volumeKg,
      'sessions': instance.sessions,
    };

_WeightPoint _$WeightPointFromJson(Map<String, dynamic> json) => _WeightPoint(
  date: DateTime.parse(json['date'] as String),
  weightKg: json['weightKg'] as num? ?? 0,
);

Map<String, dynamic> _$WeightPointToJson(_WeightPoint instance) =>
    <String, dynamic>{
      'date': instance.date.toIso8601String(),
      'weightKg': instance.weightKg,
    };

_ExerciseRecord _$ExerciseRecordFromJson(Map<String, dynamic> json) =>
    _ExerciseRecord(
      exerciseId: (json['exerciseId'] as num?)?.toInt(),
      name: json['name'] as String? ?? '',
      maxLoadKg: json['maxLoadKg'] as num? ?? 0,
      maxLoadDate: json['maxLoadDate'] == null
          ? null
          : DateTime.parse(json['maxLoadDate'] as String),
      maxLoadReps: (json['maxLoadReps'] as num?)?.toInt(),
      bestE1RmKg: json['bestE1RmKg'] as num?,
      e1RmReps: (json['e1RmReps'] as num?)?.toInt(),
      e1RmLoadKg: json['e1RmLoadKg'] as num?,
      e1RmDate: json['e1RmDate'] == null
          ? null
          : DateTime.parse(json['e1RmDate'] as String),
    );

Map<String, dynamic> _$ExerciseRecordToJson(_ExerciseRecord instance) =>
    <String, dynamic>{
      'exerciseId': instance.exerciseId,
      'name': instance.name,
      'maxLoadKg': instance.maxLoadKg,
      'maxLoadDate': instance.maxLoadDate?.toIso8601String(),
      'maxLoadReps': instance.maxLoadReps,
      'bestE1RmKg': instance.bestE1RmKg,
      'e1RmReps': instance.e1RmReps,
      'e1RmLoadKg': instance.e1RmLoadKg,
      'e1RmDate': instance.e1RmDate?.toIso8601String(),
    };
