// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'coach_controller.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_CoachConversation _$CoachConversationFromJson(Map<String, dynamic> json) =>
    _CoachConversation(
      id: json['id'] as String,
      title: json['title'] as String? ?? '',
      updatedAt: json['updatedAt'] as String?,
      messages: (json['messages'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$CoachConversationToJson(_CoachConversation instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'updatedAt': instance.updatedAt,
      'messages': instance.messages,
    };

_CoachMessage _$CoachMessageFromJson(Map<String, dynamic> json) =>
    _CoachMessage(
      id: json['id'] as String,
      fromUser: json['fromUser'] as bool? ?? false,
      content: json['content'] as String? ?? '',
      createdAt: json['createdAt'] as String?,
    );

Map<String, dynamic> _$CoachMessageToJson(_CoachMessage instance) =>
    <String, dynamic>{
      'id': instance.id,
      'fromUser': instance.fromUser,
      'content': instance.content,
      'createdAt': instance.createdAt,
    };
