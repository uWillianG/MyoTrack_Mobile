// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'profile_models.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$UserProfile {

 String? get id; String? get userId; String? get birthDate; String? get sex; double? get heightCm; String? get biotype; String get experienceLevel; String get goal; int get trainingDaysPerWeek; List<String> get priorityMuscleGroups; String? get injuryNotes; List<String> get injuryTags; List<String> get availableEquipment; List<String> get dietaryRestrictions; List<String> get foodPreferences;
/// Create a copy of UserProfile
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$UserProfileCopyWith<UserProfile> get copyWith => _$UserProfileCopyWithImpl<UserProfile>(this as UserProfile, _$identity);

  /// Serializes this UserProfile to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UserProfile&&(identical(other.id, id) || other.id == id)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.birthDate, birthDate) || other.birthDate == birthDate)&&(identical(other.sex, sex) || other.sex == sex)&&(identical(other.heightCm, heightCm) || other.heightCm == heightCm)&&(identical(other.biotype, biotype) || other.biotype == biotype)&&(identical(other.experienceLevel, experienceLevel) || other.experienceLevel == experienceLevel)&&(identical(other.goal, goal) || other.goal == goal)&&(identical(other.trainingDaysPerWeek, trainingDaysPerWeek) || other.trainingDaysPerWeek == trainingDaysPerWeek)&&const DeepCollectionEquality().equals(other.priorityMuscleGroups, priorityMuscleGroups)&&(identical(other.injuryNotes, injuryNotes) || other.injuryNotes == injuryNotes)&&const DeepCollectionEquality().equals(other.injuryTags, injuryTags)&&const DeepCollectionEquality().equals(other.availableEquipment, availableEquipment)&&const DeepCollectionEquality().equals(other.dietaryRestrictions, dietaryRestrictions)&&const DeepCollectionEquality().equals(other.foodPreferences, foodPreferences));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,userId,birthDate,sex,heightCm,biotype,experienceLevel,goal,trainingDaysPerWeek,const DeepCollectionEquality().hash(priorityMuscleGroups),injuryNotes,const DeepCollectionEquality().hash(injuryTags),const DeepCollectionEquality().hash(availableEquipment),const DeepCollectionEquality().hash(dietaryRestrictions),const DeepCollectionEquality().hash(foodPreferences));

@override
String toString() {
  return 'UserProfile(id: $id, userId: $userId, birthDate: $birthDate, sex: $sex, heightCm: $heightCm, biotype: $biotype, experienceLevel: $experienceLevel, goal: $goal, trainingDaysPerWeek: $trainingDaysPerWeek, priorityMuscleGroups: $priorityMuscleGroups, injuryNotes: $injuryNotes, injuryTags: $injuryTags, availableEquipment: $availableEquipment, dietaryRestrictions: $dietaryRestrictions, foodPreferences: $foodPreferences)';
}


}

/// @nodoc
abstract mixin class $UserProfileCopyWith<$Res>  {
  factory $UserProfileCopyWith(UserProfile value, $Res Function(UserProfile) _then) = _$UserProfileCopyWithImpl;
@useResult
$Res call({
 String? id, String? userId, String? birthDate, String? sex, double? heightCm, String? biotype, String experienceLevel, String goal, int trainingDaysPerWeek, List<String> priorityMuscleGroups, String? injuryNotes, List<String> injuryTags, List<String> availableEquipment, List<String> dietaryRestrictions, List<String> foodPreferences
});




}
/// @nodoc
class _$UserProfileCopyWithImpl<$Res>
    implements $UserProfileCopyWith<$Res> {
  _$UserProfileCopyWithImpl(this._self, this._then);

  final UserProfile _self;
  final $Res Function(UserProfile) _then;

/// Create a copy of UserProfile
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = freezed,Object? userId = freezed,Object? birthDate = freezed,Object? sex = freezed,Object? heightCm = freezed,Object? biotype = freezed,Object? experienceLevel = null,Object? goal = null,Object? trainingDaysPerWeek = null,Object? priorityMuscleGroups = null,Object? injuryNotes = freezed,Object? injuryTags = null,Object? availableEquipment = null,Object? dietaryRestrictions = null,Object? foodPreferences = null,}) {
  return _then(_self.copyWith(
id: freezed == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String?,userId: freezed == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String?,birthDate: freezed == birthDate ? _self.birthDate : birthDate // ignore: cast_nullable_to_non_nullable
as String?,sex: freezed == sex ? _self.sex : sex // ignore: cast_nullable_to_non_nullable
as String?,heightCm: freezed == heightCm ? _self.heightCm : heightCm // ignore: cast_nullable_to_non_nullable
as double?,biotype: freezed == biotype ? _self.biotype : biotype // ignore: cast_nullable_to_non_nullable
as String?,experienceLevel: null == experienceLevel ? _self.experienceLevel : experienceLevel // ignore: cast_nullable_to_non_nullable
as String,goal: null == goal ? _self.goal : goal // ignore: cast_nullable_to_non_nullable
as String,trainingDaysPerWeek: null == trainingDaysPerWeek ? _self.trainingDaysPerWeek : trainingDaysPerWeek // ignore: cast_nullable_to_non_nullable
as int,priorityMuscleGroups: null == priorityMuscleGroups ? _self.priorityMuscleGroups : priorityMuscleGroups // ignore: cast_nullable_to_non_nullable
as List<String>,injuryNotes: freezed == injuryNotes ? _self.injuryNotes : injuryNotes // ignore: cast_nullable_to_non_nullable
as String?,injuryTags: null == injuryTags ? _self.injuryTags : injuryTags // ignore: cast_nullable_to_non_nullable
as List<String>,availableEquipment: null == availableEquipment ? _self.availableEquipment : availableEquipment // ignore: cast_nullable_to_non_nullable
as List<String>,dietaryRestrictions: null == dietaryRestrictions ? _self.dietaryRestrictions : dietaryRestrictions // ignore: cast_nullable_to_non_nullable
as List<String>,foodPreferences: null == foodPreferences ? _self.foodPreferences : foodPreferences // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}

}


/// Adds pattern-matching-related methods to [UserProfile].
extension UserProfilePatterns on UserProfile {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _UserProfile value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _UserProfile() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _UserProfile value)  $default,){
final _that = this;
switch (_that) {
case _UserProfile():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _UserProfile value)?  $default,){
final _that = this;
switch (_that) {
case _UserProfile() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String? id,  String? userId,  String? birthDate,  String? sex,  double? heightCm,  String? biotype,  String experienceLevel,  String goal,  int trainingDaysPerWeek,  List<String> priorityMuscleGroups,  String? injuryNotes,  List<String> injuryTags,  List<String> availableEquipment,  List<String> dietaryRestrictions,  List<String> foodPreferences)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _UserProfile() when $default != null:
return $default(_that.id,_that.userId,_that.birthDate,_that.sex,_that.heightCm,_that.biotype,_that.experienceLevel,_that.goal,_that.trainingDaysPerWeek,_that.priorityMuscleGroups,_that.injuryNotes,_that.injuryTags,_that.availableEquipment,_that.dietaryRestrictions,_that.foodPreferences);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String? id,  String? userId,  String? birthDate,  String? sex,  double? heightCm,  String? biotype,  String experienceLevel,  String goal,  int trainingDaysPerWeek,  List<String> priorityMuscleGroups,  String? injuryNotes,  List<String> injuryTags,  List<String> availableEquipment,  List<String> dietaryRestrictions,  List<String> foodPreferences)  $default,) {final _that = this;
switch (_that) {
case _UserProfile():
return $default(_that.id,_that.userId,_that.birthDate,_that.sex,_that.heightCm,_that.biotype,_that.experienceLevel,_that.goal,_that.trainingDaysPerWeek,_that.priorityMuscleGroups,_that.injuryNotes,_that.injuryTags,_that.availableEquipment,_that.dietaryRestrictions,_that.foodPreferences);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String? id,  String? userId,  String? birthDate,  String? sex,  double? heightCm,  String? biotype,  String experienceLevel,  String goal,  int trainingDaysPerWeek,  List<String> priorityMuscleGroups,  String? injuryNotes,  List<String> injuryTags,  List<String> availableEquipment,  List<String> dietaryRestrictions,  List<String> foodPreferences)?  $default,) {final _that = this;
switch (_that) {
case _UserProfile() when $default != null:
return $default(_that.id,_that.userId,_that.birthDate,_that.sex,_that.heightCm,_that.biotype,_that.experienceLevel,_that.goal,_that.trainingDaysPerWeek,_that.priorityMuscleGroups,_that.injuryNotes,_that.injuryTags,_that.availableEquipment,_that.dietaryRestrictions,_that.foodPreferences);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _UserProfile implements UserProfile {
  const _UserProfile({this.id, this.userId, this.birthDate, this.sex, this.heightCm, this.biotype, this.experienceLevel = 'Beginner', this.goal = 'Hypertrophy', this.trainingDaysPerWeek = 3, final  List<String> priorityMuscleGroups = const [], this.injuryNotes, final  List<String> injuryTags = const [], final  List<String> availableEquipment = const [], final  List<String> dietaryRestrictions = const [], final  List<String> foodPreferences = const []}): _priorityMuscleGroups = priorityMuscleGroups,_injuryTags = injuryTags,_availableEquipment = availableEquipment,_dietaryRestrictions = dietaryRestrictions,_foodPreferences = foodPreferences;
  factory _UserProfile.fromJson(Map<String, dynamic> json) => _$UserProfileFromJson(json);

@override final  String? id;
@override final  String? userId;
@override final  String? birthDate;
@override final  String? sex;
@override final  double? heightCm;
@override final  String? biotype;
@override@JsonKey() final  String experienceLevel;
@override@JsonKey() final  String goal;
@override@JsonKey() final  int trainingDaysPerWeek;
 final  List<String> _priorityMuscleGroups;
@override@JsonKey() List<String> get priorityMuscleGroups {
  if (_priorityMuscleGroups is EqualUnmodifiableListView) return _priorityMuscleGroups;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_priorityMuscleGroups);
}

@override final  String? injuryNotes;
 final  List<String> _injuryTags;
@override@JsonKey() List<String> get injuryTags {
  if (_injuryTags is EqualUnmodifiableListView) return _injuryTags;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_injuryTags);
}

 final  List<String> _availableEquipment;
@override@JsonKey() List<String> get availableEquipment {
  if (_availableEquipment is EqualUnmodifiableListView) return _availableEquipment;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_availableEquipment);
}

 final  List<String> _dietaryRestrictions;
@override@JsonKey() List<String> get dietaryRestrictions {
  if (_dietaryRestrictions is EqualUnmodifiableListView) return _dietaryRestrictions;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_dietaryRestrictions);
}

 final  List<String> _foodPreferences;
@override@JsonKey() List<String> get foodPreferences {
  if (_foodPreferences is EqualUnmodifiableListView) return _foodPreferences;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_foodPreferences);
}


/// Create a copy of UserProfile
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$UserProfileCopyWith<_UserProfile> get copyWith => __$UserProfileCopyWithImpl<_UserProfile>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$UserProfileToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _UserProfile&&(identical(other.id, id) || other.id == id)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.birthDate, birthDate) || other.birthDate == birthDate)&&(identical(other.sex, sex) || other.sex == sex)&&(identical(other.heightCm, heightCm) || other.heightCm == heightCm)&&(identical(other.biotype, biotype) || other.biotype == biotype)&&(identical(other.experienceLevel, experienceLevel) || other.experienceLevel == experienceLevel)&&(identical(other.goal, goal) || other.goal == goal)&&(identical(other.trainingDaysPerWeek, trainingDaysPerWeek) || other.trainingDaysPerWeek == trainingDaysPerWeek)&&const DeepCollectionEquality().equals(other._priorityMuscleGroups, _priorityMuscleGroups)&&(identical(other.injuryNotes, injuryNotes) || other.injuryNotes == injuryNotes)&&const DeepCollectionEquality().equals(other._injuryTags, _injuryTags)&&const DeepCollectionEquality().equals(other._availableEquipment, _availableEquipment)&&const DeepCollectionEquality().equals(other._dietaryRestrictions, _dietaryRestrictions)&&const DeepCollectionEquality().equals(other._foodPreferences, _foodPreferences));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,userId,birthDate,sex,heightCm,biotype,experienceLevel,goal,trainingDaysPerWeek,const DeepCollectionEquality().hash(_priorityMuscleGroups),injuryNotes,const DeepCollectionEquality().hash(_injuryTags),const DeepCollectionEquality().hash(_availableEquipment),const DeepCollectionEquality().hash(_dietaryRestrictions),const DeepCollectionEquality().hash(_foodPreferences));

@override
String toString() {
  return 'UserProfile(id: $id, userId: $userId, birthDate: $birthDate, sex: $sex, heightCm: $heightCm, biotype: $biotype, experienceLevel: $experienceLevel, goal: $goal, trainingDaysPerWeek: $trainingDaysPerWeek, priorityMuscleGroups: $priorityMuscleGroups, injuryNotes: $injuryNotes, injuryTags: $injuryTags, availableEquipment: $availableEquipment, dietaryRestrictions: $dietaryRestrictions, foodPreferences: $foodPreferences)';
}


}

/// @nodoc
abstract mixin class _$UserProfileCopyWith<$Res> implements $UserProfileCopyWith<$Res> {
  factory _$UserProfileCopyWith(_UserProfile value, $Res Function(_UserProfile) _then) = __$UserProfileCopyWithImpl;
@override @useResult
$Res call({
 String? id, String? userId, String? birthDate, String? sex, double? heightCm, String? biotype, String experienceLevel, String goal, int trainingDaysPerWeek, List<String> priorityMuscleGroups, String? injuryNotes, List<String> injuryTags, List<String> availableEquipment, List<String> dietaryRestrictions, List<String> foodPreferences
});




}
/// @nodoc
class __$UserProfileCopyWithImpl<$Res>
    implements _$UserProfileCopyWith<$Res> {
  __$UserProfileCopyWithImpl(this._self, this._then);

  final _UserProfile _self;
  final $Res Function(_UserProfile) _then;

/// Create a copy of UserProfile
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = freezed,Object? userId = freezed,Object? birthDate = freezed,Object? sex = freezed,Object? heightCm = freezed,Object? biotype = freezed,Object? experienceLevel = null,Object? goal = null,Object? trainingDaysPerWeek = null,Object? priorityMuscleGroups = null,Object? injuryNotes = freezed,Object? injuryTags = null,Object? availableEquipment = null,Object? dietaryRestrictions = null,Object? foodPreferences = null,}) {
  return _then(_UserProfile(
id: freezed == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String?,userId: freezed == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String?,birthDate: freezed == birthDate ? _self.birthDate : birthDate // ignore: cast_nullable_to_non_nullable
as String?,sex: freezed == sex ? _self.sex : sex // ignore: cast_nullable_to_non_nullable
as String?,heightCm: freezed == heightCm ? _self.heightCm : heightCm // ignore: cast_nullable_to_non_nullable
as double?,biotype: freezed == biotype ? _self.biotype : biotype // ignore: cast_nullable_to_non_nullable
as String?,experienceLevel: null == experienceLevel ? _self.experienceLevel : experienceLevel // ignore: cast_nullable_to_non_nullable
as String,goal: null == goal ? _self.goal : goal // ignore: cast_nullable_to_non_nullable
as String,trainingDaysPerWeek: null == trainingDaysPerWeek ? _self.trainingDaysPerWeek : trainingDaysPerWeek // ignore: cast_nullable_to_non_nullable
as int,priorityMuscleGroups: null == priorityMuscleGroups ? _self._priorityMuscleGroups : priorityMuscleGroups // ignore: cast_nullable_to_non_nullable
as List<String>,injuryNotes: freezed == injuryNotes ? _self.injuryNotes : injuryNotes // ignore: cast_nullable_to_non_nullable
as String?,injuryTags: null == injuryTags ? _self._injuryTags : injuryTags // ignore: cast_nullable_to_non_nullable
as List<String>,availableEquipment: null == availableEquipment ? _self._availableEquipment : availableEquipment // ignore: cast_nullable_to_non_nullable
as List<String>,dietaryRestrictions: null == dietaryRestrictions ? _self._dietaryRestrictions : dietaryRestrictions // ignore: cast_nullable_to_non_nullable
as List<String>,foodPreferences: null == foodPreferences ? _self._foodPreferences : foodPreferences // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}


}


/// @nodoc
mixin _$ProfileRequest {

 String? get birthDate; String? get sex; double? get heightCm; String? get biotype; String get experienceLevel; String get goal; int get trainingDaysPerWeek; List<String> get priorityMuscleGroups; String? get injuryNotes; List<String> get injuryTags; List<String> get availableEquipment; List<String> get dietaryRestrictions; List<String> get foodPreferences;
/// Create a copy of ProfileRequest
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProfileRequestCopyWith<ProfileRequest> get copyWith => _$ProfileRequestCopyWithImpl<ProfileRequest>(this as ProfileRequest, _$identity);

  /// Serializes this ProfileRequest to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProfileRequest&&(identical(other.birthDate, birthDate) || other.birthDate == birthDate)&&(identical(other.sex, sex) || other.sex == sex)&&(identical(other.heightCm, heightCm) || other.heightCm == heightCm)&&(identical(other.biotype, biotype) || other.biotype == biotype)&&(identical(other.experienceLevel, experienceLevel) || other.experienceLevel == experienceLevel)&&(identical(other.goal, goal) || other.goal == goal)&&(identical(other.trainingDaysPerWeek, trainingDaysPerWeek) || other.trainingDaysPerWeek == trainingDaysPerWeek)&&const DeepCollectionEquality().equals(other.priorityMuscleGroups, priorityMuscleGroups)&&(identical(other.injuryNotes, injuryNotes) || other.injuryNotes == injuryNotes)&&const DeepCollectionEquality().equals(other.injuryTags, injuryTags)&&const DeepCollectionEquality().equals(other.availableEquipment, availableEquipment)&&const DeepCollectionEquality().equals(other.dietaryRestrictions, dietaryRestrictions)&&const DeepCollectionEquality().equals(other.foodPreferences, foodPreferences));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,birthDate,sex,heightCm,biotype,experienceLevel,goal,trainingDaysPerWeek,const DeepCollectionEquality().hash(priorityMuscleGroups),injuryNotes,const DeepCollectionEquality().hash(injuryTags),const DeepCollectionEquality().hash(availableEquipment),const DeepCollectionEquality().hash(dietaryRestrictions),const DeepCollectionEquality().hash(foodPreferences));

@override
String toString() {
  return 'ProfileRequest(birthDate: $birthDate, sex: $sex, heightCm: $heightCm, biotype: $biotype, experienceLevel: $experienceLevel, goal: $goal, trainingDaysPerWeek: $trainingDaysPerWeek, priorityMuscleGroups: $priorityMuscleGroups, injuryNotes: $injuryNotes, injuryTags: $injuryTags, availableEquipment: $availableEquipment, dietaryRestrictions: $dietaryRestrictions, foodPreferences: $foodPreferences)';
}


}

/// @nodoc
abstract mixin class $ProfileRequestCopyWith<$Res>  {
  factory $ProfileRequestCopyWith(ProfileRequest value, $Res Function(ProfileRequest) _then) = _$ProfileRequestCopyWithImpl;
@useResult
$Res call({
 String? birthDate, String? sex, double? heightCm, String? biotype, String experienceLevel, String goal, int trainingDaysPerWeek, List<String> priorityMuscleGroups, String? injuryNotes, List<String> injuryTags, List<String> availableEquipment, List<String> dietaryRestrictions, List<String> foodPreferences
});




}
/// @nodoc
class _$ProfileRequestCopyWithImpl<$Res>
    implements $ProfileRequestCopyWith<$Res> {
  _$ProfileRequestCopyWithImpl(this._self, this._then);

  final ProfileRequest _self;
  final $Res Function(ProfileRequest) _then;

/// Create a copy of ProfileRequest
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? birthDate = freezed,Object? sex = freezed,Object? heightCm = freezed,Object? biotype = freezed,Object? experienceLevel = null,Object? goal = null,Object? trainingDaysPerWeek = null,Object? priorityMuscleGroups = null,Object? injuryNotes = freezed,Object? injuryTags = null,Object? availableEquipment = null,Object? dietaryRestrictions = null,Object? foodPreferences = null,}) {
  return _then(_self.copyWith(
birthDate: freezed == birthDate ? _self.birthDate : birthDate // ignore: cast_nullable_to_non_nullable
as String?,sex: freezed == sex ? _self.sex : sex // ignore: cast_nullable_to_non_nullable
as String?,heightCm: freezed == heightCm ? _self.heightCm : heightCm // ignore: cast_nullable_to_non_nullable
as double?,biotype: freezed == biotype ? _self.biotype : biotype // ignore: cast_nullable_to_non_nullable
as String?,experienceLevel: null == experienceLevel ? _self.experienceLevel : experienceLevel // ignore: cast_nullable_to_non_nullable
as String,goal: null == goal ? _self.goal : goal // ignore: cast_nullable_to_non_nullable
as String,trainingDaysPerWeek: null == trainingDaysPerWeek ? _self.trainingDaysPerWeek : trainingDaysPerWeek // ignore: cast_nullable_to_non_nullable
as int,priorityMuscleGroups: null == priorityMuscleGroups ? _self.priorityMuscleGroups : priorityMuscleGroups // ignore: cast_nullable_to_non_nullable
as List<String>,injuryNotes: freezed == injuryNotes ? _self.injuryNotes : injuryNotes // ignore: cast_nullable_to_non_nullable
as String?,injuryTags: null == injuryTags ? _self.injuryTags : injuryTags // ignore: cast_nullable_to_non_nullable
as List<String>,availableEquipment: null == availableEquipment ? _self.availableEquipment : availableEquipment // ignore: cast_nullable_to_non_nullable
as List<String>,dietaryRestrictions: null == dietaryRestrictions ? _self.dietaryRestrictions : dietaryRestrictions // ignore: cast_nullable_to_non_nullable
as List<String>,foodPreferences: null == foodPreferences ? _self.foodPreferences : foodPreferences // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}

}


/// Adds pattern-matching-related methods to [ProfileRequest].
extension ProfileRequestPatterns on ProfileRequest {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ProfileRequest value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ProfileRequest() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ProfileRequest value)  $default,){
final _that = this;
switch (_that) {
case _ProfileRequest():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ProfileRequest value)?  $default,){
final _that = this;
switch (_that) {
case _ProfileRequest() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String? birthDate,  String? sex,  double? heightCm,  String? biotype,  String experienceLevel,  String goal,  int trainingDaysPerWeek,  List<String> priorityMuscleGroups,  String? injuryNotes,  List<String> injuryTags,  List<String> availableEquipment,  List<String> dietaryRestrictions,  List<String> foodPreferences)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ProfileRequest() when $default != null:
return $default(_that.birthDate,_that.sex,_that.heightCm,_that.biotype,_that.experienceLevel,_that.goal,_that.trainingDaysPerWeek,_that.priorityMuscleGroups,_that.injuryNotes,_that.injuryTags,_that.availableEquipment,_that.dietaryRestrictions,_that.foodPreferences);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String? birthDate,  String? sex,  double? heightCm,  String? biotype,  String experienceLevel,  String goal,  int trainingDaysPerWeek,  List<String> priorityMuscleGroups,  String? injuryNotes,  List<String> injuryTags,  List<String> availableEquipment,  List<String> dietaryRestrictions,  List<String> foodPreferences)  $default,) {final _that = this;
switch (_that) {
case _ProfileRequest():
return $default(_that.birthDate,_that.sex,_that.heightCm,_that.biotype,_that.experienceLevel,_that.goal,_that.trainingDaysPerWeek,_that.priorityMuscleGroups,_that.injuryNotes,_that.injuryTags,_that.availableEquipment,_that.dietaryRestrictions,_that.foodPreferences);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String? birthDate,  String? sex,  double? heightCm,  String? biotype,  String experienceLevel,  String goal,  int trainingDaysPerWeek,  List<String> priorityMuscleGroups,  String? injuryNotes,  List<String> injuryTags,  List<String> availableEquipment,  List<String> dietaryRestrictions,  List<String> foodPreferences)?  $default,) {final _that = this;
switch (_that) {
case _ProfileRequest() when $default != null:
return $default(_that.birthDate,_that.sex,_that.heightCm,_that.biotype,_that.experienceLevel,_that.goal,_that.trainingDaysPerWeek,_that.priorityMuscleGroups,_that.injuryNotes,_that.injuryTags,_that.availableEquipment,_that.dietaryRestrictions,_that.foodPreferences);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ProfileRequest implements ProfileRequest {
  const _ProfileRequest({this.birthDate, this.sex, this.heightCm, this.biotype, required this.experienceLevel, required this.goal, required this.trainingDaysPerWeek, required final  List<String> priorityMuscleGroups, this.injuryNotes, required final  List<String> injuryTags, required final  List<String> availableEquipment, required final  List<String> dietaryRestrictions, required final  List<String> foodPreferences}): _priorityMuscleGroups = priorityMuscleGroups,_injuryTags = injuryTags,_availableEquipment = availableEquipment,_dietaryRestrictions = dietaryRestrictions,_foodPreferences = foodPreferences;
  factory _ProfileRequest.fromJson(Map<String, dynamic> json) => _$ProfileRequestFromJson(json);

@override final  String? birthDate;
@override final  String? sex;
@override final  double? heightCm;
@override final  String? biotype;
@override final  String experienceLevel;
@override final  String goal;
@override final  int trainingDaysPerWeek;
 final  List<String> _priorityMuscleGroups;
@override List<String> get priorityMuscleGroups {
  if (_priorityMuscleGroups is EqualUnmodifiableListView) return _priorityMuscleGroups;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_priorityMuscleGroups);
}

@override final  String? injuryNotes;
 final  List<String> _injuryTags;
@override List<String> get injuryTags {
  if (_injuryTags is EqualUnmodifiableListView) return _injuryTags;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_injuryTags);
}

 final  List<String> _availableEquipment;
@override List<String> get availableEquipment {
  if (_availableEquipment is EqualUnmodifiableListView) return _availableEquipment;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_availableEquipment);
}

 final  List<String> _dietaryRestrictions;
@override List<String> get dietaryRestrictions {
  if (_dietaryRestrictions is EqualUnmodifiableListView) return _dietaryRestrictions;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_dietaryRestrictions);
}

 final  List<String> _foodPreferences;
@override List<String> get foodPreferences {
  if (_foodPreferences is EqualUnmodifiableListView) return _foodPreferences;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_foodPreferences);
}


/// Create a copy of ProfileRequest
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ProfileRequestCopyWith<_ProfileRequest> get copyWith => __$ProfileRequestCopyWithImpl<_ProfileRequest>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ProfileRequestToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ProfileRequest&&(identical(other.birthDate, birthDate) || other.birthDate == birthDate)&&(identical(other.sex, sex) || other.sex == sex)&&(identical(other.heightCm, heightCm) || other.heightCm == heightCm)&&(identical(other.biotype, biotype) || other.biotype == biotype)&&(identical(other.experienceLevel, experienceLevel) || other.experienceLevel == experienceLevel)&&(identical(other.goal, goal) || other.goal == goal)&&(identical(other.trainingDaysPerWeek, trainingDaysPerWeek) || other.trainingDaysPerWeek == trainingDaysPerWeek)&&const DeepCollectionEquality().equals(other._priorityMuscleGroups, _priorityMuscleGroups)&&(identical(other.injuryNotes, injuryNotes) || other.injuryNotes == injuryNotes)&&const DeepCollectionEquality().equals(other._injuryTags, _injuryTags)&&const DeepCollectionEquality().equals(other._availableEquipment, _availableEquipment)&&const DeepCollectionEquality().equals(other._dietaryRestrictions, _dietaryRestrictions)&&const DeepCollectionEquality().equals(other._foodPreferences, _foodPreferences));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,birthDate,sex,heightCm,biotype,experienceLevel,goal,trainingDaysPerWeek,const DeepCollectionEquality().hash(_priorityMuscleGroups),injuryNotes,const DeepCollectionEquality().hash(_injuryTags),const DeepCollectionEquality().hash(_availableEquipment),const DeepCollectionEquality().hash(_dietaryRestrictions),const DeepCollectionEquality().hash(_foodPreferences));

@override
String toString() {
  return 'ProfileRequest(birthDate: $birthDate, sex: $sex, heightCm: $heightCm, biotype: $biotype, experienceLevel: $experienceLevel, goal: $goal, trainingDaysPerWeek: $trainingDaysPerWeek, priorityMuscleGroups: $priorityMuscleGroups, injuryNotes: $injuryNotes, injuryTags: $injuryTags, availableEquipment: $availableEquipment, dietaryRestrictions: $dietaryRestrictions, foodPreferences: $foodPreferences)';
}


}

/// @nodoc
abstract mixin class _$ProfileRequestCopyWith<$Res> implements $ProfileRequestCopyWith<$Res> {
  factory _$ProfileRequestCopyWith(_ProfileRequest value, $Res Function(_ProfileRequest) _then) = __$ProfileRequestCopyWithImpl;
@override @useResult
$Res call({
 String? birthDate, String? sex, double? heightCm, String? biotype, String experienceLevel, String goal, int trainingDaysPerWeek, List<String> priorityMuscleGroups, String? injuryNotes, List<String> injuryTags, List<String> availableEquipment, List<String> dietaryRestrictions, List<String> foodPreferences
});




}
/// @nodoc
class __$ProfileRequestCopyWithImpl<$Res>
    implements _$ProfileRequestCopyWith<$Res> {
  __$ProfileRequestCopyWithImpl(this._self, this._then);

  final _ProfileRequest _self;
  final $Res Function(_ProfileRequest) _then;

/// Create a copy of ProfileRequest
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? birthDate = freezed,Object? sex = freezed,Object? heightCm = freezed,Object? biotype = freezed,Object? experienceLevel = null,Object? goal = null,Object? trainingDaysPerWeek = null,Object? priorityMuscleGroups = null,Object? injuryNotes = freezed,Object? injuryTags = null,Object? availableEquipment = null,Object? dietaryRestrictions = null,Object? foodPreferences = null,}) {
  return _then(_ProfileRequest(
birthDate: freezed == birthDate ? _self.birthDate : birthDate // ignore: cast_nullable_to_non_nullable
as String?,sex: freezed == sex ? _self.sex : sex // ignore: cast_nullable_to_non_nullable
as String?,heightCm: freezed == heightCm ? _self.heightCm : heightCm // ignore: cast_nullable_to_non_nullable
as double?,biotype: freezed == biotype ? _self.biotype : biotype // ignore: cast_nullable_to_non_nullable
as String?,experienceLevel: null == experienceLevel ? _self.experienceLevel : experienceLevel // ignore: cast_nullable_to_non_nullable
as String,goal: null == goal ? _self.goal : goal // ignore: cast_nullable_to_non_nullable
as String,trainingDaysPerWeek: null == trainingDaysPerWeek ? _self.trainingDaysPerWeek : trainingDaysPerWeek // ignore: cast_nullable_to_non_nullable
as int,priorityMuscleGroups: null == priorityMuscleGroups ? _self._priorityMuscleGroups : priorityMuscleGroups // ignore: cast_nullable_to_non_nullable
as List<String>,injuryNotes: freezed == injuryNotes ? _self.injuryNotes : injuryNotes // ignore: cast_nullable_to_non_nullable
as String?,injuryTags: null == injuryTags ? _self._injuryTags : injuryTags // ignore: cast_nullable_to_non_nullable
as List<String>,availableEquipment: null == availableEquipment ? _self._availableEquipment : availableEquipment // ignore: cast_nullable_to_non_nullable
as List<String>,dietaryRestrictions: null == dietaryRestrictions ? _self._dietaryRestrictions : dietaryRestrictions // ignore: cast_nullable_to_non_nullable
as List<String>,foodPreferences: null == foodPreferences ? _self._foodPreferences : foodPreferences // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}


}


/// @nodoc
mixin _$ConsentRequest {

 String get type; String get termsVersion;
/// Create a copy of ConsentRequest
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ConsentRequestCopyWith<ConsentRequest> get copyWith => _$ConsentRequestCopyWithImpl<ConsentRequest>(this as ConsentRequest, _$identity);

  /// Serializes this ConsentRequest to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ConsentRequest&&(identical(other.type, type) || other.type == type)&&(identical(other.termsVersion, termsVersion) || other.termsVersion == termsVersion));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,type,termsVersion);

@override
String toString() {
  return 'ConsentRequest(type: $type, termsVersion: $termsVersion)';
}


}

/// @nodoc
abstract mixin class $ConsentRequestCopyWith<$Res>  {
  factory $ConsentRequestCopyWith(ConsentRequest value, $Res Function(ConsentRequest) _then) = _$ConsentRequestCopyWithImpl;
@useResult
$Res call({
 String type, String termsVersion
});




}
/// @nodoc
class _$ConsentRequestCopyWithImpl<$Res>
    implements $ConsentRequestCopyWith<$Res> {
  _$ConsentRequestCopyWithImpl(this._self, this._then);

  final ConsentRequest _self;
  final $Res Function(ConsentRequest) _then;

/// Create a copy of ConsentRequest
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? type = null,Object? termsVersion = null,}) {
  return _then(_self.copyWith(
type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,termsVersion: null == termsVersion ? _self.termsVersion : termsVersion // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [ConsentRequest].
extension ConsentRequestPatterns on ConsentRequest {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ConsentRequest value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ConsentRequest() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ConsentRequest value)  $default,){
final _that = this;
switch (_that) {
case _ConsentRequest():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ConsentRequest value)?  $default,){
final _that = this;
switch (_that) {
case _ConsentRequest() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String type,  String termsVersion)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ConsentRequest() when $default != null:
return $default(_that.type,_that.termsVersion);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String type,  String termsVersion)  $default,) {final _that = this;
switch (_that) {
case _ConsentRequest():
return $default(_that.type,_that.termsVersion);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String type,  String termsVersion)?  $default,) {final _that = this;
switch (_that) {
case _ConsentRequest() when $default != null:
return $default(_that.type,_that.termsVersion);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ConsentRequest implements ConsentRequest {
  const _ConsentRequest({required this.type, required this.termsVersion});
  factory _ConsentRequest.fromJson(Map<String, dynamic> json) => _$ConsentRequestFromJson(json);

@override final  String type;
@override final  String termsVersion;

/// Create a copy of ConsentRequest
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ConsentRequestCopyWith<_ConsentRequest> get copyWith => __$ConsentRequestCopyWithImpl<_ConsentRequest>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ConsentRequestToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ConsentRequest&&(identical(other.type, type) || other.type == type)&&(identical(other.termsVersion, termsVersion) || other.termsVersion == termsVersion));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,type,termsVersion);

@override
String toString() {
  return 'ConsentRequest(type: $type, termsVersion: $termsVersion)';
}


}

/// @nodoc
abstract mixin class _$ConsentRequestCopyWith<$Res> implements $ConsentRequestCopyWith<$Res> {
  factory _$ConsentRequestCopyWith(_ConsentRequest value, $Res Function(_ConsentRequest) _then) = __$ConsentRequestCopyWithImpl;
@override @useResult
$Res call({
 String type, String termsVersion
});




}
/// @nodoc
class __$ConsentRequestCopyWithImpl<$Res>
    implements _$ConsentRequestCopyWith<$Res> {
  __$ConsentRequestCopyWithImpl(this._self, this._then);

  final _ConsentRequest _self;
  final $Res Function(_ConsentRequest) _then;

/// Create a copy of ConsentRequest
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? type = null,Object? termsVersion = null,}) {
  return _then(_ConsentRequest(
type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,termsVersion: null == termsVersion ? _self.termsVersion : termsVersion // ignore: cast_nullable_to_non_nullable
as String,
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
