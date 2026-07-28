// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'workout_models.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$WorkoutPlan {

 String get id; String get name; String get split; String get goal; int get version; String? get createdAt; String get reviewStatus; String? get reviewNote; String? get reviewedAt; List<WorkoutDay> get days;
/// Create a copy of WorkoutPlan
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$WorkoutPlanCopyWith<WorkoutPlan> get copyWith => _$WorkoutPlanCopyWithImpl<WorkoutPlan>(this as WorkoutPlan, _$identity);

  /// Serializes this WorkoutPlan to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WorkoutPlan&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.split, split) || other.split == split)&&(identical(other.goal, goal) || other.goal == goal)&&(identical(other.version, version) || other.version == version)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.reviewStatus, reviewStatus) || other.reviewStatus == reviewStatus)&&(identical(other.reviewNote, reviewNote) || other.reviewNote == reviewNote)&&(identical(other.reviewedAt, reviewedAt) || other.reviewedAt == reviewedAt)&&const DeepCollectionEquality().equals(other.days, days));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,split,goal,version,createdAt,reviewStatus,reviewNote,reviewedAt,const DeepCollectionEquality().hash(days));

@override
String toString() {
  return 'WorkoutPlan(id: $id, name: $name, split: $split, goal: $goal, version: $version, createdAt: $createdAt, reviewStatus: $reviewStatus, reviewNote: $reviewNote, reviewedAt: $reviewedAt, days: $days)';
}


}

/// @nodoc
abstract mixin class $WorkoutPlanCopyWith<$Res>  {
  factory $WorkoutPlanCopyWith(WorkoutPlan value, $Res Function(WorkoutPlan) _then) = _$WorkoutPlanCopyWithImpl;
@useResult
$Res call({
 String id, String name, String split, String goal, int version, String? createdAt, String reviewStatus, String? reviewNote, String? reviewedAt, List<WorkoutDay> days
});




}
/// @nodoc
class _$WorkoutPlanCopyWithImpl<$Res>
    implements $WorkoutPlanCopyWith<$Res> {
  _$WorkoutPlanCopyWithImpl(this._self, this._then);

  final WorkoutPlan _self;
  final $Res Function(WorkoutPlan) _then;

/// Create a copy of WorkoutPlan
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? split = null,Object? goal = null,Object? version = null,Object? createdAt = freezed,Object? reviewStatus = null,Object? reviewNote = freezed,Object? reviewedAt = freezed,Object? days = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,split: null == split ? _self.split : split // ignore: cast_nullable_to_non_nullable
as String,goal: null == goal ? _self.goal : goal // ignore: cast_nullable_to_non_nullable
as String,version: null == version ? _self.version : version // ignore: cast_nullable_to_non_nullable
as int,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as String?,reviewStatus: null == reviewStatus ? _self.reviewStatus : reviewStatus // ignore: cast_nullable_to_non_nullable
as String,reviewNote: freezed == reviewNote ? _self.reviewNote : reviewNote // ignore: cast_nullable_to_non_nullable
as String?,reviewedAt: freezed == reviewedAt ? _self.reviewedAt : reviewedAt // ignore: cast_nullable_to_non_nullable
as String?,days: null == days ? _self.days : days // ignore: cast_nullable_to_non_nullable
as List<WorkoutDay>,
  ));
}

}


/// Adds pattern-matching-related methods to [WorkoutPlan].
extension WorkoutPlanPatterns on WorkoutPlan {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _WorkoutPlan value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _WorkoutPlan() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _WorkoutPlan value)  $default,){
final _that = this;
switch (_that) {
case _WorkoutPlan():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _WorkoutPlan value)?  $default,){
final _that = this;
switch (_that) {
case _WorkoutPlan() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  String split,  String goal,  int version,  String? createdAt,  String reviewStatus,  String? reviewNote,  String? reviewedAt,  List<WorkoutDay> days)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _WorkoutPlan() when $default != null:
return $default(_that.id,_that.name,_that.split,_that.goal,_that.version,_that.createdAt,_that.reviewStatus,_that.reviewNote,_that.reviewedAt,_that.days);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  String split,  String goal,  int version,  String? createdAt,  String reviewStatus,  String? reviewNote,  String? reviewedAt,  List<WorkoutDay> days)  $default,) {final _that = this;
switch (_that) {
case _WorkoutPlan():
return $default(_that.id,_that.name,_that.split,_that.goal,_that.version,_that.createdAt,_that.reviewStatus,_that.reviewNote,_that.reviewedAt,_that.days);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  String split,  String goal,  int version,  String? createdAt,  String reviewStatus,  String? reviewNote,  String? reviewedAt,  List<WorkoutDay> days)?  $default,) {final _that = this;
switch (_that) {
case _WorkoutPlan() when $default != null:
return $default(_that.id,_that.name,_that.split,_that.goal,_that.version,_that.createdAt,_that.reviewStatus,_that.reviewNote,_that.reviewedAt,_that.days);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _WorkoutPlan implements WorkoutPlan {
  const _WorkoutPlan({required this.id, required this.name, required this.split, required this.goal, this.version = 1, this.createdAt, this.reviewStatus = 'NotReviewed', this.reviewNote, this.reviewedAt, final  List<WorkoutDay> days = const []}): _days = days;
  factory _WorkoutPlan.fromJson(Map<String, dynamic> json) => _$WorkoutPlanFromJson(json);

@override final  String id;
@override final  String name;
@override final  String split;
@override final  String goal;
@override@JsonKey() final  int version;
@override final  String? createdAt;
@override@JsonKey() final  String reviewStatus;
@override final  String? reviewNote;
@override final  String? reviewedAt;
 final  List<WorkoutDay> _days;
@override@JsonKey() List<WorkoutDay> get days {
  if (_days is EqualUnmodifiableListView) return _days;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_days);
}


/// Create a copy of WorkoutPlan
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$WorkoutPlanCopyWith<_WorkoutPlan> get copyWith => __$WorkoutPlanCopyWithImpl<_WorkoutPlan>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$WorkoutPlanToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _WorkoutPlan&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.split, split) || other.split == split)&&(identical(other.goal, goal) || other.goal == goal)&&(identical(other.version, version) || other.version == version)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.reviewStatus, reviewStatus) || other.reviewStatus == reviewStatus)&&(identical(other.reviewNote, reviewNote) || other.reviewNote == reviewNote)&&(identical(other.reviewedAt, reviewedAt) || other.reviewedAt == reviewedAt)&&const DeepCollectionEquality().equals(other._days, _days));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,split,goal,version,createdAt,reviewStatus,reviewNote,reviewedAt,const DeepCollectionEquality().hash(_days));

@override
String toString() {
  return 'WorkoutPlan(id: $id, name: $name, split: $split, goal: $goal, version: $version, createdAt: $createdAt, reviewStatus: $reviewStatus, reviewNote: $reviewNote, reviewedAt: $reviewedAt, days: $days)';
}


}

/// @nodoc
abstract mixin class _$WorkoutPlanCopyWith<$Res> implements $WorkoutPlanCopyWith<$Res> {
  factory _$WorkoutPlanCopyWith(_WorkoutPlan value, $Res Function(_WorkoutPlan) _then) = __$WorkoutPlanCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, String split, String goal, int version, String? createdAt, String reviewStatus, String? reviewNote, String? reviewedAt, List<WorkoutDay> days
});




}
/// @nodoc
class __$WorkoutPlanCopyWithImpl<$Res>
    implements _$WorkoutPlanCopyWith<$Res> {
  __$WorkoutPlanCopyWithImpl(this._self, this._then);

  final _WorkoutPlan _self;
  final $Res Function(_WorkoutPlan) _then;

/// Create a copy of WorkoutPlan
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? split = null,Object? goal = null,Object? version = null,Object? createdAt = freezed,Object? reviewStatus = null,Object? reviewNote = freezed,Object? reviewedAt = freezed,Object? days = null,}) {
  return _then(_WorkoutPlan(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,split: null == split ? _self.split : split // ignore: cast_nullable_to_non_nullable
as String,goal: null == goal ? _self.goal : goal // ignore: cast_nullable_to_non_nullable
as String,version: null == version ? _self.version : version // ignore: cast_nullable_to_non_nullable
as int,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as String?,reviewStatus: null == reviewStatus ? _self.reviewStatus : reviewStatus // ignore: cast_nullable_to_non_nullable
as String,reviewNote: freezed == reviewNote ? _self.reviewNote : reviewNote // ignore: cast_nullable_to_non_nullable
as String?,reviewedAt: freezed == reviewedAt ? _self.reviewedAt : reviewedAt // ignore: cast_nullable_to_non_nullable
as String?,days: null == days ? _self._days : days // ignore: cast_nullable_to_non_nullable
as List<WorkoutDay>,
  ));
}


}


/// @nodoc
mixin _$WorkoutDay {

 String get id; int get order; String get label; List<WorkoutExercise> get exercises;
/// Create a copy of WorkoutDay
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$WorkoutDayCopyWith<WorkoutDay> get copyWith => _$WorkoutDayCopyWithImpl<WorkoutDay>(this as WorkoutDay, _$identity);

  /// Serializes this WorkoutDay to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WorkoutDay&&(identical(other.id, id) || other.id == id)&&(identical(other.order, order) || other.order == order)&&(identical(other.label, label) || other.label == label)&&const DeepCollectionEquality().equals(other.exercises, exercises));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,order,label,const DeepCollectionEquality().hash(exercises));

@override
String toString() {
  return 'WorkoutDay(id: $id, order: $order, label: $label, exercises: $exercises)';
}


}

/// @nodoc
abstract mixin class $WorkoutDayCopyWith<$Res>  {
  factory $WorkoutDayCopyWith(WorkoutDay value, $Res Function(WorkoutDay) _then) = _$WorkoutDayCopyWithImpl;
@useResult
$Res call({
 String id, int order, String label, List<WorkoutExercise> exercises
});




}
/// @nodoc
class _$WorkoutDayCopyWithImpl<$Res>
    implements $WorkoutDayCopyWith<$Res> {
  _$WorkoutDayCopyWithImpl(this._self, this._then);

  final WorkoutDay _self;
  final $Res Function(WorkoutDay) _then;

/// Create a copy of WorkoutDay
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? order = null,Object? label = null,Object? exercises = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,order: null == order ? _self.order : order // ignore: cast_nullable_to_non_nullable
as int,label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,exercises: null == exercises ? _self.exercises : exercises // ignore: cast_nullable_to_non_nullable
as List<WorkoutExercise>,
  ));
}

}


/// Adds pattern-matching-related methods to [WorkoutDay].
extension WorkoutDayPatterns on WorkoutDay {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _WorkoutDay value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _WorkoutDay() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _WorkoutDay value)  $default,){
final _that = this;
switch (_that) {
case _WorkoutDay():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _WorkoutDay value)?  $default,){
final _that = this;
switch (_that) {
case _WorkoutDay() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  int order,  String label,  List<WorkoutExercise> exercises)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _WorkoutDay() when $default != null:
return $default(_that.id,_that.order,_that.label,_that.exercises);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  int order,  String label,  List<WorkoutExercise> exercises)  $default,) {final _that = this;
switch (_that) {
case _WorkoutDay():
return $default(_that.id,_that.order,_that.label,_that.exercises);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  int order,  String label,  List<WorkoutExercise> exercises)?  $default,) {final _that = this;
switch (_that) {
case _WorkoutDay() when $default != null:
return $default(_that.id,_that.order,_that.label,_that.exercises);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _WorkoutDay implements WorkoutDay {
  const _WorkoutDay({required this.id, required this.order, required this.label, final  List<WorkoutExercise> exercises = const []}): _exercises = exercises;
  factory _WorkoutDay.fromJson(Map<String, dynamic> json) => _$WorkoutDayFromJson(json);

@override final  String id;
@override final  int order;
@override final  String label;
 final  List<WorkoutExercise> _exercises;
@override@JsonKey() List<WorkoutExercise> get exercises {
  if (_exercises is EqualUnmodifiableListView) return _exercises;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_exercises);
}


/// Create a copy of WorkoutDay
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$WorkoutDayCopyWith<_WorkoutDay> get copyWith => __$WorkoutDayCopyWithImpl<_WorkoutDay>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$WorkoutDayToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _WorkoutDay&&(identical(other.id, id) || other.id == id)&&(identical(other.order, order) || other.order == order)&&(identical(other.label, label) || other.label == label)&&const DeepCollectionEquality().equals(other._exercises, _exercises));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,order,label,const DeepCollectionEquality().hash(_exercises));

@override
String toString() {
  return 'WorkoutDay(id: $id, order: $order, label: $label, exercises: $exercises)';
}


}

/// @nodoc
abstract mixin class _$WorkoutDayCopyWith<$Res> implements $WorkoutDayCopyWith<$Res> {
  factory _$WorkoutDayCopyWith(_WorkoutDay value, $Res Function(_WorkoutDay) _then) = __$WorkoutDayCopyWithImpl;
@override @useResult
$Res call({
 String id, int order, String label, List<WorkoutExercise> exercises
});




}
/// @nodoc
class __$WorkoutDayCopyWithImpl<$Res>
    implements _$WorkoutDayCopyWith<$Res> {
  __$WorkoutDayCopyWithImpl(this._self, this._then);

  final _WorkoutDay _self;
  final $Res Function(_WorkoutDay) _then;

/// Create a copy of WorkoutDay
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? order = null,Object? label = null,Object? exercises = null,}) {
  return _then(_WorkoutDay(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,order: null == order ? _self.order : order // ignore: cast_nullable_to_non_nullable
as int,label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,exercises: null == exercises ? _self._exercises : exercises // ignore: cast_nullable_to_non_nullable
as List<WorkoutExercise>,
  ));
}


}


/// @nodoc
mixin _$WorkoutExercise {

 String get id; int? get exerciseId; String get exerciseName; String get muscleGroup; String? get tutorialVideoUrl; int get sets; int get repsMin; int get repsMax; int get restSeconds; String? get notes;
/// Create a copy of WorkoutExercise
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$WorkoutExerciseCopyWith<WorkoutExercise> get copyWith => _$WorkoutExerciseCopyWithImpl<WorkoutExercise>(this as WorkoutExercise, _$identity);

  /// Serializes this WorkoutExercise to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WorkoutExercise&&(identical(other.id, id) || other.id == id)&&(identical(other.exerciseId, exerciseId) || other.exerciseId == exerciseId)&&(identical(other.exerciseName, exerciseName) || other.exerciseName == exerciseName)&&(identical(other.muscleGroup, muscleGroup) || other.muscleGroup == muscleGroup)&&(identical(other.tutorialVideoUrl, tutorialVideoUrl) || other.tutorialVideoUrl == tutorialVideoUrl)&&(identical(other.sets, sets) || other.sets == sets)&&(identical(other.repsMin, repsMin) || other.repsMin == repsMin)&&(identical(other.repsMax, repsMax) || other.repsMax == repsMax)&&(identical(other.restSeconds, restSeconds) || other.restSeconds == restSeconds)&&(identical(other.notes, notes) || other.notes == notes));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,exerciseId,exerciseName,muscleGroup,tutorialVideoUrl,sets,repsMin,repsMax,restSeconds,notes);

@override
String toString() {
  return 'WorkoutExercise(id: $id, exerciseId: $exerciseId, exerciseName: $exerciseName, muscleGroup: $muscleGroup, tutorialVideoUrl: $tutorialVideoUrl, sets: $sets, repsMin: $repsMin, repsMax: $repsMax, restSeconds: $restSeconds, notes: $notes)';
}


}

/// @nodoc
abstract mixin class $WorkoutExerciseCopyWith<$Res>  {
  factory $WorkoutExerciseCopyWith(WorkoutExercise value, $Res Function(WorkoutExercise) _then) = _$WorkoutExerciseCopyWithImpl;
@useResult
$Res call({
 String id, int? exerciseId, String exerciseName, String muscleGroup, String? tutorialVideoUrl, int sets, int repsMin, int repsMax, int restSeconds, String? notes
});




}
/// @nodoc
class _$WorkoutExerciseCopyWithImpl<$Res>
    implements $WorkoutExerciseCopyWith<$Res> {
  _$WorkoutExerciseCopyWithImpl(this._self, this._then);

  final WorkoutExercise _self;
  final $Res Function(WorkoutExercise) _then;

/// Create a copy of WorkoutExercise
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? exerciseId = freezed,Object? exerciseName = null,Object? muscleGroup = null,Object? tutorialVideoUrl = freezed,Object? sets = null,Object? repsMin = null,Object? repsMax = null,Object? restSeconds = null,Object? notes = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,exerciseId: freezed == exerciseId ? _self.exerciseId : exerciseId // ignore: cast_nullable_to_non_nullable
as int?,exerciseName: null == exerciseName ? _self.exerciseName : exerciseName // ignore: cast_nullable_to_non_nullable
as String,muscleGroup: null == muscleGroup ? _self.muscleGroup : muscleGroup // ignore: cast_nullable_to_non_nullable
as String,tutorialVideoUrl: freezed == tutorialVideoUrl ? _self.tutorialVideoUrl : tutorialVideoUrl // ignore: cast_nullable_to_non_nullable
as String?,sets: null == sets ? _self.sets : sets // ignore: cast_nullable_to_non_nullable
as int,repsMin: null == repsMin ? _self.repsMin : repsMin // ignore: cast_nullable_to_non_nullable
as int,repsMax: null == repsMax ? _self.repsMax : repsMax // ignore: cast_nullable_to_non_nullable
as int,restSeconds: null == restSeconds ? _self.restSeconds : restSeconds // ignore: cast_nullable_to_non_nullable
as int,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [WorkoutExercise].
extension WorkoutExercisePatterns on WorkoutExercise {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _WorkoutExercise value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _WorkoutExercise() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _WorkoutExercise value)  $default,){
final _that = this;
switch (_that) {
case _WorkoutExercise():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _WorkoutExercise value)?  $default,){
final _that = this;
switch (_that) {
case _WorkoutExercise() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  int? exerciseId,  String exerciseName,  String muscleGroup,  String? tutorialVideoUrl,  int sets,  int repsMin,  int repsMax,  int restSeconds,  String? notes)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _WorkoutExercise() when $default != null:
return $default(_that.id,_that.exerciseId,_that.exerciseName,_that.muscleGroup,_that.tutorialVideoUrl,_that.sets,_that.repsMin,_that.repsMax,_that.restSeconds,_that.notes);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  int? exerciseId,  String exerciseName,  String muscleGroup,  String? tutorialVideoUrl,  int sets,  int repsMin,  int repsMax,  int restSeconds,  String? notes)  $default,) {final _that = this;
switch (_that) {
case _WorkoutExercise():
return $default(_that.id,_that.exerciseId,_that.exerciseName,_that.muscleGroup,_that.tutorialVideoUrl,_that.sets,_that.repsMin,_that.repsMax,_that.restSeconds,_that.notes);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  int? exerciseId,  String exerciseName,  String muscleGroup,  String? tutorialVideoUrl,  int sets,  int repsMin,  int repsMax,  int restSeconds,  String? notes)?  $default,) {final _that = this;
switch (_that) {
case _WorkoutExercise() when $default != null:
return $default(_that.id,_that.exerciseId,_that.exerciseName,_that.muscleGroup,_that.tutorialVideoUrl,_that.sets,_that.repsMin,_that.repsMax,_that.restSeconds,_that.notes);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _WorkoutExercise implements WorkoutExercise {
  const _WorkoutExercise({required this.id, this.exerciseId, required this.exerciseName, this.muscleGroup = '', this.tutorialVideoUrl, this.sets = 3, this.repsMin = 8, this.repsMax = 12, this.restSeconds = 90, this.notes});
  factory _WorkoutExercise.fromJson(Map<String, dynamic> json) => _$WorkoutExerciseFromJson(json);

@override final  String id;
@override final  int? exerciseId;
@override final  String exerciseName;
@override@JsonKey() final  String muscleGroup;
@override final  String? tutorialVideoUrl;
@override@JsonKey() final  int sets;
@override@JsonKey() final  int repsMin;
@override@JsonKey() final  int repsMax;
@override@JsonKey() final  int restSeconds;
@override final  String? notes;

/// Create a copy of WorkoutExercise
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$WorkoutExerciseCopyWith<_WorkoutExercise> get copyWith => __$WorkoutExerciseCopyWithImpl<_WorkoutExercise>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$WorkoutExerciseToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _WorkoutExercise&&(identical(other.id, id) || other.id == id)&&(identical(other.exerciseId, exerciseId) || other.exerciseId == exerciseId)&&(identical(other.exerciseName, exerciseName) || other.exerciseName == exerciseName)&&(identical(other.muscleGroup, muscleGroup) || other.muscleGroup == muscleGroup)&&(identical(other.tutorialVideoUrl, tutorialVideoUrl) || other.tutorialVideoUrl == tutorialVideoUrl)&&(identical(other.sets, sets) || other.sets == sets)&&(identical(other.repsMin, repsMin) || other.repsMin == repsMin)&&(identical(other.repsMax, repsMax) || other.repsMax == repsMax)&&(identical(other.restSeconds, restSeconds) || other.restSeconds == restSeconds)&&(identical(other.notes, notes) || other.notes == notes));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,exerciseId,exerciseName,muscleGroup,tutorialVideoUrl,sets,repsMin,repsMax,restSeconds,notes);

@override
String toString() {
  return 'WorkoutExercise(id: $id, exerciseId: $exerciseId, exerciseName: $exerciseName, muscleGroup: $muscleGroup, tutorialVideoUrl: $tutorialVideoUrl, sets: $sets, repsMin: $repsMin, repsMax: $repsMax, restSeconds: $restSeconds, notes: $notes)';
}


}

/// @nodoc
abstract mixin class _$WorkoutExerciseCopyWith<$Res> implements $WorkoutExerciseCopyWith<$Res> {
  factory _$WorkoutExerciseCopyWith(_WorkoutExercise value, $Res Function(_WorkoutExercise) _then) = __$WorkoutExerciseCopyWithImpl;
@override @useResult
$Res call({
 String id, int? exerciseId, String exerciseName, String muscleGroup, String? tutorialVideoUrl, int sets, int repsMin, int repsMax, int restSeconds, String? notes
});




}
/// @nodoc
class __$WorkoutExerciseCopyWithImpl<$Res>
    implements _$WorkoutExerciseCopyWith<$Res> {
  __$WorkoutExerciseCopyWithImpl(this._self, this._then);

  final _WorkoutExercise _self;
  final $Res Function(_WorkoutExercise) _then;

/// Create a copy of WorkoutExercise
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? exerciseId = freezed,Object? exerciseName = null,Object? muscleGroup = null,Object? tutorialVideoUrl = freezed,Object? sets = null,Object? repsMin = null,Object? repsMax = null,Object? restSeconds = null,Object? notes = freezed,}) {
  return _then(_WorkoutExercise(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,exerciseId: freezed == exerciseId ? _self.exerciseId : exerciseId // ignore: cast_nullable_to_non_nullable
as int?,exerciseName: null == exerciseName ? _self.exerciseName : exerciseName // ignore: cast_nullable_to_non_nullable
as String,muscleGroup: null == muscleGroup ? _self.muscleGroup : muscleGroup // ignore: cast_nullable_to_non_nullable
as String,tutorialVideoUrl: freezed == tutorialVideoUrl ? _self.tutorialVideoUrl : tutorialVideoUrl // ignore: cast_nullable_to_non_nullable
as String?,sets: null == sets ? _self.sets : sets // ignore: cast_nullable_to_non_nullable
as int,repsMin: null == repsMin ? _self.repsMin : repsMin // ignore: cast_nullable_to_non_nullable
as int,repsMax: null == repsMax ? _self.repsMax : repsMax // ignore: cast_nullable_to_non_nullable
as int,restSeconds: null == restSeconds ? _self.restSeconds : restSeconds // ignore: cast_nullable_to_non_nullable
as int,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$WorkoutPlanSummary {

 String get id; String get name; String get split; String get status; int get version; String? get createdAt;
/// Create a copy of WorkoutPlanSummary
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$WorkoutPlanSummaryCopyWith<WorkoutPlanSummary> get copyWith => _$WorkoutPlanSummaryCopyWithImpl<WorkoutPlanSummary>(this as WorkoutPlanSummary, _$identity);

  /// Serializes this WorkoutPlanSummary to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WorkoutPlanSummary&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.split, split) || other.split == split)&&(identical(other.status, status) || other.status == status)&&(identical(other.version, version) || other.version == version)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,split,status,version,createdAt);

@override
String toString() {
  return 'WorkoutPlanSummary(id: $id, name: $name, split: $split, status: $status, version: $version, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class $WorkoutPlanSummaryCopyWith<$Res>  {
  factory $WorkoutPlanSummaryCopyWith(WorkoutPlanSummary value, $Res Function(WorkoutPlanSummary) _then) = _$WorkoutPlanSummaryCopyWithImpl;
@useResult
$Res call({
 String id, String name, String split, String status, int version, String? createdAt
});




}
/// @nodoc
class _$WorkoutPlanSummaryCopyWithImpl<$Res>
    implements $WorkoutPlanSummaryCopyWith<$Res> {
  _$WorkoutPlanSummaryCopyWithImpl(this._self, this._then);

  final WorkoutPlanSummary _self;
  final $Res Function(WorkoutPlanSummary) _then;

/// Create a copy of WorkoutPlanSummary
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? split = null,Object? status = null,Object? version = null,Object? createdAt = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,split: null == split ? _self.split : split // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,version: null == version ? _self.version : version // ignore: cast_nullable_to_non_nullable
as int,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [WorkoutPlanSummary].
extension WorkoutPlanSummaryPatterns on WorkoutPlanSummary {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _WorkoutPlanSummary value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _WorkoutPlanSummary() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _WorkoutPlanSummary value)  $default,){
final _that = this;
switch (_that) {
case _WorkoutPlanSummary():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _WorkoutPlanSummary value)?  $default,){
final _that = this;
switch (_that) {
case _WorkoutPlanSummary() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  String split,  String status,  int version,  String? createdAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _WorkoutPlanSummary() when $default != null:
return $default(_that.id,_that.name,_that.split,_that.status,_that.version,_that.createdAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  String split,  String status,  int version,  String? createdAt)  $default,) {final _that = this;
switch (_that) {
case _WorkoutPlanSummary():
return $default(_that.id,_that.name,_that.split,_that.status,_that.version,_that.createdAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  String split,  String status,  int version,  String? createdAt)?  $default,) {final _that = this;
switch (_that) {
case _WorkoutPlanSummary() when $default != null:
return $default(_that.id,_that.name,_that.split,_that.status,_that.version,_that.createdAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _WorkoutPlanSummary implements WorkoutPlanSummary {
  const _WorkoutPlanSummary({required this.id, required this.name, required this.split, this.status = 'Active', this.version = 1, this.createdAt});
  factory _WorkoutPlanSummary.fromJson(Map<String, dynamic> json) => _$WorkoutPlanSummaryFromJson(json);

@override final  String id;
@override final  String name;
@override final  String split;
@override@JsonKey() final  String status;
@override@JsonKey() final  int version;
@override final  String? createdAt;

/// Create a copy of WorkoutPlanSummary
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$WorkoutPlanSummaryCopyWith<_WorkoutPlanSummary> get copyWith => __$WorkoutPlanSummaryCopyWithImpl<_WorkoutPlanSummary>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$WorkoutPlanSummaryToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _WorkoutPlanSummary&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.split, split) || other.split == split)&&(identical(other.status, status) || other.status == status)&&(identical(other.version, version) || other.version == version)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,split,status,version,createdAt);

@override
String toString() {
  return 'WorkoutPlanSummary(id: $id, name: $name, split: $split, status: $status, version: $version, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class _$WorkoutPlanSummaryCopyWith<$Res> implements $WorkoutPlanSummaryCopyWith<$Res> {
  factory _$WorkoutPlanSummaryCopyWith(_WorkoutPlanSummary value, $Res Function(_WorkoutPlanSummary) _then) = __$WorkoutPlanSummaryCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, String split, String status, int version, String? createdAt
});




}
/// @nodoc
class __$WorkoutPlanSummaryCopyWithImpl<$Res>
    implements _$WorkoutPlanSummaryCopyWith<$Res> {
  __$WorkoutPlanSummaryCopyWithImpl(this._self, this._then);

  final _WorkoutPlanSummary _self;
  final $Res Function(_WorkoutPlanSummary) _then;

/// Create a copy of WorkoutPlanSummary
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? split = null,Object? status = null,Object? version = null,Object? createdAt = freezed,}) {
  return _then(_WorkoutPlanSummary(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,split: null == split ? _self.split : split // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,version: null == version ? _self.version : version // ignore: cast_nullable_to_non_nullable
as int,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
