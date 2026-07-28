// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'diary_models.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$DiaryMacros {

 num get kcal; num get proteinG; num get carbsG; num get fatG;
/// Create a copy of DiaryMacros
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DiaryMacrosCopyWith<DiaryMacros> get copyWith => _$DiaryMacrosCopyWithImpl<DiaryMacros>(this as DiaryMacros, _$identity);

  /// Serializes this DiaryMacros to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DiaryMacros&&(identical(other.kcal, kcal) || other.kcal == kcal)&&(identical(other.proteinG, proteinG) || other.proteinG == proteinG)&&(identical(other.carbsG, carbsG) || other.carbsG == carbsG)&&(identical(other.fatG, fatG) || other.fatG == fatG));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,kcal,proteinG,carbsG,fatG);

@override
String toString() {
  return 'DiaryMacros(kcal: $kcal, proteinG: $proteinG, carbsG: $carbsG, fatG: $fatG)';
}


}

/// @nodoc
abstract mixin class $DiaryMacrosCopyWith<$Res>  {
  factory $DiaryMacrosCopyWith(DiaryMacros value, $Res Function(DiaryMacros) _then) = _$DiaryMacrosCopyWithImpl;
@useResult
$Res call({
 num kcal, num proteinG, num carbsG, num fatG
});




}
/// @nodoc
class _$DiaryMacrosCopyWithImpl<$Res>
    implements $DiaryMacrosCopyWith<$Res> {
  _$DiaryMacrosCopyWithImpl(this._self, this._then);

  final DiaryMacros _self;
  final $Res Function(DiaryMacros) _then;

/// Create a copy of DiaryMacros
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? kcal = null,Object? proteinG = null,Object? carbsG = null,Object? fatG = null,}) {
  return _then(_self.copyWith(
kcal: null == kcal ? _self.kcal : kcal // ignore: cast_nullable_to_non_nullable
as num,proteinG: null == proteinG ? _self.proteinG : proteinG // ignore: cast_nullable_to_non_nullable
as num,carbsG: null == carbsG ? _self.carbsG : carbsG // ignore: cast_nullable_to_non_nullable
as num,fatG: null == fatG ? _self.fatG : fatG // ignore: cast_nullable_to_non_nullable
as num,
  ));
}

}


/// Adds pattern-matching-related methods to [DiaryMacros].
extension DiaryMacrosPatterns on DiaryMacros {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DiaryMacros value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DiaryMacros() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DiaryMacros value)  $default,){
final _that = this;
switch (_that) {
case _DiaryMacros():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DiaryMacros value)?  $default,){
final _that = this;
switch (_that) {
case _DiaryMacros() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( num kcal,  num proteinG,  num carbsG,  num fatG)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DiaryMacros() when $default != null:
return $default(_that.kcal,_that.proteinG,_that.carbsG,_that.fatG);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( num kcal,  num proteinG,  num carbsG,  num fatG)  $default,) {final _that = this;
switch (_that) {
case _DiaryMacros():
return $default(_that.kcal,_that.proteinG,_that.carbsG,_that.fatG);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( num kcal,  num proteinG,  num carbsG,  num fatG)?  $default,) {final _that = this;
switch (_that) {
case _DiaryMacros() when $default != null:
return $default(_that.kcal,_that.proteinG,_that.carbsG,_that.fatG);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _DiaryMacros implements DiaryMacros {
  const _DiaryMacros({this.kcal = 0, this.proteinG = 0, this.carbsG = 0, this.fatG = 0});
  factory _DiaryMacros.fromJson(Map<String, dynamic> json) => _$DiaryMacrosFromJson(json);

@override@JsonKey() final  num kcal;
@override@JsonKey() final  num proteinG;
@override@JsonKey() final  num carbsG;
@override@JsonKey() final  num fatG;

/// Create a copy of DiaryMacros
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DiaryMacrosCopyWith<_DiaryMacros> get copyWith => __$DiaryMacrosCopyWithImpl<_DiaryMacros>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$DiaryMacrosToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _DiaryMacros&&(identical(other.kcal, kcal) || other.kcal == kcal)&&(identical(other.proteinG, proteinG) || other.proteinG == proteinG)&&(identical(other.carbsG, carbsG) || other.carbsG == carbsG)&&(identical(other.fatG, fatG) || other.fatG == fatG));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,kcal,proteinG,carbsG,fatG);

@override
String toString() {
  return 'DiaryMacros(kcal: $kcal, proteinG: $proteinG, carbsG: $carbsG, fatG: $fatG)';
}


}

/// @nodoc
abstract mixin class _$DiaryMacrosCopyWith<$Res> implements $DiaryMacrosCopyWith<$Res> {
  factory _$DiaryMacrosCopyWith(_DiaryMacros value, $Res Function(_DiaryMacros) _then) = __$DiaryMacrosCopyWithImpl;
@override @useResult
$Res call({
 num kcal, num proteinG, num carbsG, num fatG
});




}
/// @nodoc
class __$DiaryMacrosCopyWithImpl<$Res>
    implements _$DiaryMacrosCopyWith<$Res> {
  __$DiaryMacrosCopyWithImpl(this._self, this._then);

  final _DiaryMacros _self;
  final $Res Function(_DiaryMacros) _then;

/// Create a copy of DiaryMacros
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? kcal = null,Object? proteinG = null,Object? carbsG = null,Object? fatG = null,}) {
  return _then(_DiaryMacros(
kcal: null == kcal ? _self.kcal : kcal // ignore: cast_nullable_to_non_nullable
as num,proteinG: null == proteinG ? _self.proteinG : proteinG // ignore: cast_nullable_to_non_nullable
as num,carbsG: null == carbsG ? _self.carbsG : carbsG // ignore: cast_nullable_to_non_nullable
as num,fatG: null == fatG ? _self.fatG : fatG // ignore: cast_nullable_to_non_nullable
as num,
  ));
}


}


/// @nodoc
mixin _$DiaryEntry {

 String get id; String? get createdAt; num get totalKcal; num get totalProteinG; num get totalCarbsG; num get totalFatG; bool get userAdjusted;/// Fora do diário: continua na lista, riscada, mas não soma no dia.
 bool get excludedFromDiary;
/// Create a copy of DiaryEntry
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DiaryEntryCopyWith<DiaryEntry> get copyWith => _$DiaryEntryCopyWithImpl<DiaryEntry>(this as DiaryEntry, _$identity);

  /// Serializes this DiaryEntry to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DiaryEntry&&(identical(other.id, id) || other.id == id)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.totalKcal, totalKcal) || other.totalKcal == totalKcal)&&(identical(other.totalProteinG, totalProteinG) || other.totalProteinG == totalProteinG)&&(identical(other.totalCarbsG, totalCarbsG) || other.totalCarbsG == totalCarbsG)&&(identical(other.totalFatG, totalFatG) || other.totalFatG == totalFatG)&&(identical(other.userAdjusted, userAdjusted) || other.userAdjusted == userAdjusted)&&(identical(other.excludedFromDiary, excludedFromDiary) || other.excludedFromDiary == excludedFromDiary));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,createdAt,totalKcal,totalProteinG,totalCarbsG,totalFatG,userAdjusted,excludedFromDiary);

@override
String toString() {
  return 'DiaryEntry(id: $id, createdAt: $createdAt, totalKcal: $totalKcal, totalProteinG: $totalProteinG, totalCarbsG: $totalCarbsG, totalFatG: $totalFatG, userAdjusted: $userAdjusted, excludedFromDiary: $excludedFromDiary)';
}


}

/// @nodoc
abstract mixin class $DiaryEntryCopyWith<$Res>  {
  factory $DiaryEntryCopyWith(DiaryEntry value, $Res Function(DiaryEntry) _then) = _$DiaryEntryCopyWithImpl;
@useResult
$Res call({
 String id, String? createdAt, num totalKcal, num totalProteinG, num totalCarbsG, num totalFatG, bool userAdjusted, bool excludedFromDiary
});




}
/// @nodoc
class _$DiaryEntryCopyWithImpl<$Res>
    implements $DiaryEntryCopyWith<$Res> {
  _$DiaryEntryCopyWithImpl(this._self, this._then);

  final DiaryEntry _self;
  final $Res Function(DiaryEntry) _then;

/// Create a copy of DiaryEntry
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? createdAt = freezed,Object? totalKcal = null,Object? totalProteinG = null,Object? totalCarbsG = null,Object? totalFatG = null,Object? userAdjusted = null,Object? excludedFromDiary = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as String?,totalKcal: null == totalKcal ? _self.totalKcal : totalKcal // ignore: cast_nullable_to_non_nullable
as num,totalProteinG: null == totalProteinG ? _self.totalProteinG : totalProteinG // ignore: cast_nullable_to_non_nullable
as num,totalCarbsG: null == totalCarbsG ? _self.totalCarbsG : totalCarbsG // ignore: cast_nullable_to_non_nullable
as num,totalFatG: null == totalFatG ? _self.totalFatG : totalFatG // ignore: cast_nullable_to_non_nullable
as num,userAdjusted: null == userAdjusted ? _self.userAdjusted : userAdjusted // ignore: cast_nullable_to_non_nullable
as bool,excludedFromDiary: null == excludedFromDiary ? _self.excludedFromDiary : excludedFromDiary // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [DiaryEntry].
extension DiaryEntryPatterns on DiaryEntry {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DiaryEntry value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DiaryEntry() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DiaryEntry value)  $default,){
final _that = this;
switch (_that) {
case _DiaryEntry():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DiaryEntry value)?  $default,){
final _that = this;
switch (_that) {
case _DiaryEntry() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String? createdAt,  num totalKcal,  num totalProteinG,  num totalCarbsG,  num totalFatG,  bool userAdjusted,  bool excludedFromDiary)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DiaryEntry() when $default != null:
return $default(_that.id,_that.createdAt,_that.totalKcal,_that.totalProteinG,_that.totalCarbsG,_that.totalFatG,_that.userAdjusted,_that.excludedFromDiary);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String? createdAt,  num totalKcal,  num totalProteinG,  num totalCarbsG,  num totalFatG,  bool userAdjusted,  bool excludedFromDiary)  $default,) {final _that = this;
switch (_that) {
case _DiaryEntry():
return $default(_that.id,_that.createdAt,_that.totalKcal,_that.totalProteinG,_that.totalCarbsG,_that.totalFatG,_that.userAdjusted,_that.excludedFromDiary);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String? createdAt,  num totalKcal,  num totalProteinG,  num totalCarbsG,  num totalFatG,  bool userAdjusted,  bool excludedFromDiary)?  $default,) {final _that = this;
switch (_that) {
case _DiaryEntry() when $default != null:
return $default(_that.id,_that.createdAt,_that.totalKcal,_that.totalProteinG,_that.totalCarbsG,_that.totalFatG,_that.userAdjusted,_that.excludedFromDiary);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _DiaryEntry implements DiaryEntry {
  const _DiaryEntry({required this.id, this.createdAt, this.totalKcal = 0, this.totalProteinG = 0, this.totalCarbsG = 0, this.totalFatG = 0, this.userAdjusted = false, this.excludedFromDiary = false});
  factory _DiaryEntry.fromJson(Map<String, dynamic> json) => _$DiaryEntryFromJson(json);

@override final  String id;
@override final  String? createdAt;
@override@JsonKey() final  num totalKcal;
@override@JsonKey() final  num totalProteinG;
@override@JsonKey() final  num totalCarbsG;
@override@JsonKey() final  num totalFatG;
@override@JsonKey() final  bool userAdjusted;
/// Fora do diário: continua na lista, riscada, mas não soma no dia.
@override@JsonKey() final  bool excludedFromDiary;

/// Create a copy of DiaryEntry
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DiaryEntryCopyWith<_DiaryEntry> get copyWith => __$DiaryEntryCopyWithImpl<_DiaryEntry>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$DiaryEntryToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _DiaryEntry&&(identical(other.id, id) || other.id == id)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.totalKcal, totalKcal) || other.totalKcal == totalKcal)&&(identical(other.totalProteinG, totalProteinG) || other.totalProteinG == totalProteinG)&&(identical(other.totalCarbsG, totalCarbsG) || other.totalCarbsG == totalCarbsG)&&(identical(other.totalFatG, totalFatG) || other.totalFatG == totalFatG)&&(identical(other.userAdjusted, userAdjusted) || other.userAdjusted == userAdjusted)&&(identical(other.excludedFromDiary, excludedFromDiary) || other.excludedFromDiary == excludedFromDiary));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,createdAt,totalKcal,totalProteinG,totalCarbsG,totalFatG,userAdjusted,excludedFromDiary);

@override
String toString() {
  return 'DiaryEntry(id: $id, createdAt: $createdAt, totalKcal: $totalKcal, totalProteinG: $totalProteinG, totalCarbsG: $totalCarbsG, totalFatG: $totalFatG, userAdjusted: $userAdjusted, excludedFromDiary: $excludedFromDiary)';
}


}

/// @nodoc
abstract mixin class _$DiaryEntryCopyWith<$Res> implements $DiaryEntryCopyWith<$Res> {
  factory _$DiaryEntryCopyWith(_DiaryEntry value, $Res Function(_DiaryEntry) _then) = __$DiaryEntryCopyWithImpl;
@override @useResult
$Res call({
 String id, String? createdAt, num totalKcal, num totalProteinG, num totalCarbsG, num totalFatG, bool userAdjusted, bool excludedFromDiary
});




}
/// @nodoc
class __$DiaryEntryCopyWithImpl<$Res>
    implements _$DiaryEntryCopyWith<$Res> {
  __$DiaryEntryCopyWithImpl(this._self, this._then);

  final _DiaryEntry _self;
  final $Res Function(_DiaryEntry) _then;

/// Create a copy of DiaryEntry
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? createdAt = freezed,Object? totalKcal = null,Object? totalProteinG = null,Object? totalCarbsG = null,Object? totalFatG = null,Object? userAdjusted = null,Object? excludedFromDiary = null,}) {
  return _then(_DiaryEntry(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as String?,totalKcal: null == totalKcal ? _self.totalKcal : totalKcal // ignore: cast_nullable_to_non_nullable
as num,totalProteinG: null == totalProteinG ? _self.totalProteinG : totalProteinG // ignore: cast_nullable_to_non_nullable
as num,totalCarbsG: null == totalCarbsG ? _self.totalCarbsG : totalCarbsG // ignore: cast_nullable_to_non_nullable
as num,totalFatG: null == totalFatG ? _self.totalFatG : totalFatG // ignore: cast_nullable_to_non_nullable
as num,userAdjusted: null == userAdjusted ? _self.userAdjusted : userAdjusted // ignore: cast_nullable_to_non_nullable
as bool,excludedFromDiary: null == excludedFromDiary ? _self.excludedFromDiary : excludedFromDiary // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}


/// @nodoc
mixin _$DiaryDayTotal {

 String get date; num get kcal;
/// Create a copy of DiaryDayTotal
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DiaryDayTotalCopyWith<DiaryDayTotal> get copyWith => _$DiaryDayTotalCopyWithImpl<DiaryDayTotal>(this as DiaryDayTotal, _$identity);

  /// Serializes this DiaryDayTotal to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DiaryDayTotal&&(identical(other.date, date) || other.date == date)&&(identical(other.kcal, kcal) || other.kcal == kcal));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,date,kcal);

@override
String toString() {
  return 'DiaryDayTotal(date: $date, kcal: $kcal)';
}


}

/// @nodoc
abstract mixin class $DiaryDayTotalCopyWith<$Res>  {
  factory $DiaryDayTotalCopyWith(DiaryDayTotal value, $Res Function(DiaryDayTotal) _then) = _$DiaryDayTotalCopyWithImpl;
@useResult
$Res call({
 String date, num kcal
});




}
/// @nodoc
class _$DiaryDayTotalCopyWithImpl<$Res>
    implements $DiaryDayTotalCopyWith<$Res> {
  _$DiaryDayTotalCopyWithImpl(this._self, this._then);

  final DiaryDayTotal _self;
  final $Res Function(DiaryDayTotal) _then;

/// Create a copy of DiaryDayTotal
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? date = null,Object? kcal = null,}) {
  return _then(_self.copyWith(
date: null == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as String,kcal: null == kcal ? _self.kcal : kcal // ignore: cast_nullable_to_non_nullable
as num,
  ));
}

}


/// Adds pattern-matching-related methods to [DiaryDayTotal].
extension DiaryDayTotalPatterns on DiaryDayTotal {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DiaryDayTotal value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DiaryDayTotal() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DiaryDayTotal value)  $default,){
final _that = this;
switch (_that) {
case _DiaryDayTotal():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DiaryDayTotal value)?  $default,){
final _that = this;
switch (_that) {
case _DiaryDayTotal() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String date,  num kcal)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DiaryDayTotal() when $default != null:
return $default(_that.date,_that.kcal);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String date,  num kcal)  $default,) {final _that = this;
switch (_that) {
case _DiaryDayTotal():
return $default(_that.date,_that.kcal);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String date,  num kcal)?  $default,) {final _that = this;
switch (_that) {
case _DiaryDayTotal() when $default != null:
return $default(_that.date,_that.kcal);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _DiaryDayTotal implements DiaryDayTotal {
  const _DiaryDayTotal({required this.date, this.kcal = 0});
  factory _DiaryDayTotal.fromJson(Map<String, dynamic> json) => _$DiaryDayTotalFromJson(json);

@override final  String date;
@override@JsonKey() final  num kcal;

/// Create a copy of DiaryDayTotal
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DiaryDayTotalCopyWith<_DiaryDayTotal> get copyWith => __$DiaryDayTotalCopyWithImpl<_DiaryDayTotal>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$DiaryDayTotalToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _DiaryDayTotal&&(identical(other.date, date) || other.date == date)&&(identical(other.kcal, kcal) || other.kcal == kcal));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,date,kcal);

@override
String toString() {
  return 'DiaryDayTotal(date: $date, kcal: $kcal)';
}


}

/// @nodoc
abstract mixin class _$DiaryDayTotalCopyWith<$Res> implements $DiaryDayTotalCopyWith<$Res> {
  factory _$DiaryDayTotalCopyWith(_DiaryDayTotal value, $Res Function(_DiaryDayTotal) _then) = __$DiaryDayTotalCopyWithImpl;
@override @useResult
$Res call({
 String date, num kcal
});




}
/// @nodoc
class __$DiaryDayTotalCopyWithImpl<$Res>
    implements _$DiaryDayTotalCopyWith<$Res> {
  __$DiaryDayTotalCopyWithImpl(this._self, this._then);

  final _DiaryDayTotal _self;
  final $Res Function(_DiaryDayTotal) _then;

/// Create a copy of DiaryDayTotal
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? date = null,Object? kcal = null,}) {
  return _then(_DiaryDayTotal(
date: null == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as String,kcal: null == kcal ? _self.kcal : kcal // ignore: cast_nullable_to_non_nullable
as num,
  ));
}


}


/// @nodoc
mixin _$DiaryDay {

 String get date;/// Metas da dieta ativa. **Null quando ainda não há dieta gerada** — e null não é zero:
/// zero seria uma meta de jejum.
 DiaryMacros? get targets; DiaryMacros get consumed; List<DiaryEntry> get entries;/// Sete dias terminando no dia pedido.
 List<DiaryDayTotal> get week;
/// Create a copy of DiaryDay
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DiaryDayCopyWith<DiaryDay> get copyWith => _$DiaryDayCopyWithImpl<DiaryDay>(this as DiaryDay, _$identity);

  /// Serializes this DiaryDay to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DiaryDay&&(identical(other.date, date) || other.date == date)&&(identical(other.targets, targets) || other.targets == targets)&&(identical(other.consumed, consumed) || other.consumed == consumed)&&const DeepCollectionEquality().equals(other.entries, entries)&&const DeepCollectionEquality().equals(other.week, week));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,date,targets,consumed,const DeepCollectionEquality().hash(entries),const DeepCollectionEquality().hash(week));

@override
String toString() {
  return 'DiaryDay(date: $date, targets: $targets, consumed: $consumed, entries: $entries, week: $week)';
}


}

/// @nodoc
abstract mixin class $DiaryDayCopyWith<$Res>  {
  factory $DiaryDayCopyWith(DiaryDay value, $Res Function(DiaryDay) _then) = _$DiaryDayCopyWithImpl;
@useResult
$Res call({
 String date, DiaryMacros? targets, DiaryMacros consumed, List<DiaryEntry> entries, List<DiaryDayTotal> week
});


$DiaryMacrosCopyWith<$Res>? get targets;$DiaryMacrosCopyWith<$Res> get consumed;

}
/// @nodoc
class _$DiaryDayCopyWithImpl<$Res>
    implements $DiaryDayCopyWith<$Res> {
  _$DiaryDayCopyWithImpl(this._self, this._then);

  final DiaryDay _self;
  final $Res Function(DiaryDay) _then;

/// Create a copy of DiaryDay
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? date = null,Object? targets = freezed,Object? consumed = null,Object? entries = null,Object? week = null,}) {
  return _then(_self.copyWith(
date: null == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as String,targets: freezed == targets ? _self.targets : targets // ignore: cast_nullable_to_non_nullable
as DiaryMacros?,consumed: null == consumed ? _self.consumed : consumed // ignore: cast_nullable_to_non_nullable
as DiaryMacros,entries: null == entries ? _self.entries : entries // ignore: cast_nullable_to_non_nullable
as List<DiaryEntry>,week: null == week ? _self.week : week // ignore: cast_nullable_to_non_nullable
as List<DiaryDayTotal>,
  ));
}
/// Create a copy of DiaryDay
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DiaryMacrosCopyWith<$Res>? get targets {
    if (_self.targets == null) {
    return null;
  }

  return $DiaryMacrosCopyWith<$Res>(_self.targets!, (value) {
    return _then(_self.copyWith(targets: value));
  });
}/// Create a copy of DiaryDay
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DiaryMacrosCopyWith<$Res> get consumed {
  
  return $DiaryMacrosCopyWith<$Res>(_self.consumed, (value) {
    return _then(_self.copyWith(consumed: value));
  });
}
}


/// Adds pattern-matching-related methods to [DiaryDay].
extension DiaryDayPatterns on DiaryDay {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DiaryDay value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DiaryDay() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DiaryDay value)  $default,){
final _that = this;
switch (_that) {
case _DiaryDay():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DiaryDay value)?  $default,){
final _that = this;
switch (_that) {
case _DiaryDay() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String date,  DiaryMacros? targets,  DiaryMacros consumed,  List<DiaryEntry> entries,  List<DiaryDayTotal> week)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DiaryDay() when $default != null:
return $default(_that.date,_that.targets,_that.consumed,_that.entries,_that.week);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String date,  DiaryMacros? targets,  DiaryMacros consumed,  List<DiaryEntry> entries,  List<DiaryDayTotal> week)  $default,) {final _that = this;
switch (_that) {
case _DiaryDay():
return $default(_that.date,_that.targets,_that.consumed,_that.entries,_that.week);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String date,  DiaryMacros? targets,  DiaryMacros consumed,  List<DiaryEntry> entries,  List<DiaryDayTotal> week)?  $default,) {final _that = this;
switch (_that) {
case _DiaryDay() when $default != null:
return $default(_that.date,_that.targets,_that.consumed,_that.entries,_that.week);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _DiaryDay implements DiaryDay {
  const _DiaryDay({required this.date, this.targets, this.consumed = const DiaryMacros(), final  List<DiaryEntry> entries = const [], final  List<DiaryDayTotal> week = const []}): _entries = entries,_week = week;
  factory _DiaryDay.fromJson(Map<String, dynamic> json) => _$DiaryDayFromJson(json);

@override final  String date;
/// Metas da dieta ativa. **Null quando ainda não há dieta gerada** — e null não é zero:
/// zero seria uma meta de jejum.
@override final  DiaryMacros? targets;
@override@JsonKey() final  DiaryMacros consumed;
 final  List<DiaryEntry> _entries;
@override@JsonKey() List<DiaryEntry> get entries {
  if (_entries is EqualUnmodifiableListView) return _entries;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_entries);
}

/// Sete dias terminando no dia pedido.
 final  List<DiaryDayTotal> _week;
/// Sete dias terminando no dia pedido.
@override@JsonKey() List<DiaryDayTotal> get week {
  if (_week is EqualUnmodifiableListView) return _week;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_week);
}


/// Create a copy of DiaryDay
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DiaryDayCopyWith<_DiaryDay> get copyWith => __$DiaryDayCopyWithImpl<_DiaryDay>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$DiaryDayToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _DiaryDay&&(identical(other.date, date) || other.date == date)&&(identical(other.targets, targets) || other.targets == targets)&&(identical(other.consumed, consumed) || other.consumed == consumed)&&const DeepCollectionEquality().equals(other._entries, _entries)&&const DeepCollectionEquality().equals(other._week, _week));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,date,targets,consumed,const DeepCollectionEquality().hash(_entries),const DeepCollectionEquality().hash(_week));

@override
String toString() {
  return 'DiaryDay(date: $date, targets: $targets, consumed: $consumed, entries: $entries, week: $week)';
}


}

/// @nodoc
abstract mixin class _$DiaryDayCopyWith<$Res> implements $DiaryDayCopyWith<$Res> {
  factory _$DiaryDayCopyWith(_DiaryDay value, $Res Function(_DiaryDay) _then) = __$DiaryDayCopyWithImpl;
@override @useResult
$Res call({
 String date, DiaryMacros? targets, DiaryMacros consumed, List<DiaryEntry> entries, List<DiaryDayTotal> week
});


@override $DiaryMacrosCopyWith<$Res>? get targets;@override $DiaryMacrosCopyWith<$Res> get consumed;

}
/// @nodoc
class __$DiaryDayCopyWithImpl<$Res>
    implements _$DiaryDayCopyWith<$Res> {
  __$DiaryDayCopyWithImpl(this._self, this._then);

  final _DiaryDay _self;
  final $Res Function(_DiaryDay) _then;

/// Create a copy of DiaryDay
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? date = null,Object? targets = freezed,Object? consumed = null,Object? entries = null,Object? week = null,}) {
  return _then(_DiaryDay(
date: null == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as String,targets: freezed == targets ? _self.targets : targets // ignore: cast_nullable_to_non_nullable
as DiaryMacros?,consumed: null == consumed ? _self.consumed : consumed // ignore: cast_nullable_to_non_nullable
as DiaryMacros,entries: null == entries ? _self._entries : entries // ignore: cast_nullable_to_non_nullable
as List<DiaryEntry>,week: null == week ? _self._week : week // ignore: cast_nullable_to_non_nullable
as List<DiaryDayTotal>,
  ));
}

/// Create a copy of DiaryDay
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DiaryMacrosCopyWith<$Res>? get targets {
    if (_self.targets == null) {
    return null;
  }

  return $DiaryMacrosCopyWith<$Res>(_self.targets!, (value) {
    return _then(_self.copyWith(targets: value));
  });
}/// Create a copy of DiaryDay
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DiaryMacrosCopyWith<$Res> get consumed {
  
  return $DiaryMacrosCopyWith<$Res>(_self.consumed, (value) {
    return _then(_self.copyWith(consumed: value));
  });
}
}

// dart format on
