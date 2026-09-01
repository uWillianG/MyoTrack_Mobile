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

    /// O Pro veio de constância, e não de pagamento.
    ///
    /// **Muda o que a tela oferece, e não só o que ela escreve.** Quem ganhou o prêmio não tem
    /// cobrança nenhuma: não há data de renovação a mostrar, e a assinatura precisa continuar
    /// à venda — é justamente quem está usando o Pro e vai perdê-lo na data abaixo.
    @Default(false) bool isGranted,

    /// Quando o prêmio acaba. Null em quem não tem concessão valendo.
    String? grantExpiresAt,

    /// Os limites do Pro, para a tela poder comparar com os de cima.
    ///
    /// **Nulável e sem `@Default`, de propósito.** Um valor padrão aqui seria o app afirmando
    /// quanto o Pro entrega — exatamente o que a tela de assinatura se recusou a fazer quando
    /// só havia os limites do próprio usuário. Sem esta resposta do servidor não há
    /// comparação a mostrar, e a tela volta a mostrar só o que a pessoa tem hoje: um app novo
    /// contra um servidor antigo continua funcionando.
    PlanLimits? pro,
  }) = _SubscriptionStatus;

  const SubscriptionStatus._();

  factory SubscriptionStatus.fromJson(Map<String, dynamic> json) =>
      _$SubscriptionStatusFromJson(json);

  bool get isPro => plan == 'Pro';

  /// Há uma assinatura paga por trás deste Pro?
  ///
  /// É o que separa "renova" de "vence": o prêmio por constância dá Pro de verdade e acaba na
  /// data marcada, sem nada para renovar.
  bool get isPaidPro => isPro && !isGranted;
}

/// Os três tetos diários de um plano.
///
/// Existe para carregar o **outro** plano ao lado do seu. Os campos do plano em vigor
/// continuam soltos em [SubscriptionStatus] porque é assim que a API sempre os mandou, e
/// mudar isso quebraria o app antigo contra o servidor novo sem necessidade nenhuma.
@freezed
abstract class PlanLimits with _$PlanLimits {
  const factory PlanLimits({
    @Default(0) int maxMealAnalysesPerDay,
    @Default(0) int maxVideoAnalysesPerDay,
    @Default(0) int maxCoachMessagesPerDay,
  }) = _PlanLimits;

  factory PlanLimits.fromJson(Map<String, dynamic> json) =>
      _$PlanLimitsFromJson(json);
}
