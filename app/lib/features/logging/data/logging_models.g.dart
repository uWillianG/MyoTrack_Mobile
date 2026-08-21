// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'logging_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_SetLogRequest _$SetLogRequestFromJson(Map<String, dynamic> json) =>
    _SetLogRequest(
      exerciseId: (json['exerciseId'] as num).toInt(),
      setNumber: (json['setNumber'] as num).toInt(),
      reps: (json['reps'] as num).toInt(),
      loadKg: (json['loadKg'] as num).toDouble(),
      rpe: (json['rpe'] as num?)?.toInt(),
    );

Map<String, dynamic> _$SetLogRequestToJson(_SetLogRequest instance) =>
    <String, dynamic>{
      'exerciseId': instance.exerciseId,
      'setNumber': instance.setNumber,
      'reps': instance.reps,
      'loadKg': instance.loadKg,
      'rpe': instance.rpe,
    };

_SessionRequest _$SessionRequestFromJson(Map<String, dynamic> json) =>
    _SessionRequest(
      date: json['date'] as String,
      workoutDayId: json['workoutDayId'] as String?,
      notes: json['notes'] as String?,
      sets: (json['sets'] as List<dynamic>)
          .map((e) => SetLogRequest.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$SessionRequestToJson(_SessionRequest instance) =>
    <String, dynamic>{
      'date': instance.date,
      'workoutDayId': instance.workoutDayId,
      'notes': instance.notes,
      'sets': instance.sets,
    };

_WorkoutSessionView _$WorkoutSessionViewFromJson(Map<String, dynamic> json) =>
    _WorkoutSessionView(
      id: json['id'] as String,
      date: json['date'] as String,
      workoutDayId: json['workoutDayId'] as String?,
      notes: json['notes'] as String?,
      totalVolumeKg: json['totalVolumeKg'] as num? ?? 0,
      sets:
          (json['sets'] as List<dynamic>?)
              ?.map((e) => SetView.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );

Map<String, dynamic> _$WorkoutSessionViewToJson(_WorkoutSessionView instance) =>
    <String, dynamic>{
      'id': instance.id,
      'date': instance.date,
      'workoutDayId': instance.workoutDayId,
      'notes': instance.notes,
      'totalVolumeKg': instance.totalVolumeKg,
      'sets': instance.sets,
    };

_SetView _$SetViewFromJson(Map<String, dynamic> json) => _SetView(
  id: json['id'] as String,
  exerciseId: (json['exerciseId'] as num?)?.toInt(),
  exerciseName: json['exerciseName'] as String? ?? '',
  setNumber: (json['setNumber'] as num?)?.toInt() ?? 1,
  reps: (json['reps'] as num?)?.toInt() ?? 0,
  loadKg: json['loadKg'] as num? ?? 0,
  rpe: (json['rpe'] as num?)?.toInt(),
);

Map<String, dynamic> _$SetViewToJson(_SetView instance) => <String, dynamic>{
  'id': instance.id,
  'exerciseId': instance.exerciseId,
  'exerciseName': instance.exerciseName,
  'setNumber': instance.setNumber,
  'reps': instance.reps,
  'loadKg': instance.loadKg,
  'rpe': instance.rpe,
};

_MeasurementView _$MeasurementViewFromJson(Map<String, dynamic> json) =>
    _MeasurementView(
      id: json['id'] as String,
      date: json['date'] as String,
      weightKg: json['weightKg'] as num?,
      bodyFatPercent: json['bodyFatPercent'] as num?,
      waistCm: json['waistCm'] as num?,
      chestCm: json['chestCm'] as num?,
      hipCm: json['hipCm'] as num?,
      armCm: json['armCm'] as num?,
      thighCm: json['thighCm'] as num?,
      calfCm: json['calfCm'] as num?,
    );

Map<String, dynamic> _$MeasurementViewToJson(_MeasurementView instance) =>
    <String, dynamic>{
      'id': instance.id,
      'date': instance.date,
      'weightKg': instance.weightKg,
      'bodyFatPercent': instance.bodyFatPercent,
      'waistCm': instance.waistCm,
      'chestCm': instance.chestCm,
      'hipCm': instance.hipCm,
      'armCm': instance.armCm,
      'thighCm': instance.thighCm,
      'calfCm': instance.calfCm,
    };

_MeasurementRequest _$MeasurementRequestFromJson(Map<String, dynamic> json) =>
    _MeasurementRequest(
      date: json['date'] as String,
      weightKg: (json['weightKg'] as num?)?.toDouble(),
      bodyFatPercent: (json['bodyFatPercent'] as num?)?.toDouble(),
      waistCm: (json['waistCm'] as num?)?.toDouble(),
      chestCm: (json['chestCm'] as num?)?.toDouble(),
      hipCm: (json['hipCm'] as num?)?.toDouble(),
      armCm: (json['armCm'] as num?)?.toDouble(),
      thighCm: (json['thighCm'] as num?)?.toDouble(),
      calfCm: (json['calfCm'] as num?)?.toDouble(),
    );

Map<String, dynamic> _$MeasurementRequestToJson(_MeasurementRequest instance) =>
    <String, dynamic>{
      'date': instance.date,
      'weightKg': instance.weightKg,
      'bodyFatPercent': instance.bodyFatPercent,
      'waistCm': instance.waistCm,
      'chestCm': instance.chestCm,
      'hipCm': instance.hipCm,
      'armCm': instance.armCm,
      'thighCm': instance.thighCm,
      'calfCm': instance.calfCm,
    };
