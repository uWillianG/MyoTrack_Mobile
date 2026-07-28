import 'package:freezed_annotation/freezed_annotation.dart';

part 'billing_models.freezed.dart';
part 'billing_models.g.dart';

/// Plano e limites do usuário — `GET /api/billing`.
///
/// É a **única fonte de verdade sobre o que está liberado**. O app nunca conclui "comprou,
/// então é Pro" a partir do retorno da loja: quem valida o recibo é o servidor, e é a resposta
/// dele que muda a tela.
@freezed
abstract class SubscriptionStatus with _$SubscriptionStatus {
  const factory SubscriptionStatus({
    /// `Free` ou `Pro`, em PascalCase como os demais enums da API.
    @Default('Free') String plan,
    @Default(0) int maxMealAnalysesPerDay,
    @Default(0) int maxVideoAnalysesPerDay,
    @Default(0) int maxCoachMessagesPerDay,

    /// Fim do período pago já cobrado. Null em quem nunca assinou.
    String? currentPeriodEnd,

    /// `Stripe`, `AppStore` ou `GooglePlay`. Null quando não há assinatura.
    String? provider,

    /// Cobrança falhou, mas o acesso ainda vale — período de tolerância da loja.
    @Default(false) bool paymentPastDue,

    /// Assinatura gerenciada pela loja: cancelar é nos ajustes do aparelho, não aqui.
    @Default(false) bool managedByStore,
  }) = _SubscriptionStatus;

  const SubscriptionStatus._();

  factory SubscriptionStatus.fromJson(Map<String, dynamic> json) =>
      _$SubscriptionStatusFromJson(json);

  bool get isPro => plan == 'Pro';
}
