// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'billing_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_SubscriptionStatus _$SubscriptionStatusFromJson(Map<String, dynamic> json) =>
    _SubscriptionStatus(
      plan: json['plan'] as String? ?? 'Free',
      maxMealAnalysesPerDay:
          (json['maxMealAnalysesPerDay'] as num?)?.toInt() ?? 0,
      maxVideoAnalysesPerDay:
          (json['maxVideoAnalysesPerDay'] as num?)?.toInt() ?? 0,
      maxCoachMessagesPerDay:
          (json['maxCoachMessagesPerDay'] as num?)?.toInt() ?? 0,
      currentPeriodEnd: json['currentPeriodEnd'] as String?,
      provider: json['provider'] as String?,
      paymentPastDue: json['paymentPastDue'] as bool? ?? false,
      managedByStore: json['managedByStore'] as bool? ?? false,
    );

Map<String, dynamic> _$SubscriptionStatusToJson(_SubscriptionStatus instance) =>
    <String, dynamic>{
      'plan': instance.plan,
      'maxMealAnalysesPerDay': instance.maxMealAnalysesPerDay,
      'maxVideoAnalysesPerDay': instance.maxVideoAnalysesPerDay,
      'maxCoachMessagesPerDay': instance.maxCoachMessagesPerDay,
      'currentPeriodEnd': instance.currentPeriodEnd,
      'provider': instance.provider,
      'paymentPastDue': instance.paymentPastDue,
      'managedByStore': instance.managedByStore,
    };
