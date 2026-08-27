// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'meal_models.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$MealAnalysisItem {

 String get description;/// Ligação com o catálogo de alimentos, quando o backend conseguiu fazê-la.
 int? get foodItemId; num get quantityG; num get kcal; num get proteinG; num get carbsG; num get fatG;/// Centro do alimento na foto, escala 0–1000. Só serve para desenhar a etiqueta na
/// versão ilustrada — nenhum número nutricional depende disso.
 int? get posX; int? get posY;
/// Create a copy of MealAnalysisItem
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MealAnalysisItemCopyWith<MealAnalysisItem> get copyWith => _$MealAnalysisItemCopyWithImpl<MealAnalysisItem>(this as MealAnalysisItem, _$identity);

  /// Serializes this MealAnalysisItem to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MealAnalysisItem&&(identical(other.description, description) || other.description == description)&&(identical(other.foodItemId, foodItemId) || other.foodItemId == foodItemId)&&(identical(other.quantityG, quantityG) || other.quantityG == quantityG)&&(identical(other.kcal, kcal) || other.kcal == kcal)&&(identical(other.proteinG, proteinG) || other.proteinG == proteinG)&&(identical(other.carbsG, carbsG) || other.carbsG == carbsG)&&(identical(other.fatG, fatG) || other.fatG == fatG)&&(identical(other.posX, posX) || other.posX == posX)&&(identical(other.posY, posY) || other.posY == posY));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,description,foodItemId,quantityG,kcal,proteinG,carbsG,fatG,posX,posY);

@override
String toString() {
  return 'MealAnalysisItem(description: $description, foodItemId: $foodItemId, quantityG: $quantityG, kcal: $kcal, proteinG: $proteinG, carbsG: $carbsG, fatG: $fatG, posX: $posX, posY: $posY)';
}


}

/// @nodoc
abstract mixin class $MealAnalysisItemCopyWith<$Res>  {
  factory $MealAnalysisItemCopyWith(MealAnalysisItem value, $Res Function(MealAnalysisItem) _then) = _$MealAnalysisItemCopyWithImpl;
@useResult
$Res call({
 String description, int? foodItemId, num quantityG, num kcal, num proteinG, num carbsG, num fatG, int? posX, int? posY
});




}
/// @nodoc
class _$MealAnalysisItemCopyWithImpl<$Res>
    implements $MealAnalysisItemCopyWith<$Res> {
  _$MealAnalysisItemCopyWithImpl(this._self, this._then);

  final MealAnalysisItem _self;
  final $Res Function(MealAnalysisItem) _then;

/// Create a copy of MealAnalysisItem
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? description = null,Object? foodItemId = freezed,Object? quantityG = null,Object? kcal = null,Object? proteinG = null,Object? carbsG = null,Object? fatG = null,Object? posX = freezed,Object? posY = freezed,}) {
  return _then(_self.copyWith(
description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,foodItemId: freezed == foodItemId ? _self.foodItemId : foodItemId // ignore: cast_nullable_to_non_nullable
as int?,quantityG: null == quantityG ? _self.quantityG : quantityG // ignore: cast_nullable_to_non_nullable
as num,kcal: null == kcal ? _self.kcal : kcal // ignore: cast_nullable_to_non_nullable
as num,proteinG: null == proteinG ? _self.proteinG : proteinG // ignore: cast_nullable_to_non_nullable
as num,carbsG: null == carbsG ? _self.carbsG : carbsG // ignore: cast_nullable_to_non_nullable
as num,fatG: null == fatG ? _self.fatG : fatG // ignore: cast_nullable_to_non_nullable
as num,posX: freezed == posX ? _self.posX : posX // ignore: cast_nullable_to_non_nullable
as int?,posY: freezed == posY ? _self.posY : posY // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}

}


/// Adds pattern-matching-related methods to [MealAnalysisItem].
extension MealAnalysisItemPatterns on MealAnalysisItem {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MealAnalysisItem value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MealAnalysisItem() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MealAnalysisItem value)  $default,){
final _that = this;
switch (_that) {
case _MealAnalysisItem():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MealAnalysisItem value)?  $default,){
final _that = this;
switch (_that) {
case _MealAnalysisItem() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String description,  int? foodItemId,  num quantityG,  num kcal,  num proteinG,  num carbsG,  num fatG,  int? posX,  int? posY)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MealAnalysisItem() when $default != null:
return $default(_that.description,_that.foodItemId,_that.quantityG,_that.kcal,_that.proteinG,_that.carbsG,_that.fatG,_that.posX,_that.posY);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String description,  int? foodItemId,  num quantityG,  num kcal,  num proteinG,  num carbsG,  num fatG,  int? posX,  int? posY)  $default,) {final _that = this;
switch (_that) {
case _MealAnalysisItem():
return $default(_that.description,_that.foodItemId,_that.quantityG,_that.kcal,_that.proteinG,_that.carbsG,_that.fatG,_that.posX,_that.posY);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String description,  int? foodItemId,  num quantityG,  num kcal,  num proteinG,  num carbsG,  num fatG,  int? posX,  int? posY)?  $default,) {final _that = this;
switch (_that) {
case _MealAnalysisItem() when $default != null:
return $default(_that.description,_that.foodItemId,_that.quantityG,_that.kcal,_that.proteinG,_that.carbsG,_that.fatG,_that.posX,_that.posY);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _MealAnalysisItem implements MealAnalysisItem {
  const _MealAnalysisItem({required this.description, this.foodItemId, this.quantityG = 0, this.kcal = 0, this.proteinG = 0, this.carbsG = 0, this.fatG = 0, this.posX, this.posY});
  factory _MealAnalysisItem.fromJson(Map<String, dynamic> json) => _$MealAnalysisItemFromJson(json);

@override final  String description;
/// Ligação com o catálogo de alimentos, quando o backend conseguiu fazê-la.
@override final  int? foodItemId;
@override@JsonKey() final  num quantityG;
@override@JsonKey() final  num kcal;
@override@JsonKey() final  num proteinG;
@override@JsonKey() final  num carbsG;
@override@JsonKey() final  num fatG;
/// Centro do alimento na foto, escala 0–1000. Só serve para desenhar a etiqueta na
/// versão ilustrada — nenhum número nutricional depende disso.
@override final  int? posX;
@override final  int? posY;

/// Create a copy of MealAnalysisItem
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MealAnalysisItemCopyWith<_MealAnalysisItem> get copyWith => __$MealAnalysisItemCopyWithImpl<_MealAnalysisItem>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$MealAnalysisItemToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _MealAnalysisItem&&(identical(other.description, description) || other.description == description)&&(identical(other.foodItemId, foodItemId) || other.foodItemId == foodItemId)&&(identical(other.quantityG, quantityG) || other.quantityG == quantityG)&&(identical(other.kcal, kcal) || other.kcal == kcal)&&(identical(other.proteinG, proteinG) || other.proteinG == proteinG)&&(identical(other.carbsG, carbsG) || other.carbsG == carbsG)&&(identical(other.fatG, fatG) || other.fatG == fatG)&&(identical(other.posX, posX) || other.posX == posX)&&(identical(other.posY, posY) || other.posY == posY));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,description,foodItemId,quantityG,kcal,proteinG,carbsG,fatG,posX,posY);

@override
String toString() {
  return 'MealAnalysisItem(description: $description, foodItemId: $foodItemId, quantityG: $quantityG, kcal: $kcal, proteinG: $proteinG, carbsG: $carbsG, fatG: $fatG, posX: $posX, posY: $posY)';
}


}

/// @nodoc
abstract mixin class _$MealAnalysisItemCopyWith<$Res> implements $MealAnalysisItemCopyWith<$Res> {
  factory _$MealAnalysisItemCopyWith(_MealAnalysisItem value, $Res Function(_MealAnalysisItem) _then) = __$MealAnalysisItemCopyWithImpl;
@override @useResult
$Res call({
 String description, int? foodItemId, num quantityG, num kcal, num proteinG, num carbsG, num fatG, int? posX, int? posY
});




}
/// @nodoc
class __$MealAnalysisItemCopyWithImpl<$Res>
    implements _$MealAnalysisItemCopyWith<$Res> {
  __$MealAnalysisItemCopyWithImpl(this._self, this._then);

  final _MealAnalysisItem _self;
  final $Res Function(_MealAnalysisItem) _then;

/// Create a copy of MealAnalysisItem
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? description = null,Object? foodItemId = freezed,Object? quantityG = null,Object? kcal = null,Object? proteinG = null,Object? carbsG = null,Object? fatG = null,Object? posX = freezed,Object? posY = freezed,}) {
  return _then(_MealAnalysisItem(
description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,foodItemId: freezed == foodItemId ? _self.foodItemId : foodItemId // ignore: cast_nullable_to_non_nullable
as int?,quantityG: null == quantityG ? _self.quantityG : quantityG // ignore: cast_nullable_to_non_nullable
as num,kcal: null == kcal ? _self.kcal : kcal // ignore: cast_nullable_to_non_nullable
as num,proteinG: null == proteinG ? _self.proteinG : proteinG // ignore: cast_nullable_to_non_nullable
as num,carbsG: null == carbsG ? _self.carbsG : carbsG // ignore: cast_nullable_to_non_nullable
as num,fatG: null == fatG ? _self.fatG : fatG // ignore: cast_nullable_to_non_nullable
as num,posX: freezed == posX ? _self.posX : posX // ignore: cast_nullable_to_non_nullable
as int?,posY: freezed == posY ? _self.posY : posY // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}


}


/// @nodoc
mixin _$MealAnalysis {

 String get id;/// Null na refeição manual: ela não passou pela fila de IA para ser gravada.
 String? get analysisJobId;/// `"Photo"` ou `"Manual"` — a origem da refeição.
///
/// **Não dá para deduzir isto de [photoUrl] nula**, e é por isso que o campo existe: a
/// retenção de mídia (LGPD) apaga a foto de análises antigas e deixa o resultado para
/// trás, então "nunca teve foto" e "a foto expirou" chegam aqui idênticas. String crua
/// como `calorieGoal` e `reviewStatus`: um enum do lado do app quebraria na primeira vez
/// que o servidor emitisse um valor novo, e o que se faz com ele aqui é decidir se cabe
/// oferecer a foto.
 String? get source; List<MealAnalysisItem> get items; num get totalKcal; num get totalProteinG; num get totalCarbsG; num get totalFatG;/// O usuário corrigiu a estimativa da IA.
 bool get userAdjusted;/// Fora do diário: continua no histórico, mas não soma no dia.
 bool get excludedFromDiary;/// URL temporária da foto. Null quando a retenção (LGPD) já apagou o arquivo — o
/// resultado da análise sobrevive à imagem.
 String? get photoUrl;/// Foto anotada pela IA. Null quando o modo ilustrado não foi pedido, ou quando a
/// geração não pôde ser feita — a análise vale igual sem ela.
 String? get illustratedPhotoUrl; String? get createdAt;
/// Create a copy of MealAnalysis
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MealAnalysisCopyWith<MealAnalysis> get copyWith => _$MealAnalysisCopyWithImpl<MealAnalysis>(this as MealAnalysis, _$identity);

  /// Serializes this MealAnalysis to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MealAnalysis&&(identical(other.id, id) || other.id == id)&&(identical(other.analysisJobId, analysisJobId) || other.analysisJobId == analysisJobId)&&(identical(other.source, source) || other.source == source)&&const DeepCollectionEquality().equals(other.items, items)&&(identical(other.totalKcal, totalKcal) || other.totalKcal == totalKcal)&&(identical(other.totalProteinG, totalProteinG) || other.totalProteinG == totalProteinG)&&(identical(other.totalCarbsG, totalCarbsG) || other.totalCarbsG == totalCarbsG)&&(identical(other.totalFatG, totalFatG) || other.totalFatG == totalFatG)&&(identical(other.userAdjusted, userAdjusted) || other.userAdjusted == userAdjusted)&&(identical(other.excludedFromDiary, excludedFromDiary) || other.excludedFromDiary == excludedFromDiary)&&(identical(other.photoUrl, photoUrl) || other.photoUrl == photoUrl)&&(identical(other.illustratedPhotoUrl, illustratedPhotoUrl) || other.illustratedPhotoUrl == illustratedPhotoUrl)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,analysisJobId,source,const DeepCollectionEquality().hash(items),totalKcal,totalProteinG,totalCarbsG,totalFatG,userAdjusted,excludedFromDiary,photoUrl,illustratedPhotoUrl,createdAt);

@override
String toString() {
  return 'MealAnalysis(id: $id, analysisJobId: $analysisJobId, source: $source, items: $items, totalKcal: $totalKcal, totalProteinG: $totalProteinG, totalCarbsG: $totalCarbsG, totalFatG: $totalFatG, userAdjusted: $userAdjusted, excludedFromDiary: $excludedFromDiary, photoUrl: $photoUrl, illustratedPhotoUrl: $illustratedPhotoUrl, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class $MealAnalysisCopyWith<$Res>  {
  factory $MealAnalysisCopyWith(MealAnalysis value, $Res Function(MealAnalysis) _then) = _$MealAnalysisCopyWithImpl;
@useResult
$Res call({
 String id, String? analysisJobId, String? source, List<MealAnalysisItem> items, num totalKcal, num totalProteinG, num totalCarbsG, num totalFatG, bool userAdjusted, bool excludedFromDiary, String? photoUrl, String? illustratedPhotoUrl, String? createdAt
});




}
/// @nodoc
class _$MealAnalysisCopyWithImpl<$Res>
    implements $MealAnalysisCopyWith<$Res> {
  _$MealAnalysisCopyWithImpl(this._self, this._then);

  final MealAnalysis _self;
  final $Res Function(MealAnalysis) _then;

/// Create a copy of MealAnalysis
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? analysisJobId = freezed,Object? source = freezed,Object? items = null,Object? totalKcal = null,Object? totalProteinG = null,Object? totalCarbsG = null,Object? totalFatG = null,Object? userAdjusted = null,Object? excludedFromDiary = null,Object? photoUrl = freezed,Object? illustratedPhotoUrl = freezed,Object? createdAt = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,analysisJobId: freezed == analysisJobId ? _self.analysisJobId : analysisJobId // ignore: cast_nullable_to_non_nullable
as String?,source: freezed == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as String?,items: null == items ? _self.items : items // ignore: cast_nullable_to_non_nullable
as List<MealAnalysisItem>,totalKcal: null == totalKcal ? _self.totalKcal : totalKcal // ignore: cast_nullable_to_non_nullable
as num,totalProteinG: null == totalProteinG ? _self.totalProteinG : totalProteinG // ignore: cast_nullable_to_non_nullable
as num,totalCarbsG: null == totalCarbsG ? _self.totalCarbsG : totalCarbsG // ignore: cast_nullable_to_non_nullable
as num,totalFatG: null == totalFatG ? _self.totalFatG : totalFatG // ignore: cast_nullable_to_non_nullable
as num,userAdjusted: null == userAdjusted ? _self.userAdjusted : userAdjusted // ignore: cast_nullable_to_non_nullable
as bool,excludedFromDiary: null == excludedFromDiary ? _self.excludedFromDiary : excludedFromDiary // ignore: cast_nullable_to_non_nullable
as bool,photoUrl: freezed == photoUrl ? _self.photoUrl : photoUrl // ignore: cast_nullable_to_non_nullable
as String?,illustratedPhotoUrl: freezed == illustratedPhotoUrl ? _self.illustratedPhotoUrl : illustratedPhotoUrl // ignore: cast_nullable_to_non_nullable
as String?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [MealAnalysis].
extension MealAnalysisPatterns on MealAnalysis {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MealAnalysis value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MealAnalysis() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MealAnalysis value)  $default,){
final _that = this;
switch (_that) {
case _MealAnalysis():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MealAnalysis value)?  $default,){
final _that = this;
switch (_that) {
case _MealAnalysis() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String? analysisJobId,  String? source,  List<MealAnalysisItem> items,  num totalKcal,  num totalProteinG,  num totalCarbsG,  num totalFatG,  bool userAdjusted,  bool excludedFromDiary,  String? photoUrl,  String? illustratedPhotoUrl,  String? createdAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MealAnalysis() when $default != null:
return $default(_that.id,_that.analysisJobId,_that.source,_that.items,_that.totalKcal,_that.totalProteinG,_that.totalCarbsG,_that.totalFatG,_that.userAdjusted,_that.excludedFromDiary,_that.photoUrl,_that.illustratedPhotoUrl,_that.createdAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String? analysisJobId,  String? source,  List<MealAnalysisItem> items,  num totalKcal,  num totalProteinG,  num totalCarbsG,  num totalFatG,  bool userAdjusted,  bool excludedFromDiary,  String? photoUrl,  String? illustratedPhotoUrl,  String? createdAt)  $default,) {final _that = this;
switch (_that) {
case _MealAnalysis():
return $default(_that.id,_that.analysisJobId,_that.source,_that.items,_that.totalKcal,_that.totalProteinG,_that.totalCarbsG,_that.totalFatG,_that.userAdjusted,_that.excludedFromDiary,_that.photoUrl,_that.illustratedPhotoUrl,_that.createdAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String? analysisJobId,  String? source,  List<MealAnalysisItem> items,  num totalKcal,  num totalProteinG,  num totalCarbsG,  num totalFatG,  bool userAdjusted,  bool excludedFromDiary,  String? photoUrl,  String? illustratedPhotoUrl,  String? createdAt)?  $default,) {final _that = this;
switch (_that) {
case _MealAnalysis() when $default != null:
return $default(_that.id,_that.analysisJobId,_that.source,_that.items,_that.totalKcal,_that.totalProteinG,_that.totalCarbsG,_that.totalFatG,_that.userAdjusted,_that.excludedFromDiary,_that.photoUrl,_that.illustratedPhotoUrl,_that.createdAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _MealAnalysis extends MealAnalysis {
  const _MealAnalysis({required this.id, this.analysisJobId, this.source, final  List<MealAnalysisItem> items = const [], this.totalKcal = 0, this.totalProteinG = 0, this.totalCarbsG = 0, this.totalFatG = 0, this.userAdjusted = false, this.excludedFromDiary = false, this.photoUrl, this.illustratedPhotoUrl, this.createdAt}): _items = items,super._();
  factory _MealAnalysis.fromJson(Map<String, dynamic> json) => _$MealAnalysisFromJson(json);

@override final  String id;
/// Null na refeição manual: ela não passou pela fila de IA para ser gravada.
@override final  String? analysisJobId;
/// `"Photo"` ou `"Manual"` — a origem da refeição.
///
/// **Não dá para deduzir isto de [photoUrl] nula**, e é por isso que o campo existe: a
/// retenção de mídia (LGPD) apaga a foto de análises antigas e deixa o resultado para
/// trás, então "nunca teve foto" e "a foto expirou" chegam aqui idênticas. String crua
/// como `calorieGoal` e `reviewStatus`: um enum do lado do app quebraria na primeira vez
/// que o servidor emitisse um valor novo, e o que se faz com ele aqui é decidir se cabe
/// oferecer a foto.
@override final  String? source;
 final  List<MealAnalysisItem> _items;
@override@JsonKey() List<MealAnalysisItem> get items {
  if (_items is EqualUnmodifiableListView) return _items;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_items);
}

@override@JsonKey() final  num totalKcal;
@override@JsonKey() final  num totalProteinG;
@override@JsonKey() final  num totalCarbsG;
@override@JsonKey() final  num totalFatG;
/// O usuário corrigiu a estimativa da IA.
@override@JsonKey() final  bool userAdjusted;
/// Fora do diário: continua no histórico, mas não soma no dia.
@override@JsonKey() final  bool excludedFromDiary;
/// URL temporária da foto. Null quando a retenção (LGPD) já apagou o arquivo — o
/// resultado da análise sobrevive à imagem.
@override final  String? photoUrl;
/// Foto anotada pela IA. Null quando o modo ilustrado não foi pedido, ou quando a
/// geração não pôde ser feita — a análise vale igual sem ela.
@override final  String? illustratedPhotoUrl;
@override final  String? createdAt;

/// Create a copy of MealAnalysis
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MealAnalysisCopyWith<_MealAnalysis> get copyWith => __$MealAnalysisCopyWithImpl<_MealAnalysis>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$MealAnalysisToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _MealAnalysis&&(identical(other.id, id) || other.id == id)&&(identical(other.analysisJobId, analysisJobId) || other.analysisJobId == analysisJobId)&&(identical(other.source, source) || other.source == source)&&const DeepCollectionEquality().equals(other._items, _items)&&(identical(other.totalKcal, totalKcal) || other.totalKcal == totalKcal)&&(identical(other.totalProteinG, totalProteinG) || other.totalProteinG == totalProteinG)&&(identical(other.totalCarbsG, totalCarbsG) || other.totalCarbsG == totalCarbsG)&&(identical(other.totalFatG, totalFatG) || other.totalFatG == totalFatG)&&(identical(other.userAdjusted, userAdjusted) || other.userAdjusted == userAdjusted)&&(identical(other.excludedFromDiary, excludedFromDiary) || other.excludedFromDiary == excludedFromDiary)&&(identical(other.photoUrl, photoUrl) || other.photoUrl == photoUrl)&&(identical(other.illustratedPhotoUrl, illustratedPhotoUrl) || other.illustratedPhotoUrl == illustratedPhotoUrl)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,analysisJobId,source,const DeepCollectionEquality().hash(_items),totalKcal,totalProteinG,totalCarbsG,totalFatG,userAdjusted,excludedFromDiary,photoUrl,illustratedPhotoUrl,createdAt);

@override
String toString() {
  return 'MealAnalysis(id: $id, analysisJobId: $analysisJobId, source: $source, items: $items, totalKcal: $totalKcal, totalProteinG: $totalProteinG, totalCarbsG: $totalCarbsG, totalFatG: $totalFatG, userAdjusted: $userAdjusted, excludedFromDiary: $excludedFromDiary, photoUrl: $photoUrl, illustratedPhotoUrl: $illustratedPhotoUrl, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class _$MealAnalysisCopyWith<$Res> implements $MealAnalysisCopyWith<$Res> {
  factory _$MealAnalysisCopyWith(_MealAnalysis value, $Res Function(_MealAnalysis) _then) = __$MealAnalysisCopyWithImpl;
@override @useResult
$Res call({
 String id, String? analysisJobId, String? source, List<MealAnalysisItem> items, num totalKcal, num totalProteinG, num totalCarbsG, num totalFatG, bool userAdjusted, bool excludedFromDiary, String? photoUrl, String? illustratedPhotoUrl, String? createdAt
});




}
/// @nodoc
class __$MealAnalysisCopyWithImpl<$Res>
    implements _$MealAnalysisCopyWith<$Res> {
  __$MealAnalysisCopyWithImpl(this._self, this._then);

  final _MealAnalysis _self;
  final $Res Function(_MealAnalysis) _then;

/// Create a copy of MealAnalysis
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? analysisJobId = freezed,Object? source = freezed,Object? items = null,Object? totalKcal = null,Object? totalProteinG = null,Object? totalCarbsG = null,Object? totalFatG = null,Object? userAdjusted = null,Object? excludedFromDiary = null,Object? photoUrl = freezed,Object? illustratedPhotoUrl = freezed,Object? createdAt = freezed,}) {
  return _then(_MealAnalysis(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,analysisJobId: freezed == analysisJobId ? _self.analysisJobId : analysisJobId // ignore: cast_nullable_to_non_nullable
as String?,source: freezed == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as String?,items: null == items ? _self._items : items // ignore: cast_nullable_to_non_nullable
as List<MealAnalysisItem>,totalKcal: null == totalKcal ? _self.totalKcal : totalKcal // ignore: cast_nullable_to_non_nullable
as num,totalProteinG: null == totalProteinG ? _self.totalProteinG : totalProteinG // ignore: cast_nullable_to_non_nullable
as num,totalCarbsG: null == totalCarbsG ? _self.totalCarbsG : totalCarbsG // ignore: cast_nullable_to_non_nullable
as num,totalFatG: null == totalFatG ? _self.totalFatG : totalFatG // ignore: cast_nullable_to_non_nullable
as num,userAdjusted: null == userAdjusted ? _self.userAdjusted : userAdjusted // ignore: cast_nullable_to_non_nullable
as bool,excludedFromDiary: null == excludedFromDiary ? _self.excludedFromDiary : excludedFromDiary // ignore: cast_nullable_to_non_nullable
as bool,photoUrl: freezed == photoUrl ? _self.photoUrl : photoUrl // ignore: cast_nullable_to_non_nullable
as String?,illustratedPhotoUrl: freezed == illustratedPhotoUrl ? _self.illustratedPhotoUrl : illustratedPhotoUrl // ignore: cast_nullable_to_non_nullable
as String?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$FoodItem {

 int get id; String get name; num get kcalPer100g; num get proteinPer100g; num get carbsPer100g; num get fatPer100g; num? get fiberPer100g;/// "TACO", "TBCA" ou "Custom" — de onde vieram os números.
 String? get source;
/// Create a copy of FoodItem
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FoodItemCopyWith<FoodItem> get copyWith => _$FoodItemCopyWithImpl<FoodItem>(this as FoodItem, _$identity);

  /// Serializes this FoodItem to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is FoodItem&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.kcalPer100g, kcalPer100g) || other.kcalPer100g == kcalPer100g)&&(identical(other.proteinPer100g, proteinPer100g) || other.proteinPer100g == proteinPer100g)&&(identical(other.carbsPer100g, carbsPer100g) || other.carbsPer100g == carbsPer100g)&&(identical(other.fatPer100g, fatPer100g) || other.fatPer100g == fatPer100g)&&(identical(other.fiberPer100g, fiberPer100g) || other.fiberPer100g == fiberPer100g)&&(identical(other.source, source) || other.source == source));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,kcalPer100g,proteinPer100g,carbsPer100g,fatPer100g,fiberPer100g,source);

@override
String toString() {
  return 'FoodItem(id: $id, name: $name, kcalPer100g: $kcalPer100g, proteinPer100g: $proteinPer100g, carbsPer100g: $carbsPer100g, fatPer100g: $fatPer100g, fiberPer100g: $fiberPer100g, source: $source)';
}


}

/// @nodoc
abstract mixin class $FoodItemCopyWith<$Res>  {
  factory $FoodItemCopyWith(FoodItem value, $Res Function(FoodItem) _then) = _$FoodItemCopyWithImpl;
@useResult
$Res call({
 int id, String name, num kcalPer100g, num proteinPer100g, num carbsPer100g, num fatPer100g, num? fiberPer100g, String? source
});




}
/// @nodoc
class _$FoodItemCopyWithImpl<$Res>
    implements $FoodItemCopyWith<$Res> {
  _$FoodItemCopyWithImpl(this._self, this._then);

  final FoodItem _self;
  final $Res Function(FoodItem) _then;

/// Create a copy of FoodItem
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? kcalPer100g = null,Object? proteinPer100g = null,Object? carbsPer100g = null,Object? fatPer100g = null,Object? fiberPer100g = freezed,Object? source = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,kcalPer100g: null == kcalPer100g ? _self.kcalPer100g : kcalPer100g // ignore: cast_nullable_to_non_nullable
as num,proteinPer100g: null == proteinPer100g ? _self.proteinPer100g : proteinPer100g // ignore: cast_nullable_to_non_nullable
as num,carbsPer100g: null == carbsPer100g ? _self.carbsPer100g : carbsPer100g // ignore: cast_nullable_to_non_nullable
as num,fatPer100g: null == fatPer100g ? _self.fatPer100g : fatPer100g // ignore: cast_nullable_to_non_nullable
as num,fiberPer100g: freezed == fiberPer100g ? _self.fiberPer100g : fiberPer100g // ignore: cast_nullable_to_non_nullable
as num?,source: freezed == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [FoodItem].
extension FoodItemPatterns on FoodItem {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _FoodItem value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _FoodItem() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _FoodItem value)  $default,){
final _that = this;
switch (_that) {
case _FoodItem():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _FoodItem value)?  $default,){
final _that = this;
switch (_that) {
case _FoodItem() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  String name,  num kcalPer100g,  num proteinPer100g,  num carbsPer100g,  num fatPer100g,  num? fiberPer100g,  String? source)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _FoodItem() when $default != null:
return $default(_that.id,_that.name,_that.kcalPer100g,_that.proteinPer100g,_that.carbsPer100g,_that.fatPer100g,_that.fiberPer100g,_that.source);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  String name,  num kcalPer100g,  num proteinPer100g,  num carbsPer100g,  num fatPer100g,  num? fiberPer100g,  String? source)  $default,) {final _that = this;
switch (_that) {
case _FoodItem():
return $default(_that.id,_that.name,_that.kcalPer100g,_that.proteinPer100g,_that.carbsPer100g,_that.fatPer100g,_that.fiberPer100g,_that.source);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  String name,  num kcalPer100g,  num proteinPer100g,  num carbsPer100g,  num fatPer100g,  num? fiberPer100g,  String? source)?  $default,) {final _that = this;
switch (_that) {
case _FoodItem() when $default != null:
return $default(_that.id,_that.name,_that.kcalPer100g,_that.proteinPer100g,_that.carbsPer100g,_that.fatPer100g,_that.fiberPer100g,_that.source);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _FoodItem implements FoodItem {
  const _FoodItem({required this.id, required this.name, this.kcalPer100g = 0, this.proteinPer100g = 0, this.carbsPer100g = 0, this.fatPer100g = 0, this.fiberPer100g, this.source});
  factory _FoodItem.fromJson(Map<String, dynamic> json) => _$FoodItemFromJson(json);

@override final  int id;
@override final  String name;
@override@JsonKey() final  num kcalPer100g;
@override@JsonKey() final  num proteinPer100g;
@override@JsonKey() final  num carbsPer100g;
@override@JsonKey() final  num fatPer100g;
@override final  num? fiberPer100g;
/// "TACO", "TBCA" ou "Custom" — de onde vieram os números.
@override final  String? source;

/// Create a copy of FoodItem
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$FoodItemCopyWith<_FoodItem> get copyWith => __$FoodItemCopyWithImpl<_FoodItem>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$FoodItemToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _FoodItem&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.kcalPer100g, kcalPer100g) || other.kcalPer100g == kcalPer100g)&&(identical(other.proteinPer100g, proteinPer100g) || other.proteinPer100g == proteinPer100g)&&(identical(other.carbsPer100g, carbsPer100g) || other.carbsPer100g == carbsPer100g)&&(identical(other.fatPer100g, fatPer100g) || other.fatPer100g == fatPer100g)&&(identical(other.fiberPer100g, fiberPer100g) || other.fiberPer100g == fiberPer100g)&&(identical(other.source, source) || other.source == source));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,kcalPer100g,proteinPer100g,carbsPer100g,fatPer100g,fiberPer100g,source);

@override
String toString() {
  return 'FoodItem(id: $id, name: $name, kcalPer100g: $kcalPer100g, proteinPer100g: $proteinPer100g, carbsPer100g: $carbsPer100g, fatPer100g: $fatPer100g, fiberPer100g: $fiberPer100g, source: $source)';
}


}

/// @nodoc
abstract mixin class _$FoodItemCopyWith<$Res> implements $FoodItemCopyWith<$Res> {
  factory _$FoodItemCopyWith(_FoodItem value, $Res Function(_FoodItem) _then) = __$FoodItemCopyWithImpl;
@override @useResult
$Res call({
 int id, String name, num kcalPer100g, num proteinPer100g, num carbsPer100g, num fatPer100g, num? fiberPer100g, String? source
});




}
/// @nodoc
class __$FoodItemCopyWithImpl<$Res>
    implements _$FoodItemCopyWith<$Res> {
  __$FoodItemCopyWithImpl(this._self, this._then);

  final _FoodItem _self;
  final $Res Function(_FoodItem) _then;

/// Create a copy of FoodItem
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? kcalPer100g = null,Object? proteinPer100g = null,Object? carbsPer100g = null,Object? fatPer100g = null,Object? fiberPer100g = freezed,Object? source = freezed,}) {
  return _then(_FoodItem(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,kcalPer100g: null == kcalPer100g ? _self.kcalPer100g : kcalPer100g // ignore: cast_nullable_to_non_nullable
as num,proteinPer100g: null == proteinPer100g ? _self.proteinPer100g : proteinPer100g // ignore: cast_nullable_to_non_nullable
as num,carbsPer100g: null == carbsPer100g ? _self.carbsPer100g : carbsPer100g // ignore: cast_nullable_to_non_nullable
as num,fatPer100g: null == fatPer100g ? _self.fatPer100g : fatPer100g // ignore: cast_nullable_to_non_nullable
as num,fiberPer100g: freezed == fiberPer100g ? _self.fiberPer100g : fiberPer100g // ignore: cast_nullable_to_non_nullable
as num?,source: freezed == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$MealManualItem {

 String get description; int? get foodItemId; num get quantityG; num get kcal; num get proteinG; num get carbsG; num get fatG;
/// Create a copy of MealManualItem
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MealManualItemCopyWith<MealManualItem> get copyWith => _$MealManualItemCopyWithImpl<MealManualItem>(this as MealManualItem, _$identity);

  /// Serializes this MealManualItem to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MealManualItem&&(identical(other.description, description) || other.description == description)&&(identical(other.foodItemId, foodItemId) || other.foodItemId == foodItemId)&&(identical(other.quantityG, quantityG) || other.quantityG == quantityG)&&(identical(other.kcal, kcal) || other.kcal == kcal)&&(identical(other.proteinG, proteinG) || other.proteinG == proteinG)&&(identical(other.carbsG, carbsG) || other.carbsG == carbsG)&&(identical(other.fatG, fatG) || other.fatG == fatG));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,description,foodItemId,quantityG,kcal,proteinG,carbsG,fatG);

@override
String toString() {
  return 'MealManualItem(description: $description, foodItemId: $foodItemId, quantityG: $quantityG, kcal: $kcal, proteinG: $proteinG, carbsG: $carbsG, fatG: $fatG)';
}


}

/// @nodoc
abstract mixin class $MealManualItemCopyWith<$Res>  {
  factory $MealManualItemCopyWith(MealManualItem value, $Res Function(MealManualItem) _then) = _$MealManualItemCopyWithImpl;
@useResult
$Res call({
 String description, int? foodItemId, num quantityG, num kcal, num proteinG, num carbsG, num fatG
});




}
/// @nodoc
class _$MealManualItemCopyWithImpl<$Res>
    implements $MealManualItemCopyWith<$Res> {
  _$MealManualItemCopyWithImpl(this._self, this._then);

  final MealManualItem _self;
  final $Res Function(MealManualItem) _then;

/// Create a copy of MealManualItem
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? description = null,Object? foodItemId = freezed,Object? quantityG = null,Object? kcal = null,Object? proteinG = null,Object? carbsG = null,Object? fatG = null,}) {
  return _then(_self.copyWith(
description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,foodItemId: freezed == foodItemId ? _self.foodItemId : foodItemId // ignore: cast_nullable_to_non_nullable
as int?,quantityG: null == quantityG ? _self.quantityG : quantityG // ignore: cast_nullable_to_non_nullable
as num,kcal: null == kcal ? _self.kcal : kcal // ignore: cast_nullable_to_non_nullable
as num,proteinG: null == proteinG ? _self.proteinG : proteinG // ignore: cast_nullable_to_non_nullable
as num,carbsG: null == carbsG ? _self.carbsG : carbsG // ignore: cast_nullable_to_non_nullable
as num,fatG: null == fatG ? _self.fatG : fatG // ignore: cast_nullable_to_non_nullable
as num,
  ));
}

}


/// Adds pattern-matching-related methods to [MealManualItem].
extension MealManualItemPatterns on MealManualItem {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MealManualItem value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MealManualItem() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MealManualItem value)  $default,){
final _that = this;
switch (_that) {
case _MealManualItem():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MealManualItem value)?  $default,){
final _that = this;
switch (_that) {
case _MealManualItem() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String description,  int? foodItemId,  num quantityG,  num kcal,  num proteinG,  num carbsG,  num fatG)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MealManualItem() when $default != null:
return $default(_that.description,_that.foodItemId,_that.quantityG,_that.kcal,_that.proteinG,_that.carbsG,_that.fatG);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String description,  int? foodItemId,  num quantityG,  num kcal,  num proteinG,  num carbsG,  num fatG)  $default,) {final _that = this;
switch (_that) {
case _MealManualItem():
return $default(_that.description,_that.foodItemId,_that.quantityG,_that.kcal,_that.proteinG,_that.carbsG,_that.fatG);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String description,  int? foodItemId,  num quantityG,  num kcal,  num proteinG,  num carbsG,  num fatG)?  $default,) {final _that = this;
switch (_that) {
case _MealManualItem() when $default != null:
return $default(_that.description,_that.foodItemId,_that.quantityG,_that.kcal,_that.proteinG,_that.carbsG,_that.fatG);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _MealManualItem implements MealManualItem {
  const _MealManualItem({required this.description, this.foodItemId, this.quantityG = 0, this.kcal = 0, this.proteinG = 0, this.carbsG = 0, this.fatG = 0});
  factory _MealManualItem.fromJson(Map<String, dynamic> json) => _$MealManualItemFromJson(json);

@override final  String description;
@override final  int? foodItemId;
@override@JsonKey() final  num quantityG;
@override@JsonKey() final  num kcal;
@override@JsonKey() final  num proteinG;
@override@JsonKey() final  num carbsG;
@override@JsonKey() final  num fatG;

/// Create a copy of MealManualItem
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MealManualItemCopyWith<_MealManualItem> get copyWith => __$MealManualItemCopyWithImpl<_MealManualItem>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$MealManualItemToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _MealManualItem&&(identical(other.description, description) || other.description == description)&&(identical(other.foodItemId, foodItemId) || other.foodItemId == foodItemId)&&(identical(other.quantityG, quantityG) || other.quantityG == quantityG)&&(identical(other.kcal, kcal) || other.kcal == kcal)&&(identical(other.proteinG, proteinG) || other.proteinG == proteinG)&&(identical(other.carbsG, carbsG) || other.carbsG == carbsG)&&(identical(other.fatG, fatG) || other.fatG == fatG));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,description,foodItemId,quantityG,kcal,proteinG,carbsG,fatG);

@override
String toString() {
  return 'MealManualItem(description: $description, foodItemId: $foodItemId, quantityG: $quantityG, kcal: $kcal, proteinG: $proteinG, carbsG: $carbsG, fatG: $fatG)';
}


}

/// @nodoc
abstract mixin class _$MealManualItemCopyWith<$Res> implements $MealManualItemCopyWith<$Res> {
  factory _$MealManualItemCopyWith(_MealManualItem value, $Res Function(_MealManualItem) _then) = __$MealManualItemCopyWithImpl;
@override @useResult
$Res call({
 String description, int? foodItemId, num quantityG, num kcal, num proteinG, num carbsG, num fatG
});




}
/// @nodoc
class __$MealManualItemCopyWithImpl<$Res>
    implements _$MealManualItemCopyWith<$Res> {
  __$MealManualItemCopyWithImpl(this._self, this._then);

  final _MealManualItem _self;
  final $Res Function(_MealManualItem) _then;

/// Create a copy of MealManualItem
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? description = null,Object? foodItemId = freezed,Object? quantityG = null,Object? kcal = null,Object? proteinG = null,Object? carbsG = null,Object? fatG = null,}) {
  return _then(_MealManualItem(
description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,foodItemId: freezed == foodItemId ? _self.foodItemId : foodItemId // ignore: cast_nullable_to_non_nullable
as int?,quantityG: null == quantityG ? _self.quantityG : quantityG // ignore: cast_nullable_to_non_nullable
as num,kcal: null == kcal ? _self.kcal : kcal // ignore: cast_nullable_to_non_nullable
as num,proteinG: null == proteinG ? _self.proteinG : proteinG // ignore: cast_nullable_to_non_nullable
as num,carbsG: null == carbsG ? _self.carbsG : carbsG // ignore: cast_nullable_to_non_nullable
as num,fatG: null == fatG ? _self.fatG : fatG // ignore: cast_nullable_to_non_nullable
as num,
  ));
}


}


/// @nodoc
mixin _$MealManualRequest {

 List<MealManualItem> get items;/// Quando a refeição foi consumida. Null = agora, no relógio do servidor.
 String? get createdAt;
/// Create a copy of MealManualRequest
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MealManualRequestCopyWith<MealManualRequest> get copyWith => _$MealManualRequestCopyWithImpl<MealManualRequest>(this as MealManualRequest, _$identity);

  /// Serializes this MealManualRequest to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MealManualRequest&&const DeepCollectionEquality().equals(other.items, items)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(items),createdAt);

@override
String toString() {
  return 'MealManualRequest(items: $items, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class $MealManualRequestCopyWith<$Res>  {
  factory $MealManualRequestCopyWith(MealManualRequest value, $Res Function(MealManualRequest) _then) = _$MealManualRequestCopyWithImpl;
@useResult
$Res call({
 List<MealManualItem> items, String? createdAt
});




}
/// @nodoc
class _$MealManualRequestCopyWithImpl<$Res>
    implements $MealManualRequestCopyWith<$Res> {
  _$MealManualRequestCopyWithImpl(this._self, this._then);

  final MealManualRequest _self;
  final $Res Function(MealManualRequest) _then;

/// Create a copy of MealManualRequest
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? items = null,Object? createdAt = freezed,}) {
  return _then(_self.copyWith(
items: null == items ? _self.items : items // ignore: cast_nullable_to_non_nullable
as List<MealManualItem>,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [MealManualRequest].
extension MealManualRequestPatterns on MealManualRequest {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MealManualRequest value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MealManualRequest() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MealManualRequest value)  $default,){
final _that = this;
switch (_that) {
case _MealManualRequest():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MealManualRequest value)?  $default,){
final _that = this;
switch (_that) {
case _MealManualRequest() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<MealManualItem> items,  String? createdAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MealManualRequest() when $default != null:
return $default(_that.items,_that.createdAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<MealManualItem> items,  String? createdAt)  $default,) {final _that = this;
switch (_that) {
case _MealManualRequest():
return $default(_that.items,_that.createdAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<MealManualItem> items,  String? createdAt)?  $default,) {final _that = this;
switch (_that) {
case _MealManualRequest() when $default != null:
return $default(_that.items,_that.createdAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _MealManualRequest implements MealManualRequest {
  const _MealManualRequest({required final  List<MealManualItem> items, this.createdAt}): _items = items;
  factory _MealManualRequest.fromJson(Map<String, dynamic> json) => _$MealManualRequestFromJson(json);

 final  List<MealManualItem> _items;
@override List<MealManualItem> get items {
  if (_items is EqualUnmodifiableListView) return _items;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_items);
}

/// Quando a refeição foi consumida. Null = agora, no relógio do servidor.
@override final  String? createdAt;

/// Create a copy of MealManualRequest
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MealManualRequestCopyWith<_MealManualRequest> get copyWith => __$MealManualRequestCopyWithImpl<_MealManualRequest>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$MealManualRequestToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _MealManualRequest&&const DeepCollectionEquality().equals(other._items, _items)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_items),createdAt);

@override
String toString() {
  return 'MealManualRequest(items: $items, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class _$MealManualRequestCopyWith<$Res> implements $MealManualRequestCopyWith<$Res> {
  factory _$MealManualRequestCopyWith(_MealManualRequest value, $Res Function(_MealManualRequest) _then) = __$MealManualRequestCopyWithImpl;
@override @useResult
$Res call({
 List<MealManualItem> items, String? createdAt
});




}
/// @nodoc
class __$MealManualRequestCopyWithImpl<$Res>
    implements _$MealManualRequestCopyWith<$Res> {
  __$MealManualRequestCopyWithImpl(this._self, this._then);

  final _MealManualRequest _self;
  final $Res Function(_MealManualRequest) _then;

/// Create a copy of MealManualRequest
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? items = null,Object? createdAt = freezed,}) {
  return _then(_MealManualRequest(
items: null == items ? _self._items : items // ignore: cast_nullable_to_non_nullable
as List<MealManualItem>,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$MealEstimate {

 List<MealAnalysisItem> get items; num get totalKcal; num get totalProteinG; num get totalCarbsG; num get totalFatG;
/// Create a copy of MealEstimate
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MealEstimateCopyWith<MealEstimate> get copyWith => _$MealEstimateCopyWithImpl<MealEstimate>(this as MealEstimate, _$identity);

  /// Serializes this MealEstimate to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MealEstimate&&const DeepCollectionEquality().equals(other.items, items)&&(identical(other.totalKcal, totalKcal) || other.totalKcal == totalKcal)&&(identical(other.totalProteinG, totalProteinG) || other.totalProteinG == totalProteinG)&&(identical(other.totalCarbsG, totalCarbsG) || other.totalCarbsG == totalCarbsG)&&(identical(other.totalFatG, totalFatG) || other.totalFatG == totalFatG));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(items),totalKcal,totalProteinG,totalCarbsG,totalFatG);

@override
String toString() {
  return 'MealEstimate(items: $items, totalKcal: $totalKcal, totalProteinG: $totalProteinG, totalCarbsG: $totalCarbsG, totalFatG: $totalFatG)';
}


}

/// @nodoc
abstract mixin class $MealEstimateCopyWith<$Res>  {
  factory $MealEstimateCopyWith(MealEstimate value, $Res Function(MealEstimate) _then) = _$MealEstimateCopyWithImpl;
@useResult
$Res call({
 List<MealAnalysisItem> items, num totalKcal, num totalProteinG, num totalCarbsG, num totalFatG
});




}
/// @nodoc
class _$MealEstimateCopyWithImpl<$Res>
    implements $MealEstimateCopyWith<$Res> {
  _$MealEstimateCopyWithImpl(this._self, this._then);

  final MealEstimate _self;
  final $Res Function(MealEstimate) _then;

/// Create a copy of MealEstimate
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? items = null,Object? totalKcal = null,Object? totalProteinG = null,Object? totalCarbsG = null,Object? totalFatG = null,}) {
  return _then(_self.copyWith(
items: null == items ? _self.items : items // ignore: cast_nullable_to_non_nullable
as List<MealAnalysisItem>,totalKcal: null == totalKcal ? _self.totalKcal : totalKcal // ignore: cast_nullable_to_non_nullable
as num,totalProteinG: null == totalProteinG ? _self.totalProteinG : totalProteinG // ignore: cast_nullable_to_non_nullable
as num,totalCarbsG: null == totalCarbsG ? _self.totalCarbsG : totalCarbsG // ignore: cast_nullable_to_non_nullable
as num,totalFatG: null == totalFatG ? _self.totalFatG : totalFatG // ignore: cast_nullable_to_non_nullable
as num,
  ));
}

}


/// Adds pattern-matching-related methods to [MealEstimate].
extension MealEstimatePatterns on MealEstimate {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MealEstimate value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MealEstimate() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MealEstimate value)  $default,){
final _that = this;
switch (_that) {
case _MealEstimate():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MealEstimate value)?  $default,){
final _that = this;
switch (_that) {
case _MealEstimate() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<MealAnalysisItem> items,  num totalKcal,  num totalProteinG,  num totalCarbsG,  num totalFatG)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MealEstimate() when $default != null:
return $default(_that.items,_that.totalKcal,_that.totalProteinG,_that.totalCarbsG,_that.totalFatG);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<MealAnalysisItem> items,  num totalKcal,  num totalProteinG,  num totalCarbsG,  num totalFatG)  $default,) {final _that = this;
switch (_that) {
case _MealEstimate():
return $default(_that.items,_that.totalKcal,_that.totalProteinG,_that.totalCarbsG,_that.totalFatG);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<MealAnalysisItem> items,  num totalKcal,  num totalProteinG,  num totalCarbsG,  num totalFatG)?  $default,) {final _that = this;
switch (_that) {
case _MealEstimate() when $default != null:
return $default(_that.items,_that.totalKcal,_that.totalProteinG,_that.totalCarbsG,_that.totalFatG);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _MealEstimate implements MealEstimate {
  const _MealEstimate({final  List<MealAnalysisItem> items = const [], this.totalKcal = 0, this.totalProteinG = 0, this.totalCarbsG = 0, this.totalFatG = 0}): _items = items;
  factory _MealEstimate.fromJson(Map<String, dynamic> json) => _$MealEstimateFromJson(json);

 final  List<MealAnalysisItem> _items;
@override@JsonKey() List<MealAnalysisItem> get items {
  if (_items is EqualUnmodifiableListView) return _items;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_items);
}

@override@JsonKey() final  num totalKcal;
@override@JsonKey() final  num totalProteinG;
@override@JsonKey() final  num totalCarbsG;
@override@JsonKey() final  num totalFatG;

/// Create a copy of MealEstimate
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MealEstimateCopyWith<_MealEstimate> get copyWith => __$MealEstimateCopyWithImpl<_MealEstimate>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$MealEstimateToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _MealEstimate&&const DeepCollectionEquality().equals(other._items, _items)&&(identical(other.totalKcal, totalKcal) || other.totalKcal == totalKcal)&&(identical(other.totalProteinG, totalProteinG) || other.totalProteinG == totalProteinG)&&(identical(other.totalCarbsG, totalCarbsG) || other.totalCarbsG == totalCarbsG)&&(identical(other.totalFatG, totalFatG) || other.totalFatG == totalFatG));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_items),totalKcal,totalProteinG,totalCarbsG,totalFatG);

@override
String toString() {
  return 'MealEstimate(items: $items, totalKcal: $totalKcal, totalProteinG: $totalProteinG, totalCarbsG: $totalCarbsG, totalFatG: $totalFatG)';
}


}

/// @nodoc
abstract mixin class _$MealEstimateCopyWith<$Res> implements $MealEstimateCopyWith<$Res> {
  factory _$MealEstimateCopyWith(_MealEstimate value, $Res Function(_MealEstimate) _then) = __$MealEstimateCopyWithImpl;
@override @useResult
$Res call({
 List<MealAnalysisItem> items, num totalKcal, num totalProteinG, num totalCarbsG, num totalFatG
});




}
/// @nodoc
class __$MealEstimateCopyWithImpl<$Res>
    implements _$MealEstimateCopyWith<$Res> {
  __$MealEstimateCopyWithImpl(this._self, this._then);

  final _MealEstimate _self;
  final $Res Function(_MealEstimate) _then;

/// Create a copy of MealEstimate
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? items = null,Object? totalKcal = null,Object? totalProteinG = null,Object? totalCarbsG = null,Object? totalFatG = null,}) {
  return _then(_MealEstimate(
items: null == items ? _self._items : items // ignore: cast_nullable_to_non_nullable
as List<MealAnalysisItem>,totalKcal: null == totalKcal ? _self.totalKcal : totalKcal // ignore: cast_nullable_to_non_nullable
as num,totalProteinG: null == totalProteinG ? _self.totalProteinG : totalProteinG // ignore: cast_nullable_to_non_nullable
as num,totalCarbsG: null == totalCarbsG ? _self.totalCarbsG : totalCarbsG // ignore: cast_nullable_to_non_nullable
as num,totalFatG: null == totalFatG ? _self.totalFatG : totalFatG // ignore: cast_nullable_to_non_nullable
as num,
  ));
}


}


/// @nodoc
mixin _$MealAdjustRequest {

 List<MealAnalysisItem>? get items; bool? get excludedFromDiary;
/// Create a copy of MealAdjustRequest
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MealAdjustRequestCopyWith<MealAdjustRequest> get copyWith => _$MealAdjustRequestCopyWithImpl<MealAdjustRequest>(this as MealAdjustRequest, _$identity);

  /// Serializes this MealAdjustRequest to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MealAdjustRequest&&const DeepCollectionEquality().equals(other.items, items)&&(identical(other.excludedFromDiary, excludedFromDiary) || other.excludedFromDiary == excludedFromDiary));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(items),excludedFromDiary);

@override
String toString() {
  return 'MealAdjustRequest(items: $items, excludedFromDiary: $excludedFromDiary)';
}


}

/// @nodoc
abstract mixin class $MealAdjustRequestCopyWith<$Res>  {
  factory $MealAdjustRequestCopyWith(MealAdjustRequest value, $Res Function(MealAdjustRequest) _then) = _$MealAdjustRequestCopyWithImpl;
@useResult
$Res call({
 List<MealAnalysisItem>? items, bool? excludedFromDiary
});




}
/// @nodoc
class _$MealAdjustRequestCopyWithImpl<$Res>
    implements $MealAdjustRequestCopyWith<$Res> {
  _$MealAdjustRequestCopyWithImpl(this._self, this._then);

  final MealAdjustRequest _self;
  final $Res Function(MealAdjustRequest) _then;

/// Create a copy of MealAdjustRequest
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? items = freezed,Object? excludedFromDiary = freezed,}) {
  return _then(_self.copyWith(
items: freezed == items ? _self.items : items // ignore: cast_nullable_to_non_nullable
as List<MealAnalysisItem>?,excludedFromDiary: freezed == excludedFromDiary ? _self.excludedFromDiary : excludedFromDiary // ignore: cast_nullable_to_non_nullable
as bool?,
  ));
}

}


/// Adds pattern-matching-related methods to [MealAdjustRequest].
extension MealAdjustRequestPatterns on MealAdjustRequest {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MealAdjustRequest value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MealAdjustRequest() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MealAdjustRequest value)  $default,){
final _that = this;
switch (_that) {
case _MealAdjustRequest():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MealAdjustRequest value)?  $default,){
final _that = this;
switch (_that) {
case _MealAdjustRequest() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<MealAnalysisItem>? items,  bool? excludedFromDiary)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MealAdjustRequest() when $default != null:
return $default(_that.items,_that.excludedFromDiary);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<MealAnalysisItem>? items,  bool? excludedFromDiary)  $default,) {final _that = this;
switch (_that) {
case _MealAdjustRequest():
return $default(_that.items,_that.excludedFromDiary);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<MealAnalysisItem>? items,  bool? excludedFromDiary)?  $default,) {final _that = this;
switch (_that) {
case _MealAdjustRequest() when $default != null:
return $default(_that.items,_that.excludedFromDiary);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _MealAdjustRequest implements MealAdjustRequest {
  const _MealAdjustRequest({final  List<MealAnalysisItem>? items, this.excludedFromDiary}): _items = items;
  factory _MealAdjustRequest.fromJson(Map<String, dynamic> json) => _$MealAdjustRequestFromJson(json);

 final  List<MealAnalysisItem>? _items;
@override List<MealAnalysisItem>? get items {
  final value = _items;
  if (value == null) return null;
  if (_items is EqualUnmodifiableListView) return _items;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(value);
}

@override final  bool? excludedFromDiary;

/// Create a copy of MealAdjustRequest
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MealAdjustRequestCopyWith<_MealAdjustRequest> get copyWith => __$MealAdjustRequestCopyWithImpl<_MealAdjustRequest>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$MealAdjustRequestToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _MealAdjustRequest&&const DeepCollectionEquality().equals(other._items, _items)&&(identical(other.excludedFromDiary, excludedFromDiary) || other.excludedFromDiary == excludedFromDiary));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_items),excludedFromDiary);

@override
String toString() {
  return 'MealAdjustRequest(items: $items, excludedFromDiary: $excludedFromDiary)';
}


}

/// @nodoc
abstract mixin class _$MealAdjustRequestCopyWith<$Res> implements $MealAdjustRequestCopyWith<$Res> {
  factory _$MealAdjustRequestCopyWith(_MealAdjustRequest value, $Res Function(_MealAdjustRequest) _then) = __$MealAdjustRequestCopyWithImpl;
@override @useResult
$Res call({
 List<MealAnalysisItem>? items, bool? excludedFromDiary
});




}
/// @nodoc
class __$MealAdjustRequestCopyWithImpl<$Res>
    implements _$MealAdjustRequestCopyWith<$Res> {
  __$MealAdjustRequestCopyWithImpl(this._self, this._then);

  final _MealAdjustRequest _self;
  final $Res Function(_MealAdjustRequest) _then;

/// Create a copy of MealAdjustRequest
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? items = freezed,Object? excludedFromDiary = freezed,}) {
  return _then(_MealAdjustRequest(
items: freezed == items ? _self._items : items // ignore: cast_nullable_to_non_nullable
as List<MealAnalysisItem>?,excludedFromDiary: freezed == excludedFromDiary ? _self.excludedFromDiary : excludedFromDiary // ignore: cast_nullable_to_non_nullable
as bool?,
  ));
}


}

// dart format on
