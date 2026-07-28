// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'diet_models.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$DietPlan {

 String get id; String get name; String get calorieGoal; int get version; String? get createdAt; String get reviewStatus; String? get reviewNote; String? get reviewedAt; Macros get targets; Macros get totals; List<DietMeal> get meals;
/// Create a copy of DietPlan
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DietPlanCopyWith<DietPlan> get copyWith => _$DietPlanCopyWithImpl<DietPlan>(this as DietPlan, _$identity);

  /// Serializes this DietPlan to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DietPlan&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.calorieGoal, calorieGoal) || other.calorieGoal == calorieGoal)&&(identical(other.version, version) || other.version == version)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.reviewStatus, reviewStatus) || other.reviewStatus == reviewStatus)&&(identical(other.reviewNote, reviewNote) || other.reviewNote == reviewNote)&&(identical(other.reviewedAt, reviewedAt) || other.reviewedAt == reviewedAt)&&(identical(other.targets, targets) || other.targets == targets)&&(identical(other.totals, totals) || other.totals == totals)&&const DeepCollectionEquality().equals(other.meals, meals));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,calorieGoal,version,createdAt,reviewStatus,reviewNote,reviewedAt,targets,totals,const DeepCollectionEquality().hash(meals));

@override
String toString() {
  return 'DietPlan(id: $id, name: $name, calorieGoal: $calorieGoal, version: $version, createdAt: $createdAt, reviewStatus: $reviewStatus, reviewNote: $reviewNote, reviewedAt: $reviewedAt, targets: $targets, totals: $totals, meals: $meals)';
}


}

/// @nodoc
abstract mixin class $DietPlanCopyWith<$Res>  {
  factory $DietPlanCopyWith(DietPlan value, $Res Function(DietPlan) _then) = _$DietPlanCopyWithImpl;
@useResult
$Res call({
 String id, String name, String calorieGoal, int version, String? createdAt, String reviewStatus, String? reviewNote, String? reviewedAt, Macros targets, Macros totals, List<DietMeal> meals
});


$MacrosCopyWith<$Res> get targets;$MacrosCopyWith<$Res> get totals;

}
/// @nodoc
class _$DietPlanCopyWithImpl<$Res>
    implements $DietPlanCopyWith<$Res> {
  _$DietPlanCopyWithImpl(this._self, this._then);

  final DietPlan _self;
  final $Res Function(DietPlan) _then;

/// Create a copy of DietPlan
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? calorieGoal = null,Object? version = null,Object? createdAt = freezed,Object? reviewStatus = null,Object? reviewNote = freezed,Object? reviewedAt = freezed,Object? targets = null,Object? totals = null,Object? meals = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,calorieGoal: null == calorieGoal ? _self.calorieGoal : calorieGoal // ignore: cast_nullable_to_non_nullable
as String,version: null == version ? _self.version : version // ignore: cast_nullable_to_non_nullable
as int,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as String?,reviewStatus: null == reviewStatus ? _self.reviewStatus : reviewStatus // ignore: cast_nullable_to_non_nullable
as String,reviewNote: freezed == reviewNote ? _self.reviewNote : reviewNote // ignore: cast_nullable_to_non_nullable
as String?,reviewedAt: freezed == reviewedAt ? _self.reviewedAt : reviewedAt // ignore: cast_nullable_to_non_nullable
as String?,targets: null == targets ? _self.targets : targets // ignore: cast_nullable_to_non_nullable
as Macros,totals: null == totals ? _self.totals : totals // ignore: cast_nullable_to_non_nullable
as Macros,meals: null == meals ? _self.meals : meals // ignore: cast_nullable_to_non_nullable
as List<DietMeal>,
  ));
}
/// Create a copy of DietPlan
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$MacrosCopyWith<$Res> get targets {
  
  return $MacrosCopyWith<$Res>(_self.targets, (value) {
    return _then(_self.copyWith(targets: value));
  });
}/// Create a copy of DietPlan
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$MacrosCopyWith<$Res> get totals {
  
  return $MacrosCopyWith<$Res>(_self.totals, (value) {
    return _then(_self.copyWith(totals: value));
  });
}
}


/// Adds pattern-matching-related methods to [DietPlan].
extension DietPlanPatterns on DietPlan {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DietPlan value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DietPlan() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DietPlan value)  $default,){
final _that = this;
switch (_that) {
case _DietPlan():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DietPlan value)?  $default,){
final _that = this;
switch (_that) {
case _DietPlan() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  String calorieGoal,  int version,  String? createdAt,  String reviewStatus,  String? reviewNote,  String? reviewedAt,  Macros targets,  Macros totals,  List<DietMeal> meals)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DietPlan() when $default != null:
return $default(_that.id,_that.name,_that.calorieGoal,_that.version,_that.createdAt,_that.reviewStatus,_that.reviewNote,_that.reviewedAt,_that.targets,_that.totals,_that.meals);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  String calorieGoal,  int version,  String? createdAt,  String reviewStatus,  String? reviewNote,  String? reviewedAt,  Macros targets,  Macros totals,  List<DietMeal> meals)  $default,) {final _that = this;
switch (_that) {
case _DietPlan():
return $default(_that.id,_that.name,_that.calorieGoal,_that.version,_that.createdAt,_that.reviewStatus,_that.reviewNote,_that.reviewedAt,_that.targets,_that.totals,_that.meals);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  String calorieGoal,  int version,  String? createdAt,  String reviewStatus,  String? reviewNote,  String? reviewedAt,  Macros targets,  Macros totals,  List<DietMeal> meals)?  $default,) {final _that = this;
switch (_that) {
case _DietPlan() when $default != null:
return $default(_that.id,_that.name,_that.calorieGoal,_that.version,_that.createdAt,_that.reviewStatus,_that.reviewNote,_that.reviewedAt,_that.targets,_that.totals,_that.meals);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _DietPlan implements DietPlan {
  const _DietPlan({required this.id, required this.name, this.calorieGoal = 'Maintenance', this.version = 1, this.createdAt, this.reviewStatus = 'NotReviewed', this.reviewNote, this.reviewedAt, required this.targets, required this.totals, final  List<DietMeal> meals = const []}): _meals = meals;
  factory _DietPlan.fromJson(Map<String, dynamic> json) => _$DietPlanFromJson(json);

@override final  String id;
@override final  String name;
@override@JsonKey() final  String calorieGoal;
@override@JsonKey() final  int version;
@override final  String? createdAt;
@override@JsonKey() final  String reviewStatus;
@override final  String? reviewNote;
@override final  String? reviewedAt;
@override final  Macros targets;
@override final  Macros totals;
 final  List<DietMeal> _meals;
@override@JsonKey() List<DietMeal> get meals {
  if (_meals is EqualUnmodifiableListView) return _meals;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_meals);
}


/// Create a copy of DietPlan
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DietPlanCopyWith<_DietPlan> get copyWith => __$DietPlanCopyWithImpl<_DietPlan>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$DietPlanToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _DietPlan&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.calorieGoal, calorieGoal) || other.calorieGoal == calorieGoal)&&(identical(other.version, version) || other.version == version)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.reviewStatus, reviewStatus) || other.reviewStatus == reviewStatus)&&(identical(other.reviewNote, reviewNote) || other.reviewNote == reviewNote)&&(identical(other.reviewedAt, reviewedAt) || other.reviewedAt == reviewedAt)&&(identical(other.targets, targets) || other.targets == targets)&&(identical(other.totals, totals) || other.totals == totals)&&const DeepCollectionEquality().equals(other._meals, _meals));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,calorieGoal,version,createdAt,reviewStatus,reviewNote,reviewedAt,targets,totals,const DeepCollectionEquality().hash(_meals));

@override
String toString() {
  return 'DietPlan(id: $id, name: $name, calorieGoal: $calorieGoal, version: $version, createdAt: $createdAt, reviewStatus: $reviewStatus, reviewNote: $reviewNote, reviewedAt: $reviewedAt, targets: $targets, totals: $totals, meals: $meals)';
}


}

/// @nodoc
abstract mixin class _$DietPlanCopyWith<$Res> implements $DietPlanCopyWith<$Res> {
  factory _$DietPlanCopyWith(_DietPlan value, $Res Function(_DietPlan) _then) = __$DietPlanCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, String calorieGoal, int version, String? createdAt, String reviewStatus, String? reviewNote, String? reviewedAt, Macros targets, Macros totals, List<DietMeal> meals
});


@override $MacrosCopyWith<$Res> get targets;@override $MacrosCopyWith<$Res> get totals;

}
/// @nodoc
class __$DietPlanCopyWithImpl<$Res>
    implements _$DietPlanCopyWith<$Res> {
  __$DietPlanCopyWithImpl(this._self, this._then);

  final _DietPlan _self;
  final $Res Function(_DietPlan) _then;

/// Create a copy of DietPlan
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? calorieGoal = null,Object? version = null,Object? createdAt = freezed,Object? reviewStatus = null,Object? reviewNote = freezed,Object? reviewedAt = freezed,Object? targets = null,Object? totals = null,Object? meals = null,}) {
  return _then(_DietPlan(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,calorieGoal: null == calorieGoal ? _self.calorieGoal : calorieGoal // ignore: cast_nullable_to_non_nullable
as String,version: null == version ? _self.version : version // ignore: cast_nullable_to_non_nullable
as int,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as String?,reviewStatus: null == reviewStatus ? _self.reviewStatus : reviewStatus // ignore: cast_nullable_to_non_nullable
as String,reviewNote: freezed == reviewNote ? _self.reviewNote : reviewNote // ignore: cast_nullable_to_non_nullable
as String?,reviewedAt: freezed == reviewedAt ? _self.reviewedAt : reviewedAt // ignore: cast_nullable_to_non_nullable
as String?,targets: null == targets ? _self.targets : targets // ignore: cast_nullable_to_non_nullable
as Macros,totals: null == totals ? _self.totals : totals // ignore: cast_nullable_to_non_nullable
as Macros,meals: null == meals ? _self._meals : meals // ignore: cast_nullable_to_non_nullable
as List<DietMeal>,
  ));
}

/// Create a copy of DietPlan
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$MacrosCopyWith<$Res> get targets {
  
  return $MacrosCopyWith<$Res>(_self.targets, (value) {
    return _then(_self.copyWith(targets: value));
  });
}/// Create a copy of DietPlan
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$MacrosCopyWith<$Res> get totals {
  
  return $MacrosCopyWith<$Res>(_self.totals, (value) {
    return _then(_self.copyWith(totals: value));
  });
}
}


/// @nodoc
mixin _$Macros {

 num get kcal; num get proteinG; num get carbsG; num get fatG;
/// Create a copy of Macros
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MacrosCopyWith<Macros> get copyWith => _$MacrosCopyWithImpl<Macros>(this as Macros, _$identity);

  /// Serializes this Macros to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Macros&&(identical(other.kcal, kcal) || other.kcal == kcal)&&(identical(other.proteinG, proteinG) || other.proteinG == proteinG)&&(identical(other.carbsG, carbsG) || other.carbsG == carbsG)&&(identical(other.fatG, fatG) || other.fatG == fatG));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,kcal,proteinG,carbsG,fatG);

@override
String toString() {
  return 'Macros(kcal: $kcal, proteinG: $proteinG, carbsG: $carbsG, fatG: $fatG)';
}


}

/// @nodoc
abstract mixin class $MacrosCopyWith<$Res>  {
  factory $MacrosCopyWith(Macros value, $Res Function(Macros) _then) = _$MacrosCopyWithImpl;
@useResult
$Res call({
 num kcal, num proteinG, num carbsG, num fatG
});




}
/// @nodoc
class _$MacrosCopyWithImpl<$Res>
    implements $MacrosCopyWith<$Res> {
  _$MacrosCopyWithImpl(this._self, this._then);

  final Macros _self;
  final $Res Function(Macros) _then;

/// Create a copy of Macros
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


/// Adds pattern-matching-related methods to [Macros].
extension MacrosPatterns on Macros {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Macros value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Macros() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Macros value)  $default,){
final _that = this;
switch (_that) {
case _Macros():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Macros value)?  $default,){
final _that = this;
switch (_that) {
case _Macros() when $default != null:
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
case _Macros() when $default != null:
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
case _Macros():
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
case _Macros() when $default != null:
return $default(_that.kcal,_that.proteinG,_that.carbsG,_that.fatG);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Macros implements Macros {
  const _Macros({this.kcal = 0, this.proteinG = 0, this.carbsG = 0, this.fatG = 0});
  factory _Macros.fromJson(Map<String, dynamic> json) => _$MacrosFromJson(json);

@override@JsonKey() final  num kcal;
@override@JsonKey() final  num proteinG;
@override@JsonKey() final  num carbsG;
@override@JsonKey() final  num fatG;

/// Create a copy of Macros
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MacrosCopyWith<_Macros> get copyWith => __$MacrosCopyWithImpl<_Macros>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$MacrosToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Macros&&(identical(other.kcal, kcal) || other.kcal == kcal)&&(identical(other.proteinG, proteinG) || other.proteinG == proteinG)&&(identical(other.carbsG, carbsG) || other.carbsG == carbsG)&&(identical(other.fatG, fatG) || other.fatG == fatG));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,kcal,proteinG,carbsG,fatG);

@override
String toString() {
  return 'Macros(kcal: $kcal, proteinG: $proteinG, carbsG: $carbsG, fatG: $fatG)';
}


}

/// @nodoc
abstract mixin class _$MacrosCopyWith<$Res> implements $MacrosCopyWith<$Res> {
  factory _$MacrosCopyWith(_Macros value, $Res Function(_Macros) _then) = __$MacrosCopyWithImpl;
@override @useResult
$Res call({
 num kcal, num proteinG, num carbsG, num fatG
});




}
/// @nodoc
class __$MacrosCopyWithImpl<$Res>
    implements _$MacrosCopyWith<$Res> {
  __$MacrosCopyWithImpl(this._self, this._then);

  final _Macros _self;
  final $Res Function(_Macros) _then;

/// Create a copy of Macros
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? kcal = null,Object? proteinG = null,Object? carbsG = null,Object? fatG = null,}) {
  return _then(_Macros(
kcal: null == kcal ? _self.kcal : kcal // ignore: cast_nullable_to_non_nullable
as num,proteinG: null == proteinG ? _self.proteinG : proteinG // ignore: cast_nullable_to_non_nullable
as num,carbsG: null == carbsG ? _self.carbsG : carbsG // ignore: cast_nullable_to_non_nullable
as num,fatG: null == fatG ? _self.fatG : fatG // ignore: cast_nullable_to_non_nullable
as num,
  ));
}


}


/// @nodoc
mixin _$DietMeal {

 String get id; int get order; String get name; List<DietMealItem> get items;
/// Create a copy of DietMeal
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DietMealCopyWith<DietMeal> get copyWith => _$DietMealCopyWithImpl<DietMeal>(this as DietMeal, _$identity);

  /// Serializes this DietMeal to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DietMeal&&(identical(other.id, id) || other.id == id)&&(identical(other.order, order) || other.order == order)&&(identical(other.name, name) || other.name == name)&&const DeepCollectionEquality().equals(other.items, items));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,order,name,const DeepCollectionEquality().hash(items));

@override
String toString() {
  return 'DietMeal(id: $id, order: $order, name: $name, items: $items)';
}


}

/// @nodoc
abstract mixin class $DietMealCopyWith<$Res>  {
  factory $DietMealCopyWith(DietMeal value, $Res Function(DietMeal) _then) = _$DietMealCopyWithImpl;
@useResult
$Res call({
 String id, int order, String name, List<DietMealItem> items
});




}
/// @nodoc
class _$DietMealCopyWithImpl<$Res>
    implements $DietMealCopyWith<$Res> {
  _$DietMealCopyWithImpl(this._self, this._then);

  final DietMeal _self;
  final $Res Function(DietMeal) _then;

/// Create a copy of DietMeal
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? order = null,Object? name = null,Object? items = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,order: null == order ? _self.order : order // ignore: cast_nullable_to_non_nullable
as int,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,items: null == items ? _self.items : items // ignore: cast_nullable_to_non_nullable
as List<DietMealItem>,
  ));
}

}


/// Adds pattern-matching-related methods to [DietMeal].
extension DietMealPatterns on DietMeal {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DietMeal value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DietMeal() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DietMeal value)  $default,){
final _that = this;
switch (_that) {
case _DietMeal():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DietMeal value)?  $default,){
final _that = this;
switch (_that) {
case _DietMeal() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  int order,  String name,  List<DietMealItem> items)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DietMeal() when $default != null:
return $default(_that.id,_that.order,_that.name,_that.items);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  int order,  String name,  List<DietMealItem> items)  $default,) {final _that = this;
switch (_that) {
case _DietMeal():
return $default(_that.id,_that.order,_that.name,_that.items);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  int order,  String name,  List<DietMealItem> items)?  $default,) {final _that = this;
switch (_that) {
case _DietMeal() when $default != null:
return $default(_that.id,_that.order,_that.name,_that.items);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _DietMeal implements DietMeal {
  const _DietMeal({required this.id, required this.order, required this.name, final  List<DietMealItem> items = const []}): _items = items;
  factory _DietMeal.fromJson(Map<String, dynamic> json) => _$DietMealFromJson(json);

@override final  String id;
@override final  int order;
@override final  String name;
 final  List<DietMealItem> _items;
@override@JsonKey() List<DietMealItem> get items {
  if (_items is EqualUnmodifiableListView) return _items;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_items);
}


/// Create a copy of DietMeal
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DietMealCopyWith<_DietMeal> get copyWith => __$DietMealCopyWithImpl<_DietMeal>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$DietMealToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _DietMeal&&(identical(other.id, id) || other.id == id)&&(identical(other.order, order) || other.order == order)&&(identical(other.name, name) || other.name == name)&&const DeepCollectionEquality().equals(other._items, _items));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,order,name,const DeepCollectionEquality().hash(_items));

@override
String toString() {
  return 'DietMeal(id: $id, order: $order, name: $name, items: $items)';
}


}

/// @nodoc
abstract mixin class _$DietMealCopyWith<$Res> implements $DietMealCopyWith<$Res> {
  factory _$DietMealCopyWith(_DietMeal value, $Res Function(_DietMeal) _then) = __$DietMealCopyWithImpl;
@override @useResult
$Res call({
 String id, int order, String name, List<DietMealItem> items
});




}
/// @nodoc
class __$DietMealCopyWithImpl<$Res>
    implements _$DietMealCopyWith<$Res> {
  __$DietMealCopyWithImpl(this._self, this._then);

  final _DietMeal _self;
  final $Res Function(_DietMeal) _then;

/// Create a copy of DietMeal
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? order = null,Object? name = null,Object? items = null,}) {
  return _then(_DietMeal(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,order: null == order ? _self.order : order // ignore: cast_nullable_to_non_nullable
as int,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,items: null == items ? _self._items : items // ignore: cast_nullable_to_non_nullable
as List<DietMealItem>,
  ));
}


}


/// @nodoc
mixin _$DietMealItem {

 String get id; int? get foodItemId; String get foodName; num get quantityG; num get kcal; num get proteinG; num get carbsG; num get fatG;
/// Create a copy of DietMealItem
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DietMealItemCopyWith<DietMealItem> get copyWith => _$DietMealItemCopyWithImpl<DietMealItem>(this as DietMealItem, _$identity);

  /// Serializes this DietMealItem to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DietMealItem&&(identical(other.id, id) || other.id == id)&&(identical(other.foodItemId, foodItemId) || other.foodItemId == foodItemId)&&(identical(other.foodName, foodName) || other.foodName == foodName)&&(identical(other.quantityG, quantityG) || other.quantityG == quantityG)&&(identical(other.kcal, kcal) || other.kcal == kcal)&&(identical(other.proteinG, proteinG) || other.proteinG == proteinG)&&(identical(other.carbsG, carbsG) || other.carbsG == carbsG)&&(identical(other.fatG, fatG) || other.fatG == fatG));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,foodItemId,foodName,quantityG,kcal,proteinG,carbsG,fatG);

@override
String toString() {
  return 'DietMealItem(id: $id, foodItemId: $foodItemId, foodName: $foodName, quantityG: $quantityG, kcal: $kcal, proteinG: $proteinG, carbsG: $carbsG, fatG: $fatG)';
}


}

/// @nodoc
abstract mixin class $DietMealItemCopyWith<$Res>  {
  factory $DietMealItemCopyWith(DietMealItem value, $Res Function(DietMealItem) _then) = _$DietMealItemCopyWithImpl;
@useResult
$Res call({
 String id, int? foodItemId, String foodName, num quantityG, num kcal, num proteinG, num carbsG, num fatG
});




}
/// @nodoc
class _$DietMealItemCopyWithImpl<$Res>
    implements $DietMealItemCopyWith<$Res> {
  _$DietMealItemCopyWithImpl(this._self, this._then);

  final DietMealItem _self;
  final $Res Function(DietMealItem) _then;

/// Create a copy of DietMealItem
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? foodItemId = freezed,Object? foodName = null,Object? quantityG = null,Object? kcal = null,Object? proteinG = null,Object? carbsG = null,Object? fatG = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,foodItemId: freezed == foodItemId ? _self.foodItemId : foodItemId // ignore: cast_nullable_to_non_nullable
as int?,foodName: null == foodName ? _self.foodName : foodName // ignore: cast_nullable_to_non_nullable
as String,quantityG: null == quantityG ? _self.quantityG : quantityG // ignore: cast_nullable_to_non_nullable
as num,kcal: null == kcal ? _self.kcal : kcal // ignore: cast_nullable_to_non_nullable
as num,proteinG: null == proteinG ? _self.proteinG : proteinG // ignore: cast_nullable_to_non_nullable
as num,carbsG: null == carbsG ? _self.carbsG : carbsG // ignore: cast_nullable_to_non_nullable
as num,fatG: null == fatG ? _self.fatG : fatG // ignore: cast_nullable_to_non_nullable
as num,
  ));
}

}


/// Adds pattern-matching-related methods to [DietMealItem].
extension DietMealItemPatterns on DietMealItem {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DietMealItem value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DietMealItem() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DietMealItem value)  $default,){
final _that = this;
switch (_that) {
case _DietMealItem():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DietMealItem value)?  $default,){
final _that = this;
switch (_that) {
case _DietMealItem() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  int? foodItemId,  String foodName,  num quantityG,  num kcal,  num proteinG,  num carbsG,  num fatG)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DietMealItem() when $default != null:
return $default(_that.id,_that.foodItemId,_that.foodName,_that.quantityG,_that.kcal,_that.proteinG,_that.carbsG,_that.fatG);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  int? foodItemId,  String foodName,  num quantityG,  num kcal,  num proteinG,  num carbsG,  num fatG)  $default,) {final _that = this;
switch (_that) {
case _DietMealItem():
return $default(_that.id,_that.foodItemId,_that.foodName,_that.quantityG,_that.kcal,_that.proteinG,_that.carbsG,_that.fatG);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  int? foodItemId,  String foodName,  num quantityG,  num kcal,  num proteinG,  num carbsG,  num fatG)?  $default,) {final _that = this;
switch (_that) {
case _DietMealItem() when $default != null:
return $default(_that.id,_that.foodItemId,_that.foodName,_that.quantityG,_that.kcal,_that.proteinG,_that.carbsG,_that.fatG);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _DietMealItem implements DietMealItem {
  const _DietMealItem({required this.id, this.foodItemId, required this.foodName, this.quantityG = 0, this.kcal = 0, this.proteinG = 0, this.carbsG = 0, this.fatG = 0});
  factory _DietMealItem.fromJson(Map<String, dynamic> json) => _$DietMealItemFromJson(json);

@override final  String id;
@override final  int? foodItemId;
@override final  String foodName;
@override@JsonKey() final  num quantityG;
@override@JsonKey() final  num kcal;
@override@JsonKey() final  num proteinG;
@override@JsonKey() final  num carbsG;
@override@JsonKey() final  num fatG;

/// Create a copy of DietMealItem
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DietMealItemCopyWith<_DietMealItem> get copyWith => __$DietMealItemCopyWithImpl<_DietMealItem>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$DietMealItemToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _DietMealItem&&(identical(other.id, id) || other.id == id)&&(identical(other.foodItemId, foodItemId) || other.foodItemId == foodItemId)&&(identical(other.foodName, foodName) || other.foodName == foodName)&&(identical(other.quantityG, quantityG) || other.quantityG == quantityG)&&(identical(other.kcal, kcal) || other.kcal == kcal)&&(identical(other.proteinG, proteinG) || other.proteinG == proteinG)&&(identical(other.carbsG, carbsG) || other.carbsG == carbsG)&&(identical(other.fatG, fatG) || other.fatG == fatG));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,foodItemId,foodName,quantityG,kcal,proteinG,carbsG,fatG);

@override
String toString() {
  return 'DietMealItem(id: $id, foodItemId: $foodItemId, foodName: $foodName, quantityG: $quantityG, kcal: $kcal, proteinG: $proteinG, carbsG: $carbsG, fatG: $fatG)';
}


}

/// @nodoc
abstract mixin class _$DietMealItemCopyWith<$Res> implements $DietMealItemCopyWith<$Res> {
  factory _$DietMealItemCopyWith(_DietMealItem value, $Res Function(_DietMealItem) _then) = __$DietMealItemCopyWithImpl;
@override @useResult
$Res call({
 String id, int? foodItemId, String foodName, num quantityG, num kcal, num proteinG, num carbsG, num fatG
});




}
/// @nodoc
class __$DietMealItemCopyWithImpl<$Res>
    implements _$DietMealItemCopyWith<$Res> {
  __$DietMealItemCopyWithImpl(this._self, this._then);

  final _DietMealItem _self;
  final $Res Function(_DietMealItem) _then;

/// Create a copy of DietMealItem
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? foodItemId = freezed,Object? foodName = null,Object? quantityG = null,Object? kcal = null,Object? proteinG = null,Object? carbsG = null,Object? fatG = null,}) {
  return _then(_DietMealItem(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,foodItemId: freezed == foodItemId ? _self.foodItemId : foodItemId // ignore: cast_nullable_to_non_nullable
as int?,foodName: null == foodName ? _self.foodName : foodName // ignore: cast_nullable_to_non_nullable
as String,quantityG: null == quantityG ? _self.quantityG : quantityG // ignore: cast_nullable_to_non_nullable
as num,kcal: null == kcal ? _self.kcal : kcal // ignore: cast_nullable_to_non_nullable
as num,proteinG: null == proteinG ? _self.proteinG : proteinG // ignore: cast_nullable_to_non_nullable
as num,carbsG: null == carbsG ? _self.carbsG : carbsG // ignore: cast_nullable_to_non_nullable
as num,fatG: null == fatG ? _self.fatG : fatG // ignore: cast_nullable_to_non_nullable
as num,
  ));
}


}


/// @nodoc
mixin _$DietPlanSummary {

 String get id; String get name; String get calorieGoal; String get status; int get version; num get targetKcal; String? get createdAt;
/// Create a copy of DietPlanSummary
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DietPlanSummaryCopyWith<DietPlanSummary> get copyWith => _$DietPlanSummaryCopyWithImpl<DietPlanSummary>(this as DietPlanSummary, _$identity);

  /// Serializes this DietPlanSummary to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DietPlanSummary&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.calorieGoal, calorieGoal) || other.calorieGoal == calorieGoal)&&(identical(other.status, status) || other.status == status)&&(identical(other.version, version) || other.version == version)&&(identical(other.targetKcal, targetKcal) || other.targetKcal == targetKcal)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,calorieGoal,status,version,targetKcal,createdAt);

@override
String toString() {
  return 'DietPlanSummary(id: $id, name: $name, calorieGoal: $calorieGoal, status: $status, version: $version, targetKcal: $targetKcal, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class $DietPlanSummaryCopyWith<$Res>  {
  factory $DietPlanSummaryCopyWith(DietPlanSummary value, $Res Function(DietPlanSummary) _then) = _$DietPlanSummaryCopyWithImpl;
@useResult
$Res call({
 String id, String name, String calorieGoal, String status, int version, num targetKcal, String? createdAt
});




}
/// @nodoc
class _$DietPlanSummaryCopyWithImpl<$Res>
    implements $DietPlanSummaryCopyWith<$Res> {
  _$DietPlanSummaryCopyWithImpl(this._self, this._then);

  final DietPlanSummary _self;
  final $Res Function(DietPlanSummary) _then;

/// Create a copy of DietPlanSummary
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? calorieGoal = null,Object? status = null,Object? version = null,Object? targetKcal = null,Object? createdAt = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,calorieGoal: null == calorieGoal ? _self.calorieGoal : calorieGoal // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,version: null == version ? _self.version : version // ignore: cast_nullable_to_non_nullable
as int,targetKcal: null == targetKcal ? _self.targetKcal : targetKcal // ignore: cast_nullable_to_non_nullable
as num,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [DietPlanSummary].
extension DietPlanSummaryPatterns on DietPlanSummary {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DietPlanSummary value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DietPlanSummary() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DietPlanSummary value)  $default,){
final _that = this;
switch (_that) {
case _DietPlanSummary():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DietPlanSummary value)?  $default,){
final _that = this;
switch (_that) {
case _DietPlanSummary() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  String calorieGoal,  String status,  int version,  num targetKcal,  String? createdAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DietPlanSummary() when $default != null:
return $default(_that.id,_that.name,_that.calorieGoal,_that.status,_that.version,_that.targetKcal,_that.createdAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  String calorieGoal,  String status,  int version,  num targetKcal,  String? createdAt)  $default,) {final _that = this;
switch (_that) {
case _DietPlanSummary():
return $default(_that.id,_that.name,_that.calorieGoal,_that.status,_that.version,_that.targetKcal,_that.createdAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  String calorieGoal,  String status,  int version,  num targetKcal,  String? createdAt)?  $default,) {final _that = this;
switch (_that) {
case _DietPlanSummary() when $default != null:
return $default(_that.id,_that.name,_that.calorieGoal,_that.status,_that.version,_that.targetKcal,_that.createdAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _DietPlanSummary implements DietPlanSummary {
  const _DietPlanSummary({required this.id, required this.name, this.calorieGoal = 'Maintenance', this.status = 'Active', this.version = 1, this.targetKcal = 0, this.createdAt});
  factory _DietPlanSummary.fromJson(Map<String, dynamic> json) => _$DietPlanSummaryFromJson(json);

@override final  String id;
@override final  String name;
@override@JsonKey() final  String calorieGoal;
@override@JsonKey() final  String status;
@override@JsonKey() final  int version;
@override@JsonKey() final  num targetKcal;
@override final  String? createdAt;

/// Create a copy of DietPlanSummary
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DietPlanSummaryCopyWith<_DietPlanSummary> get copyWith => __$DietPlanSummaryCopyWithImpl<_DietPlanSummary>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$DietPlanSummaryToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _DietPlanSummary&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.calorieGoal, calorieGoal) || other.calorieGoal == calorieGoal)&&(identical(other.status, status) || other.status == status)&&(identical(other.version, version) || other.version == version)&&(identical(other.targetKcal, targetKcal) || other.targetKcal == targetKcal)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,calorieGoal,status,version,targetKcal,createdAt);

@override
String toString() {
  return 'DietPlanSummary(id: $id, name: $name, calorieGoal: $calorieGoal, status: $status, version: $version, targetKcal: $targetKcal, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class _$DietPlanSummaryCopyWith<$Res> implements $DietPlanSummaryCopyWith<$Res> {
  factory _$DietPlanSummaryCopyWith(_DietPlanSummary value, $Res Function(_DietPlanSummary) _then) = __$DietPlanSummaryCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, String calorieGoal, String status, int version, num targetKcal, String? createdAt
});




}
/// @nodoc
class __$DietPlanSummaryCopyWithImpl<$Res>
    implements _$DietPlanSummaryCopyWith<$Res> {
  __$DietPlanSummaryCopyWithImpl(this._self, this._then);

  final _DietPlanSummary _self;
  final $Res Function(_DietPlanSummary) _then;

/// Create a copy of DietPlanSummary
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? calorieGoal = null,Object? status = null,Object? version = null,Object? targetKcal = null,Object? createdAt = freezed,}) {
  return _then(_DietPlanSummary(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,calorieGoal: null == calorieGoal ? _self.calorieGoal : calorieGoal // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,version: null == version ? _self.version : version // ignore: cast_nullable_to_non_nullable
as int,targetKcal: null == targetKcal ? _self.targetKcal : targetKcal // ignore: cast_nullable_to_non_nullable
as num,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
