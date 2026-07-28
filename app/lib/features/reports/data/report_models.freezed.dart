// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'report_models.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$WeeklyMetrics {

 String? get weekStart; int get sessions; int get totalSets; num get totalVolumeKg;/// Variação do volume contra a semana anterior. Null quando não houve treino nela.
 num? get volumeChangePercent; String? get topExercise; num? get topExerciseVolumeKg; num? get weightStartKg; num? get weightEndKg; num? get weightChangeKg; int get mealsLogged; int get daysWithMealLogged; num? get avgKcalPerLoggedDay;
/// Create a copy of WeeklyMetrics
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$WeeklyMetricsCopyWith<WeeklyMetrics> get copyWith => _$WeeklyMetricsCopyWithImpl<WeeklyMetrics>(this as WeeklyMetrics, _$identity);

  /// Serializes this WeeklyMetrics to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WeeklyMetrics&&(identical(other.weekStart, weekStart) || other.weekStart == weekStart)&&(identical(other.sessions, sessions) || other.sessions == sessions)&&(identical(other.totalSets, totalSets) || other.totalSets == totalSets)&&(identical(other.totalVolumeKg, totalVolumeKg) || other.totalVolumeKg == totalVolumeKg)&&(identical(other.volumeChangePercent, volumeChangePercent) || other.volumeChangePercent == volumeChangePercent)&&(identical(other.topExercise, topExercise) || other.topExercise == topExercise)&&(identical(other.topExerciseVolumeKg, topExerciseVolumeKg) || other.topExerciseVolumeKg == topExerciseVolumeKg)&&(identical(other.weightStartKg, weightStartKg) || other.weightStartKg == weightStartKg)&&(identical(other.weightEndKg, weightEndKg) || other.weightEndKg == weightEndKg)&&(identical(other.weightChangeKg, weightChangeKg) || other.weightChangeKg == weightChangeKg)&&(identical(other.mealsLogged, mealsLogged) || other.mealsLogged == mealsLogged)&&(identical(other.daysWithMealLogged, daysWithMealLogged) || other.daysWithMealLogged == daysWithMealLogged)&&(identical(other.avgKcalPerLoggedDay, avgKcalPerLoggedDay) || other.avgKcalPerLoggedDay == avgKcalPerLoggedDay));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,weekStart,sessions,totalSets,totalVolumeKg,volumeChangePercent,topExercise,topExerciseVolumeKg,weightStartKg,weightEndKg,weightChangeKg,mealsLogged,daysWithMealLogged,avgKcalPerLoggedDay);

@override
String toString() {
  return 'WeeklyMetrics(weekStart: $weekStart, sessions: $sessions, totalSets: $totalSets, totalVolumeKg: $totalVolumeKg, volumeChangePercent: $volumeChangePercent, topExercise: $topExercise, topExerciseVolumeKg: $topExerciseVolumeKg, weightStartKg: $weightStartKg, weightEndKg: $weightEndKg, weightChangeKg: $weightChangeKg, mealsLogged: $mealsLogged, daysWithMealLogged: $daysWithMealLogged, avgKcalPerLoggedDay: $avgKcalPerLoggedDay)';
}


}

/// @nodoc
abstract mixin class $WeeklyMetricsCopyWith<$Res>  {
  factory $WeeklyMetricsCopyWith(WeeklyMetrics value, $Res Function(WeeklyMetrics) _then) = _$WeeklyMetricsCopyWithImpl;
@useResult
$Res call({
 String? weekStart, int sessions, int totalSets, num totalVolumeKg, num? volumeChangePercent, String? topExercise, num? topExerciseVolumeKg, num? weightStartKg, num? weightEndKg, num? weightChangeKg, int mealsLogged, int daysWithMealLogged, num? avgKcalPerLoggedDay
});




}
/// @nodoc
class _$WeeklyMetricsCopyWithImpl<$Res>
    implements $WeeklyMetricsCopyWith<$Res> {
  _$WeeklyMetricsCopyWithImpl(this._self, this._then);

  final WeeklyMetrics _self;
  final $Res Function(WeeklyMetrics) _then;

/// Create a copy of WeeklyMetrics
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? weekStart = freezed,Object? sessions = null,Object? totalSets = null,Object? totalVolumeKg = null,Object? volumeChangePercent = freezed,Object? topExercise = freezed,Object? topExerciseVolumeKg = freezed,Object? weightStartKg = freezed,Object? weightEndKg = freezed,Object? weightChangeKg = freezed,Object? mealsLogged = null,Object? daysWithMealLogged = null,Object? avgKcalPerLoggedDay = freezed,}) {
  return _then(_self.copyWith(
weekStart: freezed == weekStart ? _self.weekStart : weekStart // ignore: cast_nullable_to_non_nullable
as String?,sessions: null == sessions ? _self.sessions : sessions // ignore: cast_nullable_to_non_nullable
as int,totalSets: null == totalSets ? _self.totalSets : totalSets // ignore: cast_nullable_to_non_nullable
as int,totalVolumeKg: null == totalVolumeKg ? _self.totalVolumeKg : totalVolumeKg // ignore: cast_nullable_to_non_nullable
as num,volumeChangePercent: freezed == volumeChangePercent ? _self.volumeChangePercent : volumeChangePercent // ignore: cast_nullable_to_non_nullable
as num?,topExercise: freezed == topExercise ? _self.topExercise : topExercise // ignore: cast_nullable_to_non_nullable
as String?,topExerciseVolumeKg: freezed == topExerciseVolumeKg ? _self.topExerciseVolumeKg : topExerciseVolumeKg // ignore: cast_nullable_to_non_nullable
as num?,weightStartKg: freezed == weightStartKg ? _self.weightStartKg : weightStartKg // ignore: cast_nullable_to_non_nullable
as num?,weightEndKg: freezed == weightEndKg ? _self.weightEndKg : weightEndKg // ignore: cast_nullable_to_non_nullable
as num?,weightChangeKg: freezed == weightChangeKg ? _self.weightChangeKg : weightChangeKg // ignore: cast_nullable_to_non_nullable
as num?,mealsLogged: null == mealsLogged ? _self.mealsLogged : mealsLogged // ignore: cast_nullable_to_non_nullable
as int,daysWithMealLogged: null == daysWithMealLogged ? _self.daysWithMealLogged : daysWithMealLogged // ignore: cast_nullable_to_non_nullable
as int,avgKcalPerLoggedDay: freezed == avgKcalPerLoggedDay ? _self.avgKcalPerLoggedDay : avgKcalPerLoggedDay // ignore: cast_nullable_to_non_nullable
as num?,
  ));
}

}


/// Adds pattern-matching-related methods to [WeeklyMetrics].
extension WeeklyMetricsPatterns on WeeklyMetrics {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _WeeklyMetrics value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _WeeklyMetrics() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _WeeklyMetrics value)  $default,){
final _that = this;
switch (_that) {
case _WeeklyMetrics():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _WeeklyMetrics value)?  $default,){
final _that = this;
switch (_that) {
case _WeeklyMetrics() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String? weekStart,  int sessions,  int totalSets,  num totalVolumeKg,  num? volumeChangePercent,  String? topExercise,  num? topExerciseVolumeKg,  num? weightStartKg,  num? weightEndKg,  num? weightChangeKg,  int mealsLogged,  int daysWithMealLogged,  num? avgKcalPerLoggedDay)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _WeeklyMetrics() when $default != null:
return $default(_that.weekStart,_that.sessions,_that.totalSets,_that.totalVolumeKg,_that.volumeChangePercent,_that.topExercise,_that.topExerciseVolumeKg,_that.weightStartKg,_that.weightEndKg,_that.weightChangeKg,_that.mealsLogged,_that.daysWithMealLogged,_that.avgKcalPerLoggedDay);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String? weekStart,  int sessions,  int totalSets,  num totalVolumeKg,  num? volumeChangePercent,  String? topExercise,  num? topExerciseVolumeKg,  num? weightStartKg,  num? weightEndKg,  num? weightChangeKg,  int mealsLogged,  int daysWithMealLogged,  num? avgKcalPerLoggedDay)  $default,) {final _that = this;
switch (_that) {
case _WeeklyMetrics():
return $default(_that.weekStart,_that.sessions,_that.totalSets,_that.totalVolumeKg,_that.volumeChangePercent,_that.topExercise,_that.topExerciseVolumeKg,_that.weightStartKg,_that.weightEndKg,_that.weightChangeKg,_that.mealsLogged,_that.daysWithMealLogged,_that.avgKcalPerLoggedDay);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String? weekStart,  int sessions,  int totalSets,  num totalVolumeKg,  num? volumeChangePercent,  String? topExercise,  num? topExerciseVolumeKg,  num? weightStartKg,  num? weightEndKg,  num? weightChangeKg,  int mealsLogged,  int daysWithMealLogged,  num? avgKcalPerLoggedDay)?  $default,) {final _that = this;
switch (_that) {
case _WeeklyMetrics() when $default != null:
return $default(_that.weekStart,_that.sessions,_that.totalSets,_that.totalVolumeKg,_that.volumeChangePercent,_that.topExercise,_that.topExerciseVolumeKg,_that.weightStartKg,_that.weightEndKg,_that.weightChangeKg,_that.mealsLogged,_that.daysWithMealLogged,_that.avgKcalPerLoggedDay);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _WeeklyMetrics implements WeeklyMetrics {
  const _WeeklyMetrics({this.weekStart, this.sessions = 0, this.totalSets = 0, this.totalVolumeKg = 0, this.volumeChangePercent, this.topExercise, this.topExerciseVolumeKg, this.weightStartKg, this.weightEndKg, this.weightChangeKg, this.mealsLogged = 0, this.daysWithMealLogged = 0, this.avgKcalPerLoggedDay});
  factory _WeeklyMetrics.fromJson(Map<String, dynamic> json) => _$WeeklyMetricsFromJson(json);

@override final  String? weekStart;
@override@JsonKey() final  int sessions;
@override@JsonKey() final  int totalSets;
@override@JsonKey() final  num totalVolumeKg;
/// Variação do volume contra a semana anterior. Null quando não houve treino nela.
@override final  num? volumeChangePercent;
@override final  String? topExercise;
@override final  num? topExerciseVolumeKg;
@override final  num? weightStartKg;
@override final  num? weightEndKg;
@override final  num? weightChangeKg;
@override@JsonKey() final  int mealsLogged;
@override@JsonKey() final  int daysWithMealLogged;
@override final  num? avgKcalPerLoggedDay;

/// Create a copy of WeeklyMetrics
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$WeeklyMetricsCopyWith<_WeeklyMetrics> get copyWith => __$WeeklyMetricsCopyWithImpl<_WeeklyMetrics>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$WeeklyMetricsToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _WeeklyMetrics&&(identical(other.weekStart, weekStart) || other.weekStart == weekStart)&&(identical(other.sessions, sessions) || other.sessions == sessions)&&(identical(other.totalSets, totalSets) || other.totalSets == totalSets)&&(identical(other.totalVolumeKg, totalVolumeKg) || other.totalVolumeKg == totalVolumeKg)&&(identical(other.volumeChangePercent, volumeChangePercent) || other.volumeChangePercent == volumeChangePercent)&&(identical(other.topExercise, topExercise) || other.topExercise == topExercise)&&(identical(other.topExerciseVolumeKg, topExerciseVolumeKg) || other.topExerciseVolumeKg == topExerciseVolumeKg)&&(identical(other.weightStartKg, weightStartKg) || other.weightStartKg == weightStartKg)&&(identical(other.weightEndKg, weightEndKg) || other.weightEndKg == weightEndKg)&&(identical(other.weightChangeKg, weightChangeKg) || other.weightChangeKg == weightChangeKg)&&(identical(other.mealsLogged, mealsLogged) || other.mealsLogged == mealsLogged)&&(identical(other.daysWithMealLogged, daysWithMealLogged) || other.daysWithMealLogged == daysWithMealLogged)&&(identical(other.avgKcalPerLoggedDay, avgKcalPerLoggedDay) || other.avgKcalPerLoggedDay == avgKcalPerLoggedDay));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,weekStart,sessions,totalSets,totalVolumeKg,volumeChangePercent,topExercise,topExerciseVolumeKg,weightStartKg,weightEndKg,weightChangeKg,mealsLogged,daysWithMealLogged,avgKcalPerLoggedDay);

@override
String toString() {
  return 'WeeklyMetrics(weekStart: $weekStart, sessions: $sessions, totalSets: $totalSets, totalVolumeKg: $totalVolumeKg, volumeChangePercent: $volumeChangePercent, topExercise: $topExercise, topExerciseVolumeKg: $topExerciseVolumeKg, weightStartKg: $weightStartKg, weightEndKg: $weightEndKg, weightChangeKg: $weightChangeKg, mealsLogged: $mealsLogged, daysWithMealLogged: $daysWithMealLogged, avgKcalPerLoggedDay: $avgKcalPerLoggedDay)';
}


}

/// @nodoc
abstract mixin class _$WeeklyMetricsCopyWith<$Res> implements $WeeklyMetricsCopyWith<$Res> {
  factory _$WeeklyMetricsCopyWith(_WeeklyMetrics value, $Res Function(_WeeklyMetrics) _then) = __$WeeklyMetricsCopyWithImpl;
@override @useResult
$Res call({
 String? weekStart, int sessions, int totalSets, num totalVolumeKg, num? volumeChangePercent, String? topExercise, num? topExerciseVolumeKg, num? weightStartKg, num? weightEndKg, num? weightChangeKg, int mealsLogged, int daysWithMealLogged, num? avgKcalPerLoggedDay
});




}
/// @nodoc
class __$WeeklyMetricsCopyWithImpl<$Res>
    implements _$WeeklyMetricsCopyWith<$Res> {
  __$WeeklyMetricsCopyWithImpl(this._self, this._then);

  final _WeeklyMetrics _self;
  final $Res Function(_WeeklyMetrics) _then;

/// Create a copy of WeeklyMetrics
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? weekStart = freezed,Object? sessions = null,Object? totalSets = null,Object? totalVolumeKg = null,Object? volumeChangePercent = freezed,Object? topExercise = freezed,Object? topExerciseVolumeKg = freezed,Object? weightStartKg = freezed,Object? weightEndKg = freezed,Object? weightChangeKg = freezed,Object? mealsLogged = null,Object? daysWithMealLogged = null,Object? avgKcalPerLoggedDay = freezed,}) {
  return _then(_WeeklyMetrics(
weekStart: freezed == weekStart ? _self.weekStart : weekStart // ignore: cast_nullable_to_non_nullable
as String?,sessions: null == sessions ? _self.sessions : sessions // ignore: cast_nullable_to_non_nullable
as int,totalSets: null == totalSets ? _self.totalSets : totalSets // ignore: cast_nullable_to_non_nullable
as int,totalVolumeKg: null == totalVolumeKg ? _self.totalVolumeKg : totalVolumeKg // ignore: cast_nullable_to_non_nullable
as num,volumeChangePercent: freezed == volumeChangePercent ? _self.volumeChangePercent : volumeChangePercent // ignore: cast_nullable_to_non_nullable
as num?,topExercise: freezed == topExercise ? _self.topExercise : topExercise // ignore: cast_nullable_to_non_nullable
as String?,topExerciseVolumeKg: freezed == topExerciseVolumeKg ? _self.topExerciseVolumeKg : topExerciseVolumeKg // ignore: cast_nullable_to_non_nullable
as num?,weightStartKg: freezed == weightStartKg ? _self.weightStartKg : weightStartKg // ignore: cast_nullable_to_non_nullable
as num?,weightEndKg: freezed == weightEndKg ? _self.weightEndKg : weightEndKg // ignore: cast_nullable_to_non_nullable
as num?,weightChangeKg: freezed == weightChangeKg ? _self.weightChangeKg : weightChangeKg // ignore: cast_nullable_to_non_nullable
as num?,mealsLogged: null == mealsLogged ? _self.mealsLogged : mealsLogged // ignore: cast_nullable_to_non_nullable
as int,daysWithMealLogged: null == daysWithMealLogged ? _self.daysWithMealLogged : daysWithMealLogged // ignore: cast_nullable_to_non_nullable
as int,avgKcalPerLoggedDay: freezed == avgKcalPerLoggedDay ? _self.avgKcalPerLoggedDay : avgKcalPerLoggedDay // ignore: cast_nullable_to_non_nullable
as num?,
  ));
}


}


/// @nodoc
mixin _$WeeklyNarrative {

 String get summary; List<String> get highlights; List<String> get recommendations;
/// Create a copy of WeeklyNarrative
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$WeeklyNarrativeCopyWith<WeeklyNarrative> get copyWith => _$WeeklyNarrativeCopyWithImpl<WeeklyNarrative>(this as WeeklyNarrative, _$identity);

  /// Serializes this WeeklyNarrative to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WeeklyNarrative&&(identical(other.summary, summary) || other.summary == summary)&&const DeepCollectionEquality().equals(other.highlights, highlights)&&const DeepCollectionEquality().equals(other.recommendations, recommendations));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,summary,const DeepCollectionEquality().hash(highlights),const DeepCollectionEquality().hash(recommendations));

@override
String toString() {
  return 'WeeklyNarrative(summary: $summary, highlights: $highlights, recommendations: $recommendations)';
}


}

/// @nodoc
abstract mixin class $WeeklyNarrativeCopyWith<$Res>  {
  factory $WeeklyNarrativeCopyWith(WeeklyNarrative value, $Res Function(WeeklyNarrative) _then) = _$WeeklyNarrativeCopyWithImpl;
@useResult
$Res call({
 String summary, List<String> highlights, List<String> recommendations
});




}
/// @nodoc
class _$WeeklyNarrativeCopyWithImpl<$Res>
    implements $WeeklyNarrativeCopyWith<$Res> {
  _$WeeklyNarrativeCopyWithImpl(this._self, this._then);

  final WeeklyNarrative _self;
  final $Res Function(WeeklyNarrative) _then;

/// Create a copy of WeeklyNarrative
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? summary = null,Object? highlights = null,Object? recommendations = null,}) {
  return _then(_self.copyWith(
summary: null == summary ? _self.summary : summary // ignore: cast_nullable_to_non_nullable
as String,highlights: null == highlights ? _self.highlights : highlights // ignore: cast_nullable_to_non_nullable
as List<String>,recommendations: null == recommendations ? _self.recommendations : recommendations // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}

}


/// Adds pattern-matching-related methods to [WeeklyNarrative].
extension WeeklyNarrativePatterns on WeeklyNarrative {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _WeeklyNarrative value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _WeeklyNarrative() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _WeeklyNarrative value)  $default,){
final _that = this;
switch (_that) {
case _WeeklyNarrative():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _WeeklyNarrative value)?  $default,){
final _that = this;
switch (_that) {
case _WeeklyNarrative() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String summary,  List<String> highlights,  List<String> recommendations)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _WeeklyNarrative() when $default != null:
return $default(_that.summary,_that.highlights,_that.recommendations);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String summary,  List<String> highlights,  List<String> recommendations)  $default,) {final _that = this;
switch (_that) {
case _WeeklyNarrative():
return $default(_that.summary,_that.highlights,_that.recommendations);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String summary,  List<String> highlights,  List<String> recommendations)?  $default,) {final _that = this;
switch (_that) {
case _WeeklyNarrative() when $default != null:
return $default(_that.summary,_that.highlights,_that.recommendations);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _WeeklyNarrative implements WeeklyNarrative {
  const _WeeklyNarrative({this.summary = '', final  List<String> highlights = const [], final  List<String> recommendations = const []}): _highlights = highlights,_recommendations = recommendations;
  factory _WeeklyNarrative.fromJson(Map<String, dynamic> json) => _$WeeklyNarrativeFromJson(json);

@override@JsonKey() final  String summary;
 final  List<String> _highlights;
@override@JsonKey() List<String> get highlights {
  if (_highlights is EqualUnmodifiableListView) return _highlights;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_highlights);
}

 final  List<String> _recommendations;
@override@JsonKey() List<String> get recommendations {
  if (_recommendations is EqualUnmodifiableListView) return _recommendations;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_recommendations);
}


/// Create a copy of WeeklyNarrative
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$WeeklyNarrativeCopyWith<_WeeklyNarrative> get copyWith => __$WeeklyNarrativeCopyWithImpl<_WeeklyNarrative>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$WeeklyNarrativeToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _WeeklyNarrative&&(identical(other.summary, summary) || other.summary == summary)&&const DeepCollectionEquality().equals(other._highlights, _highlights)&&const DeepCollectionEquality().equals(other._recommendations, _recommendations));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,summary,const DeepCollectionEquality().hash(_highlights),const DeepCollectionEquality().hash(_recommendations));

@override
String toString() {
  return 'WeeklyNarrative(summary: $summary, highlights: $highlights, recommendations: $recommendations)';
}


}

/// @nodoc
abstract mixin class _$WeeklyNarrativeCopyWith<$Res> implements $WeeklyNarrativeCopyWith<$Res> {
  factory _$WeeklyNarrativeCopyWith(_WeeklyNarrative value, $Res Function(_WeeklyNarrative) _then) = __$WeeklyNarrativeCopyWithImpl;
@override @useResult
$Res call({
 String summary, List<String> highlights, List<String> recommendations
});




}
/// @nodoc
class __$WeeklyNarrativeCopyWithImpl<$Res>
    implements _$WeeklyNarrativeCopyWith<$Res> {
  __$WeeklyNarrativeCopyWithImpl(this._self, this._then);

  final _WeeklyNarrative _self;
  final $Res Function(_WeeklyNarrative) _then;

/// Create a copy of WeeklyNarrative
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? summary = null,Object? highlights = null,Object? recommendations = null,}) {
  return _then(_WeeklyNarrative(
summary: null == summary ? _self.summary : summary // ignore: cast_nullable_to_non_nullable
as String,highlights: null == highlights ? _self._highlights : highlights // ignore: cast_nullable_to_non_nullable
as List<String>,recommendations: null == recommendations ? _self._recommendations : recommendations // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}


}


/// @nodoc
mixin _$WeeklyReport {

 String get id; String? get weekStart; WeeklyMetrics get metrics;/// Null é normal: sem IA configurada o relatório vale pelos números.
 WeeklyNarrative? get narrative; String? get createdAt;
/// Create a copy of WeeklyReport
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$WeeklyReportCopyWith<WeeklyReport> get copyWith => _$WeeklyReportCopyWithImpl<WeeklyReport>(this as WeeklyReport, _$identity);

  /// Serializes this WeeklyReport to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WeeklyReport&&(identical(other.id, id) || other.id == id)&&(identical(other.weekStart, weekStart) || other.weekStart == weekStart)&&(identical(other.metrics, metrics) || other.metrics == metrics)&&(identical(other.narrative, narrative) || other.narrative == narrative)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,weekStart,metrics,narrative,createdAt);

@override
String toString() {
  return 'WeeklyReport(id: $id, weekStart: $weekStart, metrics: $metrics, narrative: $narrative, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class $WeeklyReportCopyWith<$Res>  {
  factory $WeeklyReportCopyWith(WeeklyReport value, $Res Function(WeeklyReport) _then) = _$WeeklyReportCopyWithImpl;
@useResult
$Res call({
 String id, String? weekStart, WeeklyMetrics metrics, WeeklyNarrative? narrative, String? createdAt
});


$WeeklyMetricsCopyWith<$Res> get metrics;$WeeklyNarrativeCopyWith<$Res>? get narrative;

}
/// @nodoc
class _$WeeklyReportCopyWithImpl<$Res>
    implements $WeeklyReportCopyWith<$Res> {
  _$WeeklyReportCopyWithImpl(this._self, this._then);

  final WeeklyReport _self;
  final $Res Function(WeeklyReport) _then;

/// Create a copy of WeeklyReport
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? weekStart = freezed,Object? metrics = null,Object? narrative = freezed,Object? createdAt = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,weekStart: freezed == weekStart ? _self.weekStart : weekStart // ignore: cast_nullable_to_non_nullable
as String?,metrics: null == metrics ? _self.metrics : metrics // ignore: cast_nullable_to_non_nullable
as WeeklyMetrics,narrative: freezed == narrative ? _self.narrative : narrative // ignore: cast_nullable_to_non_nullable
as WeeklyNarrative?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}
/// Create a copy of WeeklyReport
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$WeeklyMetricsCopyWith<$Res> get metrics {
  
  return $WeeklyMetricsCopyWith<$Res>(_self.metrics, (value) {
    return _then(_self.copyWith(metrics: value));
  });
}/// Create a copy of WeeklyReport
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$WeeklyNarrativeCopyWith<$Res>? get narrative {
    if (_self.narrative == null) {
    return null;
  }

  return $WeeklyNarrativeCopyWith<$Res>(_self.narrative!, (value) {
    return _then(_self.copyWith(narrative: value));
  });
}
}


/// Adds pattern-matching-related methods to [WeeklyReport].
extension WeeklyReportPatterns on WeeklyReport {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _WeeklyReport value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _WeeklyReport() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _WeeklyReport value)  $default,){
final _that = this;
switch (_that) {
case _WeeklyReport():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _WeeklyReport value)?  $default,){
final _that = this;
switch (_that) {
case _WeeklyReport() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String? weekStart,  WeeklyMetrics metrics,  WeeklyNarrative? narrative,  String? createdAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _WeeklyReport() when $default != null:
return $default(_that.id,_that.weekStart,_that.metrics,_that.narrative,_that.createdAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String? weekStart,  WeeklyMetrics metrics,  WeeklyNarrative? narrative,  String? createdAt)  $default,) {final _that = this;
switch (_that) {
case _WeeklyReport():
return $default(_that.id,_that.weekStart,_that.metrics,_that.narrative,_that.createdAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String? weekStart,  WeeklyMetrics metrics,  WeeklyNarrative? narrative,  String? createdAt)?  $default,) {final _that = this;
switch (_that) {
case _WeeklyReport() when $default != null:
return $default(_that.id,_that.weekStart,_that.metrics,_that.narrative,_that.createdAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _WeeklyReport implements WeeklyReport {
  const _WeeklyReport({required this.id, this.weekStart, this.metrics = const WeeklyMetrics(), this.narrative, this.createdAt});
  factory _WeeklyReport.fromJson(Map<String, dynamic> json) => _$WeeklyReportFromJson(json);

@override final  String id;
@override final  String? weekStart;
@override@JsonKey() final  WeeklyMetrics metrics;
/// Null é normal: sem IA configurada o relatório vale pelos números.
@override final  WeeklyNarrative? narrative;
@override final  String? createdAt;

/// Create a copy of WeeklyReport
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$WeeklyReportCopyWith<_WeeklyReport> get copyWith => __$WeeklyReportCopyWithImpl<_WeeklyReport>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$WeeklyReportToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _WeeklyReport&&(identical(other.id, id) || other.id == id)&&(identical(other.weekStart, weekStart) || other.weekStart == weekStart)&&(identical(other.metrics, metrics) || other.metrics == metrics)&&(identical(other.narrative, narrative) || other.narrative == narrative)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,weekStart,metrics,narrative,createdAt);

@override
String toString() {
  return 'WeeklyReport(id: $id, weekStart: $weekStart, metrics: $metrics, narrative: $narrative, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class _$WeeklyReportCopyWith<$Res> implements $WeeklyReportCopyWith<$Res> {
  factory _$WeeklyReportCopyWith(_WeeklyReport value, $Res Function(_WeeklyReport) _then) = __$WeeklyReportCopyWithImpl;
@override @useResult
$Res call({
 String id, String? weekStart, WeeklyMetrics metrics, WeeklyNarrative? narrative, String? createdAt
});


@override $WeeklyMetricsCopyWith<$Res> get metrics;@override $WeeklyNarrativeCopyWith<$Res>? get narrative;

}
/// @nodoc
class __$WeeklyReportCopyWithImpl<$Res>
    implements _$WeeklyReportCopyWith<$Res> {
  __$WeeklyReportCopyWithImpl(this._self, this._then);

  final _WeeklyReport _self;
  final $Res Function(_WeeklyReport) _then;

/// Create a copy of WeeklyReport
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? weekStart = freezed,Object? metrics = null,Object? narrative = freezed,Object? createdAt = freezed,}) {
  return _then(_WeeklyReport(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,weekStart: freezed == weekStart ? _self.weekStart : weekStart // ignore: cast_nullable_to_non_nullable
as String?,metrics: null == metrics ? _self.metrics : metrics // ignore: cast_nullable_to_non_nullable
as WeeklyMetrics,narrative: freezed == narrative ? _self.narrative : narrative // ignore: cast_nullable_to_non_nullable
as WeeklyNarrative?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

/// Create a copy of WeeklyReport
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$WeeklyMetricsCopyWith<$Res> get metrics {
  
  return $WeeklyMetricsCopyWith<$Res>(_self.metrics, (value) {
    return _then(_self.copyWith(metrics: value));
  });
}/// Create a copy of WeeklyReport
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$WeeklyNarrativeCopyWith<$Res>? get narrative {
    if (_self.narrative == null) {
    return null;
  }

  return $WeeklyNarrativeCopyWith<$Res>(_self.narrative!, (value) {
    return _then(_self.copyWith(narrative: value));
  });
}
}

// dart format on
