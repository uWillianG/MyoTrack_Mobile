// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'progress_controller.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$LastSet {

 int get reps; num get loadKg;
/// Create a copy of LastSet
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LastSetCopyWith<LastSet> get copyWith => _$LastSetCopyWithImpl<LastSet>(this as LastSet, _$identity);

  /// Serializes this LastSet to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LastSet&&(identical(other.reps, reps) || other.reps == reps)&&(identical(other.loadKg, loadKg) || other.loadKg == loadKg));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,reps,loadKg);

@override
String toString() {
  return 'LastSet(reps: $reps, loadKg: $loadKg)';
}


}

/// @nodoc
abstract mixin class $LastSetCopyWith<$Res>  {
  factory $LastSetCopyWith(LastSet value, $Res Function(LastSet) _then) = _$LastSetCopyWithImpl;
@useResult
$Res call({
 int reps, num loadKg
});




}
/// @nodoc
class _$LastSetCopyWithImpl<$Res>
    implements $LastSetCopyWith<$Res> {
  _$LastSetCopyWithImpl(this._self, this._then);

  final LastSet _self;
  final $Res Function(LastSet) _then;

/// Create a copy of LastSet
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? reps = null,Object? loadKg = null,}) {
  return _then(_self.copyWith(
reps: null == reps ? _self.reps : reps // ignore: cast_nullable_to_non_nullable
as int,loadKg: null == loadKg ? _self.loadKg : loadKg // ignore: cast_nullable_to_non_nullable
as num,
  ));
}

}


/// Adds pattern-matching-related methods to [LastSet].
extension LastSetPatterns on LastSet {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _LastSet value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _LastSet() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _LastSet value)  $default,){
final _that = this;
switch (_that) {
case _LastSet():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _LastSet value)?  $default,){
final _that = this;
switch (_that) {
case _LastSet() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int reps,  num loadKg)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _LastSet() when $default != null:
return $default(_that.reps,_that.loadKg);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int reps,  num loadKg)  $default,) {final _that = this;
switch (_that) {
case _LastSet():
return $default(_that.reps,_that.loadKg);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int reps,  num loadKg)?  $default,) {final _that = this;
switch (_that) {
case _LastSet() when $default != null:
return $default(_that.reps,_that.loadKg);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _LastSet implements LastSet {
  const _LastSet({this.reps = 0, this.loadKg = 0});
  factory _LastSet.fromJson(Map<String, dynamic> json) => _$LastSetFromJson(json);

@override@JsonKey() final  int reps;
@override@JsonKey() final  num loadKg;

/// Create a copy of LastSet
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$LastSetCopyWith<_LastSet> get copyWith => __$LastSetCopyWithImpl<_LastSet>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$LastSetToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _LastSet&&(identical(other.reps, reps) || other.reps == reps)&&(identical(other.loadKg, loadKg) || other.loadKg == loadKg));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,reps,loadKg);

@override
String toString() {
  return 'LastSet(reps: $reps, loadKg: $loadKg)';
}


}

/// @nodoc
abstract mixin class _$LastSetCopyWith<$Res> implements $LastSetCopyWith<$Res> {
  factory _$LastSetCopyWith(_LastSet value, $Res Function(_LastSet) _then) = __$LastSetCopyWithImpl;
@override @useResult
$Res call({
 int reps, num loadKg
});




}
/// @nodoc
class __$LastSetCopyWithImpl<$Res>
    implements _$LastSetCopyWith<$Res> {
  __$LastSetCopyWithImpl(this._self, this._then);

  final _LastSet _self;
  final $Res Function(_LastSet) _then;

/// Create a copy of LastSet
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? reps = null,Object? loadKg = null,}) {
  return _then(_LastSet(
reps: null == reps ? _self.reps : reps // ignore: cast_nullable_to_non_nullable
as int,loadKg: null == loadKg ? _self.loadKg : loadKg // ignore: cast_nullable_to_non_nullable
as num,
  ));
}


}


/// @nodoc
mixin _$ProgressSuggestion {

 String? get workoutDayId; String? get dayLabel; int? get exerciseId; String get exerciseName; int get sets; int get repsMin; int get repsMax;/// Null em quem nunca registrou este exercício.
 String? get lastSessionDate; List<LastSet> get lastSets;/// `Start`, `Increase`, `ProgressReps` ou `Consolidate`.
 String get action;/// Carga sugerida. Null quando o plano também não trouxe uma.
 num? get nextLoadKg; int get targetReps; num? get incrementKg;
/// Create a copy of ProgressSuggestion
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProgressSuggestionCopyWith<ProgressSuggestion> get copyWith => _$ProgressSuggestionCopyWithImpl<ProgressSuggestion>(this as ProgressSuggestion, _$identity);

  /// Serializes this ProgressSuggestion to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProgressSuggestion&&(identical(other.workoutDayId, workoutDayId) || other.workoutDayId == workoutDayId)&&(identical(other.dayLabel, dayLabel) || other.dayLabel == dayLabel)&&(identical(other.exerciseId, exerciseId) || other.exerciseId == exerciseId)&&(identical(other.exerciseName, exerciseName) || other.exerciseName == exerciseName)&&(identical(other.sets, sets) || other.sets == sets)&&(identical(other.repsMin, repsMin) || other.repsMin == repsMin)&&(identical(other.repsMax, repsMax) || other.repsMax == repsMax)&&(identical(other.lastSessionDate, lastSessionDate) || other.lastSessionDate == lastSessionDate)&&const DeepCollectionEquality().equals(other.lastSets, lastSets)&&(identical(other.action, action) || other.action == action)&&(identical(other.nextLoadKg, nextLoadKg) || other.nextLoadKg == nextLoadKg)&&(identical(other.targetReps, targetReps) || other.targetReps == targetReps)&&(identical(other.incrementKg, incrementKg) || other.incrementKg == incrementKg));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,workoutDayId,dayLabel,exerciseId,exerciseName,sets,repsMin,repsMax,lastSessionDate,const DeepCollectionEquality().hash(lastSets),action,nextLoadKg,targetReps,incrementKg);

@override
String toString() {
  return 'ProgressSuggestion(workoutDayId: $workoutDayId, dayLabel: $dayLabel, exerciseId: $exerciseId, exerciseName: $exerciseName, sets: $sets, repsMin: $repsMin, repsMax: $repsMax, lastSessionDate: $lastSessionDate, lastSets: $lastSets, action: $action, nextLoadKg: $nextLoadKg, targetReps: $targetReps, incrementKg: $incrementKg)';
}


}

/// @nodoc
abstract mixin class $ProgressSuggestionCopyWith<$Res>  {
  factory $ProgressSuggestionCopyWith(ProgressSuggestion value, $Res Function(ProgressSuggestion) _then) = _$ProgressSuggestionCopyWithImpl;
@useResult
$Res call({
 String? workoutDayId, String? dayLabel, int? exerciseId, String exerciseName, int sets, int repsMin, int repsMax, String? lastSessionDate, List<LastSet> lastSets, String action, num? nextLoadKg, int targetReps, num? incrementKg
});




}
/// @nodoc
class _$ProgressSuggestionCopyWithImpl<$Res>
    implements $ProgressSuggestionCopyWith<$Res> {
  _$ProgressSuggestionCopyWithImpl(this._self, this._then);

  final ProgressSuggestion _self;
  final $Res Function(ProgressSuggestion) _then;

/// Create a copy of ProgressSuggestion
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? workoutDayId = freezed,Object? dayLabel = freezed,Object? exerciseId = freezed,Object? exerciseName = null,Object? sets = null,Object? repsMin = null,Object? repsMax = null,Object? lastSessionDate = freezed,Object? lastSets = null,Object? action = null,Object? nextLoadKg = freezed,Object? targetReps = null,Object? incrementKg = freezed,}) {
  return _then(_self.copyWith(
workoutDayId: freezed == workoutDayId ? _self.workoutDayId : workoutDayId // ignore: cast_nullable_to_non_nullable
as String?,dayLabel: freezed == dayLabel ? _self.dayLabel : dayLabel // ignore: cast_nullable_to_non_nullable
as String?,exerciseId: freezed == exerciseId ? _self.exerciseId : exerciseId // ignore: cast_nullable_to_non_nullable
as int?,exerciseName: null == exerciseName ? _self.exerciseName : exerciseName // ignore: cast_nullable_to_non_nullable
as String,sets: null == sets ? _self.sets : sets // ignore: cast_nullable_to_non_nullable
as int,repsMin: null == repsMin ? _self.repsMin : repsMin // ignore: cast_nullable_to_non_nullable
as int,repsMax: null == repsMax ? _self.repsMax : repsMax // ignore: cast_nullable_to_non_nullable
as int,lastSessionDate: freezed == lastSessionDate ? _self.lastSessionDate : lastSessionDate // ignore: cast_nullable_to_non_nullable
as String?,lastSets: null == lastSets ? _self.lastSets : lastSets // ignore: cast_nullable_to_non_nullable
as List<LastSet>,action: null == action ? _self.action : action // ignore: cast_nullable_to_non_nullable
as String,nextLoadKg: freezed == nextLoadKg ? _self.nextLoadKg : nextLoadKg // ignore: cast_nullable_to_non_nullable
as num?,targetReps: null == targetReps ? _self.targetReps : targetReps // ignore: cast_nullable_to_non_nullable
as int,incrementKg: freezed == incrementKg ? _self.incrementKg : incrementKg // ignore: cast_nullable_to_non_nullable
as num?,
  ));
}

}


/// Adds pattern-matching-related methods to [ProgressSuggestion].
extension ProgressSuggestionPatterns on ProgressSuggestion {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ProgressSuggestion value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ProgressSuggestion() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ProgressSuggestion value)  $default,){
final _that = this;
switch (_that) {
case _ProgressSuggestion():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ProgressSuggestion value)?  $default,){
final _that = this;
switch (_that) {
case _ProgressSuggestion() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String? workoutDayId,  String? dayLabel,  int? exerciseId,  String exerciseName,  int sets,  int repsMin,  int repsMax,  String? lastSessionDate,  List<LastSet> lastSets,  String action,  num? nextLoadKg,  int targetReps,  num? incrementKg)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ProgressSuggestion() when $default != null:
return $default(_that.workoutDayId,_that.dayLabel,_that.exerciseId,_that.exerciseName,_that.sets,_that.repsMin,_that.repsMax,_that.lastSessionDate,_that.lastSets,_that.action,_that.nextLoadKg,_that.targetReps,_that.incrementKg);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String? workoutDayId,  String? dayLabel,  int? exerciseId,  String exerciseName,  int sets,  int repsMin,  int repsMax,  String? lastSessionDate,  List<LastSet> lastSets,  String action,  num? nextLoadKg,  int targetReps,  num? incrementKg)  $default,) {final _that = this;
switch (_that) {
case _ProgressSuggestion():
return $default(_that.workoutDayId,_that.dayLabel,_that.exerciseId,_that.exerciseName,_that.sets,_that.repsMin,_that.repsMax,_that.lastSessionDate,_that.lastSets,_that.action,_that.nextLoadKg,_that.targetReps,_that.incrementKg);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String? workoutDayId,  String? dayLabel,  int? exerciseId,  String exerciseName,  int sets,  int repsMin,  int repsMax,  String? lastSessionDate,  List<LastSet> lastSets,  String action,  num? nextLoadKg,  int targetReps,  num? incrementKg)?  $default,) {final _that = this;
switch (_that) {
case _ProgressSuggestion() when $default != null:
return $default(_that.workoutDayId,_that.dayLabel,_that.exerciseId,_that.exerciseName,_that.sets,_that.repsMin,_that.repsMax,_that.lastSessionDate,_that.lastSets,_that.action,_that.nextLoadKg,_that.targetReps,_that.incrementKg);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ProgressSuggestion extends ProgressSuggestion {
  const _ProgressSuggestion({this.workoutDayId, this.dayLabel, this.exerciseId, this.exerciseName = '', this.sets = 0, this.repsMin = 0, this.repsMax = 0, this.lastSessionDate, final  List<LastSet> lastSets = const [], this.action = 'Start', this.nextLoadKg, this.targetReps = 0, this.incrementKg}): _lastSets = lastSets,super._();
  factory _ProgressSuggestion.fromJson(Map<String, dynamic> json) => _$ProgressSuggestionFromJson(json);

@override final  String? workoutDayId;
@override final  String? dayLabel;
@override final  int? exerciseId;
@override@JsonKey() final  String exerciseName;
@override@JsonKey() final  int sets;
@override@JsonKey() final  int repsMin;
@override@JsonKey() final  int repsMax;
/// Null em quem nunca registrou este exercício.
@override final  String? lastSessionDate;
 final  List<LastSet> _lastSets;
@override@JsonKey() List<LastSet> get lastSets {
  if (_lastSets is EqualUnmodifiableListView) return _lastSets;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_lastSets);
}

/// `Start`, `Increase`, `ProgressReps` ou `Consolidate`.
@override@JsonKey() final  String action;
/// Carga sugerida. Null quando o plano também não trouxe uma.
@override final  num? nextLoadKg;
@override@JsonKey() final  int targetReps;
@override final  num? incrementKg;

/// Create a copy of ProgressSuggestion
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ProgressSuggestionCopyWith<_ProgressSuggestion> get copyWith => __$ProgressSuggestionCopyWithImpl<_ProgressSuggestion>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ProgressSuggestionToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ProgressSuggestion&&(identical(other.workoutDayId, workoutDayId) || other.workoutDayId == workoutDayId)&&(identical(other.dayLabel, dayLabel) || other.dayLabel == dayLabel)&&(identical(other.exerciseId, exerciseId) || other.exerciseId == exerciseId)&&(identical(other.exerciseName, exerciseName) || other.exerciseName == exerciseName)&&(identical(other.sets, sets) || other.sets == sets)&&(identical(other.repsMin, repsMin) || other.repsMin == repsMin)&&(identical(other.repsMax, repsMax) || other.repsMax == repsMax)&&(identical(other.lastSessionDate, lastSessionDate) || other.lastSessionDate == lastSessionDate)&&const DeepCollectionEquality().equals(other._lastSets, _lastSets)&&(identical(other.action, action) || other.action == action)&&(identical(other.nextLoadKg, nextLoadKg) || other.nextLoadKg == nextLoadKg)&&(identical(other.targetReps, targetReps) || other.targetReps == targetReps)&&(identical(other.incrementKg, incrementKg) || other.incrementKg == incrementKg));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,workoutDayId,dayLabel,exerciseId,exerciseName,sets,repsMin,repsMax,lastSessionDate,const DeepCollectionEquality().hash(_lastSets),action,nextLoadKg,targetReps,incrementKg);

@override
String toString() {
  return 'ProgressSuggestion(workoutDayId: $workoutDayId, dayLabel: $dayLabel, exerciseId: $exerciseId, exerciseName: $exerciseName, sets: $sets, repsMin: $repsMin, repsMax: $repsMax, lastSessionDate: $lastSessionDate, lastSets: $lastSets, action: $action, nextLoadKg: $nextLoadKg, targetReps: $targetReps, incrementKg: $incrementKg)';
}


}

/// @nodoc
abstract mixin class _$ProgressSuggestionCopyWith<$Res> implements $ProgressSuggestionCopyWith<$Res> {
  factory _$ProgressSuggestionCopyWith(_ProgressSuggestion value, $Res Function(_ProgressSuggestion) _then) = __$ProgressSuggestionCopyWithImpl;
@override @useResult
$Res call({
 String? workoutDayId, String? dayLabel, int? exerciseId, String exerciseName, int sets, int repsMin, int repsMax, String? lastSessionDate, List<LastSet> lastSets, String action, num? nextLoadKg, int targetReps, num? incrementKg
});




}
/// @nodoc
class __$ProgressSuggestionCopyWithImpl<$Res>
    implements _$ProgressSuggestionCopyWith<$Res> {
  __$ProgressSuggestionCopyWithImpl(this._self, this._then);

  final _ProgressSuggestion _self;
  final $Res Function(_ProgressSuggestion) _then;

/// Create a copy of ProgressSuggestion
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? workoutDayId = freezed,Object? dayLabel = freezed,Object? exerciseId = freezed,Object? exerciseName = null,Object? sets = null,Object? repsMin = null,Object? repsMax = null,Object? lastSessionDate = freezed,Object? lastSets = null,Object? action = null,Object? nextLoadKg = freezed,Object? targetReps = null,Object? incrementKg = freezed,}) {
  return _then(_ProgressSuggestion(
workoutDayId: freezed == workoutDayId ? _self.workoutDayId : workoutDayId // ignore: cast_nullable_to_non_nullable
as String?,dayLabel: freezed == dayLabel ? _self.dayLabel : dayLabel // ignore: cast_nullable_to_non_nullable
as String?,exerciseId: freezed == exerciseId ? _self.exerciseId : exerciseId // ignore: cast_nullable_to_non_nullable
as int?,exerciseName: null == exerciseName ? _self.exerciseName : exerciseName // ignore: cast_nullable_to_non_nullable
as String,sets: null == sets ? _self.sets : sets // ignore: cast_nullable_to_non_nullable
as int,repsMin: null == repsMin ? _self.repsMin : repsMin // ignore: cast_nullable_to_non_nullable
as int,repsMax: null == repsMax ? _self.repsMax : repsMax // ignore: cast_nullable_to_non_nullable
as int,lastSessionDate: freezed == lastSessionDate ? _self.lastSessionDate : lastSessionDate // ignore: cast_nullable_to_non_nullable
as String?,lastSets: null == lastSets ? _self._lastSets : lastSets // ignore: cast_nullable_to_non_nullable
as List<LastSet>,action: null == action ? _self.action : action // ignore: cast_nullable_to_non_nullable
as String,nextLoadKg: freezed == nextLoadKg ? _self.nextLoadKg : nextLoadKg // ignore: cast_nullable_to_non_nullable
as num?,targetReps: null == targetReps ? _self.targetReps : targetReps // ignore: cast_nullable_to_non_nullable
as int,incrementKg: freezed == incrementKg ? _self.incrementKg : incrementKg // ignore: cast_nullable_to_non_nullable
as num?,
  ));
}


}

// dart format on
