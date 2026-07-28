// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'billing_models.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$SubscriptionStatus {

/// `Free` ou `Pro`, em PascalCase como os demais enums da API.
 String get plan; int get maxMealAnalysesPerDay; int get maxVideoAnalysesPerDay; int get maxCoachMessagesPerDay;/// Fim do período pago já cobrado. Null em quem nunca assinou.
 String? get currentPeriodEnd;/// `Stripe`, `AppStore` ou `GooglePlay`. Null quando não há assinatura.
 String? get provider;/// Cobrança falhou, mas o acesso ainda vale — período de tolerância da loja.
 bool get paymentPastDue;/// Assinatura gerenciada pela loja: cancelar é nos ajustes do aparelho, não aqui.
 bool get managedByStore;
/// Create a copy of SubscriptionStatus
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SubscriptionStatusCopyWith<SubscriptionStatus> get copyWith => _$SubscriptionStatusCopyWithImpl<SubscriptionStatus>(this as SubscriptionStatus, _$identity);

  /// Serializes this SubscriptionStatus to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SubscriptionStatus&&(identical(other.plan, plan) || other.plan == plan)&&(identical(other.maxMealAnalysesPerDay, maxMealAnalysesPerDay) || other.maxMealAnalysesPerDay == maxMealAnalysesPerDay)&&(identical(other.maxVideoAnalysesPerDay, maxVideoAnalysesPerDay) || other.maxVideoAnalysesPerDay == maxVideoAnalysesPerDay)&&(identical(other.maxCoachMessagesPerDay, maxCoachMessagesPerDay) || other.maxCoachMessagesPerDay == maxCoachMessagesPerDay)&&(identical(other.currentPeriodEnd, currentPeriodEnd) || other.currentPeriodEnd == currentPeriodEnd)&&(identical(other.provider, provider) || other.provider == provider)&&(identical(other.paymentPastDue, paymentPastDue) || other.paymentPastDue == paymentPastDue)&&(identical(other.managedByStore, managedByStore) || other.managedByStore == managedByStore));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,plan,maxMealAnalysesPerDay,maxVideoAnalysesPerDay,maxCoachMessagesPerDay,currentPeriodEnd,provider,paymentPastDue,managedByStore);

@override
String toString() {
  return 'SubscriptionStatus(plan: $plan, maxMealAnalysesPerDay: $maxMealAnalysesPerDay, maxVideoAnalysesPerDay: $maxVideoAnalysesPerDay, maxCoachMessagesPerDay: $maxCoachMessagesPerDay, currentPeriodEnd: $currentPeriodEnd, provider: $provider, paymentPastDue: $paymentPastDue, managedByStore: $managedByStore)';
}


}

/// @nodoc
abstract mixin class $SubscriptionStatusCopyWith<$Res>  {
  factory $SubscriptionStatusCopyWith(SubscriptionStatus value, $Res Function(SubscriptionStatus) _then) = _$SubscriptionStatusCopyWithImpl;
@useResult
$Res call({
 String plan, int maxMealAnalysesPerDay, int maxVideoAnalysesPerDay, int maxCoachMessagesPerDay, String? currentPeriodEnd, String? provider, bool paymentPastDue, bool managedByStore
});




}
/// @nodoc
class _$SubscriptionStatusCopyWithImpl<$Res>
    implements $SubscriptionStatusCopyWith<$Res> {
  _$SubscriptionStatusCopyWithImpl(this._self, this._then);

  final SubscriptionStatus _self;
  final $Res Function(SubscriptionStatus) _then;

/// Create a copy of SubscriptionStatus
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? plan = null,Object? maxMealAnalysesPerDay = null,Object? maxVideoAnalysesPerDay = null,Object? maxCoachMessagesPerDay = null,Object? currentPeriodEnd = freezed,Object? provider = freezed,Object? paymentPastDue = null,Object? managedByStore = null,}) {
  return _then(_self.copyWith(
plan: null == plan ? _self.plan : plan // ignore: cast_nullable_to_non_nullable
as String,maxMealAnalysesPerDay: null == maxMealAnalysesPerDay ? _self.maxMealAnalysesPerDay : maxMealAnalysesPerDay // ignore: cast_nullable_to_non_nullable
as int,maxVideoAnalysesPerDay: null == maxVideoAnalysesPerDay ? _self.maxVideoAnalysesPerDay : maxVideoAnalysesPerDay // ignore: cast_nullable_to_non_nullable
as int,maxCoachMessagesPerDay: null == maxCoachMessagesPerDay ? _self.maxCoachMessagesPerDay : maxCoachMessagesPerDay // ignore: cast_nullable_to_non_nullable
as int,currentPeriodEnd: freezed == currentPeriodEnd ? _self.currentPeriodEnd : currentPeriodEnd // ignore: cast_nullable_to_non_nullable
as String?,provider: freezed == provider ? _self.provider : provider // ignore: cast_nullable_to_non_nullable
as String?,paymentPastDue: null == paymentPastDue ? _self.paymentPastDue : paymentPastDue // ignore: cast_nullable_to_non_nullable
as bool,managedByStore: null == managedByStore ? _self.managedByStore : managedByStore // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [SubscriptionStatus].
extension SubscriptionStatusPatterns on SubscriptionStatus {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SubscriptionStatus value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SubscriptionStatus() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SubscriptionStatus value)  $default,){
final _that = this;
switch (_that) {
case _SubscriptionStatus():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SubscriptionStatus value)?  $default,){
final _that = this;
switch (_that) {
case _SubscriptionStatus() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String plan,  int maxMealAnalysesPerDay,  int maxVideoAnalysesPerDay,  int maxCoachMessagesPerDay,  String? currentPeriodEnd,  String? provider,  bool paymentPastDue,  bool managedByStore)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SubscriptionStatus() when $default != null:
return $default(_that.plan,_that.maxMealAnalysesPerDay,_that.maxVideoAnalysesPerDay,_that.maxCoachMessagesPerDay,_that.currentPeriodEnd,_that.provider,_that.paymentPastDue,_that.managedByStore);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String plan,  int maxMealAnalysesPerDay,  int maxVideoAnalysesPerDay,  int maxCoachMessagesPerDay,  String? currentPeriodEnd,  String? provider,  bool paymentPastDue,  bool managedByStore)  $default,) {final _that = this;
switch (_that) {
case _SubscriptionStatus():
return $default(_that.plan,_that.maxMealAnalysesPerDay,_that.maxVideoAnalysesPerDay,_that.maxCoachMessagesPerDay,_that.currentPeriodEnd,_that.provider,_that.paymentPastDue,_that.managedByStore);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String plan,  int maxMealAnalysesPerDay,  int maxVideoAnalysesPerDay,  int maxCoachMessagesPerDay,  String? currentPeriodEnd,  String? provider,  bool paymentPastDue,  bool managedByStore)?  $default,) {final _that = this;
switch (_that) {
case _SubscriptionStatus() when $default != null:
return $default(_that.plan,_that.maxMealAnalysesPerDay,_that.maxVideoAnalysesPerDay,_that.maxCoachMessagesPerDay,_that.currentPeriodEnd,_that.provider,_that.paymentPastDue,_that.managedByStore);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SubscriptionStatus extends SubscriptionStatus {
  const _SubscriptionStatus({this.plan = 'Free', this.maxMealAnalysesPerDay = 0, this.maxVideoAnalysesPerDay = 0, this.maxCoachMessagesPerDay = 0, this.currentPeriodEnd, this.provider, this.paymentPastDue = false, this.managedByStore = false}): super._();
  factory _SubscriptionStatus.fromJson(Map<String, dynamic> json) => _$SubscriptionStatusFromJson(json);

/// `Free` ou `Pro`, em PascalCase como os demais enums da API.
@override@JsonKey() final  String plan;
@override@JsonKey() final  int maxMealAnalysesPerDay;
@override@JsonKey() final  int maxVideoAnalysesPerDay;
@override@JsonKey() final  int maxCoachMessagesPerDay;
/// Fim do período pago já cobrado. Null em quem nunca assinou.
@override final  String? currentPeriodEnd;
/// `Stripe`, `AppStore` ou `GooglePlay`. Null quando não há assinatura.
@override final  String? provider;
/// Cobrança falhou, mas o acesso ainda vale — período de tolerância da loja.
@override@JsonKey() final  bool paymentPastDue;
/// Assinatura gerenciada pela loja: cancelar é nos ajustes do aparelho, não aqui.
@override@JsonKey() final  bool managedByStore;

/// Create a copy of SubscriptionStatus
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SubscriptionStatusCopyWith<_SubscriptionStatus> get copyWith => __$SubscriptionStatusCopyWithImpl<_SubscriptionStatus>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SubscriptionStatusToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SubscriptionStatus&&(identical(other.plan, plan) || other.plan == plan)&&(identical(other.maxMealAnalysesPerDay, maxMealAnalysesPerDay) || other.maxMealAnalysesPerDay == maxMealAnalysesPerDay)&&(identical(other.maxVideoAnalysesPerDay, maxVideoAnalysesPerDay) || other.maxVideoAnalysesPerDay == maxVideoAnalysesPerDay)&&(identical(other.maxCoachMessagesPerDay, maxCoachMessagesPerDay) || other.maxCoachMessagesPerDay == maxCoachMessagesPerDay)&&(identical(other.currentPeriodEnd, currentPeriodEnd) || other.currentPeriodEnd == currentPeriodEnd)&&(identical(other.provider, provider) || other.provider == provider)&&(identical(other.paymentPastDue, paymentPastDue) || other.paymentPastDue == paymentPastDue)&&(identical(other.managedByStore, managedByStore) || other.managedByStore == managedByStore));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,plan,maxMealAnalysesPerDay,maxVideoAnalysesPerDay,maxCoachMessagesPerDay,currentPeriodEnd,provider,paymentPastDue,managedByStore);

@override
String toString() {
  return 'SubscriptionStatus(plan: $plan, maxMealAnalysesPerDay: $maxMealAnalysesPerDay, maxVideoAnalysesPerDay: $maxVideoAnalysesPerDay, maxCoachMessagesPerDay: $maxCoachMessagesPerDay, currentPeriodEnd: $currentPeriodEnd, provider: $provider, paymentPastDue: $paymentPastDue, managedByStore: $managedByStore)';
}


}

/// @nodoc
abstract mixin class _$SubscriptionStatusCopyWith<$Res> implements $SubscriptionStatusCopyWith<$Res> {
  factory _$SubscriptionStatusCopyWith(_SubscriptionStatus value, $Res Function(_SubscriptionStatus) _then) = __$SubscriptionStatusCopyWithImpl;
@override @useResult
$Res call({
 String plan, int maxMealAnalysesPerDay, int maxVideoAnalysesPerDay, int maxCoachMessagesPerDay, String? currentPeriodEnd, String? provider, bool paymentPastDue, bool managedByStore
});




}
/// @nodoc
class __$SubscriptionStatusCopyWithImpl<$Res>
    implements _$SubscriptionStatusCopyWith<$Res> {
  __$SubscriptionStatusCopyWithImpl(this._self, this._then);

  final _SubscriptionStatus _self;
  final $Res Function(_SubscriptionStatus) _then;

/// Create a copy of SubscriptionStatus
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? plan = null,Object? maxMealAnalysesPerDay = null,Object? maxVideoAnalysesPerDay = null,Object? maxCoachMessagesPerDay = null,Object? currentPeriodEnd = freezed,Object? provider = freezed,Object? paymentPastDue = null,Object? managedByStore = null,}) {
  return _then(_SubscriptionStatus(
plan: null == plan ? _self.plan : plan // ignore: cast_nullable_to_non_nullable
as String,maxMealAnalysesPerDay: null == maxMealAnalysesPerDay ? _self.maxMealAnalysesPerDay : maxMealAnalysesPerDay // ignore: cast_nullable_to_non_nullable
as int,maxVideoAnalysesPerDay: null == maxVideoAnalysesPerDay ? _self.maxVideoAnalysesPerDay : maxVideoAnalysesPerDay // ignore: cast_nullable_to_non_nullable
as int,maxCoachMessagesPerDay: null == maxCoachMessagesPerDay ? _self.maxCoachMessagesPerDay : maxCoachMessagesPerDay // ignore: cast_nullable_to_non_nullable
as int,currentPeriodEnd: freezed == currentPeriodEnd ? _self.currentPeriodEnd : currentPeriodEnd // ignore: cast_nullable_to_non_nullable
as String?,provider: freezed == provider ? _self.provider : provider // ignore: cast_nullable_to_non_nullable
as String?,paymentPastDue: null == paymentPastDue ? _self.paymentPastDue : paymentPastDue // ignore: cast_nullable_to_non_nullable
as bool,managedByStore: null == managedByStore ? _self.managedByStore : managedByStore // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
