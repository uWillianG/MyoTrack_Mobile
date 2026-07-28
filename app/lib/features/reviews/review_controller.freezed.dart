// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'review_controller.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ReviewQueueItem {

 String get id; String get name; int get version; String? get createdAt;/// E-mail do aluno: é o que diz ao revisor de quem é o plano.
 String? get student;/// Divisão do treino (`split`) — só nos treinos.
 String? get split; String? get goal;/// Meta calórica — só nas dietas.
 num? get targetKcal; String? get calorieGoal;
/// Create a copy of ReviewQueueItem
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ReviewQueueItemCopyWith<ReviewQueueItem> get copyWith => _$ReviewQueueItemCopyWithImpl<ReviewQueueItem>(this as ReviewQueueItem, _$identity);

  /// Serializes this ReviewQueueItem to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ReviewQueueItem&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.version, version) || other.version == version)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.student, student) || other.student == student)&&(identical(other.split, split) || other.split == split)&&(identical(other.goal, goal) || other.goal == goal)&&(identical(other.targetKcal, targetKcal) || other.targetKcal == targetKcal)&&(identical(other.calorieGoal, calorieGoal) || other.calorieGoal == calorieGoal));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,version,createdAt,student,split,goal,targetKcal,calorieGoal);

@override
String toString() {
  return 'ReviewQueueItem(id: $id, name: $name, version: $version, createdAt: $createdAt, student: $student, split: $split, goal: $goal, targetKcal: $targetKcal, calorieGoal: $calorieGoal)';
}


}

/// @nodoc
abstract mixin class $ReviewQueueItemCopyWith<$Res>  {
  factory $ReviewQueueItemCopyWith(ReviewQueueItem value, $Res Function(ReviewQueueItem) _then) = _$ReviewQueueItemCopyWithImpl;
@useResult
$Res call({
 String id, String name, int version, String? createdAt, String? student, String? split, String? goal, num? targetKcal, String? calorieGoal
});




}
/// @nodoc
class _$ReviewQueueItemCopyWithImpl<$Res>
    implements $ReviewQueueItemCopyWith<$Res> {
  _$ReviewQueueItemCopyWithImpl(this._self, this._then);

  final ReviewQueueItem _self;
  final $Res Function(ReviewQueueItem) _then;

/// Create a copy of ReviewQueueItem
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? version = null,Object? createdAt = freezed,Object? student = freezed,Object? split = freezed,Object? goal = freezed,Object? targetKcal = freezed,Object? calorieGoal = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,version: null == version ? _self.version : version // ignore: cast_nullable_to_non_nullable
as int,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as String?,student: freezed == student ? _self.student : student // ignore: cast_nullable_to_non_nullable
as String?,split: freezed == split ? _self.split : split // ignore: cast_nullable_to_non_nullable
as String?,goal: freezed == goal ? _self.goal : goal // ignore: cast_nullable_to_non_nullable
as String?,targetKcal: freezed == targetKcal ? _self.targetKcal : targetKcal // ignore: cast_nullable_to_non_nullable
as num?,calorieGoal: freezed == calorieGoal ? _self.calorieGoal : calorieGoal // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [ReviewQueueItem].
extension ReviewQueueItemPatterns on ReviewQueueItem {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ReviewQueueItem value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ReviewQueueItem() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ReviewQueueItem value)  $default,){
final _that = this;
switch (_that) {
case _ReviewQueueItem():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ReviewQueueItem value)?  $default,){
final _that = this;
switch (_that) {
case _ReviewQueueItem() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  int version,  String? createdAt,  String? student,  String? split,  String? goal,  num? targetKcal,  String? calorieGoal)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ReviewQueueItem() when $default != null:
return $default(_that.id,_that.name,_that.version,_that.createdAt,_that.student,_that.split,_that.goal,_that.targetKcal,_that.calorieGoal);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  int version,  String? createdAt,  String? student,  String? split,  String? goal,  num? targetKcal,  String? calorieGoal)  $default,) {final _that = this;
switch (_that) {
case _ReviewQueueItem():
return $default(_that.id,_that.name,_that.version,_that.createdAt,_that.student,_that.split,_that.goal,_that.targetKcal,_that.calorieGoal);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  int version,  String? createdAt,  String? student,  String? split,  String? goal,  num? targetKcal,  String? calorieGoal)?  $default,) {final _that = this;
switch (_that) {
case _ReviewQueueItem() when $default != null:
return $default(_that.id,_that.name,_that.version,_that.createdAt,_that.student,_that.split,_that.goal,_that.targetKcal,_that.calorieGoal);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ReviewQueueItem implements ReviewQueueItem {
  const _ReviewQueueItem({required this.id, this.name = '', this.version = 1, this.createdAt, this.student, this.split, this.goal, this.targetKcal, this.calorieGoal});
  factory _ReviewQueueItem.fromJson(Map<String, dynamic> json) => _$ReviewQueueItemFromJson(json);

@override final  String id;
@override@JsonKey() final  String name;
@override@JsonKey() final  int version;
@override final  String? createdAt;
/// E-mail do aluno: é o que diz ao revisor de quem é o plano.
@override final  String? student;
/// Divisão do treino (`split`) — só nos treinos.
@override final  String? split;
@override final  String? goal;
/// Meta calórica — só nas dietas.
@override final  num? targetKcal;
@override final  String? calorieGoal;

/// Create a copy of ReviewQueueItem
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ReviewQueueItemCopyWith<_ReviewQueueItem> get copyWith => __$ReviewQueueItemCopyWithImpl<_ReviewQueueItem>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ReviewQueueItemToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ReviewQueueItem&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.version, version) || other.version == version)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.student, student) || other.student == student)&&(identical(other.split, split) || other.split == split)&&(identical(other.goal, goal) || other.goal == goal)&&(identical(other.targetKcal, targetKcal) || other.targetKcal == targetKcal)&&(identical(other.calorieGoal, calorieGoal) || other.calorieGoal == calorieGoal));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,version,createdAt,student,split,goal,targetKcal,calorieGoal);

@override
String toString() {
  return 'ReviewQueueItem(id: $id, name: $name, version: $version, createdAt: $createdAt, student: $student, split: $split, goal: $goal, targetKcal: $targetKcal, calorieGoal: $calorieGoal)';
}


}

/// @nodoc
abstract mixin class _$ReviewQueueItemCopyWith<$Res> implements $ReviewQueueItemCopyWith<$Res> {
  factory _$ReviewQueueItemCopyWith(_ReviewQueueItem value, $Res Function(_ReviewQueueItem) _then) = __$ReviewQueueItemCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, int version, String? createdAt, String? student, String? split, String? goal, num? targetKcal, String? calorieGoal
});




}
/// @nodoc
class __$ReviewQueueItemCopyWithImpl<$Res>
    implements _$ReviewQueueItemCopyWith<$Res> {
  __$ReviewQueueItemCopyWithImpl(this._self, this._then);

  final _ReviewQueueItem _self;
  final $Res Function(_ReviewQueueItem) _then;

/// Create a copy of ReviewQueueItem
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? version = null,Object? createdAt = freezed,Object? student = freezed,Object? split = freezed,Object? goal = freezed,Object? targetKcal = freezed,Object? calorieGoal = freezed,}) {
  return _then(_ReviewQueueItem(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,version: null == version ? _self.version : version // ignore: cast_nullable_to_non_nullable
as int,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as String?,student: freezed == student ? _self.student : student // ignore: cast_nullable_to_non_nullable
as String?,split: freezed == split ? _self.split : split // ignore: cast_nullable_to_non_nullable
as String?,goal: freezed == goal ? _self.goal : goal // ignore: cast_nullable_to_non_nullable
as String?,targetKcal: freezed == targetKcal ? _self.targetKcal : targetKcal // ignore: cast_nullable_to_non_nullable
as num?,calorieGoal: freezed == calorieGoal ? _self.calorieGoal : calorieGoal // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
