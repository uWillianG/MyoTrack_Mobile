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
 bool get managedByStore;/// O Pro veio de constância, e não de pagamento.
///
/// **Muda o que a tela oferece, e não só o que ela escreve.** Quem ganhou o prêmio não tem
/// cobrança nenhuma: não há data de renovação a mostrar, e a assinatura precisa continuar
/// à venda — é justamente quem está usando o Pro e vai perdê-lo na data abaixo.
 bool get isGranted;/// Quando o prêmio acaba. Null em quem não tem concessão valendo.
 String? get grantExpiresAt;/// Os limites do Pro, para a tela poder comparar com os de cima.
///
/// **Nulável e sem `@Default`, de propósito.** Um valor padrão aqui seria o app afirmando
/// quanto o Pro entrega — exatamente o que a tela de assinatura se recusou a fazer quando
/// só havia os limites do próprio usuário. Sem esta resposta do servidor não há
/// comparação a mostrar, e a tela volta a mostrar só o que a pessoa tem hoje: um app novo
/// contra um servidor antigo continua funcionando.
 PlanLimits? get pro;
/// Create a copy of SubscriptionStatus
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SubscriptionStatusCopyWith<SubscriptionStatus> get copyWith => _$SubscriptionStatusCopyWithImpl<SubscriptionStatus>(this as SubscriptionStatus, _$identity);

  /// Serializes this SubscriptionStatus to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SubscriptionStatus&&(identical(other.plan, plan) || other.plan == plan)&&(identical(other.maxMealAnalysesPerDay, maxMealAnalysesPerDay) || other.maxMealAnalysesPerDay == maxMealAnalysesPerDay)&&(identical(other.maxVideoAnalysesPerDay, maxVideoAnalysesPerDay) || other.maxVideoAnalysesPerDay == maxVideoAnalysesPerDay)&&(identical(other.maxCoachMessagesPerDay, maxCoachMessagesPerDay) || other.maxCoachMessagesPerDay == maxCoachMessagesPerDay)&&(identical(other.currentPeriodEnd, currentPeriodEnd) || other.currentPeriodEnd == currentPeriodEnd)&&(identical(other.provider, provider) || other.provider == provider)&&(identical(other.paymentPastDue, paymentPastDue) || other.paymentPastDue == paymentPastDue)&&(identical(other.managedByStore, managedByStore) || other.managedByStore == managedByStore)&&(identical(other.isGranted, isGranted) || other.isGranted == isGranted)&&(identical(other.grantExpiresAt, grantExpiresAt) || other.grantExpiresAt == grantExpiresAt)&&(identical(other.pro, pro) || other.pro == pro));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,plan,maxMealAnalysesPerDay,maxVideoAnalysesPerDay,maxCoachMessagesPerDay,currentPeriodEnd,provider,paymentPastDue,managedByStore,isGranted,grantExpiresAt,pro);

@override
String toString() {
  return 'SubscriptionStatus(plan: $plan, maxMealAnalysesPerDay: $maxMealAnalysesPerDay, maxVideoAnalysesPerDay: $maxVideoAnalysesPerDay, maxCoachMessagesPerDay: $maxCoachMessagesPerDay, currentPeriodEnd: $currentPeriodEnd, provider: $provider, paymentPastDue: $paymentPastDue, managedByStore: $managedByStore, isGranted: $isGranted, grantExpiresAt: $grantExpiresAt, pro: $pro)';
}


}

/// @nodoc
abstract mixin class $SubscriptionStatusCopyWith<$Res>  {
  factory $SubscriptionStatusCopyWith(SubscriptionStatus value, $Res Function(SubscriptionStatus) _then) = _$SubscriptionStatusCopyWithImpl;
@useResult
$Res call({
 String plan, int maxMealAnalysesPerDay, int maxVideoAnalysesPerDay, int maxCoachMessagesPerDay, String? currentPeriodEnd, String? provider, bool paymentPastDue, bool managedByStore, bool isGranted, String? grantExpiresAt, PlanLimits? pro
});


$PlanLimitsCopyWith<$Res>? get pro;

}
/// @nodoc
class _$SubscriptionStatusCopyWithImpl<$Res>
    implements $SubscriptionStatusCopyWith<$Res> {
  _$SubscriptionStatusCopyWithImpl(this._self, this._then);

  final SubscriptionStatus _self;
  final $Res Function(SubscriptionStatus) _then;

/// Create a copy of SubscriptionStatus
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? plan = null,Object? maxMealAnalysesPerDay = null,Object? maxVideoAnalysesPerDay = null,Object? maxCoachMessagesPerDay = null,Object? currentPeriodEnd = freezed,Object? provider = freezed,Object? paymentPastDue = null,Object? managedByStore = null,Object? isGranted = null,Object? grantExpiresAt = freezed,Object? pro = freezed,}) {
  return _then(_self.copyWith(
plan: null == plan ? _self.plan : plan // ignore: cast_nullable_to_non_nullable
as String,maxMealAnalysesPerDay: null == maxMealAnalysesPerDay ? _self.maxMealAnalysesPerDay : maxMealAnalysesPerDay // ignore: cast_nullable_to_non_nullable
as int,maxVideoAnalysesPerDay: null == maxVideoAnalysesPerDay ? _self.maxVideoAnalysesPerDay : maxVideoAnalysesPerDay // ignore: cast_nullable_to_non_nullable
as int,maxCoachMessagesPerDay: null == maxCoachMessagesPerDay ? _self.maxCoachMessagesPerDay : maxCoachMessagesPerDay // ignore: cast_nullable_to_non_nullable
as int,currentPeriodEnd: freezed == currentPeriodEnd ? _self.currentPeriodEnd : currentPeriodEnd // ignore: cast_nullable_to_non_nullable
as String?,provider: freezed == provider ? _self.provider : provider // ignore: cast_nullable_to_non_nullable
as String?,paymentPastDue: null == paymentPastDue ? _self.paymentPastDue : paymentPastDue // ignore: cast_nullable_to_non_nullable
as bool,managedByStore: null == managedByStore ? _self.managedByStore : managedByStore // ignore: cast_nullable_to_non_nullable
as bool,isGranted: null == isGranted ? _self.isGranted : isGranted // ignore: cast_nullable_to_non_nullable
as bool,grantExpiresAt: freezed == grantExpiresAt ? _self.grantExpiresAt : grantExpiresAt // ignore: cast_nullable_to_non_nullable
as String?,pro: freezed == pro ? _self.pro : pro // ignore: cast_nullable_to_non_nullable
as PlanLimits?,
  ));
}
/// Create a copy of SubscriptionStatus
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PlanLimitsCopyWith<$Res>? get pro {
    if (_self.pro == null) {
    return null;
  }

  return $PlanLimitsCopyWith<$Res>(_self.pro!, (value) {
    return _then(_self.copyWith(pro: value));
  });
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String plan,  int maxMealAnalysesPerDay,  int maxVideoAnalysesPerDay,  int maxCoachMessagesPerDay,  String? currentPeriodEnd,  String? provider,  bool paymentPastDue,  bool managedByStore,  bool isGranted,  String? grantExpiresAt,  PlanLimits? pro)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SubscriptionStatus() when $default != null:
return $default(_that.plan,_that.maxMealAnalysesPerDay,_that.maxVideoAnalysesPerDay,_that.maxCoachMessagesPerDay,_that.currentPeriodEnd,_that.provider,_that.paymentPastDue,_that.managedByStore,_that.isGranted,_that.grantExpiresAt,_that.pro);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String plan,  int maxMealAnalysesPerDay,  int maxVideoAnalysesPerDay,  int maxCoachMessagesPerDay,  String? currentPeriodEnd,  String? provider,  bool paymentPastDue,  bool managedByStore,  bool isGranted,  String? grantExpiresAt,  PlanLimits? pro)  $default,) {final _that = this;
switch (_that) {
case _SubscriptionStatus():
return $default(_that.plan,_that.maxMealAnalysesPerDay,_that.maxVideoAnalysesPerDay,_that.maxCoachMessagesPerDay,_that.currentPeriodEnd,_that.provider,_that.paymentPastDue,_that.managedByStore,_that.isGranted,_that.grantExpiresAt,_that.pro);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String plan,  int maxMealAnalysesPerDay,  int maxVideoAnalysesPerDay,  int maxCoachMessagesPerDay,  String? currentPeriodEnd,  String? provider,  bool paymentPastDue,  bool managedByStore,  bool isGranted,  String? grantExpiresAt,  PlanLimits? pro)?  $default,) {final _that = this;
switch (_that) {
case _SubscriptionStatus() when $default != null:
return $default(_that.plan,_that.maxMealAnalysesPerDay,_that.maxVideoAnalysesPerDay,_that.maxCoachMessagesPerDay,_that.currentPeriodEnd,_that.provider,_that.paymentPastDue,_that.managedByStore,_that.isGranted,_that.grantExpiresAt,_that.pro);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SubscriptionStatus extends SubscriptionStatus {
  const _SubscriptionStatus({this.plan = 'Free', this.maxMealAnalysesPerDay = 0, this.maxVideoAnalysesPerDay = 0, this.maxCoachMessagesPerDay = 0, this.currentPeriodEnd, this.provider, this.paymentPastDue = false, this.managedByStore = false, this.isGranted = false, this.grantExpiresAt, this.pro}): super._();
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
/// O Pro veio de constância, e não de pagamento.
///
/// **Muda o que a tela oferece, e não só o que ela escreve.** Quem ganhou o prêmio não tem
/// cobrança nenhuma: não há data de renovação a mostrar, e a assinatura precisa continuar
/// à venda — é justamente quem está usando o Pro e vai perdê-lo na data abaixo.
@override@JsonKey() final  bool isGranted;
/// Quando o prêmio acaba. Null em quem não tem concessão valendo.
@override final  String? grantExpiresAt;
/// Os limites do Pro, para a tela poder comparar com os de cima.
///
/// **Nulável e sem `@Default`, de propósito.** Um valor padrão aqui seria o app afirmando
/// quanto o Pro entrega — exatamente o que a tela de assinatura se recusou a fazer quando
/// só havia os limites do próprio usuário. Sem esta resposta do servidor não há
/// comparação a mostrar, e a tela volta a mostrar só o que a pessoa tem hoje: um app novo
/// contra um servidor antigo continua funcionando.
@override final  PlanLimits? pro;

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
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SubscriptionStatus&&(identical(other.plan, plan) || other.plan == plan)&&(identical(other.maxMealAnalysesPerDay, maxMealAnalysesPerDay) || other.maxMealAnalysesPerDay == maxMealAnalysesPerDay)&&(identical(other.maxVideoAnalysesPerDay, maxVideoAnalysesPerDay) || other.maxVideoAnalysesPerDay == maxVideoAnalysesPerDay)&&(identical(other.maxCoachMessagesPerDay, maxCoachMessagesPerDay) || other.maxCoachMessagesPerDay == maxCoachMessagesPerDay)&&(identical(other.currentPeriodEnd, currentPeriodEnd) || other.currentPeriodEnd == currentPeriodEnd)&&(identical(other.provider, provider) || other.provider == provider)&&(identical(other.paymentPastDue, paymentPastDue) || other.paymentPastDue == paymentPastDue)&&(identical(other.managedByStore, managedByStore) || other.managedByStore == managedByStore)&&(identical(other.isGranted, isGranted) || other.isGranted == isGranted)&&(identical(other.grantExpiresAt, grantExpiresAt) || other.grantExpiresAt == grantExpiresAt)&&(identical(other.pro, pro) || other.pro == pro));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,plan,maxMealAnalysesPerDay,maxVideoAnalysesPerDay,maxCoachMessagesPerDay,currentPeriodEnd,provider,paymentPastDue,managedByStore,isGranted,grantExpiresAt,pro);

@override
String toString() {
  return 'SubscriptionStatus(plan: $plan, maxMealAnalysesPerDay: $maxMealAnalysesPerDay, maxVideoAnalysesPerDay: $maxVideoAnalysesPerDay, maxCoachMessagesPerDay: $maxCoachMessagesPerDay, currentPeriodEnd: $currentPeriodEnd, provider: $provider, paymentPastDue: $paymentPastDue, managedByStore: $managedByStore, isGranted: $isGranted, grantExpiresAt: $grantExpiresAt, pro: $pro)';
}


}

/// @nodoc
abstract mixin class _$SubscriptionStatusCopyWith<$Res> implements $SubscriptionStatusCopyWith<$Res> {
  factory _$SubscriptionStatusCopyWith(_SubscriptionStatus value, $Res Function(_SubscriptionStatus) _then) = __$SubscriptionStatusCopyWithImpl;
@override @useResult
$Res call({
 String plan, int maxMealAnalysesPerDay, int maxVideoAnalysesPerDay, int maxCoachMessagesPerDay, String? currentPeriodEnd, String? provider, bool paymentPastDue, bool managedByStore, bool isGranted, String? grantExpiresAt, PlanLimits? pro
});


@override $PlanLimitsCopyWith<$Res>? get pro;

}
/// @nodoc
class __$SubscriptionStatusCopyWithImpl<$Res>
    implements _$SubscriptionStatusCopyWith<$Res> {
  __$SubscriptionStatusCopyWithImpl(this._self, this._then);

  final _SubscriptionStatus _self;
  final $Res Function(_SubscriptionStatus) _then;

/// Create a copy of SubscriptionStatus
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? plan = null,Object? maxMealAnalysesPerDay = null,Object? maxVideoAnalysesPerDay = null,Object? maxCoachMessagesPerDay = null,Object? currentPeriodEnd = freezed,Object? provider = freezed,Object? paymentPastDue = null,Object? managedByStore = null,Object? isGranted = null,Object? grantExpiresAt = freezed,Object? pro = freezed,}) {
  return _then(_SubscriptionStatus(
plan: null == plan ? _self.plan : plan // ignore: cast_nullable_to_non_nullable
as String,maxMealAnalysesPerDay: null == maxMealAnalysesPerDay ? _self.maxMealAnalysesPerDay : maxMealAnalysesPerDay // ignore: cast_nullable_to_non_nullable
as int,maxVideoAnalysesPerDay: null == maxVideoAnalysesPerDay ? _self.maxVideoAnalysesPerDay : maxVideoAnalysesPerDay // ignore: cast_nullable_to_non_nullable
as int,maxCoachMessagesPerDay: null == maxCoachMessagesPerDay ? _self.maxCoachMessagesPerDay : maxCoachMessagesPerDay // ignore: cast_nullable_to_non_nullable
as int,currentPeriodEnd: freezed == currentPeriodEnd ? _self.currentPeriodEnd : currentPeriodEnd // ignore: cast_nullable_to_non_nullable
as String?,provider: freezed == provider ? _self.provider : provider // ignore: cast_nullable_to_non_nullable
as String?,paymentPastDue: null == paymentPastDue ? _self.paymentPastDue : paymentPastDue // ignore: cast_nullable_to_non_nullable
as bool,managedByStore: null == managedByStore ? _self.managedByStore : managedByStore // ignore: cast_nullable_to_non_nullable
as bool,isGranted: null == isGranted ? _self.isGranted : isGranted // ignore: cast_nullable_to_non_nullable
as bool,grantExpiresAt: freezed == grantExpiresAt ? _self.grantExpiresAt : grantExpiresAt // ignore: cast_nullable_to_non_nullable
as String?,pro: freezed == pro ? _self.pro : pro // ignore: cast_nullable_to_non_nullable
as PlanLimits?,
  ));
}

/// Create a copy of SubscriptionStatus
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PlanLimitsCopyWith<$Res>? get pro {
    if (_self.pro == null) {
    return null;
  }

  return $PlanLimitsCopyWith<$Res>(_self.pro!, (value) {
    return _then(_self.copyWith(pro: value));
  });
}
}


/// @nodoc
mixin _$PlanLimits {

 int get maxMealAnalysesPerDay; int get maxVideoAnalysesPerDay; int get maxCoachMessagesPerDay;
/// Create a copy of PlanLimits
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PlanLimitsCopyWith<PlanLimits> get copyWith => _$PlanLimitsCopyWithImpl<PlanLimits>(this as PlanLimits, _$identity);

  /// Serializes this PlanLimits to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PlanLimits&&(identical(other.maxMealAnalysesPerDay, maxMealAnalysesPerDay) || other.maxMealAnalysesPerDay == maxMealAnalysesPerDay)&&(identical(other.maxVideoAnalysesPerDay, maxVideoAnalysesPerDay) || other.maxVideoAnalysesPerDay == maxVideoAnalysesPerDay)&&(identical(other.maxCoachMessagesPerDay, maxCoachMessagesPerDay) || other.maxCoachMessagesPerDay == maxCoachMessagesPerDay));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,maxMealAnalysesPerDay,maxVideoAnalysesPerDay,maxCoachMessagesPerDay);

@override
String toString() {
  return 'PlanLimits(maxMealAnalysesPerDay: $maxMealAnalysesPerDay, maxVideoAnalysesPerDay: $maxVideoAnalysesPerDay, maxCoachMessagesPerDay: $maxCoachMessagesPerDay)';
}


}

/// @nodoc
abstract mixin class $PlanLimitsCopyWith<$Res>  {
  factory $PlanLimitsCopyWith(PlanLimits value, $Res Function(PlanLimits) _then) = _$PlanLimitsCopyWithImpl;
@useResult
$Res call({
 int maxMealAnalysesPerDay, int maxVideoAnalysesPerDay, int maxCoachMessagesPerDay
});




}
/// @nodoc
class _$PlanLimitsCopyWithImpl<$Res>
    implements $PlanLimitsCopyWith<$Res> {
  _$PlanLimitsCopyWithImpl(this._self, this._then);

  final PlanLimits _self;
  final $Res Function(PlanLimits) _then;

/// Create a copy of PlanLimits
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? maxMealAnalysesPerDay = null,Object? maxVideoAnalysesPerDay = null,Object? maxCoachMessagesPerDay = null,}) {
  return _then(_self.copyWith(
maxMealAnalysesPerDay: null == maxMealAnalysesPerDay ? _self.maxMealAnalysesPerDay : maxMealAnalysesPerDay // ignore: cast_nullable_to_non_nullable
as int,maxVideoAnalysesPerDay: null == maxVideoAnalysesPerDay ? _self.maxVideoAnalysesPerDay : maxVideoAnalysesPerDay // ignore: cast_nullable_to_non_nullable
as int,maxCoachMessagesPerDay: null == maxCoachMessagesPerDay ? _self.maxCoachMessagesPerDay : maxCoachMessagesPerDay // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [PlanLimits].
extension PlanLimitsPatterns on PlanLimits {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PlanLimits value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PlanLimits() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PlanLimits value)  $default,){
final _that = this;
switch (_that) {
case _PlanLimits():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PlanLimits value)?  $default,){
final _that = this;
switch (_that) {
case _PlanLimits() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int maxMealAnalysesPerDay,  int maxVideoAnalysesPerDay,  int maxCoachMessagesPerDay)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PlanLimits() when $default != null:
return $default(_that.maxMealAnalysesPerDay,_that.maxVideoAnalysesPerDay,_that.maxCoachMessagesPerDay);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int maxMealAnalysesPerDay,  int maxVideoAnalysesPerDay,  int maxCoachMessagesPerDay)  $default,) {final _that = this;
switch (_that) {
case _PlanLimits():
return $default(_that.maxMealAnalysesPerDay,_that.maxVideoAnalysesPerDay,_that.maxCoachMessagesPerDay);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int maxMealAnalysesPerDay,  int maxVideoAnalysesPerDay,  int maxCoachMessagesPerDay)?  $default,) {final _that = this;
switch (_that) {
case _PlanLimits() when $default != null:
return $default(_that.maxMealAnalysesPerDay,_that.maxVideoAnalysesPerDay,_that.maxCoachMessagesPerDay);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PlanLimits implements PlanLimits {
  const _PlanLimits({this.maxMealAnalysesPerDay = 0, this.maxVideoAnalysesPerDay = 0, this.maxCoachMessagesPerDay = 0});
  factory _PlanLimits.fromJson(Map<String, dynamic> json) => _$PlanLimitsFromJson(json);

@override@JsonKey() final  int maxMealAnalysesPerDay;
@override@JsonKey() final  int maxVideoAnalysesPerDay;
@override@JsonKey() final  int maxCoachMessagesPerDay;

/// Create a copy of PlanLimits
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PlanLimitsCopyWith<_PlanLimits> get copyWith => __$PlanLimitsCopyWithImpl<_PlanLimits>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PlanLimitsToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PlanLimits&&(identical(other.maxMealAnalysesPerDay, maxMealAnalysesPerDay) || other.maxMealAnalysesPerDay == maxMealAnalysesPerDay)&&(identical(other.maxVideoAnalysesPerDay, maxVideoAnalysesPerDay) || other.maxVideoAnalysesPerDay == maxVideoAnalysesPerDay)&&(identical(other.maxCoachMessagesPerDay, maxCoachMessagesPerDay) || other.maxCoachMessagesPerDay == maxCoachMessagesPerDay));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,maxMealAnalysesPerDay,maxVideoAnalysesPerDay,maxCoachMessagesPerDay);

@override
String toString() {
  return 'PlanLimits(maxMealAnalysesPerDay: $maxMealAnalysesPerDay, maxVideoAnalysesPerDay: $maxVideoAnalysesPerDay, maxCoachMessagesPerDay: $maxCoachMessagesPerDay)';
}


}

/// @nodoc
abstract mixin class _$PlanLimitsCopyWith<$Res> implements $PlanLimitsCopyWith<$Res> {
  factory _$PlanLimitsCopyWith(_PlanLimits value, $Res Function(_PlanLimits) _then) = __$PlanLimitsCopyWithImpl;
@override @useResult
$Res call({
 int maxMealAnalysesPerDay, int maxVideoAnalysesPerDay, int maxCoachMessagesPerDay
});




}
/// @nodoc
class __$PlanLimitsCopyWithImpl<$Res>
    implements _$PlanLimitsCopyWith<$Res> {
  __$PlanLimitsCopyWithImpl(this._self, this._then);

  final _PlanLimits _self;
  final $Res Function(_PlanLimits) _then;

/// Create a copy of PlanLimits
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? maxMealAnalysesPerDay = null,Object? maxVideoAnalysesPerDay = null,Object? maxCoachMessagesPerDay = null,}) {
  return _then(_PlanLimits(
maxMealAnalysesPerDay: null == maxMealAnalysesPerDay ? _self.maxMealAnalysesPerDay : maxMealAnalysesPerDay // ignore: cast_nullable_to_non_nullable
as int,maxVideoAnalysesPerDay: null == maxVideoAnalysesPerDay ? _self.maxVideoAnalysesPerDay : maxVideoAnalysesPerDay // ignore: cast_nullable_to_non_nullable
as int,maxCoachMessagesPerDay: null == maxCoachMessagesPerDay ? _self.maxCoachMessagesPerDay : maxCoachMessagesPerDay // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
