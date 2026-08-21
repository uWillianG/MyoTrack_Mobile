// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'logging_models.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$SetLogRequest {

 int get exerciseId; int get setNumber; int get reps; double get loadKg; int? get rpe;
/// Create a copy of SetLogRequest
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SetLogRequestCopyWith<SetLogRequest> get copyWith => _$SetLogRequestCopyWithImpl<SetLogRequest>(this as SetLogRequest, _$identity);

  /// Serializes this SetLogRequest to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SetLogRequest&&(identical(other.exerciseId, exerciseId) || other.exerciseId == exerciseId)&&(identical(other.setNumber, setNumber) || other.setNumber == setNumber)&&(identical(other.reps, reps) || other.reps == reps)&&(identical(other.loadKg, loadKg) || other.loadKg == loadKg)&&(identical(other.rpe, rpe) || other.rpe == rpe));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,exerciseId,setNumber,reps,loadKg,rpe);

@override
String toString() {
  return 'SetLogRequest(exerciseId: $exerciseId, setNumber: $setNumber, reps: $reps, loadKg: $loadKg, rpe: $rpe)';
}


}

/// @nodoc
abstract mixin class $SetLogRequestCopyWith<$Res>  {
  factory $SetLogRequestCopyWith(SetLogRequest value, $Res Function(SetLogRequest) _then) = _$SetLogRequestCopyWithImpl;
@useResult
$Res call({
 int exerciseId, int setNumber, int reps, double loadKg, int? rpe
});




}
/// @nodoc
class _$SetLogRequestCopyWithImpl<$Res>
    implements $SetLogRequestCopyWith<$Res> {
  _$SetLogRequestCopyWithImpl(this._self, this._then);

  final SetLogRequest _self;
  final $Res Function(SetLogRequest) _then;

/// Create a copy of SetLogRequest
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? exerciseId = null,Object? setNumber = null,Object? reps = null,Object? loadKg = null,Object? rpe = freezed,}) {
  return _then(_self.copyWith(
exerciseId: null == exerciseId ? _self.exerciseId : exerciseId // ignore: cast_nullable_to_non_nullable
as int,setNumber: null == setNumber ? _self.setNumber : setNumber // ignore: cast_nullable_to_non_nullable
as int,reps: null == reps ? _self.reps : reps // ignore: cast_nullable_to_non_nullable
as int,loadKg: null == loadKg ? _self.loadKg : loadKg // ignore: cast_nullable_to_non_nullable
as double,rpe: freezed == rpe ? _self.rpe : rpe // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}

}


/// Adds pattern-matching-related methods to [SetLogRequest].
extension SetLogRequestPatterns on SetLogRequest {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SetLogRequest value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SetLogRequest() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SetLogRequest value)  $default,){
final _that = this;
switch (_that) {
case _SetLogRequest():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SetLogRequest value)?  $default,){
final _that = this;
switch (_that) {
case _SetLogRequest() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int exerciseId,  int setNumber,  int reps,  double loadKg,  int? rpe)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SetLogRequest() when $default != null:
return $default(_that.exerciseId,_that.setNumber,_that.reps,_that.loadKg,_that.rpe);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int exerciseId,  int setNumber,  int reps,  double loadKg,  int? rpe)  $default,) {final _that = this;
switch (_that) {
case _SetLogRequest():
return $default(_that.exerciseId,_that.setNumber,_that.reps,_that.loadKg,_that.rpe);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int exerciseId,  int setNumber,  int reps,  double loadKg,  int? rpe)?  $default,) {final _that = this;
switch (_that) {
case _SetLogRequest() when $default != null:
return $default(_that.exerciseId,_that.setNumber,_that.reps,_that.loadKg,_that.rpe);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SetLogRequest implements SetLogRequest {
  const _SetLogRequest({required this.exerciseId, required this.setNumber, required this.reps, required this.loadKg, this.rpe});
  factory _SetLogRequest.fromJson(Map<String, dynamic> json) => _$SetLogRequestFromJson(json);

@override final  int exerciseId;
@override final  int setNumber;
@override final  int reps;
@override final  double loadKg;
@override final  int? rpe;

/// Create a copy of SetLogRequest
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SetLogRequestCopyWith<_SetLogRequest> get copyWith => __$SetLogRequestCopyWithImpl<_SetLogRequest>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SetLogRequestToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SetLogRequest&&(identical(other.exerciseId, exerciseId) || other.exerciseId == exerciseId)&&(identical(other.setNumber, setNumber) || other.setNumber == setNumber)&&(identical(other.reps, reps) || other.reps == reps)&&(identical(other.loadKg, loadKg) || other.loadKg == loadKg)&&(identical(other.rpe, rpe) || other.rpe == rpe));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,exerciseId,setNumber,reps,loadKg,rpe);

@override
String toString() {
  return 'SetLogRequest(exerciseId: $exerciseId, setNumber: $setNumber, reps: $reps, loadKg: $loadKg, rpe: $rpe)';
}


}

/// @nodoc
abstract mixin class _$SetLogRequestCopyWith<$Res> implements $SetLogRequestCopyWith<$Res> {
  factory _$SetLogRequestCopyWith(_SetLogRequest value, $Res Function(_SetLogRequest) _then) = __$SetLogRequestCopyWithImpl;
@override @useResult
$Res call({
 int exerciseId, int setNumber, int reps, double loadKg, int? rpe
});




}
/// @nodoc
class __$SetLogRequestCopyWithImpl<$Res>
    implements _$SetLogRequestCopyWith<$Res> {
  __$SetLogRequestCopyWithImpl(this._self, this._then);

  final _SetLogRequest _self;
  final $Res Function(_SetLogRequest) _then;

/// Create a copy of SetLogRequest
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? exerciseId = null,Object? setNumber = null,Object? reps = null,Object? loadKg = null,Object? rpe = freezed,}) {
  return _then(_SetLogRequest(
exerciseId: null == exerciseId ? _self.exerciseId : exerciseId // ignore: cast_nullable_to_non_nullable
as int,setNumber: null == setNumber ? _self.setNumber : setNumber // ignore: cast_nullable_to_non_nullable
as int,reps: null == reps ? _self.reps : reps // ignore: cast_nullable_to_non_nullable
as int,loadKg: null == loadKg ? _self.loadKg : loadKg // ignore: cast_nullable_to_non_nullable
as double,rpe: freezed == rpe ? _self.rpe : rpe // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}


}


/// @nodoc
mixin _$SessionRequest {

 String get date; String? get workoutDayId; String? get notes; List<SetLogRequest> get sets;
/// Create a copy of SessionRequest
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SessionRequestCopyWith<SessionRequest> get copyWith => _$SessionRequestCopyWithImpl<SessionRequest>(this as SessionRequest, _$identity);

  /// Serializes this SessionRequest to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SessionRequest&&(identical(other.date, date) || other.date == date)&&(identical(other.workoutDayId, workoutDayId) || other.workoutDayId == workoutDayId)&&(identical(other.notes, notes) || other.notes == notes)&&const DeepCollectionEquality().equals(other.sets, sets));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,date,workoutDayId,notes,const DeepCollectionEquality().hash(sets));

@override
String toString() {
  return 'SessionRequest(date: $date, workoutDayId: $workoutDayId, notes: $notes, sets: $sets)';
}


}

/// @nodoc
abstract mixin class $SessionRequestCopyWith<$Res>  {
  factory $SessionRequestCopyWith(SessionRequest value, $Res Function(SessionRequest) _then) = _$SessionRequestCopyWithImpl;
@useResult
$Res call({
 String date, String? workoutDayId, String? notes, List<SetLogRequest> sets
});




}
/// @nodoc
class _$SessionRequestCopyWithImpl<$Res>
    implements $SessionRequestCopyWith<$Res> {
  _$SessionRequestCopyWithImpl(this._self, this._then);

  final SessionRequest _self;
  final $Res Function(SessionRequest) _then;

/// Create a copy of SessionRequest
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? date = null,Object? workoutDayId = freezed,Object? notes = freezed,Object? sets = null,}) {
  return _then(_self.copyWith(
date: null == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as String,workoutDayId: freezed == workoutDayId ? _self.workoutDayId : workoutDayId // ignore: cast_nullable_to_non_nullable
as String?,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,sets: null == sets ? _self.sets : sets // ignore: cast_nullable_to_non_nullable
as List<SetLogRequest>,
  ));
}

}


/// Adds pattern-matching-related methods to [SessionRequest].
extension SessionRequestPatterns on SessionRequest {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SessionRequest value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SessionRequest() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SessionRequest value)  $default,){
final _that = this;
switch (_that) {
case _SessionRequest():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SessionRequest value)?  $default,){
final _that = this;
switch (_that) {
case _SessionRequest() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String date,  String? workoutDayId,  String? notes,  List<SetLogRequest> sets)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SessionRequest() when $default != null:
return $default(_that.date,_that.workoutDayId,_that.notes,_that.sets);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String date,  String? workoutDayId,  String? notes,  List<SetLogRequest> sets)  $default,) {final _that = this;
switch (_that) {
case _SessionRequest():
return $default(_that.date,_that.workoutDayId,_that.notes,_that.sets);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String date,  String? workoutDayId,  String? notes,  List<SetLogRequest> sets)?  $default,) {final _that = this;
switch (_that) {
case _SessionRequest() when $default != null:
return $default(_that.date,_that.workoutDayId,_that.notes,_that.sets);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SessionRequest implements SessionRequest {
  const _SessionRequest({required this.date, this.workoutDayId, this.notes, required final  List<SetLogRequest> sets}): _sets = sets;
  factory _SessionRequest.fromJson(Map<String, dynamic> json) => _$SessionRequestFromJson(json);

@override final  String date;
@override final  String? workoutDayId;
@override final  String? notes;
 final  List<SetLogRequest> _sets;
@override List<SetLogRequest> get sets {
  if (_sets is EqualUnmodifiableListView) return _sets;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_sets);
}


/// Create a copy of SessionRequest
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SessionRequestCopyWith<_SessionRequest> get copyWith => __$SessionRequestCopyWithImpl<_SessionRequest>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SessionRequestToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SessionRequest&&(identical(other.date, date) || other.date == date)&&(identical(other.workoutDayId, workoutDayId) || other.workoutDayId == workoutDayId)&&(identical(other.notes, notes) || other.notes == notes)&&const DeepCollectionEquality().equals(other._sets, _sets));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,date,workoutDayId,notes,const DeepCollectionEquality().hash(_sets));

@override
String toString() {
  return 'SessionRequest(date: $date, workoutDayId: $workoutDayId, notes: $notes, sets: $sets)';
}


}

/// @nodoc
abstract mixin class _$SessionRequestCopyWith<$Res> implements $SessionRequestCopyWith<$Res> {
  factory _$SessionRequestCopyWith(_SessionRequest value, $Res Function(_SessionRequest) _then) = __$SessionRequestCopyWithImpl;
@override @useResult
$Res call({
 String date, String? workoutDayId, String? notes, List<SetLogRequest> sets
});




}
/// @nodoc
class __$SessionRequestCopyWithImpl<$Res>
    implements _$SessionRequestCopyWith<$Res> {
  __$SessionRequestCopyWithImpl(this._self, this._then);

  final _SessionRequest _self;
  final $Res Function(_SessionRequest) _then;

/// Create a copy of SessionRequest
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? date = null,Object? workoutDayId = freezed,Object? notes = freezed,Object? sets = null,}) {
  return _then(_SessionRequest(
date: null == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as String,workoutDayId: freezed == workoutDayId ? _self.workoutDayId : workoutDayId // ignore: cast_nullable_to_non_nullable
as String?,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,sets: null == sets ? _self._sets : sets // ignore: cast_nullable_to_non_nullable
as List<SetLogRequest>,
  ));
}


}


/// @nodoc
mixin _$WorkoutSessionView {

 String get id; String get date; String? get workoutDayId; String? get notes; num get totalVolumeKg; List<SetView> get sets;
/// Create a copy of WorkoutSessionView
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$WorkoutSessionViewCopyWith<WorkoutSessionView> get copyWith => _$WorkoutSessionViewCopyWithImpl<WorkoutSessionView>(this as WorkoutSessionView, _$identity);

  /// Serializes this WorkoutSessionView to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WorkoutSessionView&&(identical(other.id, id) || other.id == id)&&(identical(other.date, date) || other.date == date)&&(identical(other.workoutDayId, workoutDayId) || other.workoutDayId == workoutDayId)&&(identical(other.notes, notes) || other.notes == notes)&&(identical(other.totalVolumeKg, totalVolumeKg) || other.totalVolumeKg == totalVolumeKg)&&const DeepCollectionEquality().equals(other.sets, sets));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,date,workoutDayId,notes,totalVolumeKg,const DeepCollectionEquality().hash(sets));

@override
String toString() {
  return 'WorkoutSessionView(id: $id, date: $date, workoutDayId: $workoutDayId, notes: $notes, totalVolumeKg: $totalVolumeKg, sets: $sets)';
}


}

/// @nodoc
abstract mixin class $WorkoutSessionViewCopyWith<$Res>  {
  factory $WorkoutSessionViewCopyWith(WorkoutSessionView value, $Res Function(WorkoutSessionView) _then) = _$WorkoutSessionViewCopyWithImpl;
@useResult
$Res call({
 String id, String date, String? workoutDayId, String? notes, num totalVolumeKg, List<SetView> sets
});




}
/// @nodoc
class _$WorkoutSessionViewCopyWithImpl<$Res>
    implements $WorkoutSessionViewCopyWith<$Res> {
  _$WorkoutSessionViewCopyWithImpl(this._self, this._then);

  final WorkoutSessionView _self;
  final $Res Function(WorkoutSessionView) _then;

/// Create a copy of WorkoutSessionView
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? date = null,Object? workoutDayId = freezed,Object? notes = freezed,Object? totalVolumeKg = null,Object? sets = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,date: null == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as String,workoutDayId: freezed == workoutDayId ? _self.workoutDayId : workoutDayId // ignore: cast_nullable_to_non_nullable
as String?,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,totalVolumeKg: null == totalVolumeKg ? _self.totalVolumeKg : totalVolumeKg // ignore: cast_nullable_to_non_nullable
as num,sets: null == sets ? _self.sets : sets // ignore: cast_nullable_to_non_nullable
as List<SetView>,
  ));
}

}


/// Adds pattern-matching-related methods to [WorkoutSessionView].
extension WorkoutSessionViewPatterns on WorkoutSessionView {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _WorkoutSessionView value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _WorkoutSessionView() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _WorkoutSessionView value)  $default,){
final _that = this;
switch (_that) {
case _WorkoutSessionView():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _WorkoutSessionView value)?  $default,){
final _that = this;
switch (_that) {
case _WorkoutSessionView() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String date,  String? workoutDayId,  String? notes,  num totalVolumeKg,  List<SetView> sets)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _WorkoutSessionView() when $default != null:
return $default(_that.id,_that.date,_that.workoutDayId,_that.notes,_that.totalVolumeKg,_that.sets);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String date,  String? workoutDayId,  String? notes,  num totalVolumeKg,  List<SetView> sets)  $default,) {final _that = this;
switch (_that) {
case _WorkoutSessionView():
return $default(_that.id,_that.date,_that.workoutDayId,_that.notes,_that.totalVolumeKg,_that.sets);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String date,  String? workoutDayId,  String? notes,  num totalVolumeKg,  List<SetView> sets)?  $default,) {final _that = this;
switch (_that) {
case _WorkoutSessionView() when $default != null:
return $default(_that.id,_that.date,_that.workoutDayId,_that.notes,_that.totalVolumeKg,_that.sets);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _WorkoutSessionView implements WorkoutSessionView {
  const _WorkoutSessionView({required this.id, required this.date, this.workoutDayId, this.notes, this.totalVolumeKg = 0, final  List<SetView> sets = const []}): _sets = sets;
  factory _WorkoutSessionView.fromJson(Map<String, dynamic> json) => _$WorkoutSessionViewFromJson(json);

@override final  String id;
@override final  String date;
@override final  String? workoutDayId;
@override final  String? notes;
@override@JsonKey() final  num totalVolumeKg;
 final  List<SetView> _sets;
@override@JsonKey() List<SetView> get sets {
  if (_sets is EqualUnmodifiableListView) return _sets;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_sets);
}


/// Create a copy of WorkoutSessionView
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$WorkoutSessionViewCopyWith<_WorkoutSessionView> get copyWith => __$WorkoutSessionViewCopyWithImpl<_WorkoutSessionView>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$WorkoutSessionViewToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _WorkoutSessionView&&(identical(other.id, id) || other.id == id)&&(identical(other.date, date) || other.date == date)&&(identical(other.workoutDayId, workoutDayId) || other.workoutDayId == workoutDayId)&&(identical(other.notes, notes) || other.notes == notes)&&(identical(other.totalVolumeKg, totalVolumeKg) || other.totalVolumeKg == totalVolumeKg)&&const DeepCollectionEquality().equals(other._sets, _sets));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,date,workoutDayId,notes,totalVolumeKg,const DeepCollectionEquality().hash(_sets));

@override
String toString() {
  return 'WorkoutSessionView(id: $id, date: $date, workoutDayId: $workoutDayId, notes: $notes, totalVolumeKg: $totalVolumeKg, sets: $sets)';
}


}

/// @nodoc
abstract mixin class _$WorkoutSessionViewCopyWith<$Res> implements $WorkoutSessionViewCopyWith<$Res> {
  factory _$WorkoutSessionViewCopyWith(_WorkoutSessionView value, $Res Function(_WorkoutSessionView) _then) = __$WorkoutSessionViewCopyWithImpl;
@override @useResult
$Res call({
 String id, String date, String? workoutDayId, String? notes, num totalVolumeKg, List<SetView> sets
});




}
/// @nodoc
class __$WorkoutSessionViewCopyWithImpl<$Res>
    implements _$WorkoutSessionViewCopyWith<$Res> {
  __$WorkoutSessionViewCopyWithImpl(this._self, this._then);

  final _WorkoutSessionView _self;
  final $Res Function(_WorkoutSessionView) _then;

/// Create a copy of WorkoutSessionView
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? date = null,Object? workoutDayId = freezed,Object? notes = freezed,Object? totalVolumeKg = null,Object? sets = null,}) {
  return _then(_WorkoutSessionView(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,date: null == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as String,workoutDayId: freezed == workoutDayId ? _self.workoutDayId : workoutDayId // ignore: cast_nullable_to_non_nullable
as String?,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,totalVolumeKg: null == totalVolumeKg ? _self.totalVolumeKg : totalVolumeKg // ignore: cast_nullable_to_non_nullable
as num,sets: null == sets ? _self._sets : sets // ignore: cast_nullable_to_non_nullable
as List<SetView>,
  ));
}


}


/// @nodoc
mixin _$SetView {

 String get id; int? get exerciseId; String get exerciseName; int get setNumber; int get reps; num get loadKg; int? get rpe;
/// Create a copy of SetView
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SetViewCopyWith<SetView> get copyWith => _$SetViewCopyWithImpl<SetView>(this as SetView, _$identity);

  /// Serializes this SetView to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SetView&&(identical(other.id, id) || other.id == id)&&(identical(other.exerciseId, exerciseId) || other.exerciseId == exerciseId)&&(identical(other.exerciseName, exerciseName) || other.exerciseName == exerciseName)&&(identical(other.setNumber, setNumber) || other.setNumber == setNumber)&&(identical(other.reps, reps) || other.reps == reps)&&(identical(other.loadKg, loadKg) || other.loadKg == loadKg)&&(identical(other.rpe, rpe) || other.rpe == rpe));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,exerciseId,exerciseName,setNumber,reps,loadKg,rpe);

@override
String toString() {
  return 'SetView(id: $id, exerciseId: $exerciseId, exerciseName: $exerciseName, setNumber: $setNumber, reps: $reps, loadKg: $loadKg, rpe: $rpe)';
}


}

/// @nodoc
abstract mixin class $SetViewCopyWith<$Res>  {
  factory $SetViewCopyWith(SetView value, $Res Function(SetView) _then) = _$SetViewCopyWithImpl;
@useResult
$Res call({
 String id, int? exerciseId, String exerciseName, int setNumber, int reps, num loadKg, int? rpe
});




}
/// @nodoc
class _$SetViewCopyWithImpl<$Res>
    implements $SetViewCopyWith<$Res> {
  _$SetViewCopyWithImpl(this._self, this._then);

  final SetView _self;
  final $Res Function(SetView) _then;

/// Create a copy of SetView
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? exerciseId = freezed,Object? exerciseName = null,Object? setNumber = null,Object? reps = null,Object? loadKg = null,Object? rpe = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,exerciseId: freezed == exerciseId ? _self.exerciseId : exerciseId // ignore: cast_nullable_to_non_nullable
as int?,exerciseName: null == exerciseName ? _self.exerciseName : exerciseName // ignore: cast_nullable_to_non_nullable
as String,setNumber: null == setNumber ? _self.setNumber : setNumber // ignore: cast_nullable_to_non_nullable
as int,reps: null == reps ? _self.reps : reps // ignore: cast_nullable_to_non_nullable
as int,loadKg: null == loadKg ? _self.loadKg : loadKg // ignore: cast_nullable_to_non_nullable
as num,rpe: freezed == rpe ? _self.rpe : rpe // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}

}


/// Adds pattern-matching-related methods to [SetView].
extension SetViewPatterns on SetView {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SetView value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SetView() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SetView value)  $default,){
final _that = this;
switch (_that) {
case _SetView():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SetView value)?  $default,){
final _that = this;
switch (_that) {
case _SetView() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  int? exerciseId,  String exerciseName,  int setNumber,  int reps,  num loadKg,  int? rpe)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SetView() when $default != null:
return $default(_that.id,_that.exerciseId,_that.exerciseName,_that.setNumber,_that.reps,_that.loadKg,_that.rpe);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  int? exerciseId,  String exerciseName,  int setNumber,  int reps,  num loadKg,  int? rpe)  $default,) {final _that = this;
switch (_that) {
case _SetView():
return $default(_that.id,_that.exerciseId,_that.exerciseName,_that.setNumber,_that.reps,_that.loadKg,_that.rpe);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  int? exerciseId,  String exerciseName,  int setNumber,  int reps,  num loadKg,  int? rpe)?  $default,) {final _that = this;
switch (_that) {
case _SetView() when $default != null:
return $default(_that.id,_that.exerciseId,_that.exerciseName,_that.setNumber,_that.reps,_that.loadKg,_that.rpe);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SetView implements SetView {
  const _SetView({required this.id, this.exerciseId, this.exerciseName = '', this.setNumber = 1, this.reps = 0, this.loadKg = 0, this.rpe});
  factory _SetView.fromJson(Map<String, dynamic> json) => _$SetViewFromJson(json);

@override final  String id;
@override final  int? exerciseId;
@override@JsonKey() final  String exerciseName;
@override@JsonKey() final  int setNumber;
@override@JsonKey() final  int reps;
@override@JsonKey() final  num loadKg;
@override final  int? rpe;

/// Create a copy of SetView
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SetViewCopyWith<_SetView> get copyWith => __$SetViewCopyWithImpl<_SetView>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SetViewToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SetView&&(identical(other.id, id) || other.id == id)&&(identical(other.exerciseId, exerciseId) || other.exerciseId == exerciseId)&&(identical(other.exerciseName, exerciseName) || other.exerciseName == exerciseName)&&(identical(other.setNumber, setNumber) || other.setNumber == setNumber)&&(identical(other.reps, reps) || other.reps == reps)&&(identical(other.loadKg, loadKg) || other.loadKg == loadKg)&&(identical(other.rpe, rpe) || other.rpe == rpe));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,exerciseId,exerciseName,setNumber,reps,loadKg,rpe);

@override
String toString() {
  return 'SetView(id: $id, exerciseId: $exerciseId, exerciseName: $exerciseName, setNumber: $setNumber, reps: $reps, loadKg: $loadKg, rpe: $rpe)';
}


}

/// @nodoc
abstract mixin class _$SetViewCopyWith<$Res> implements $SetViewCopyWith<$Res> {
  factory _$SetViewCopyWith(_SetView value, $Res Function(_SetView) _then) = __$SetViewCopyWithImpl;
@override @useResult
$Res call({
 String id, int? exerciseId, String exerciseName, int setNumber, int reps, num loadKg, int? rpe
});




}
/// @nodoc
class __$SetViewCopyWithImpl<$Res>
    implements _$SetViewCopyWith<$Res> {
  __$SetViewCopyWithImpl(this._self, this._then);

  final _SetView _self;
  final $Res Function(_SetView) _then;

/// Create a copy of SetView
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? exerciseId = freezed,Object? exerciseName = null,Object? setNumber = null,Object? reps = null,Object? loadKg = null,Object? rpe = freezed,}) {
  return _then(_SetView(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,exerciseId: freezed == exerciseId ? _self.exerciseId : exerciseId // ignore: cast_nullable_to_non_nullable
as int?,exerciseName: null == exerciseName ? _self.exerciseName : exerciseName // ignore: cast_nullable_to_non_nullable
as String,setNumber: null == setNumber ? _self.setNumber : setNumber // ignore: cast_nullable_to_non_nullable
as int,reps: null == reps ? _self.reps : reps // ignore: cast_nullable_to_non_nullable
as int,loadKg: null == loadKg ? _self.loadKg : loadKg // ignore: cast_nullable_to_non_nullable
as num,rpe: freezed == rpe ? _self.rpe : rpe // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}


}


/// @nodoc
mixin _$MeasurementView {

 String get id; String get date; num? get weightKg; num? get bodyFatPercent; num? get waistCm; num? get chestCm; num? get hipCm; num? get armCm; num? get thighCm; num? get calfCm;
/// Create a copy of MeasurementView
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MeasurementViewCopyWith<MeasurementView> get copyWith => _$MeasurementViewCopyWithImpl<MeasurementView>(this as MeasurementView, _$identity);

  /// Serializes this MeasurementView to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MeasurementView&&(identical(other.id, id) || other.id == id)&&(identical(other.date, date) || other.date == date)&&(identical(other.weightKg, weightKg) || other.weightKg == weightKg)&&(identical(other.bodyFatPercent, bodyFatPercent) || other.bodyFatPercent == bodyFatPercent)&&(identical(other.waistCm, waistCm) || other.waistCm == waistCm)&&(identical(other.chestCm, chestCm) || other.chestCm == chestCm)&&(identical(other.hipCm, hipCm) || other.hipCm == hipCm)&&(identical(other.armCm, armCm) || other.armCm == armCm)&&(identical(other.thighCm, thighCm) || other.thighCm == thighCm)&&(identical(other.calfCm, calfCm) || other.calfCm == calfCm));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,date,weightKg,bodyFatPercent,waistCm,chestCm,hipCm,armCm,thighCm,calfCm);

@override
String toString() {
  return 'MeasurementView(id: $id, date: $date, weightKg: $weightKg, bodyFatPercent: $bodyFatPercent, waistCm: $waistCm, chestCm: $chestCm, hipCm: $hipCm, armCm: $armCm, thighCm: $thighCm, calfCm: $calfCm)';
}


}

/// @nodoc
abstract mixin class $MeasurementViewCopyWith<$Res>  {
  factory $MeasurementViewCopyWith(MeasurementView value, $Res Function(MeasurementView) _then) = _$MeasurementViewCopyWithImpl;
@useResult
$Res call({
 String id, String date, num? weightKg, num? bodyFatPercent, num? waistCm, num? chestCm, num? hipCm, num? armCm, num? thighCm, num? calfCm
});




}
/// @nodoc
class _$MeasurementViewCopyWithImpl<$Res>
    implements $MeasurementViewCopyWith<$Res> {
  _$MeasurementViewCopyWithImpl(this._self, this._then);

  final MeasurementView _self;
  final $Res Function(MeasurementView) _then;

/// Create a copy of MeasurementView
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? date = null,Object? weightKg = freezed,Object? bodyFatPercent = freezed,Object? waistCm = freezed,Object? chestCm = freezed,Object? hipCm = freezed,Object? armCm = freezed,Object? thighCm = freezed,Object? calfCm = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,date: null == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as String,weightKg: freezed == weightKg ? _self.weightKg : weightKg // ignore: cast_nullable_to_non_nullable
as num?,bodyFatPercent: freezed == bodyFatPercent ? _self.bodyFatPercent : bodyFatPercent // ignore: cast_nullable_to_non_nullable
as num?,waistCm: freezed == waistCm ? _self.waistCm : waistCm // ignore: cast_nullable_to_non_nullable
as num?,chestCm: freezed == chestCm ? _self.chestCm : chestCm // ignore: cast_nullable_to_non_nullable
as num?,hipCm: freezed == hipCm ? _self.hipCm : hipCm // ignore: cast_nullable_to_non_nullable
as num?,armCm: freezed == armCm ? _self.armCm : armCm // ignore: cast_nullable_to_non_nullable
as num?,thighCm: freezed == thighCm ? _self.thighCm : thighCm // ignore: cast_nullable_to_non_nullable
as num?,calfCm: freezed == calfCm ? _self.calfCm : calfCm // ignore: cast_nullable_to_non_nullable
as num?,
  ));
}

}


/// Adds pattern-matching-related methods to [MeasurementView].
extension MeasurementViewPatterns on MeasurementView {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MeasurementView value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MeasurementView() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MeasurementView value)  $default,){
final _that = this;
switch (_that) {
case _MeasurementView():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MeasurementView value)?  $default,){
final _that = this;
switch (_that) {
case _MeasurementView() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String date,  num? weightKg,  num? bodyFatPercent,  num? waistCm,  num? chestCm,  num? hipCm,  num? armCm,  num? thighCm,  num? calfCm)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MeasurementView() when $default != null:
return $default(_that.id,_that.date,_that.weightKg,_that.bodyFatPercent,_that.waistCm,_that.chestCm,_that.hipCm,_that.armCm,_that.thighCm,_that.calfCm);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String date,  num? weightKg,  num? bodyFatPercent,  num? waistCm,  num? chestCm,  num? hipCm,  num? armCm,  num? thighCm,  num? calfCm)  $default,) {final _that = this;
switch (_that) {
case _MeasurementView():
return $default(_that.id,_that.date,_that.weightKg,_that.bodyFatPercent,_that.waistCm,_that.chestCm,_that.hipCm,_that.armCm,_that.thighCm,_that.calfCm);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String date,  num? weightKg,  num? bodyFatPercent,  num? waistCm,  num? chestCm,  num? hipCm,  num? armCm,  num? thighCm,  num? calfCm)?  $default,) {final _that = this;
switch (_that) {
case _MeasurementView() when $default != null:
return $default(_that.id,_that.date,_that.weightKg,_that.bodyFatPercent,_that.waistCm,_that.chestCm,_that.hipCm,_that.armCm,_that.thighCm,_that.calfCm);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _MeasurementView implements MeasurementView {
  const _MeasurementView({required this.id, required this.date, this.weightKg, this.bodyFatPercent, this.waistCm, this.chestCm, this.hipCm, this.armCm, this.thighCm, this.calfCm});
  factory _MeasurementView.fromJson(Map<String, dynamic> json) => _$MeasurementViewFromJson(json);

@override final  String id;
@override final  String date;
@override final  num? weightKg;
@override final  num? bodyFatPercent;
@override final  num? waistCm;
@override final  num? chestCm;
@override final  num? hipCm;
@override final  num? armCm;
@override final  num? thighCm;
@override final  num? calfCm;

/// Create a copy of MeasurementView
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MeasurementViewCopyWith<_MeasurementView> get copyWith => __$MeasurementViewCopyWithImpl<_MeasurementView>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$MeasurementViewToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _MeasurementView&&(identical(other.id, id) || other.id == id)&&(identical(other.date, date) || other.date == date)&&(identical(other.weightKg, weightKg) || other.weightKg == weightKg)&&(identical(other.bodyFatPercent, bodyFatPercent) || other.bodyFatPercent == bodyFatPercent)&&(identical(other.waistCm, waistCm) || other.waistCm == waistCm)&&(identical(other.chestCm, chestCm) || other.chestCm == chestCm)&&(identical(other.hipCm, hipCm) || other.hipCm == hipCm)&&(identical(other.armCm, armCm) || other.armCm == armCm)&&(identical(other.thighCm, thighCm) || other.thighCm == thighCm)&&(identical(other.calfCm, calfCm) || other.calfCm == calfCm));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,date,weightKg,bodyFatPercent,waistCm,chestCm,hipCm,armCm,thighCm,calfCm);

@override
String toString() {
  return 'MeasurementView(id: $id, date: $date, weightKg: $weightKg, bodyFatPercent: $bodyFatPercent, waistCm: $waistCm, chestCm: $chestCm, hipCm: $hipCm, armCm: $armCm, thighCm: $thighCm, calfCm: $calfCm)';
}


}

/// @nodoc
abstract mixin class _$MeasurementViewCopyWith<$Res> implements $MeasurementViewCopyWith<$Res> {
  factory _$MeasurementViewCopyWith(_MeasurementView value, $Res Function(_MeasurementView) _then) = __$MeasurementViewCopyWithImpl;
@override @useResult
$Res call({
 String id, String date, num? weightKg, num? bodyFatPercent, num? waistCm, num? chestCm, num? hipCm, num? armCm, num? thighCm, num? calfCm
});




}
/// @nodoc
class __$MeasurementViewCopyWithImpl<$Res>
    implements _$MeasurementViewCopyWith<$Res> {
  __$MeasurementViewCopyWithImpl(this._self, this._then);

  final _MeasurementView _self;
  final $Res Function(_MeasurementView) _then;

/// Create a copy of MeasurementView
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? date = null,Object? weightKg = freezed,Object? bodyFatPercent = freezed,Object? waistCm = freezed,Object? chestCm = freezed,Object? hipCm = freezed,Object? armCm = freezed,Object? thighCm = freezed,Object? calfCm = freezed,}) {
  return _then(_MeasurementView(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,date: null == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as String,weightKg: freezed == weightKg ? _self.weightKg : weightKg // ignore: cast_nullable_to_non_nullable
as num?,bodyFatPercent: freezed == bodyFatPercent ? _self.bodyFatPercent : bodyFatPercent // ignore: cast_nullable_to_non_nullable
as num?,waistCm: freezed == waistCm ? _self.waistCm : waistCm // ignore: cast_nullable_to_non_nullable
as num?,chestCm: freezed == chestCm ? _self.chestCm : chestCm // ignore: cast_nullable_to_non_nullable
as num?,hipCm: freezed == hipCm ? _self.hipCm : hipCm // ignore: cast_nullable_to_non_nullable
as num?,armCm: freezed == armCm ? _self.armCm : armCm // ignore: cast_nullable_to_non_nullable
as num?,thighCm: freezed == thighCm ? _self.thighCm : thighCm // ignore: cast_nullable_to_non_nullable
as num?,calfCm: freezed == calfCm ? _self.calfCm : calfCm // ignore: cast_nullable_to_non_nullable
as num?,
  ));
}


}


/// @nodoc
mixin _$MeasurementRequest {

 String get date; double? get weightKg; double? get bodyFatPercent; double? get waistCm; double? get chestCm; double? get hipCm; double? get armCm; double? get thighCm; double? get calfCm;
/// Create a copy of MeasurementRequest
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MeasurementRequestCopyWith<MeasurementRequest> get copyWith => _$MeasurementRequestCopyWithImpl<MeasurementRequest>(this as MeasurementRequest, _$identity);

  /// Serializes this MeasurementRequest to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MeasurementRequest&&(identical(other.date, date) || other.date == date)&&(identical(other.weightKg, weightKg) || other.weightKg == weightKg)&&(identical(other.bodyFatPercent, bodyFatPercent) || other.bodyFatPercent == bodyFatPercent)&&(identical(other.waistCm, waistCm) || other.waistCm == waistCm)&&(identical(other.chestCm, chestCm) || other.chestCm == chestCm)&&(identical(other.hipCm, hipCm) || other.hipCm == hipCm)&&(identical(other.armCm, armCm) || other.armCm == armCm)&&(identical(other.thighCm, thighCm) || other.thighCm == thighCm)&&(identical(other.calfCm, calfCm) || other.calfCm == calfCm));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,date,weightKg,bodyFatPercent,waistCm,chestCm,hipCm,armCm,thighCm,calfCm);

@override
String toString() {
  return 'MeasurementRequest(date: $date, weightKg: $weightKg, bodyFatPercent: $bodyFatPercent, waistCm: $waistCm, chestCm: $chestCm, hipCm: $hipCm, armCm: $armCm, thighCm: $thighCm, calfCm: $calfCm)';
}


}

/// @nodoc
abstract mixin class $MeasurementRequestCopyWith<$Res>  {
  factory $MeasurementRequestCopyWith(MeasurementRequest value, $Res Function(MeasurementRequest) _then) = _$MeasurementRequestCopyWithImpl;
@useResult
$Res call({
 String date, double? weightKg, double? bodyFatPercent, double? waistCm, double? chestCm, double? hipCm, double? armCm, double? thighCm, double? calfCm
});




}
/// @nodoc
class _$MeasurementRequestCopyWithImpl<$Res>
    implements $MeasurementRequestCopyWith<$Res> {
  _$MeasurementRequestCopyWithImpl(this._self, this._then);

  final MeasurementRequest _self;
  final $Res Function(MeasurementRequest) _then;

/// Create a copy of MeasurementRequest
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? date = null,Object? weightKg = freezed,Object? bodyFatPercent = freezed,Object? waistCm = freezed,Object? chestCm = freezed,Object? hipCm = freezed,Object? armCm = freezed,Object? thighCm = freezed,Object? calfCm = freezed,}) {
  return _then(_self.copyWith(
date: null == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as String,weightKg: freezed == weightKg ? _self.weightKg : weightKg // ignore: cast_nullable_to_non_nullable
as double?,bodyFatPercent: freezed == bodyFatPercent ? _self.bodyFatPercent : bodyFatPercent // ignore: cast_nullable_to_non_nullable
as double?,waistCm: freezed == waistCm ? _self.waistCm : waistCm // ignore: cast_nullable_to_non_nullable
as double?,chestCm: freezed == chestCm ? _self.chestCm : chestCm // ignore: cast_nullable_to_non_nullable
as double?,hipCm: freezed == hipCm ? _self.hipCm : hipCm // ignore: cast_nullable_to_non_nullable
as double?,armCm: freezed == armCm ? _self.armCm : armCm // ignore: cast_nullable_to_non_nullable
as double?,thighCm: freezed == thighCm ? _self.thighCm : thighCm // ignore: cast_nullable_to_non_nullable
as double?,calfCm: freezed == calfCm ? _self.calfCm : calfCm // ignore: cast_nullable_to_non_nullable
as double?,
  ));
}

}


/// Adds pattern-matching-related methods to [MeasurementRequest].
extension MeasurementRequestPatterns on MeasurementRequest {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MeasurementRequest value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MeasurementRequest() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MeasurementRequest value)  $default,){
final _that = this;
switch (_that) {
case _MeasurementRequest():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MeasurementRequest value)?  $default,){
final _that = this;
switch (_that) {
case _MeasurementRequest() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String date,  double? weightKg,  double? bodyFatPercent,  double? waistCm,  double? chestCm,  double? hipCm,  double? armCm,  double? thighCm,  double? calfCm)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MeasurementRequest() when $default != null:
return $default(_that.date,_that.weightKg,_that.bodyFatPercent,_that.waistCm,_that.chestCm,_that.hipCm,_that.armCm,_that.thighCm,_that.calfCm);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String date,  double? weightKg,  double? bodyFatPercent,  double? waistCm,  double? chestCm,  double? hipCm,  double? armCm,  double? thighCm,  double? calfCm)  $default,) {final _that = this;
switch (_that) {
case _MeasurementRequest():
return $default(_that.date,_that.weightKg,_that.bodyFatPercent,_that.waistCm,_that.chestCm,_that.hipCm,_that.armCm,_that.thighCm,_that.calfCm);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String date,  double? weightKg,  double? bodyFatPercent,  double? waistCm,  double? chestCm,  double? hipCm,  double? armCm,  double? thighCm,  double? calfCm)?  $default,) {final _that = this;
switch (_that) {
case _MeasurementRequest() when $default != null:
return $default(_that.date,_that.weightKg,_that.bodyFatPercent,_that.waistCm,_that.chestCm,_that.hipCm,_that.armCm,_that.thighCm,_that.calfCm);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _MeasurementRequest implements MeasurementRequest {
  const _MeasurementRequest({required this.date, this.weightKg, this.bodyFatPercent, this.waistCm, this.chestCm, this.hipCm, this.armCm, this.thighCm, this.calfCm});
  factory _MeasurementRequest.fromJson(Map<String, dynamic> json) => _$MeasurementRequestFromJson(json);

@override final  String date;
@override final  double? weightKg;
@override final  double? bodyFatPercent;
@override final  double? waistCm;
@override final  double? chestCm;
@override final  double? hipCm;
@override final  double? armCm;
@override final  double? thighCm;
@override final  double? calfCm;

/// Create a copy of MeasurementRequest
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MeasurementRequestCopyWith<_MeasurementRequest> get copyWith => __$MeasurementRequestCopyWithImpl<_MeasurementRequest>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$MeasurementRequestToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _MeasurementRequest&&(identical(other.date, date) || other.date == date)&&(identical(other.weightKg, weightKg) || other.weightKg == weightKg)&&(identical(other.bodyFatPercent, bodyFatPercent) || other.bodyFatPercent == bodyFatPercent)&&(identical(other.waistCm, waistCm) || other.waistCm == waistCm)&&(identical(other.chestCm, chestCm) || other.chestCm == chestCm)&&(identical(other.hipCm, hipCm) || other.hipCm == hipCm)&&(identical(other.armCm, armCm) || other.armCm == armCm)&&(identical(other.thighCm, thighCm) || other.thighCm == thighCm)&&(identical(other.calfCm, calfCm) || other.calfCm == calfCm));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,date,weightKg,bodyFatPercent,waistCm,chestCm,hipCm,armCm,thighCm,calfCm);

@override
String toString() {
  return 'MeasurementRequest(date: $date, weightKg: $weightKg, bodyFatPercent: $bodyFatPercent, waistCm: $waistCm, chestCm: $chestCm, hipCm: $hipCm, armCm: $armCm, thighCm: $thighCm, calfCm: $calfCm)';
}


}

/// @nodoc
abstract mixin class _$MeasurementRequestCopyWith<$Res> implements $MeasurementRequestCopyWith<$Res> {
  factory _$MeasurementRequestCopyWith(_MeasurementRequest value, $Res Function(_MeasurementRequest) _then) = __$MeasurementRequestCopyWithImpl;
@override @useResult
$Res call({
 String date, double? weightKg, double? bodyFatPercent, double? waistCm, double? chestCm, double? hipCm, double? armCm, double? thighCm, double? calfCm
});




}
/// @nodoc
class __$MeasurementRequestCopyWithImpl<$Res>
    implements _$MeasurementRequestCopyWith<$Res> {
  __$MeasurementRequestCopyWithImpl(this._self, this._then);

  final _MeasurementRequest _self;
  final $Res Function(_MeasurementRequest) _then;

/// Create a copy of MeasurementRequest
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? date = null,Object? weightKg = freezed,Object? bodyFatPercent = freezed,Object? waistCm = freezed,Object? chestCm = freezed,Object? hipCm = freezed,Object? armCm = freezed,Object? thighCm = freezed,Object? calfCm = freezed,}) {
  return _then(_MeasurementRequest(
date: null == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as String,weightKg: freezed == weightKg ? _self.weightKg : weightKg // ignore: cast_nullable_to_non_nullable
as double?,bodyFatPercent: freezed == bodyFatPercent ? _self.bodyFatPercent : bodyFatPercent // ignore: cast_nullable_to_non_nullable
as double?,waistCm: freezed == waistCm ? _self.waistCm : waistCm // ignore: cast_nullable_to_non_nullable
as double?,chestCm: freezed == chestCm ? _self.chestCm : chestCm // ignore: cast_nullable_to_non_nullable
as double?,hipCm: freezed == hipCm ? _self.hipCm : hipCm // ignore: cast_nullable_to_non_nullable
as double?,armCm: freezed == armCm ? _self.armCm : armCm // ignore: cast_nullable_to_non_nullable
as double?,thighCm: freezed == thighCm ? _self.thighCm : thighCm // ignore: cast_nullable_to_non_nullable
as double?,calfCm: freezed == calfCm ? _self.calfCm : calfCm // ignore: cast_nullable_to_non_nullable
as double?,
  ));
}


}

// dart format on
