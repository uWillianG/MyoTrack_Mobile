package com.myotrack.domain.service;

import com.myotrack.domain.SubscriptionProvider;
import java.util.Locale;
import java.util.Set;

/**
 * Decide se um status de assinatura dá direito ao plano Pro.
 *
 * <p>Cada provedor tem seu próprio vocabulário, e o ponto delicado é o mesmo nos três: **existe
 * um intervalo entre "o pagamento falhou" e "o acesso acaba"**. Cortar o Pro no primeiro
 * problema de cobrança pune quem só trocou de cartão — as três plataformas tentam cobrar de novo
 * por dias antes de desistir. Este é o único lugar onde essa política vive.
 */
public final class SubscriptionEntitlement {

    private SubscriptionEntitlement() {
    }

    /**
     * Stripe. {@code past_due} entra como período de graça: o Stripe ainda está tentando cobrar
     * (smart retries) e o corte definitivo vem com {@code canceled}/{@code unpaid} ou com o
     * evento {@code customer.subscription.deleted}.
     */
    private static final Set<String> STRIPE_ENTITLED = Set.of("active", "trialing", "past_due");

    /**
     * App Store — o {@code status} do App Store Server API.
     *
     * <ul>
     *   <li>1 Active — assinatura corrente</li>
     *   <li>3 In Billing Retry — a Apple está retentando a cobrança</li>
     *   <li>4 In Billing Grace Period — período de graça configurado no App Store Connect</li>
     * </ul>
     *
     * Ficam de fora 2 (Expired) e 5 (Revoked — reembolso ou cancelamento familiar; corta na hora).
     */
    private static final Set<String> APPLE_ENTITLED = Set.of("1", "3", "4");

    /**
     * Google Play — o {@code subscriptionState} da Play Developer API.
     *
     * <p>{@code CANCELED} <b>dá</b> direito: no Google significa "não vai renovar", e o usuário
     * mantém acesso até o fim do período já pago. Tratar como corte imediato tiraria dias que a
     * pessoa pagou. {@code ON_HOLD} não dá: aí o acesso já foi suspenso pela própria loja.
     */
    private static final Set<String> GOOGLE_ENTITLED = Set.of(
            "SUBSCRIPTION_STATE_ACTIVE",
            "SUBSCRIPTION_STATE_IN_GRACE_PERIOD",
            "SUBSCRIPTION_STATE_CANCELED");

    /**
     * O status informado mantém o Pro ativo?
     *
     * <p>Status desconhecido devolve {@code false}: na dúvida, o acesso pago não é concedido — e
     * um estado novo de loja aparece no log antes de virar acesso indevido.
     */
    public static boolean isEntitled(SubscriptionProvider provider, String status) {
        if (status == null || status.isBlank()) {
            return false;
        }
        return switch (provider) {
            case STRIPE -> STRIPE_ENTITLED.contains(status.trim().toLowerCase(Locale.ROOT));
            case APP_STORE -> APPLE_ENTITLED.contains(status.trim());
            case GOOGLE_PLAY -> GOOGLE_ENTITLED.contains(status.trim().toUpperCase(Locale.ROOT));
        };
    }

    /**
     * O acesso está valendo por tolerância a falha de cobrança, e não por pagamento em dia?
     *
     * <p>A tela usa isto para avisar que o pagamento falhou enquanto o acesso continua — é a
     * janela em que o usuário ainda consegue resolver sem perder nada.
     */
    public static boolean isInGracePeriod(SubscriptionProvider provider, String status) {
        if (!isEntitled(provider, status)) {
            return false;
        }
        return switch (provider) {
            case STRIPE -> "past_due".equalsIgnoreCase(status.trim());
            case APP_STORE -> "3".equals(status.trim()) || "4".equals(status.trim());
            case GOOGLE_PLAY ->
                    "SUBSCRIPTION_STATE_IN_GRACE_PERIOD".equalsIgnoreCase(status.trim());
        };
    }
}
