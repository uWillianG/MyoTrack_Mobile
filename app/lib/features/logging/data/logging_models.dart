import 'package:freezed_annotation/freezed_annotation.dart';

part 'logging_models.freezed.dart';
part 'logging_models.g.dart';

/// Exercício do catálogo — `GET /api/exercises`.
@freezed
abstract class ExerciseOption with _$ExerciseOption {
  const factory ExerciseOption({
    required int id,
    required String name,
    @Default('') String muscleGroup,
    @Default('') String equipment,
    @Default(false) bool isCompound,
  }) = _ExerciseOption;

  factory ExerciseOption.fromJson(Map<String, dynamic> json) =>
      _$ExerciseOptionFromJson(json);
}

/// Uma série a registrar — corpo de `POST /api/sessions`.
@freezed
abstract class SetLogRequest with _$SetLogRequest {
  const factory SetLogRequest({
    required int exerciseId,
    required int setNumber,
    required int reps,
    required double loadKg,
    int? rpe,
  }) = _SetLogRequest;

  factory SetLogRequest.fromJson(Map<String, dynamic> json) =>
      _$SetLogRequestFromJson(json);
}

@freezed
abstract class SessionRequest with _$SessionRequest {
  const factory SessionRequest({
    required String date,
    String? workoutDayId,
    String? notes,
    required List<SetLogRequest> sets,
  }) = _SessionRequest;

  factory SessionRequest.fromJson(Map<String, dynamic> json) =>
      _$SessionRequestFromJson(json);
}

/// Sessão já registrada — `GET /api/sessions`.
@freezed
abstract class WorkoutSessionView with _$WorkoutSessionView {
  const factory WorkoutSessionView({
    required String id,
    required String date,
    String? workoutDayId,
    String? notes,
    @Default(0) num totalVolumeKg,
    @Default([]) List<SetView> sets,
  }) = _WorkoutSessionView;

  factory WorkoutSessionView.fromJson(Map<String, dynamic> json) =>
      _$WorkoutSessionViewFromJson(json);
}

@freezed
abstract class SetView with _$SetView {
  const factory SetView({
    required String id,
    int? exerciseId,
    @Default('') String exerciseName,
    @Default(1) int setNumber,
    @Default(0) int reps,
    @Default(0) num loadKg,
    int? rpe,
  }) = _SetView;

  factory SetView.fromJson(Map<String, dynamic> json) =>
      _$SetViewFromJson(json);
}

/// Medida corporal — `POST /api/measurements`.
@freezed
abstract class MeasurementRequest with _$MeasurementRequest {
  const factory MeasurementRequest({
    required String date,
    double? weightKg,
    double? bodyFatPercent,
    double? waistCm,
    double? chestCm,
    double? hipCm,
    double? armCm,
    double? thighCm,
    double? calfCm,
  }) = _MeasurementRequest;

  factory MeasurementRequest.fromJson(Map<String, dynamic> json) =>
      _$MeasurementRequestFromJson(json);
}
