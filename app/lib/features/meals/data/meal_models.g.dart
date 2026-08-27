// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'meal_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_MealAnalysisItem _$MealAnalysisItemFromJson(Map<String, dynamic> json) =>
    _MealAnalysisItem(
      description: json['description'] as String,
      foodItemId: (json['foodItemId'] as num?)?.toInt(),
      quantityG: json['quantityG'] as num? ?? 0,
      kcal: json['kcal'] as num? ?? 0,
      proteinG: json['proteinG'] as num? ?? 0,
      carbsG: json['carbsG'] as num? ?? 0,
      fatG: json['fatG'] as num? ?? 0,
      posX: (json['posX'] as num?)?.toInt(),
      posY: (json['posY'] as num?)?.toInt(),
    );

Map<String, dynamic> _$MealAnalysisItemToJson(_MealAnalysisItem instance) =>
    <String, dynamic>{
      'description': instance.description,
      'foodItemId': instance.foodItemId,
      'quantityG': instance.quantityG,
      'kcal': instance.kcal,
      'proteinG': instance.proteinG,
      'carbsG': instance.carbsG,
      'fatG': instance.fatG,
      'posX': instance.posX,
      'posY': instance.posY,
    };

_MealAnalysis _$MealAnalysisFromJson(Map<String, dynamic> json) =>
    _MealAnalysis(
      id: json['id'] as String,
      analysisJobId: json['analysisJobId'] as String?,
      source: json['source'] as String?,
      items:
          (json['items'] as List<dynamic>?)
              ?.map((e) => MealAnalysisItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      totalKcal: json['totalKcal'] as num? ?? 0,
      totalProteinG: json['totalProteinG'] as num? ?? 0,
      totalCarbsG: json['totalCarbsG'] as num? ?? 0,
      totalFatG: json['totalFatG'] as num? ?? 0,
      userAdjusted: json['userAdjusted'] as bool? ?? false,
      excludedFromDiary: json['excludedFromDiary'] as bool? ?? false,
      photoUrl: json['photoUrl'] as String?,
      illustratedPhotoUrl: json['illustratedPhotoUrl'] as String?,
      createdAt: json['createdAt'] as String?,
    );

Map<String, dynamic> _$MealAnalysisToJson(_MealAnalysis instance) =>
    <String, dynamic>{
      'id': instance.id,
      'analysisJobId': instance.analysisJobId,
      'source': instance.source,
      'items': instance.items,
      'totalKcal': instance.totalKcal,
      'totalProteinG': instance.totalProteinG,
      'totalCarbsG': instance.totalCarbsG,
      'totalFatG': instance.totalFatG,
      'userAdjusted': instance.userAdjusted,
      'excludedFromDiary': instance.excludedFromDiary,
      'photoUrl': instance.photoUrl,
      'illustratedPhotoUrl': instance.illustratedPhotoUrl,
      'createdAt': instance.createdAt,
    };

_FoodItem _$FoodItemFromJson(Map<String, dynamic> json) => _FoodItem(
  id: (json['id'] as num).toInt(),
  name: json['name'] as String,
  kcalPer100g: json['kcalPer100g'] as num? ?? 0,
  proteinPer100g: json['proteinPer100g'] as num? ?? 0,
  carbsPer100g: json['carbsPer100g'] as num? ?? 0,
  fatPer100g: json['fatPer100g'] as num? ?? 0,
  fiberPer100g: json['fiberPer100g'] as num?,
  source: json['source'] as String?,
);

Map<String, dynamic> _$FoodItemToJson(_FoodItem instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'kcalPer100g': instance.kcalPer100g,
  'proteinPer100g': instance.proteinPer100g,
  'carbsPer100g': instance.carbsPer100g,
  'fatPer100g': instance.fatPer100g,
  'fiberPer100g': instance.fiberPer100g,
  'source': instance.source,
};

_MealManualItem _$MealManualItemFromJson(Map<String, dynamic> json) =>
    _MealManualItem(
      description: json['description'] as String,
      foodItemId: (json['foodItemId'] as num?)?.toInt(),
      quantityG: json['quantityG'] as num? ?? 0,
      kcal: json['kcal'] as num? ?? 0,
      proteinG: json['proteinG'] as num? ?? 0,
      carbsG: json['carbsG'] as num? ?? 0,
      fatG: json['fatG'] as num? ?? 0,
    );

Map<String, dynamic> _$MealManualItemToJson(_MealManualItem instance) =>
    <String, dynamic>{
      'description': instance.description,
      'foodItemId': instance.foodItemId,
      'quantityG': instance.quantityG,
      'kcal': instance.kcal,
      'proteinG': instance.proteinG,
      'carbsG': instance.carbsG,
      'fatG': instance.fatG,
    };

_MealManualRequest _$MealManualRequestFromJson(Map<String, dynamic> json) =>
    _MealManualRequest(
      items: (json['items'] as List<dynamic>)
          .map((e) => MealManualItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      createdAt: json['createdAt'] as String?,
    );

Map<String, dynamic> _$MealManualRequestToJson(_MealManualRequest instance) =>
    <String, dynamic>{'items': instance.items, 'createdAt': instance.createdAt};

_MealEstimate _$MealEstimateFromJson(Map<String, dynamic> json) =>
    _MealEstimate(
      items:
          (json['items'] as List<dynamic>?)
              ?.map((e) => MealAnalysisItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      totalKcal: json['totalKcal'] as num? ?? 0,
      totalProteinG: json['totalProteinG'] as num? ?? 0,
      totalCarbsG: json['totalCarbsG'] as num? ?? 0,
      totalFatG: json['totalFatG'] as num? ?? 0,
    );

Map<String, dynamic> _$MealEstimateToJson(_MealEstimate instance) =>
    <String, dynamic>{
      'items': instance.items,
      'totalKcal': instance.totalKcal,
      'totalProteinG': instance.totalProteinG,
      'totalCarbsG': instance.totalCarbsG,
      'totalFatG': instance.totalFatG,
    };

_MealAdjustRequest _$MealAdjustRequestFromJson(Map<String, dynamic> json) =>
    _MealAdjustRequest(
      items: (json['items'] as List<dynamic>?)
          ?.map((e) => MealAnalysisItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      excludedFromDiary: json['excludedFromDiary'] as bool?,
    );

Map<String, dynamic> _$MealAdjustRequestToJson(_MealAdjustRequest instance) =>
    <String, dynamic>{
      'items': instance.items,
      'excludedFromDiary': instance.excludedFromDiary,
    };
