package com.myotrack.api.billing;

import com.myotrack.domain.SubscriptionProvider;
import java.time.OffsetDateTime;

/**
 * Verifica um recibo de compra junto à loja.
 *
 * <p><b>O cliente nunca decide se tem Pro.</b> O app manda o recibo; quem consulta a loja e
 * decide é o servidor. Um {@code purchaseToken} aceito sem verificação é acesso Pro grátis para
 * qualquer um com um proxy HTTP.
 *
 * <p>Quando não há credenciais configuradas, {@link #isConfigured()} devolve {@code false} e o
 * endpoint responde 503 — <b>nunca</b> concede o benefício por omissão. É o mesmo princípio de
 * falha fechada que o backend .NET aplica ao Stripe.
 */
public interface StoreReceiptVerifier {

    SubscriptionProvider provider();

    boolean isConfigured();

    /**
     * Consulta a loja e devolve o estado atual da assinatura.
     *
     * @param receipt para a Apple, o JWS da transação; para o Google, o {@code purchaseToken}
     * @param productId identificador do produto na loja, usado para conferir que o recibo é
     *     mesmo do plano Pro e não de outro item
     * @throws StoreVerificationException se a loja recusar o recibo ou estiver inacessível
     */
    VerifiedSubscription verify(String receipt, String productId);

    /**
     * Estado normalizado da assinatura, já pronto para o {@link SubscriptionService}.
     *
     * @param providerSubscriptionId {@code originalTransactionId} (Apple) ou
     *     {@code purchaseToken} (Google) — a chave estável que as notificações usam
     * @param status status bruto da loja, interpretado por
     *     {@link com.myotrack.domain.service.SubscriptionEntitlement}
     */
    record VerifiedSubscription(
            String providerSubscriptionId,
            String status,
            OffsetDateTime expiresAt) {
    }

    /** Recibo recusado, malformado ou loja inacessível. */
    class StoreVerificationException extends RuntimeException {

        public StoreVerificationException(String message) {
            super(message);
        }

        public StoreVerificationException(String message, Throwable cause) {
            super(message, cause);
        }
    }
}
