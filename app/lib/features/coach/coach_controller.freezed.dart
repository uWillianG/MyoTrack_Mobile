// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'coach_controller.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$CoachMessage {

 String get id;/// True = escrita pelo usuário; false = resposta do coach.
 bool get fromUser; String get content; String? get createdAt;
/// Create a copy of CoachMessage
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CoachMessageCopyWith<CoachMessage> get copyWith => _$CoachMessageCopyWithImpl<CoachMessage>(this as CoachMessage, _$identity);

  /// Serializes this CoachMessage to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CoachMessage&&(identical(other.id, id) || other.id == id)&&(identical(other.fromUser, fromUser) || other.fromUser == fromUser)&&(identical(other.content, content) || other.content == content)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,fromUser,content,createdAt);

@override
String toString() {
  return 'CoachMessage(id: $id, fromUser: $fromUser, content: $content, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class $CoachMessageCopyWith<$Res>  {
  factory $CoachMessageCopyWith(CoachMessage value, $Res Function(CoachMessage) _then) = _$CoachMessageCopyWithImpl;
@useResult
$Res call({
 String id, bool fromUser, String content, String? createdAt
});




}
/// @nodoc
class _$CoachMessageCopyWithImpl<$Res>
    implements $CoachMessageCopyWith<$Res> {
  _$CoachMessageCopyWithImpl(this._self, this._then);

  final CoachMessage _self;
  final $Res Function(CoachMessage) _then;

/// Create a copy of CoachMessage
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? fromUser = null,Object? content = null,Object? createdAt = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,fromUser: null == fromUser ? _self.fromUser : fromUser // ignore: cast_nullable_to_non_nullable
as bool,content: null == content ? _self.content : content // ignore: cast_nullable_to_non_nullable
as String,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [CoachMessage].
extension CoachMessagePatterns on CoachMessage {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CoachMessage value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CoachMessage() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CoachMessage value)  $default,){
final _that = this;
switch (_that) {
case _CoachMessage():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CoachMessage value)?  $default,){
final _that = this;
switch (_that) {
case _CoachMessage() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  bool fromUser,  String content,  String? createdAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CoachMessage() when $default != null:
return $default(_that.id,_that.fromUser,_that.content,_that.createdAt);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  bool fromUser,  String content,  String? createdAt)  $default,) {final _that = this;
switch (_that) {
case _CoachMessage():
return $default(_that.id,_that.fromUser,_that.content,_that.createdAt);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  bool fromUser,  String content,  String? createdAt)?  $default,) {final _that = this;
switch (_that) {
case _CoachMessage() when $default != null:
return $default(_that.id,_that.fromUser,_that.content,_that.createdAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CoachMessage implements CoachMessage {
  const _CoachMessage({required this.id, this.fromUser = false, this.content = '', this.createdAt});
  factory _CoachMessage.fromJson(Map<String, dynamic> json) => _$CoachMessageFromJson(json);

@override final  String id;
/// True = escrita pelo usuário; false = resposta do coach.
@override@JsonKey() final  bool fromUser;
@override@JsonKey() final  String content;
@override final  String? createdAt;

/// Create a copy of CoachMessage
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CoachMessageCopyWith<_CoachMessage> get copyWith => __$CoachMessageCopyWithImpl<_CoachMessage>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CoachMessageToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CoachMessage&&(identical(other.id, id) || other.id == id)&&(identical(other.fromUser, fromUser) || other.fromUser == fromUser)&&(identical(other.content, content) || other.content == content)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,fromUser,content,createdAt);

@override
String toString() {
  return 'CoachMessage(id: $id, fromUser: $fromUser, content: $content, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class _$CoachMessageCopyWith<$Res> implements $CoachMessageCopyWith<$Res> {
  factory _$CoachMessageCopyWith(_CoachMessage value, $Res Function(_CoachMessage) _then) = __$CoachMessageCopyWithImpl;
@override @useResult
$Res call({
 String id, bool fromUser, String content, String? createdAt
});




}
/// @nodoc
class __$CoachMessageCopyWithImpl<$Res>
    implements _$CoachMessageCopyWith<$Res> {
  __$CoachMessageCopyWithImpl(this._self, this._then);

  final _CoachMessage _self;
  final $Res Function(_CoachMessage) _then;

/// Create a copy of CoachMessage
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? fromUser = null,Object? content = null,Object? createdAt = freezed,}) {
  return _then(_CoachMessage(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,fromUser: null == fromUser ? _self.fromUser : fromUser // ignore: cast_nullable_to_non_nullable
as bool,content: null == content ? _self.content : content // ignore: cast_nullable_to_non_nullable
as String,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
