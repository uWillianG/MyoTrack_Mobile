import 'package:freezed_annotation/freezed_annotation.dart';

part 'diet_models.freezed.dart';
part 'diet_models.g.dart';

/// Plano alimentar ativo — `GET /api/diet-plans/active`.
@freezed
abstract class DietPlan with _$DietPlan {
  const factory DietPlan({
    required String id,
    required String name,
    @Default('Maintenance') String calorieGoal,
    @Default(1) int version,
    String? createdAt,
    @Default('NotReviewed') String reviewStatus,
    String? reviewNote,
    String? reviewedAt,
    required Macros targets,
    required Macros totals,
    @Default([]) List<DietMeal> meals,
  }) = _DietPlan;

  factory DietPlan.fromJson(Map<String, dynamic> json) =>
      _$DietPlanFromJson(json);
}

/// Valores nutricionais de um dia — metas ou realizado.
@freezed
abstract class Macros with _$Macros {
  const factory Macros({
    @Default(0) num kcal,
    @Default(0) num proteinG,
    @Default(0) num carbsG,
    @Default(0) num fatG,
  }) = _Macros;

  factory Macros.fromJson(Map<String, dynamic> json) => _$MacrosFromJson(json);
}

@freezed
abstract class DietMeal with _$DietMeal {
  const factory DietMeal({
    required String id,
    required int order,
    required String name,
    @Default([]) List<DietMealItem> items,
  }) = _DietMeal;

  factory DietMeal.fromJson(Map<String, dynamic> json) =>
      _$DietMealFromJson(json);
}

@freezed
abstract class DietMealItem with _$DietMealItem {
  const factory DietMealItem({
    required String id,
    int? foodItemId,
    required String foodName,
    @Default(0) num quantityG,
    @Default(0) num kcal,
    @Default(0) num proteinG,
    @Default(0) num carbsG,
    @Default(0) num fatG,
  }) = _DietMealItem;

  factory DietMealItem.fromJson(Map<String, dynamic> json) =>
      _$DietMealItemFromJson(json);
}

/// Linha do histórico — `GET /api/diet-plans`.
@freezed
abstract class DietPlanSummary with _$DietPlanSummary {
  const factory DietPlanSummary({
    required String id,
    required String name,
    @Default('Maintenance') String calorieGoal,
    @Default('Active') String status,
    @Default(1) int version,
    @Default(0) num targetKcal,
    String? createdAt,
  }) = _DietPlanSummary;

  factory DietPlanSummary.fromJson(Map<String, dynamic> json) =>
      _$DietPlanSummaryFromJson(json);
}

/// Rótulos em pt-BR dos objetivos calóricos, iguais aos da SPA.
class DietLabels {
  const DietLabels._();

  static const Map<String, String> calorieGoals = {
    'Deficit': 'Déficit calórico',
    'Maintenance': 'Manutenção',
    'Surplus': 'Superávit calórico',
  };

  /// Um valor novo no servidor aparece cru em vez de sumir da tela.
  static String calorieGoal(String value) => calorieGoals[value] ?? value;
}
