// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'review_controller.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ReviewQueueItem _$ReviewQueueItemFromJson(Map<String, dynamic> json) =>
    _ReviewQueueItem(
      id: json['id'] as String,
      name: json['name'] as String? ?? '',
      version: (json['version'] as num?)?.toInt() ?? 1,
      createdAt: json['createdAt'] as String?,
      student: json['student'] as String?,
      split: json['split'] as String?,
      goal: json['goal'] as String?,
      targetKcal: json['targetKcal'] as num?,
      calorieGoal: json['calorieGoal'] as String?,
    );

Map<String, dynamic> _$ReviewQueueItemToJson(_ReviewQueueItem instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'version': instance.version,
      'createdAt': instance.createdAt,
      'student': instance.student,
      'split': instance.split,
      'goal': instance.goal,
      'targetKcal': instance.targetKcal,
      'calorieGoal': instance.calorieGoal,
    };
