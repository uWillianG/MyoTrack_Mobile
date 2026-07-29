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


/// @nodoc
mixin _$WeeklyVolume {

/// Segunda-feira da semana.
 DateTime get weekStart; num get volumeKg;/// Treinos na semana, contados por sessão — vinte séries num dia são um treino.
 int get sessions;
/// Create a copy of WeeklyVolume
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$WeeklyVolumeCopyWith<WeeklyVolume> get copyWith => _$WeeklyVolumeCopyWithImpl<WeeklyVolume>(this as WeeklyVolume, _$identity);

  /// Serializes this WeeklyVolume to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WeeklyVolume&&(identical(other.weekStart, weekStart) || other.weekStart == weekStart)&&(identical(other.volumeKg, volumeKg) || other.volumeKg == volumeKg)&&(identical(other.sessions, sessions) || other.sessions == sessions));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,weekStart,volumeKg,sessions);

@override
String toString() {
  return 'WeeklyVolume(weekStart: $weekStart, volumeKg: $volumeKg, sessions: $sessions)';
}


}

/// @nodoc
abstract mixin class $WeeklyVolumeCopyWith<$Res>  {
  factory $WeeklyVolumeCopyWith(WeeklyVolume value, $Res Function(WeeklyVolume) _then) = _$WeeklyVolumeCopyWithImpl;
@useResult
$Res call({
 DateTime weekStart, num volumeKg, int sessions
});




}
/// @nodoc
class _$WeeklyVolumeCopyWithImpl<$Res>
    implements $WeeklyVolumeCopyWith<$Res> {
  _$WeeklyVolumeCopyWithImpl(this._self, this._then);

  final WeeklyVolume _self;
  final $Res Function(WeeklyVolume) _then;

/// Create a copy of WeeklyVolume
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? weekStart = null,Object? volumeKg = null,Object? sessions = null,}) {
  return _then(_self.copyWith(
weekStart: null == weekStart ? _self.weekStart : weekStart // ignore: cast_nullable_to_non_nullable
as DateTime,volumeKg: null == volumeKg ? _self.volumeKg : volumeKg // ignore: cast_nullable_to_non_nullable
as num,sessions: null == sessions ? _self.sessions : sessions // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [WeeklyVolume].
extension WeeklyVolumePatterns on WeeklyVolume {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _WeeklyVolume value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _WeeklyVolume() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _WeeklyVolume value)  $default,){
final _that = this;
switch (_that) {
case _WeeklyVolume():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _WeeklyVolume value)?  $default,){
final _that = this;
switch (_that) {
case _WeeklyVolume() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( DateTime weekStart,  num volumeKg,  int sessions)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _WeeklyVolume() when $default != null:
return $default(_that.weekStart,_that.volumeKg,_that.sessions);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( DateTime weekStart,  num volumeKg,  int sessions)  $default,) {final _that = this;
switch (_that) {
case _WeeklyVolume():
return $default(_that.weekStart,_that.volumeKg,_that.sessions);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( DateTime weekStart,  num volumeKg,  int sessions)?  $default,) {final _that = this;
switch (_that) {
case _WeeklyVolume() when $default != null:
return $default(_that.weekStart,_that.volumeKg,_that.sessions);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _WeeklyVolume implements WeeklyVolume {
  const _WeeklyVolume({required this.weekStart, this.volumeKg = 0, this.sessions = 0});
  factory _WeeklyVolume.fromJson(Map<String, dynamic> json) => _$WeeklyVolumeFromJson(json);

/// Segunda-feira da semana.
@override final  DateTime weekStart;
@override@JsonKey() final  num volumeKg;
/// Treinos na semana, contados por sessão — vinte séries num dia são um treino.
@override@JsonKey() final  int sessions;

/// Create a copy of WeeklyVolume
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$WeeklyVolumeCopyWith<_WeeklyVolume> get copyWith => __$WeeklyVolumeCopyWithImpl<_WeeklyVolume>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$WeeklyVolumeToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _WeeklyVolume&&(identical(other.weekStart, weekStart) || other.weekStart == weekStart)&&(identical(other.volumeKg, volumeKg) || other.volumeKg == volumeKg)&&(identical(other.sessions, sessions) || other.sessions == sessions));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,weekStart,volumeKg,sessions);

@override
String toString() {
  return 'WeeklyVolume(weekStart: $weekStart, volumeKg: $volumeKg, sessions: $sessions)';
}


}

/// @nodoc
abstract mixin class _$WeeklyVolumeCopyWith<$Res> implements $WeeklyVolumeCopyWith<$Res> {
  factory _$WeeklyVolumeCopyWith(_WeeklyVolume value, $Res Function(_WeeklyVolume) _then) = __$WeeklyVolumeCopyWithImpl;
@override @useResult
$Res call({
 DateTime weekStart, num volumeKg, int sessions
});




}
/// @nodoc
class __$WeeklyVolumeCopyWithImpl<$Res>
    implements _$WeeklyVolumeCopyWith<$Res> {
  __$WeeklyVolumeCopyWithImpl(this._self, this._then);

  final _WeeklyVolume _self;
  final $Res Function(_WeeklyVolume) _then;

/// Create a copy of WeeklyVolume
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? weekStart = null,Object? volumeKg = null,Object? sessions = null,}) {
  return _then(_WeeklyVolume(
weekStart: null == weekStart ? _self.weekStart : weekStart // ignore: cast_nullable_to_non_nullable
as DateTime,volumeKg: null == volumeKg ? _self.volumeKg : volumeKg // ignore: cast_nullable_to_non_nullable
as num,sessions: null == sessions ? _self.sessions : sessions // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$WeightPoint {

 DateTime get date; num get weightKg;
/// Create a copy of WeightPoint
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$WeightPointCopyWith<WeightPoint> get copyWith => _$WeightPointCopyWithImpl<WeightPoint>(this as WeightPoint, _$identity);

  /// Serializes this WeightPoint to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WeightPoint&&(identical(other.date, date) || other.date == date)&&(identical(other.weightKg, weightKg) || other.weightKg == weightKg));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,date,weightKg);

@override
String toString() {
  return 'WeightPoint(date: $date, weightKg: $weightKg)';
}


}

/// @nodoc
abstract mixin class $WeightPointCopyWith<$Res>  {
  factory $WeightPointCopyWith(WeightPoint value, $Res Function(WeightPoint) _then) = _$WeightPointCopyWithImpl;
@useResult
$Res call({
 DateTime date, num weightKg
});




}
/// @nodoc
class _$WeightPointCopyWithImpl<$Res>
    implements $WeightPointCopyWith<$Res> {
  _$WeightPointCopyWithImpl(this._self, this._then);

  final WeightPoint _self;
  final $Res Function(WeightPoint) _then;

/// Create a copy of WeightPoint
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? date = null,Object? weightKg = null,}) {
  return _then(_self.copyWith(
date: null == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as DateTime,weightKg: null == weightKg ? _self.weightKg : weightKg // ignore: cast_nullable_to_non_nullable
as num,
  ));
}

}


/// Adds pattern-matching-related methods to [WeightPoint].
extension WeightPointPatterns on WeightPoint {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _WeightPoint value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _WeightPoint() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _WeightPoint value)  $default,){
final _that = this;
switch (_that) {
case _WeightPoint():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _WeightPoint value)?  $default,){
final _that = this;
switch (_that) {
case _WeightPoint() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( DateTime date,  num weightKg)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _WeightPoint() when $default != null:
return $default(_that.date,_that.weightKg);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( DateTime date,  num weightKg)  $default,) {final _that = this;
switch (_that) {
case _WeightPoint():
return $default(_that.date,_that.weightKg);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( DateTime date,  num weightKg)?  $default,) {final _that = this;
switch (_that) {
case _WeightPoint() when $default != null:
return $default(_that.date,_that.weightKg);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _WeightPoint implements WeightPoint {
  const _WeightPoint({required this.date, this.weightKg = 0});
  factory _WeightPoint.fromJson(Map<String, dynamic> json) => _$WeightPointFromJson(json);

@override final  DateTime date;
@override@JsonKey() final  num weightKg;

/// Create a copy of WeightPoint
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$WeightPointCopyWith<_WeightPoint> get copyWith => __$WeightPointCopyWithImpl<_WeightPoint>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$WeightPointToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _WeightPoint&&(identical(other.date, date) || other.date == date)&&(identical(other.weightKg, weightKg) || other.weightKg == weightKg));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,date,weightKg);

@override
String toString() {
  return 'WeightPoint(date: $date, weightKg: $weightKg)';
}


}

/// @nodoc
abstract mixin class _$WeightPointCopyWith<$Res> implements $WeightPointCopyWith<$Res> {
  factory _$WeightPointCopyWith(_WeightPoint value, $Res Function(_WeightPoint) _then) = __$WeightPointCopyWithImpl;
@override @useResult
$Res call({
 DateTime date, num weightKg
});




}
/// @nodoc
class __$WeightPointCopyWithImpl<$Res>
    implements _$WeightPointCopyWith<$Res> {
  __$WeightPointCopyWithImpl(this._self, this._then);

  final _WeightPoint _self;
  final $Res Function(_WeightPoint) _then;

/// Create a copy of WeightPoint
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? date = null,Object? weightKg = null,}) {
  return _then(_WeightPoint(
date: null == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as DateTime,weightKg: null == weightKg ? _self.weightKg : weightKg // ignore: cast_nullable_to_non_nullable
as num,
  ));
}


}


/// @nodoc
mixin _$ExerciseRecord {

 int? get exerciseId; String get name; num get maxLoadKg; DateTime? get maxLoadDate;/// Repetições daquela série. "120 kg" sozinho não diz se foi uma única ou oito.
 int? get maxLoadReps; num? get bestE1RmKg; int? get e1RmReps; num? get e1RmLoadKg; DateTime? get e1RmDate;
/// Create a copy of ExerciseRecord
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ExerciseRecordCopyWith<ExerciseRecord> get copyWith => _$ExerciseRecordCopyWithImpl<ExerciseRecord>(this as ExerciseRecord, _$identity);

  /// Serializes this ExerciseRecord to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ExerciseRecord&&(identical(other.exerciseId, exerciseId) || other.exerciseId == exerciseId)&&(identical(other.name, name) || other.name == name)&&(identical(other.maxLoadKg, maxLoadKg) || other.maxLoadKg == maxLoadKg)&&(identical(other.maxLoadDate, maxLoadDate) || other.maxLoadDate == maxLoadDate)&&(identical(other.maxLoadReps, maxLoadReps) || other.maxLoadReps == maxLoadReps)&&(identical(other.bestE1RmKg, bestE1RmKg) || other.bestE1RmKg == bestE1RmKg)&&(identical(other.e1RmReps, e1RmReps) || other.e1RmReps == e1RmReps)&&(identical(other.e1RmLoadKg, e1RmLoadKg) || other.e1RmLoadKg == e1RmLoadKg)&&(identical(other.e1RmDate, e1RmDate) || other.e1RmDate == e1RmDate));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,exerciseId,name,maxLoadKg,maxLoadDate,maxLoadReps,bestE1RmKg,e1RmReps,e1RmLoadKg,e1RmDate);

@override
String toString() {
  return 'ExerciseRecord(exerciseId: $exerciseId, name: $name, maxLoadKg: $maxLoadKg, maxLoadDate: $maxLoadDate, maxLoadReps: $maxLoadReps, bestE1RmKg: $bestE1RmKg, e1RmReps: $e1RmReps, e1RmLoadKg: $e1RmLoadKg, e1RmDate: $e1RmDate)';
}


}

/// @nodoc
abstract mixin class $ExerciseRecordCopyWith<$Res>  {
  factory $ExerciseRecordCopyWith(ExerciseRecord value, $Res Function(ExerciseRecord) _then) = _$ExerciseRecordCopyWithImpl;
@useResult
$Res call({
 int? exerciseId, String name, num maxLoadKg, DateTime? maxLoadDate, int? maxLoadReps, num? bestE1RmKg, int? e1RmReps, num? e1RmLoadKg, DateTime? e1RmDate
});




}
/// @nodoc
class _$ExerciseRecordCopyWithImpl<$Res>
    implements $ExerciseRecordCopyWith<$Res> {
  _$ExerciseRecordCopyWithImpl(this._self, this._then);

  final ExerciseRecord _self;
  final $Res Function(ExerciseRecord) _then;

/// Create a copy of ExerciseRecord
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? exerciseId = freezed,Object? name = null,Object? maxLoadKg = null,Object? maxLoadDate = freezed,Object? maxLoadReps = freezed,Object? bestE1RmKg = freezed,Object? e1RmReps = freezed,Object? e1RmLoadKg = freezed,Object? e1RmDate = freezed,}) {
  return _then(_self.copyWith(
exerciseId: freezed == exerciseId ? _self.exerciseId : exerciseId // ignore: cast_nullable_to_non_nullable
as int?,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,maxLoadKg: null == maxLoadKg ? _self.maxLoadKg : maxLoadKg // ignore: cast_nullable_to_non_nullable
as num,maxLoadDate: freezed == maxLoadDate ? _self.maxLoadDate : maxLoadDate // ignore: cast_nullable_to_non_nullable
as DateTime?,maxLoadReps: freezed == maxLoadReps ? _self.maxLoadReps : maxLoadReps // ignore: cast_nullable_to_non_nullable
as int?,bestE1RmKg: freezed == bestE1RmKg ? _self.bestE1RmKg : bestE1RmKg // ignore: cast_nullable_to_non_nullable
as num?,e1RmReps: freezed == e1RmReps ? _self.e1RmReps : e1RmReps // ignore: cast_nullable_to_non_nullable
as int?,e1RmLoadKg: freezed == e1RmLoadKg ? _self.e1RmLoadKg : e1RmLoadKg // ignore: cast_nullable_to_non_nullable
as num?,e1RmDate: freezed == e1RmDate ? _self.e1RmDate : e1RmDate // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [ExerciseRecord].
extension ExerciseRecordPatterns on ExerciseRecord {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ExerciseRecord value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ExerciseRecord() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ExerciseRecord value)  $default,){
final _that = this;
switch (_that) {
case _ExerciseRecord():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ExerciseRecord value)?  $default,){
final _that = this;
switch (_that) {
case _ExerciseRecord() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int? exerciseId,  String name,  num maxLoadKg,  DateTime? maxLoadDate,  int? maxLoadReps,  num? bestE1RmKg,  int? e1RmReps,  num? e1RmLoadKg,  DateTime? e1RmDate)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ExerciseRecord() when $default != null:
return $default(_that.exerciseId,_that.name,_that.maxLoadKg,_that.maxLoadDate,_that.maxLoadReps,_that.bestE1RmKg,_that.e1RmReps,_that.e1RmLoadKg,_that.e1RmDate);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int? exerciseId,  String name,  num maxLoadKg,  DateTime? maxLoadDate,  int? maxLoadReps,  num? bestE1RmKg,  int? e1RmReps,  num? e1RmLoadKg,  DateTime? e1RmDate)  $default,) {final _that = this;
switch (_that) {
case _ExerciseRecord():
return $default(_that.exerciseId,_that.name,_that.maxLoadKg,_that.maxLoadDate,_that.maxLoadReps,_that.bestE1RmKg,_that.e1RmReps,_that.e1RmLoadKg,_that.e1RmDate);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int? exerciseId,  String name,  num maxLoadKg,  DateTime? maxLoadDate,  int? maxLoadReps,  num? bestE1RmKg,  int? e1RmReps,  num? e1RmLoadKg,  DateTime? e1RmDate)?  $default,) {final _that = this;
switch (_that) {
case _ExerciseRecord() when $default != null:
return $default(_that.exerciseId,_that.name,_that.maxLoadKg,_that.maxLoadDate,_that.maxLoadReps,_that.bestE1RmKg,_that.e1RmReps,_that.e1RmLoadKg,_that.e1RmDate);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ExerciseRecord implements ExerciseRecord {
  const _ExerciseRecord({this.exerciseId, this.name = '', this.maxLoadKg = 0, this.maxLoadDate, this.maxLoadReps, this.bestE1RmKg, this.e1RmReps, this.e1RmLoadKg, this.e1RmDate});
  factory _ExerciseRecord.fromJson(Map<String, dynamic> json) => _$ExerciseRecordFromJson(json);

@override final  int? exerciseId;
@override@JsonKey() final  String name;
@override@JsonKey() final  num maxLoadKg;
@override final  DateTime? maxLoadDate;
/// Repetições daquela série. "120 kg" sozinho não diz se foi uma única ou oito.
@override final  int? maxLoadReps;
@override final  num? bestE1RmKg;
@override final  int? e1RmReps;
@override final  num? e1RmLoadKg;
@override final  DateTime? e1RmDate;

/// Create a copy of ExerciseRecord
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ExerciseRecordCopyWith<_ExerciseRecord> get copyWith => __$ExerciseRecordCopyWithImpl<_ExerciseRecord>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ExerciseRecordToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ExerciseRecord&&(identical(other.exerciseId, exerciseId) || other.exerciseId == exerciseId)&&(identical(other.name, name) || other.name == name)&&(identical(other.maxLoadKg, maxLoadKg) || other.maxLoadKg == maxLoadKg)&&(identical(other.maxLoadDate, maxLoadDate) || other.maxLoadDate == maxLoadDate)&&(identical(other.maxLoadReps, maxLoadReps) || other.maxLoadReps == maxLoadReps)&&(identical(other.bestE1RmKg, bestE1RmKg) || other.bestE1RmKg == bestE1RmKg)&&(identical(other.e1RmReps, e1RmReps) || other.e1RmReps == e1RmReps)&&(identical(other.e1RmLoadKg, e1RmLoadKg) || other.e1RmLoadKg == e1RmLoadKg)&&(identical(other.e1RmDate, e1RmDate) || other.e1RmDate == e1RmDate));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,exerciseId,name,maxLoadKg,maxLoadDate,maxLoadReps,bestE1RmKg,e1RmReps,e1RmLoadKg,e1RmDate);

@override
String toString() {
  return 'ExerciseRecord(exerciseId: $exerciseId, name: $name, maxLoadKg: $maxLoadKg, maxLoadDate: $maxLoadDate, maxLoadReps: $maxLoadReps, bestE1RmKg: $bestE1RmKg, e1RmReps: $e1RmReps, e1RmLoadKg: $e1RmLoadKg, e1RmDate: $e1RmDate)';
}


}

/// @nodoc
abstract mixin class _$ExerciseRecordCopyWith<$Res> implements $ExerciseRecordCopyWith<$Res> {
  factory _$ExerciseRecordCopyWith(_ExerciseRecord value, $Res Function(_ExerciseRecord) _then) = __$ExerciseRecordCopyWithImpl;
@override @useResult
$Res call({
 int? exerciseId, String name, num maxLoadKg, DateTime? maxLoadDate, int? maxLoadReps, num? bestE1RmKg, int? e1RmReps, num? e1RmLoadKg, DateTime? e1RmDate
});




}
/// @nodoc
class __$ExerciseRecordCopyWithImpl<$Res>
    implements _$ExerciseRecordCopyWith<$Res> {
  __$ExerciseRecordCopyWithImpl(this._self, this._then);

  final _ExerciseRecord _self;
  final $Res Function(_ExerciseRecord) _then;

/// Create a copy of ExerciseRecord
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? exerciseId = freezed,Object? name = null,Object? maxLoadKg = null,Object? maxLoadDate = freezed,Object? maxLoadReps = freezed,Object? bestE1RmKg = freezed,Object? e1RmReps = freezed,Object? e1RmLoadKg = freezed,Object? e1RmDate = freezed,}) {
  return _then(_ExerciseRecord(
exerciseId: freezed == exerciseId ? _self.exerciseId : exerciseId // ignore: cast_nullable_to_non_nullable
as int?,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,maxLoadKg: null == maxLoadKg ? _self.maxLoadKg : maxLoadKg // ignore: cast_nullable_to_non_nullable
as num,maxLoadDate: freezed == maxLoadDate ? _self.maxLoadDate : maxLoadDate // ignore: cast_nullable_to_non_nullable
as DateTime?,maxLoadReps: freezed == maxLoadReps ? _self.maxLoadReps : maxLoadReps // ignore: cast_nullable_to_non_nullable
as int?,bestE1RmKg: freezed == bestE1RmKg ? _self.bestE1RmKg : bestE1RmKg // ignore: cast_nullable_to_non_nullable
as num?,e1RmReps: freezed == e1RmReps ? _self.e1RmReps : e1RmReps // ignore: cast_nullable_to_non_nullable
as int?,e1RmLoadKg: freezed == e1RmLoadKg ? _self.e1RmLoadKg : e1RmLoadKg // ignore: cast_nullable_to_non_nullable
as num?,e1RmDate: freezed == e1RmDate ? _self.e1RmDate : e1RmDate // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on
