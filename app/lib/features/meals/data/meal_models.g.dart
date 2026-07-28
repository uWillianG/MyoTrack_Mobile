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
    };

_MealAnalysis _$MealAnalysisFromJson(Map<String, dynamic> json) =>
    _MealAnalysis(
      id: json['id'] as String,
      analysisJobId: json['analysisJobId'] as String?,
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
      createdAt: json['createdAt'] as String?,
    );

Map<String, dynamic> _$MealAnalysisToJson(_MealAnalysis instance) =>
    <String, dynamic>{
      'id': instance.id,
      'analysisJobId': instance.analysisJobId,
      'items': instance.items,
      'totalKcal': instance.totalKcal,
      'totalProteinG': instance.totalProteinG,
      'totalCarbsG': instance.totalCarbsG,
      'totalFatG': instance.totalFatG,
      'userAdjusted': instance.userAdjusted,
      'excludedFromDiary': instance.excludedFromDiary,
      'photoUrl': instance.photoUrl,
      'createdAt': instance.createdAt,
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
