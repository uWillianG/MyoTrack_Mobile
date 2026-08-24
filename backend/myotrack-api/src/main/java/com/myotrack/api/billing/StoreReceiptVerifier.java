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
     * O estado atual de uma assinatura que já conhecemos, pelo identificador do provedor.
     *
     * <p>É o que uma notificação de loja precisa. Ela avisa que <b>algo</b> mudou e, no caso do
     * Google, diz apenas isso: renovou, cancelou, entrou em espera. Decidir a partir do tipo do
     * evento seria reconstruir o estado a partir de avisos que chegam fora de ordem e se repetem
     * — perguntar de novo custa uma requisição e devolve a verdade.
     *
     * <p>Diferente de {@link #verify}, aqui não se confere produto: quem já está na tabela entrou
     * por uma compra que foi conferida uma vez, e uma notificação não é o lugar de rever isso.
     *
     * @throws StoreVerificationException se a loja não reconhecer o identificador ou estiver
     *     inacessível
     */
    VerifiedSubscription refresh(String providerSubscriptionId);

    /**
     * Estado normalizado da assinatura, já pronto para o {@link SubscriptionService}.
     *
     * @param providerSubscriptionId {@code originalTransactionId} (Apple) ou
     *     {@code purchaseToken} (Google) — a chave estável que as notificações usam
     * @param status status bruto da loja, interpretado por
     *     {@link com.myotrack.domain.service.SubscriptionEntitlement}
     * @param linkedProviderSubscriptionId identificador <b>anterior</b> da mesma assinatura,
     *     quando a loja o trocou. Acontece no Google: mudar de plano ou reassinar emite um
     *     {@code purchaseToken} novo, e é só por este campo que a linha já existente é
     *     reencontrada — sem ele, a mudança de plano criaria uma segunda assinatura órfã e o
     *     usuário perderia o Pro que continua pagando. Na Apple é sempre {@code null}: o
     *     {@code originalTransactionId} nasce com a primeira compra e não muda mais.
     * @param accountId o identificador de conta que o <b>app</b> mandou junto da compra
     *     ({@code appAccountToken} na Apple, {@code obfuscatedExternalAccountId} no Google) e
     *     que a loja devolve. É o único jeito de uma notificação saber de quem é a assinatura
     *     quando ela ainda não está na tabela. Null quando a compra foi feita por uma versão do
     *     app que não o mandava, ou quando a loja não o repassa.
     */
    record VerifiedSubscription(
            String providerSubscriptionId,
            String status,
            OffsetDateTime expiresAt,
            String linkedProviderSubscriptionId,
            String accountId) {

        public VerifiedSubscription(
                String providerSubscriptionId, String status, OffsetDateTime expiresAt) {
            this(providerSubscriptionId, status, expiresAt, null, null);
        }
    }

    /** Recibo recusado ou malformado — a loja entendeu e disse não. */
    class StoreVerificationException extends RuntimeException {

        public StoreVerificationException(String message) {
            super(message);
        }

        public StoreVerificationException(String message, Throwable cause) {
            super(message, cause);
        }
    }

    /**
     * A loja não respondeu — fora do ar, timeout, credencial nossa recusada.
     *
     * <p>Separada da recusa porque <b>as duas dão respostas HTTP diferentes, e o app age de forma
     * diferente em cada uma</b>: num 4xx ele finaliza a compra, porque insistir só reentregaria o
     * mesmo recibo recusado; num 5xx ele deixa pendente, e a loja reentrega até dar certo.
     * Devolver 400 numa indisponibilidade transitória faria o app descartar uma compra paga.
     */
    class StoreUnavailableException extends StoreVerificationException {

        public StoreUnavailableException(String message, Throwable cause) {
            super(message, cause);
        }
    }
}
