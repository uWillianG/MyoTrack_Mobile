// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'video_models.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$VideoExerciseOption {

 String get slug; String get label;
/// Create a copy of VideoExerciseOption
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$VideoExerciseOptionCopyWith<VideoExerciseOption> get copyWith => _$VideoExerciseOptionCopyWithImpl<VideoExerciseOption>(this as VideoExerciseOption, _$identity);

  /// Serializes this VideoExerciseOption to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is VideoExerciseOption&&(identical(other.slug, slug) || other.slug == slug)&&(identical(other.label, label) || other.label == label));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,slug,label);

@override
String toString() {
  return 'VideoExerciseOption(slug: $slug, label: $label)';
}


}

/// @nodoc
abstract mixin class $VideoExerciseOptionCopyWith<$Res>  {
  factory $VideoExerciseOptionCopyWith(VideoExerciseOption value, $Res Function(VideoExerciseOption) _then) = _$VideoExerciseOptionCopyWithImpl;
@useResult
$Res call({
 String slug, String label
});




}
/// @nodoc
class _$VideoExerciseOptionCopyWithImpl<$Res>
    implements $VideoExerciseOptionCopyWith<$Res> {
  _$VideoExerciseOptionCopyWithImpl(this._self, this._then);

  final VideoExerciseOption _self;
  final $Res Function(VideoExerciseOption) _then;

/// Create a copy of VideoExerciseOption
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? slug = null,Object? label = null,}) {
  return _then(_self.copyWith(
slug: null == slug ? _self.slug : slug // ignore: cast_nullable_to_non_nullable
as String,label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [VideoExerciseOption].
extension VideoExerciseOptionPatterns on VideoExerciseOption {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _VideoExerciseOption value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _VideoExerciseOption() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _VideoExerciseOption value)  $default,){
final _that = this;
switch (_that) {
case _VideoExerciseOption():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _VideoExerciseOption value)?  $default,){
final _that = this;
switch (_that) {
case _VideoExerciseOption() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String slug,  String label)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _VideoExerciseOption() when $default != null:
return $default(_that.slug,_that.label);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String slug,  String label)  $default,) {final _that = this;
switch (_that) {
case _VideoExerciseOption():
return $default(_that.slug,_that.label);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String slug,  String label)?  $default,) {final _that = this;
switch (_that) {
case _VideoExerciseOption() when $default != null:
return $default(_that.slug,_that.label);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _VideoExerciseOption implements VideoExerciseOption {
  const _VideoExerciseOption({required this.slug, required this.label});
  factory _VideoExerciseOption.fromJson(Map<String, dynamic> json) => _$VideoExerciseOptionFromJson(json);

@override final  String slug;
@override final  String label;

/// Create a copy of VideoExerciseOption
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$VideoExerciseOptionCopyWith<_VideoExerciseOption> get copyWith => __$VideoExerciseOptionCopyWithImpl<_VideoExerciseOption>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$VideoExerciseOptionToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _VideoExerciseOption&&(identical(other.slug, slug) || other.slug == slug)&&(identical(other.label, label) || other.label == label));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,slug,label);

@override
String toString() {
  return 'VideoExerciseOption(slug: $slug, label: $label)';
}


}

/// @nodoc
abstract mixin class _$VideoExerciseOptionCopyWith<$Res> implements $VideoExerciseOptionCopyWith<$Res> {
  factory _$VideoExerciseOptionCopyWith(_VideoExerciseOption value, $Res Function(_VideoExerciseOption) _then) = __$VideoExerciseOptionCopyWithImpl;
@override @useResult
$Res call({
 String slug, String label
});




}
/// @nodoc
class __$VideoExerciseOptionCopyWithImpl<$Res>
    implements _$VideoExerciseOptionCopyWith<$Res> {
  __$VideoExerciseOptionCopyWithImpl(this._self, this._then);

  final _VideoExerciseOption _self;
  final $Res Function(_VideoExerciseOption) _then;

/// Create a copy of VideoExerciseOption
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? slug = null,Object? label = null,}) {
  return _then(_VideoExerciseOption(
slug: null == slug ? _self.slug : slug // ignore: cast_nullable_to_non_nullable
as String,label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$VideoIssue {

 String get code; String get message; List<double> get timestampsSec;
/// Create a copy of VideoIssue
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$VideoIssueCopyWith<VideoIssue> get copyWith => _$VideoIssueCopyWithImpl<VideoIssue>(this as VideoIssue, _$identity);

  /// Serializes this VideoIssue to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is VideoIssue&&(identical(other.code, code) || other.code == code)&&(identical(other.message, message) || other.message == message)&&const DeepCollectionEquality().equals(other.timestampsSec, timestampsSec));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,code,message,const DeepCollectionEquality().hash(timestampsSec));

@override
String toString() {
  return 'VideoIssue(code: $code, message: $message, timestampsSec: $timestampsSec)';
}


}

/// @nodoc
abstract mixin class $VideoIssueCopyWith<$Res>  {
  factory $VideoIssueCopyWith(VideoIssue value, $Res Function(VideoIssue) _then) = _$VideoIssueCopyWithImpl;
@useResult
$Res call({
 String code, String message, List<double> timestampsSec
});




}
/// @nodoc
class _$VideoIssueCopyWithImpl<$Res>
    implements $VideoIssueCopyWith<$Res> {
  _$VideoIssueCopyWithImpl(this._self, this._then);

  final VideoIssue _self;
  final $Res Function(VideoIssue) _then;

/// Create a copy of VideoIssue
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? code = null,Object? message = null,Object? timestampsSec = null,}) {
  return _then(_self.copyWith(
code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as String,message: null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,timestampsSec: null == timestampsSec ? _self.timestampsSec : timestampsSec // ignore: cast_nullable_to_non_nullable
as List<double>,
  ));
}

}


/// Adds pattern-matching-related methods to [VideoIssue].
extension VideoIssuePatterns on VideoIssue {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _VideoIssue value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _VideoIssue() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _VideoIssue value)  $default,){
final _that = this;
switch (_that) {
case _VideoIssue():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _VideoIssue value)?  $default,){
final _that = this;
switch (_that) {
case _VideoIssue() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String code,  String message,  List<double> timestampsSec)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _VideoIssue() when $default != null:
return $default(_that.code,_that.message,_that.timestampsSec);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String code,  String message,  List<double> timestampsSec)  $default,) {final _that = this;
switch (_that) {
case _VideoIssue():
return $default(_that.code,_that.message,_that.timestampsSec);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String code,  String message,  List<double> timestampsSec)?  $default,) {final _that = this;
switch (_that) {
case _VideoIssue() when $default != null:
return $default(_that.code,_that.message,_that.timestampsSec);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _VideoIssue implements VideoIssue {
  const _VideoIssue({this.code = '', this.message = '', final  List<double> timestampsSec = const []}): _timestampsSec = timestampsSec;
  factory _VideoIssue.fromJson(Map<String, dynamic> json) => _$VideoIssueFromJson(json);

@override@JsonKey() final  String code;
@override@JsonKey() final  String message;
 final  List<double> _timestampsSec;
@override@JsonKey() List<double> get timestampsSec {
  if (_timestampsSec is EqualUnmodifiableListView) return _timestampsSec;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_timestampsSec);
}


/// Create a copy of VideoIssue
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$VideoIssueCopyWith<_VideoIssue> get copyWith => __$VideoIssueCopyWithImpl<_VideoIssue>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$VideoIssueToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _VideoIssue&&(identical(other.code, code) || other.code == code)&&(identical(other.message, message) || other.message == message)&&const DeepCollectionEquality().equals(other._timestampsSec, _timestampsSec));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,code,message,const DeepCollectionEquality().hash(_timestampsSec));

@override
String toString() {
  return 'VideoIssue(code: $code, message: $message, timestampsSec: $timestampsSec)';
}


}

/// @nodoc
abstract mixin class _$VideoIssueCopyWith<$Res> implements $VideoIssueCopyWith<$Res> {
  factory _$VideoIssueCopyWith(_VideoIssue value, $Res Function(_VideoIssue) _then) = __$VideoIssueCopyWithImpl;
@override @useResult
$Res call({
 String code, String message, List<double> timestampsSec
});




}
/// @nodoc
class __$VideoIssueCopyWithImpl<$Res>
    implements _$VideoIssueCopyWith<$Res> {
  __$VideoIssueCopyWithImpl(this._self, this._then);

  final _VideoIssue _self;
  final $Res Function(_VideoIssue) _then;

/// Create a copy of VideoIssue
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? code = null,Object? message = null,Object? timestampsSec = null,}) {
  return _then(_VideoIssue(
code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as String,message: null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,timestampsSec: null == timestampsSec ? _self._timestampsSec : timestampsSec // ignore: cast_nullable_to_non_nullable
as List<double>,
  ));
}


}


/// @nodoc
mixin _$VideoCorrectPoint {

 String get code; String get message;
/// Create a copy of VideoCorrectPoint
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$VideoCorrectPointCopyWith<VideoCorrectPoint> get copyWith => _$VideoCorrectPointCopyWithImpl<VideoCorrectPoint>(this as VideoCorrectPoint, _$identity);

  /// Serializes this VideoCorrectPoint to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is VideoCorrectPoint&&(identical(other.code, code) || other.code == code)&&(identical(other.message, message) || other.message == message));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,code,message);

@override
String toString() {
  return 'VideoCorrectPoint(code: $code, message: $message)';
}


}

/// @nodoc
abstract mixin class $VideoCorrectPointCopyWith<$Res>  {
  factory $VideoCorrectPointCopyWith(VideoCorrectPoint value, $Res Function(VideoCorrectPoint) _then) = _$VideoCorrectPointCopyWithImpl;
@useResult
$Res call({
 String code, String message
});




}
/// @nodoc
class _$VideoCorrectPointCopyWithImpl<$Res>
    implements $VideoCorrectPointCopyWith<$Res> {
  _$VideoCorrectPointCopyWithImpl(this._self, this._then);

  final VideoCorrectPoint _self;
  final $Res Function(VideoCorrectPoint) _then;

/// Create a copy of VideoCorrectPoint
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? code = null,Object? message = null,}) {
  return _then(_self.copyWith(
code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as String,message: null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [VideoCorrectPoint].
extension VideoCorrectPointPatterns on VideoCorrectPoint {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _VideoCorrectPoint value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _VideoCorrectPoint() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _VideoCorrectPoint value)  $default,){
final _that = this;
switch (_that) {
case _VideoCorrectPoint():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _VideoCorrectPoint value)?  $default,){
final _that = this;
switch (_that) {
case _VideoCorrectPoint() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String code,  String message)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _VideoCorrectPoint() when $default != null:
return $default(_that.code,_that.message);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String code,  String message)  $default,) {final _that = this;
switch (_that) {
case _VideoCorrectPoint():
return $default(_that.code,_that.message);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String code,  String message)?  $default,) {final _that = this;
switch (_that) {
case _VideoCorrectPoint() when $default != null:
return $default(_that.code,_that.message);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _VideoCorrectPoint implements VideoCorrectPoint {
  const _VideoCorrectPoint({this.code = '', this.message = ''});
  factory _VideoCorrectPoint.fromJson(Map<String, dynamic> json) => _$VideoCorrectPointFromJson(json);

@override@JsonKey() final  String code;
@override@JsonKey() final  String message;

/// Create a copy of VideoCorrectPoint
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$VideoCorrectPointCopyWith<_VideoCorrectPoint> get copyWith => __$VideoCorrectPointCopyWithImpl<_VideoCorrectPoint>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$VideoCorrectPointToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _VideoCorrectPoint&&(identical(other.code, code) || other.code == code)&&(identical(other.message, message) || other.message == message));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,code,message);

@override
String toString() {
  return 'VideoCorrectPoint(code: $code, message: $message)';
}


}

/// @nodoc
abstract mixin class _$VideoCorrectPointCopyWith<$Res> implements $VideoCorrectPointCopyWith<$Res> {
  factory _$VideoCorrectPointCopyWith(_VideoCorrectPoint value, $Res Function(_VideoCorrectPoint) _then) = __$VideoCorrectPointCopyWithImpl;
@override @useResult
$Res call({
 String code, String message
});




}
/// @nodoc
class __$VideoCorrectPointCopyWithImpl<$Res>
    implements _$VideoCorrectPointCopyWith<$Res> {
  __$VideoCorrectPointCopyWithImpl(this._self, this._then);

  final _VideoCorrectPoint _self;
  final $Res Function(_VideoCorrectPoint) _then;

/// Create a copy of VideoCorrectPoint
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? code = null,Object? message = null,}) {
  return _then(_VideoCorrectPoint(
code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as String,message: null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$VideoResult {

 List<VideoIssue> get issues; List<VideoCorrectPoint> get correctPoints;/// Métricas brutas do serviço (ângulos, duração, cobertura da pose). Ficam como mapa
/// porque as heurísticas evoluem, e um campo novo não deve exigir versão nova do app.
 Map<String, dynamic> get metrics;/// Preenchido quando não deu para avaliar — vídeo tremido, corpo cortado, luz ruim.
 String? get notEvaluableReason;
/// Create a copy of VideoResult
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$VideoResultCopyWith<VideoResult> get copyWith => _$VideoResultCopyWithImpl<VideoResult>(this as VideoResult, _$identity);

  /// Serializes this VideoResult to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is VideoResult&&const DeepCollectionEquality().equals(other.issues, issues)&&const DeepCollectionEquality().equals(other.correctPoints, correctPoints)&&const DeepCollectionEquality().equals(other.metrics, metrics)&&(identical(other.notEvaluableReason, notEvaluableReason) || other.notEvaluableReason == notEvaluableReason));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(issues),const DeepCollectionEquality().hash(correctPoints),const DeepCollectionEquality().hash(metrics),notEvaluableReason);

@override
String toString() {
  return 'VideoResult(issues: $issues, correctPoints: $correctPoints, metrics: $metrics, notEvaluableReason: $notEvaluableReason)';
}


}

/// @nodoc
abstract mixin class $VideoResultCopyWith<$Res>  {
  factory $VideoResultCopyWith(VideoResult value, $Res Function(VideoResult) _then) = _$VideoResultCopyWithImpl;
@useResult
$Res call({
 List<VideoIssue> issues, List<VideoCorrectPoint> correctPoints, Map<String, dynamic> metrics, String? notEvaluableReason
});




}
/// @nodoc
class _$VideoResultCopyWithImpl<$Res>
    implements $VideoResultCopyWith<$Res> {
  _$VideoResultCopyWithImpl(this._self, this._then);

  final VideoResult _self;
  final $Res Function(VideoResult) _then;

/// Create a copy of VideoResult
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? issues = null,Object? correctPoints = null,Object? metrics = null,Object? notEvaluableReason = freezed,}) {
  return _then(_self.copyWith(
issues: null == issues ? _self.issues : issues // ignore: cast_nullable_to_non_nullable
as List<VideoIssue>,correctPoints: null == correctPoints ? _self.correctPoints : correctPoints // ignore: cast_nullable_to_non_nullable
as List<VideoCorrectPoint>,metrics: null == metrics ? _self.metrics : metrics // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,notEvaluableReason: freezed == notEvaluableReason ? _self.notEvaluableReason : notEvaluableReason // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [VideoResult].
extension VideoResultPatterns on VideoResult {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _VideoResult value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _VideoResult() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _VideoResult value)  $default,){
final _that = this;
switch (_that) {
case _VideoResult():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _VideoResult value)?  $default,){
final _that = this;
switch (_that) {
case _VideoResult() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<VideoIssue> issues,  List<VideoCorrectPoint> correctPoints,  Map<String, dynamic> metrics,  String? notEvaluableReason)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _VideoResult() when $default != null:
return $default(_that.issues,_that.correctPoints,_that.metrics,_that.notEvaluableReason);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<VideoIssue> issues,  List<VideoCorrectPoint> correctPoints,  Map<String, dynamic> metrics,  String? notEvaluableReason)  $default,) {final _that = this;
switch (_that) {
case _VideoResult():
return $default(_that.issues,_that.correctPoints,_that.metrics,_that.notEvaluableReason);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<VideoIssue> issues,  List<VideoCorrectPoint> correctPoints,  Map<String, dynamic> metrics,  String? notEvaluableReason)?  $default,) {final _that = this;
switch (_that) {
case _VideoResult() when $default != null:
return $default(_that.issues,_that.correctPoints,_that.metrics,_that.notEvaluableReason);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _VideoResult implements VideoResult {
  const _VideoResult({final  List<VideoIssue> issues = const [], final  List<VideoCorrectPoint> correctPoints = const [], final  Map<String, dynamic> metrics = const {}, this.notEvaluableReason}): _issues = issues,_correctPoints = correctPoints,_metrics = metrics;
  factory _VideoResult.fromJson(Map<String, dynamic> json) => _$VideoResultFromJson(json);

 final  List<VideoIssue> _issues;
@override@JsonKey() List<VideoIssue> get issues {
  if (_issues is EqualUnmodifiableListView) return _issues;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_issues);
}

 final  List<VideoCorrectPoint> _correctPoints;
@override@JsonKey() List<VideoCorrectPoint> get correctPoints {
  if (_correctPoints is EqualUnmodifiableListView) return _correctPoints;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_correctPoints);
}

/// Métricas brutas do serviço (ângulos, duração, cobertura da pose). Ficam como mapa
/// porque as heurísticas evoluem, e um campo novo não deve exigir versão nova do app.
 final  Map<String, dynamic> _metrics;
/// Métricas brutas do serviço (ângulos, duração, cobertura da pose). Ficam como mapa
/// porque as heurísticas evoluem, e um campo novo não deve exigir versão nova do app.
@override@JsonKey() Map<String, dynamic> get metrics {
  if (_metrics is EqualUnmodifiableMapView) return _metrics;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_metrics);
}

/// Preenchido quando não deu para avaliar — vídeo tremido, corpo cortado, luz ruim.
@override final  String? notEvaluableReason;

/// Create a copy of VideoResult
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$VideoResultCopyWith<_VideoResult> get copyWith => __$VideoResultCopyWithImpl<_VideoResult>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$VideoResultToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _VideoResult&&const DeepCollectionEquality().equals(other._issues, _issues)&&const DeepCollectionEquality().equals(other._correctPoints, _correctPoints)&&const DeepCollectionEquality().equals(other._metrics, _metrics)&&(identical(other.notEvaluableReason, notEvaluableReason) || other.notEvaluableReason == notEvaluableReason));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_issues),const DeepCollectionEquality().hash(_correctPoints),const DeepCollectionEquality().hash(_metrics),notEvaluableReason);

@override
String toString() {
  return 'VideoResult(issues: $issues, correctPoints: $correctPoints, metrics: $metrics, notEvaluableReason: $notEvaluableReason)';
}


}

/// @nodoc
abstract mixin class _$VideoResultCopyWith<$Res> implements $VideoResultCopyWith<$Res> {
  factory _$VideoResultCopyWith(_VideoResult value, $Res Function(_VideoResult) _then) = __$VideoResultCopyWithImpl;
@override @useResult
$Res call({
 List<VideoIssue> issues, List<VideoCorrectPoint> correctPoints, Map<String, dynamic> metrics, String? notEvaluableReason
});




}
/// @nodoc
class __$VideoResultCopyWithImpl<$Res>
    implements _$VideoResultCopyWith<$Res> {
  __$VideoResultCopyWithImpl(this._self, this._then);

  final _VideoResult _self;
  final $Res Function(_VideoResult) _then;

/// Create a copy of VideoResult
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? issues = null,Object? correctPoints = null,Object? metrics = null,Object? notEvaluableReason = freezed,}) {
  return _then(_VideoResult(
issues: null == issues ? _self._issues : issues // ignore: cast_nullable_to_non_nullable
as List<VideoIssue>,correctPoints: null == correctPoints ? _self._correctPoints : correctPoints // ignore: cast_nullable_to_non_nullable
as List<VideoCorrectPoint>,metrics: null == metrics ? _self._metrics : metrics // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,notEvaluableReason: freezed == notEvaluableReason ? _self.notEvaluableReason : notEvaluableReason // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$VideoAnalysis {

 String get id; String? get analysisJobId; String get analyzedExercise;/// 0–100, ou null quando a pose não pôde ser avaliada com confiança. Null **não** é zero:
/// zero seria uma execução péssima, que é uma afirmação bem diferente.
 int? get score; int get repCount; VideoResult get result;/// URLs temporárias; null depois de a retenção apagar a mídia.
 String? get videoUrl; String? get overlayVideoUrl; String? get createdAt;
/// Create a copy of VideoAnalysis
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$VideoAnalysisCopyWith<VideoAnalysis> get copyWith => _$VideoAnalysisCopyWithImpl<VideoAnalysis>(this as VideoAnalysis, _$identity);

  /// Serializes this VideoAnalysis to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is VideoAnalysis&&(identical(other.id, id) || other.id == id)&&(identical(other.analysisJobId, analysisJobId) || other.analysisJobId == analysisJobId)&&(identical(other.analyzedExercise, analyzedExercise) || other.analyzedExercise == analyzedExercise)&&(identical(other.score, score) || other.score == score)&&(identical(other.repCount, repCount) || other.repCount == repCount)&&(identical(other.result, result) || other.result == result)&&(identical(other.videoUrl, videoUrl) || other.videoUrl == videoUrl)&&(identical(other.overlayVideoUrl, overlayVideoUrl) || other.overlayVideoUrl == overlayVideoUrl)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,analysisJobId,analyzedExercise,score,repCount,result,videoUrl,overlayVideoUrl,createdAt);

@override
String toString() {
  return 'VideoAnalysis(id: $id, analysisJobId: $analysisJobId, analyzedExercise: $analyzedExercise, score: $score, repCount: $repCount, result: $result, videoUrl: $videoUrl, overlayVideoUrl: $overlayVideoUrl, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class $VideoAnalysisCopyWith<$Res>  {
  factory $VideoAnalysisCopyWith(VideoAnalysis value, $Res Function(VideoAnalysis) _then) = _$VideoAnalysisCopyWithImpl;
@useResult
$Res call({
 String id, String? analysisJobId, String analyzedExercise, int? score, int repCount, VideoResult result, String? videoUrl, String? overlayVideoUrl, String? createdAt
});


$VideoResultCopyWith<$Res> get result;

}
/// @nodoc
class _$VideoAnalysisCopyWithImpl<$Res>
    implements $VideoAnalysisCopyWith<$Res> {
  _$VideoAnalysisCopyWithImpl(this._self, this._then);

  final VideoAnalysis _self;
  final $Res Function(VideoAnalysis) _then;

/// Create a copy of VideoAnalysis
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? analysisJobId = freezed,Object? analyzedExercise = null,Object? score = freezed,Object? repCount = null,Object? result = null,Object? videoUrl = freezed,Object? overlayVideoUrl = freezed,Object? createdAt = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,analysisJobId: freezed == analysisJobId ? _self.analysisJobId : analysisJobId // ignore: cast_nullable_to_non_nullable
as String?,analyzedExercise: null == analyzedExercise ? _self.analyzedExercise : analyzedExercise // ignore: cast_nullable_to_non_nullable
as String,score: freezed == score ? _self.score : score // ignore: cast_nullable_to_non_nullable
as int?,repCount: null == repCount ? _self.repCount : repCount // ignore: cast_nullable_to_non_nullable
as int,result: null == result ? _self.result : result // ignore: cast_nullable_to_non_nullable
as VideoResult,videoUrl: freezed == videoUrl ? _self.videoUrl : videoUrl // ignore: cast_nullable_to_non_nullable
as String?,overlayVideoUrl: freezed == overlayVideoUrl ? _self.overlayVideoUrl : overlayVideoUrl // ignore: cast_nullable_to_non_nullable
as String?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}
/// Create a copy of VideoAnalysis
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$VideoResultCopyWith<$Res> get result {
  
  return $VideoResultCopyWith<$Res>(_self.result, (value) {
    return _then(_self.copyWith(result: value));
  });
}
}


/// Adds pattern-matching-related methods to [VideoAnalysis].
extension VideoAnalysisPatterns on VideoAnalysis {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _VideoAnalysis value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _VideoAnalysis() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _VideoAnalysis value)  $default,){
final _that = this;
switch (_that) {
case _VideoAnalysis():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _VideoAnalysis value)?  $default,){
final _that = this;
switch (_that) {
case _VideoAnalysis() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String? analysisJobId,  String analyzedExercise,  int? score,  int repCount,  VideoResult result,  String? videoUrl,  String? overlayVideoUrl,  String? createdAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _VideoAnalysis() when $default != null:
return $default(_that.id,_that.analysisJobId,_that.analyzedExercise,_that.score,_that.repCount,_that.result,_that.videoUrl,_that.overlayVideoUrl,_that.createdAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String? analysisJobId,  String analyzedExercise,  int? score,  int repCount,  VideoResult result,  String? videoUrl,  String? overlayVideoUrl,  String? createdAt)  $default,) {final _that = this;
switch (_that) {
case _VideoAnalysis():
return $default(_that.id,_that.analysisJobId,_that.analyzedExercise,_that.score,_that.repCount,_that.result,_that.videoUrl,_that.overlayVideoUrl,_that.createdAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String? analysisJobId,  String analyzedExercise,  int? score,  int repCount,  VideoResult result,  String? videoUrl,  String? overlayVideoUrl,  String? createdAt)?  $default,) {final _that = this;
switch (_that) {
case _VideoAnalysis() when $default != null:
return $default(_that.id,_that.analysisJobId,_that.analyzedExercise,_that.score,_that.repCount,_that.result,_that.videoUrl,_that.overlayVideoUrl,_that.createdAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _VideoAnalysis implements VideoAnalysis {
  const _VideoAnalysis({required this.id, this.analysisJobId, this.analyzedExercise = '', this.score, this.repCount = 0, this.result = const VideoResult(), this.videoUrl, this.overlayVideoUrl, this.createdAt});
  factory _VideoAnalysis.fromJson(Map<String, dynamic> json) => _$VideoAnalysisFromJson(json);

@override final  String id;
@override final  String? analysisJobId;
@override@JsonKey() final  String analyzedExercise;
/// 0–100, ou null quando a pose não pôde ser avaliada com confiança. Null **não** é zero:
/// zero seria uma execução péssima, que é uma afirmação bem diferente.
@override final  int? score;
@override@JsonKey() final  int repCount;
@override@JsonKey() final  VideoResult result;
/// URLs temporárias; null depois de a retenção apagar a mídia.
@override final  String? videoUrl;
@override final  String? overlayVideoUrl;
@override final  String? createdAt;

/// Create a copy of VideoAnalysis
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$VideoAnalysisCopyWith<_VideoAnalysis> get copyWith => __$VideoAnalysisCopyWithImpl<_VideoAnalysis>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$VideoAnalysisToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _VideoAnalysis&&(identical(other.id, id) || other.id == id)&&(identical(other.analysisJobId, analysisJobId) || other.analysisJobId == analysisJobId)&&(identical(other.analyzedExercise, analyzedExercise) || other.analyzedExercise == analyzedExercise)&&(identical(other.score, score) || other.score == score)&&(identical(other.repCount, repCount) || other.repCount == repCount)&&(identical(other.result, result) || other.result == result)&&(identical(other.videoUrl, videoUrl) || other.videoUrl == videoUrl)&&(identical(other.overlayVideoUrl, overlayVideoUrl) || other.overlayVideoUrl == overlayVideoUrl)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,analysisJobId,analyzedExercise,score,repCount,result,videoUrl,overlayVideoUrl,createdAt);

@override
String toString() {
  return 'VideoAnalysis(id: $id, analysisJobId: $analysisJobId, analyzedExercise: $analyzedExercise, score: $score, repCount: $repCount, result: $result, videoUrl: $videoUrl, overlayVideoUrl: $overlayVideoUrl, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class _$VideoAnalysisCopyWith<$Res> implements $VideoAnalysisCopyWith<$Res> {
  factory _$VideoAnalysisCopyWith(_VideoAnalysis value, $Res Function(_VideoAnalysis) _then) = __$VideoAnalysisCopyWithImpl;
@override @useResult
$Res call({
 String id, String? analysisJobId, String analyzedExercise, int? score, int repCount, VideoResult result, String? videoUrl, String? overlayVideoUrl, String? createdAt
});


@override $VideoResultCopyWith<$Res> get result;

}
/// @nodoc
class __$VideoAnalysisCopyWithImpl<$Res>
    implements _$VideoAnalysisCopyWith<$Res> {
  __$VideoAnalysisCopyWithImpl(this._self, this._then);

  final _VideoAnalysis _self;
  final $Res Function(_VideoAnalysis) _then;

/// Create a copy of VideoAnalysis
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? analysisJobId = freezed,Object? analyzedExercise = null,Object? score = freezed,Object? repCount = null,Object? result = null,Object? videoUrl = freezed,Object? overlayVideoUrl = freezed,Object? createdAt = freezed,}) {
  return _then(_VideoAnalysis(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,analysisJobId: freezed == analysisJobId ? _self.analysisJobId : analysisJobId // ignore: cast_nullable_to_non_nullable
as String?,analyzedExercise: null == analyzedExercise ? _self.analyzedExercise : analyzedExercise // ignore: cast_nullable_to_non_nullable
as String,score: freezed == score ? _self.score : score // ignore: cast_nullable_to_non_nullable
as int?,repCount: null == repCount ? _self.repCount : repCount // ignore: cast_nullable_to_non_nullable
as int,result: null == result ? _self.result : result // ignore: cast_nullable_to_non_nullable
as VideoResult,videoUrl: freezed == videoUrl ? _self.videoUrl : videoUrl // ignore: cast_nullable_to_non_nullable
as String?,overlayVideoUrl: freezed == overlayVideoUrl ? _self.overlayVideoUrl : overlayVideoUrl // ignore: cast_nullable_to_non_nullable
as String?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

/// Create a copy of VideoAnalysis
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$VideoResultCopyWith<$Res> get result {
  
  return $VideoResultCopyWith<$Res>(_self.result, (value) {
    return _then(_self.copyWith(result: value));
  });
}
}


/// @nodoc
mixin _$VideoUploadTicket {

 String get mediaKey; String get uploadUrl; int get expiresInSeconds;
/// Create a copy of VideoUploadTicket
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$VideoUploadTicketCopyWith<VideoUploadTicket> get copyWith => _$VideoUploadTicketCopyWithImpl<VideoUploadTicket>(this as VideoUploadTicket, _$identity);

  /// Serializes this VideoUploadTicket to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is VideoUploadTicket&&(identical(other.mediaKey, mediaKey) || other.mediaKey == mediaKey)&&(identical(other.uploadUrl, uploadUrl) || other.uploadUrl == uploadUrl)&&(identical(other.expiresInSeconds, expiresInSeconds) || other.expiresInSeconds == expiresInSeconds));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,mediaKey,uploadUrl,expiresInSeconds);

@override
String toString() {
  return 'VideoUploadTicket(mediaKey: $mediaKey, uploadUrl: $uploadUrl, expiresInSeconds: $expiresInSeconds)';
}


}

/// @nodoc
abstract mixin class $VideoUploadTicketCopyWith<$Res>  {
  factory $VideoUploadTicketCopyWith(VideoUploadTicket value, $Res Function(VideoUploadTicket) _then) = _$VideoUploadTicketCopyWithImpl;
@useResult
$Res call({
 String mediaKey, String uploadUrl, int expiresInSeconds
});




}
/// @nodoc
class _$VideoUploadTicketCopyWithImpl<$Res>
    implements $VideoUploadTicketCopyWith<$Res> {
  _$VideoUploadTicketCopyWithImpl(this._self, this._then);

  final VideoUploadTicket _self;
  final $Res Function(VideoUploadTicket) _then;

/// Create a copy of VideoUploadTicket
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? mediaKey = null,Object? uploadUrl = null,Object? expiresInSeconds = null,}) {
  return _then(_self.copyWith(
mediaKey: null == mediaKey ? _self.mediaKey : mediaKey // ignore: cast_nullable_to_non_nullable
as String,uploadUrl: null == uploadUrl ? _self.uploadUrl : uploadUrl // ignore: cast_nullable_to_non_nullable
as String,expiresInSeconds: null == expiresInSeconds ? _self.expiresInSeconds : expiresInSeconds // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [VideoUploadTicket].
extension VideoUploadTicketPatterns on VideoUploadTicket {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _VideoUploadTicket value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _VideoUploadTicket() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _VideoUploadTicket value)  $default,){
final _that = this;
switch (_that) {
case _VideoUploadTicket():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _VideoUploadTicket value)?  $default,){
final _that = this;
switch (_that) {
case _VideoUploadTicket() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String mediaKey,  String uploadUrl,  int expiresInSeconds)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _VideoUploadTicket() when $default != null:
return $default(_that.mediaKey,_that.uploadUrl,_that.expiresInSeconds);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String mediaKey,  String uploadUrl,  int expiresInSeconds)  $default,) {final _that = this;
switch (_that) {
case _VideoUploadTicket():
return $default(_that.mediaKey,_that.uploadUrl,_that.expiresInSeconds);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String mediaKey,  String uploadUrl,  int expiresInSeconds)?  $default,) {final _that = this;
switch (_that) {
case _VideoUploadTicket() when $default != null:
return $default(_that.mediaKey,_that.uploadUrl,_that.expiresInSeconds);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _VideoUploadTicket implements VideoUploadTicket {
  const _VideoUploadTicket({required this.mediaKey, required this.uploadUrl, this.expiresInSeconds = 0});
  factory _VideoUploadTicket.fromJson(Map<String, dynamic> json) => _$VideoUploadTicketFromJson(json);

@override final  String mediaKey;
@override final  String uploadUrl;
@override@JsonKey() final  int expiresInSeconds;

/// Create a copy of VideoUploadTicket
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$VideoUploadTicketCopyWith<_VideoUploadTicket> get copyWith => __$VideoUploadTicketCopyWithImpl<_VideoUploadTicket>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$VideoUploadTicketToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _VideoUploadTicket&&(identical(other.mediaKey, mediaKey) || other.mediaKey == mediaKey)&&(identical(other.uploadUrl, uploadUrl) || other.uploadUrl == uploadUrl)&&(identical(other.expiresInSeconds, expiresInSeconds) || other.expiresInSeconds == expiresInSeconds));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,mediaKey,uploadUrl,expiresInSeconds);

@override
String toString() {
  return 'VideoUploadTicket(mediaKey: $mediaKey, uploadUrl: $uploadUrl, expiresInSeconds: $expiresInSeconds)';
}


}

/// @nodoc
abstract mixin class _$VideoUploadTicketCopyWith<$Res> implements $VideoUploadTicketCopyWith<$Res> {
  factory _$VideoUploadTicketCopyWith(_VideoUploadTicket value, $Res Function(_VideoUploadTicket) _then) = __$VideoUploadTicketCopyWithImpl;
@override @useResult
$Res call({
 String mediaKey, String uploadUrl, int expiresInSeconds
});




}
/// @nodoc
class __$VideoUploadTicketCopyWithImpl<$Res>
    implements _$VideoUploadTicketCopyWith<$Res> {
  __$VideoUploadTicketCopyWithImpl(this._self, this._then);

  final _VideoUploadTicket _self;
  final $Res Function(_VideoUploadTicket) _then;

/// Create a copy of VideoUploadTicket
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? mediaKey = null,Object? uploadUrl = null,Object? expiresInSeconds = null,}) {
  return _then(_VideoUploadTicket(
mediaKey: null == mediaKey ? _self.mediaKey : mediaKey // ignore: cast_nullable_to_non_nullable
as String,uploadUrl: null == uploadUrl ? _self.uploadUrl : uploadUrl // ignore: cast_nullable_to_non_nullable
as String,expiresInSeconds: null == expiresInSeconds ? _self.expiresInSeconds : expiresInSeconds // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
