import 'package:freezed_annotation/freezed_annotation.dart';

part 'workout_models.freezed.dart';
part 'workout_models.g.dart';

/// Plano de treino ativo — `GET /api/workout-plans/active`.
///
/// Como no perfil, os enums (`goal`, `reviewStatus`) chegam como `String` em PascalCase e
/// ficam assim: um status novo no servidor não pode quebrar a tela de um app já instalado.
@freezed
abstract class WorkoutPlan with _$WorkoutPlan {
  const factory WorkoutPlan({
    required String id,
    required String name,
    required String split,
    required String goal,
    @Default(1) int version,
    String? createdAt,
    @Default('NotReviewed') String reviewStatus,
    String? reviewNote,
    String? reviewedAt,
    @Default([]) List<WorkoutDay> days,
  }) = _WorkoutPlan;

  factory WorkoutPlan.fromJson(Map<String, dynamic> json) =>
      _$WorkoutPlanFromJson(json);
}

@freezed
abstract class WorkoutDay with _$WorkoutDay {
  const factory WorkoutDay({
    required String id,
    required int order,
    required String label,
    @Default([]) List<WorkoutExercise> exercises,
  }) = _WorkoutDay;

  factory WorkoutDay.fromJson(Map<String, dynamic> json) =>
      _$WorkoutDayFromJson(json);
}

@freezed
abstract class WorkoutExercise with _$WorkoutExercise {
  const factory WorkoutExercise({
    required String id,
    int? exerciseId,
    required String exerciseName,
    @Default('') String muscleGroup,
    String? tutorialVideoUrl,
    @Default(3) int sets,
    @Default(8) int repsMin,
    @Default(12) int repsMax,
    @Default(90) int restSeconds,
    String? notes,
  }) = _WorkoutExercise;

  factory WorkoutExercise.fromJson(Map<String, dynamic> json) =>
      _$WorkoutExerciseFromJson(json);
}

/// Linha do histórico — `GET /api/workout-plans`.
@freezed
abstract class WorkoutPlanSummary with _$WorkoutPlanSummary {
  const factory WorkoutPlanSummary({
    required String id,
    required String name,
    required String split,
    @Default('Active') String status,
    @Default(1) int version,
    String? createdAt,
  }) = _WorkoutPlanSummary;

  factory WorkoutPlanSummary.fromJson(Map<String, dynamic> json) =>
      _$WorkoutPlanSummaryFromJson(json);
}
