// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'profile_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_UserProfile _$UserProfileFromJson(Map<String, dynamic> json) => _UserProfile(
  id: json['id'] as String?,
  userId: json['userId'] as String?,
  birthDate: json['birthDate'] as String?,
  sex: json['sex'] as String?,
  heightCm: (json['heightCm'] as num?)?.toDouble(),
  biotype: json['biotype'] as String?,
  experienceLevel: json['experienceLevel'] as String? ?? 'Beginner',
  goal: json['goal'] as String? ?? 'Hypertrophy',
  trainingDaysPerWeek: (json['trainingDaysPerWeek'] as num?)?.toInt() ?? 3,
  priorityMuscleGroups:
      (json['priorityMuscleGroups'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const [],
  injuryNotes: json['injuryNotes'] as String?,
  injuryTags:
      (json['injuryTags'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const [],
  availableEquipment:
      (json['availableEquipment'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const [],
  dietaryRestrictions:
      (json['dietaryRestrictions'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const [],
  foodPreferences:
      (json['foodPreferences'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const [],
);

Map<String, dynamic> _$UserProfileToJson(_UserProfile instance) =>
    <String, dynamic>{
      'id': instance.id,
      'userId': instance.userId,
      'birthDate': instance.birthDate,
      'sex': instance.sex,
      'heightCm': instance.heightCm,
      'biotype': instance.biotype,
      'experienceLevel': instance.experienceLevel,
      'goal': instance.goal,
      'trainingDaysPerWeek': instance.trainingDaysPerWeek,
      'priorityMuscleGroups': instance.priorityMuscleGroups,
      'injuryNotes': instance.injuryNotes,
      'injuryTags': instance.injuryTags,
      'availableEquipment': instance.availableEquipment,
      'dietaryRestrictions': instance.dietaryRestrictions,
      'foodPreferences': instance.foodPreferences,
    };

_ProfileRequest _$ProfileRequestFromJson(Map<String, dynamic> json) =>
    _ProfileRequest(
      birthDate: json['birthDate'] as String?,
      sex: json['sex'] as String?,
      heightCm: (json['heightCm'] as num?)?.toDouble(),
      biotype: json['biotype'] as String?,
      experienceLevel: json['experienceLevel'] as String,
      goal: json['goal'] as String,
      trainingDaysPerWeek: (json['trainingDaysPerWeek'] as num).toInt(),
      priorityMuscleGroups: (json['priorityMuscleGroups'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      injuryNotes: json['injuryNotes'] as String?,
      injuryTags: (json['injuryTags'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      availableEquipment: (json['availableEquipment'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      dietaryRestrictions: (json['dietaryRestrictions'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      foodPreferences: (json['foodPreferences'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
    );

Map<String, dynamic> _$ProfileRequestToJson(_ProfileRequest instance) =>
    <String, dynamic>{
      'birthDate': instance.birthDate,
      'sex': instance.sex,
      'heightCm': instance.heightCm,
      'biotype': instance.biotype,
      'experienceLevel': instance.experienceLevel,
      'goal': instance.goal,
      'trainingDaysPerWeek': instance.trainingDaysPerWeek,
      'priorityMuscleGroups': instance.priorityMuscleGroups,
      'injuryNotes': instance.injuryNotes,
      'injuryTags': instance.injuryTags,
      'availableEquipment': instance.availableEquipment,
      'dietaryRestrictions': instance.dietaryRestrictions,
      'foodPreferences': instance.foodPreferences,
    };

_ConsentRequest _$ConsentRequestFromJson(Map<String, dynamic> json) =>
    _ConsentRequest(
      type: json['type'] as String,
      termsVersion: json['termsVersion'] as String,
    );

Map<String, dynamic> _$ConsentRequestToJson(_ConsentRequest instance) =>
    <String, dynamic>{
      'type': instance.type,
      'termsVersion': instance.termsVersion,
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
