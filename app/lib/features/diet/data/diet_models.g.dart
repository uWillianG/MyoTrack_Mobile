// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'diet_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_DietPlan _$DietPlanFromJson(Map<String, dynamic> json) => _DietPlan(
  id: json['id'] as String,
  name: json['name'] as String,
  calorieGoal: json['calorieGoal'] as String? ?? 'Maintenance',
  version: (json['version'] as num?)?.toInt() ?? 1,
  createdAt: json['createdAt'] as String?,
  reviewStatus: json['reviewStatus'] as String? ?? 'NotReviewed',
  reviewNote: json['reviewNote'] as String?,
  reviewedAt: json['reviewedAt'] as String?,
  targets: Macros.fromJson(json['targets'] as Map<String, dynamic>),
  totals: Macros.fromJson(json['totals'] as Map<String, dynamic>),
  meals:
      (json['meals'] as List<dynamic>?)
          ?.map((e) => DietMeal.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
);

Map<String, dynamic> _$DietPlanToJson(_DietPlan instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'calorieGoal': instance.calorieGoal,
  'version': instance.version,
  'createdAt': instance.createdAt,
  'reviewStatus': instance.reviewStatus,
  'reviewNote': instance.reviewNote,
  'reviewedAt': instance.reviewedAt,
  'targets': instance.targets,
  'totals': instance.totals,
  'meals': instance.meals,
};

_Macros _$MacrosFromJson(Map<String, dynamic> json) => _Macros(
  kcal: json['kcal'] as num? ?? 0,
  proteinG: json['proteinG'] as num? ?? 0,
  carbsG: json['carbsG'] as num? ?? 0,
  fatG: json['fatG'] as num? ?? 0,
);

Map<String, dynamic> _$MacrosToJson(_Macros instance) => <String, dynamic>{
  'kcal': instance.kcal,
  'proteinG': instance.proteinG,
  'carbsG': instance.carbsG,
  'fatG': instance.fatG,
};

_DietMeal _$DietMealFromJson(Map<String, dynamic> json) => _DietMeal(
  id: json['id'] as String,
  order: (json['order'] as num).toInt(),
  name: json['name'] as String,
  items:
      (json['items'] as List<dynamic>?)
          ?.map((e) => DietMealItem.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
);

Map<String, dynamic> _$DietMealToJson(_DietMeal instance) => <String, dynamic>{
  'id': instance.id,
  'order': instance.order,
  'name': instance.name,
  'items': instance.items,
};

_DietMealItem _$DietMealItemFromJson(Map<String, dynamic> json) =>
    _DietMealItem(
      id: json['id'] as String,
      foodItemId: (json['foodItemId'] as num?)?.toInt(),
      foodName: json['foodName'] as String,
      quantityG: json['quantityG'] as num? ?? 0,
      kcal: json['kcal'] as num? ?? 0,
      proteinG: json['proteinG'] as num? ?? 0,
      carbsG: json['carbsG'] as num? ?? 0,
      fatG: json['fatG'] as num? ?? 0,
    );

Map<String, dynamic> _$DietMealItemToJson(_DietMealItem instance) =>
    <String, dynamic>{
      'id': instance.id,
      'foodItemId': instance.foodItemId,
      'foodName': instance.foodName,
      'quantityG': instance.quantityG,
      'kcal': instance.kcal,
      'proteinG': instance.proteinG,
      'carbsG': instance.carbsG,
      'fatG': instance.fatG,
    };

_DietPlanSummary _$DietPlanSummaryFromJson(Map<String, dynamic> json) =>
    _DietPlanSummary(
      id: json['id'] as String,
      name: json['name'] as String,
      calorieGoal: json['calorieGoal'] as String? ?? 'Maintenance',
      status: json['status'] as String? ?? 'Active',
      version: (json['version'] as num?)?.toInt() ?? 1,
      targetKcal: json['targetKcal'] as num? ?? 0,
      createdAt: json['createdAt'] as String?,
    );

Map<String, dynamic> _$DietPlanSummaryToJson(_DietPlanSummary instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'calorieGoal': instance.calorieGoal,
      'status': instance.status,
      'version': instance.version,
      'targetKcal': instance.targetKcal,
      'createdAt': instance.createdAt,
    };
