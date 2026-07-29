// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'diary_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_DiaryMacros _$DiaryMacrosFromJson(Map<String, dynamic> json) => _DiaryMacros(
  kcal: json['kcal'] as num? ?? 0,
  proteinG: json['proteinG'] as num? ?? 0,
  carbsG: json['carbsG'] as num? ?? 0,
  fatG: json['fatG'] as num? ?? 0,
);

Map<String, dynamic> _$DiaryMacrosToJson(_DiaryMacros instance) =>
    <String, dynamic>{
      'kcal': instance.kcal,
      'proteinG': instance.proteinG,
      'carbsG': instance.carbsG,
      'fatG': instance.fatG,
    };

_DiaryEntry _$DiaryEntryFromJson(Map<String, dynamic> json) => _DiaryEntry(
  id: json['id'] as String,
  createdAt: json['createdAt'] as String?,
  totalKcal: json['totalKcal'] as num? ?? 0,
  totalProteinG: json['totalProteinG'] as num? ?? 0,
  totalCarbsG: json['totalCarbsG'] as num? ?? 0,
  totalFatG: json['totalFatG'] as num? ?? 0,
  userAdjusted: json['userAdjusted'] as bool? ?? false,
  excludedFromDiary: json['excludedFromDiary'] as bool? ?? false,
);

Map<String, dynamic> _$DiaryEntryToJson(_DiaryEntry instance) =>
    <String, dynamic>{
      'id': instance.id,
      'createdAt': instance.createdAt,
      'totalKcal': instance.totalKcal,
      'totalProteinG': instance.totalProteinG,
      'totalCarbsG': instance.totalCarbsG,
      'totalFatG': instance.totalFatG,
      'userAdjusted': instance.userAdjusted,
      'excludedFromDiary': instance.excludedFromDiary,
    };

_DiaryDayTotal _$DiaryDayTotalFromJson(Map<String, dynamic> json) =>
    _DiaryDayTotal(
      date: json['date'] as String,
      kcal: json['kcal'] as num? ?? 0,
    );

Map<String, dynamic> _$DiaryDayTotalToJson(_DiaryDayTotal instance) =>
    <String, dynamic>{'date': instance.date, 'kcal': instance.kcal};

_DiaryDay _$DiaryDayFromJson(Map<String, dynamic> json) => _DiaryDay(
  date: json['date'] as String,
  targets: json['targets'] == null
      ? null
      : DiaryMacros.fromJson(json['targets'] as Map<String, dynamic>),
  consumed: json['consumed'] == null
      ? const DiaryMacros()
      : DiaryMacros.fromJson(json['consumed'] as Map<String, dynamic>),
  entries:
      (json['entries'] as List<dynamic>?)
          ?.map((e) => DiaryEntry.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
  week:
      (json['week'] as List<dynamic>?)
          ?.map((e) => DiaryDayTotal.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
);

Map<String, dynamic> _$DiaryDayToJson(_DiaryDay instance) => <String, dynamic>{
  'date': instance.date,
  'targets': instance.targets,
  'consumed': instance.consumed,
  'entries': instance.entries,
  'week': instance.week,
};
