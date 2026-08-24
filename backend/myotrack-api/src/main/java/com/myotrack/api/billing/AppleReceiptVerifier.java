package com.myotrack.api.billing;

import com.fasterxml.jackson.databind.JsonNode;
import com.myotrack.api.billing.AppleSignedData.InvalidSignedDataException;
import com.myotrack.domain.SubscriptionProvider;
import java.net.URI;
import java.time.Instant;
import java.time.OffsetDateTime;
import java.time.ZoneOffset;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.HttpHeaders;
import org.springframework.stereotype.Component;
import org.springframework.web.client.HttpClientErrorException;
import org.springframework.web.client.RestClient;
import org.springframework.web.client.RestClientException;

/**
 * Verifica compras da App Store contra a App Store Server API.
 *
 * <p>São dois passos, e os dois são necessários. O primeiro é conferir a assinatura do JWS que o
 * app mandou — isso já prova que a Apple emitiu aquela transação. O segundo é <b>perguntar à
 * Apple o estado atual</b> daquela assinatura, porque o JWS diz o que aconteceu no momento da
 * compra e nada mais: um recibo legítimo de seis meses atrás, de uma assinatura cancelada desde
 * então, continua com assinatura criptográfica válida para sempre. Quem responde "isto ainda
 * vale?" é a Server API.
 *
 * <p>O ambiente (produção ou sandbox) não é configurado: vem dentro do próprio dado assinado. Um
 * app em TestFlight e um app publicado mandam recibos de mundos diferentes para o mesmo servidor,
 * e escolher o host por configuração significaria uma instalação incapaz de testar a compra ou
 * incapaz de vendê-la.
 */
@Component
public class AppleReceiptVerifier implements StoreReceiptVerifier {

    private static final Logger log = LoggerFactory.getLogger(AppleReceiptVerifier.class);

    static final String PRODUCTION_URL = "https://api.storekit.itunes.apple.com";
    static final String SANDBOX_URL = "https://api.storekit-sandbox.itunes.apple.com";

    static final String SANDBOX = "Sandbox";

    private final AppStoreProperties properties;
    private final AppleSignedData signedData;
    private final AppStoreServerTokens tokens;
    private final RestClient restClient;

    public AppleReceiptVerifier(
            AppStoreProperties properties,
            AppleSignedData signedData,
            AppStoreServerTokens tokens,
            RestClient.Builder restClientBuilder) {
        this.properties = properties;
        this.signedData = signedData;
        this.tokens = tokens;
        this.restClient = restClientBuilder.build();
    }

    @Override
    public SubscriptionProvider provider() {
        return SubscriptionProvider.APP_STORE;
    }

    @Override
    public boolean isConfigured() {
        return properties.isConfigured();
    }

    @Override
    public VerifiedSubscription verify(String receipt, String productId) {
        final JsonNode transaction = decode(receipt);

        // O bundle id é o que separa "um recibo válido" de "um recibo deste app". Sem esta
        // conferência, o recibo de qualquer outro app assinado pela Apple viraria Pro aqui.
        final String bundleId = transaction.path("bundleId").asText();
        if (!properties.bundleId().equals(bundleId)) {
            throw new StoreVerificationException("Recibo de outro app: " + bundleId);
        }

        final String purchased = transaction.path("productId").asText();
        if (productId != null && !productId.equals(purchased)) {
            throw new StoreVerificationException("Recibo de outro produto: " + purchased);
        }

        final String originalTransactionId = transaction.path("originalTransactionId").asText();
        if (originalTransactionId.isBlank()) {
            throw new StoreVerificationException("Recibo sem originalTransactionId.");
        }

        return status(originalTransactionId, transaction.path("environment").asText());
    }

    /**
     * Sem o dado assinado em mãos não há como saber o ambiente, então tenta produção e cai para
     * sandbox no 404. A ordem importa: em produção a primeira tentativa acerta sempre, e é lá que
     * o volume está.
     */
    @Override
    public VerifiedSubscription refresh(String providerSubscriptionId) {
        try {
            return status(providerSubscriptionId, null);
        } catch (SubscriptionNotFoundException e) {
            return status(providerSubscriptionId, SANDBOX);
        }
    }

    /**
     * Estado atual da assinatura na Apple.
     *
     * <p>A resposta traz os grupos de assinatura do usuário e, em cada um, a última transação. O
     * {@code status} é o número que a Apple define (1 ativa, 2 expirada, 3 em retentativa de
     * cobrança, 4 em período de graça, 5 revogada) e sai daqui como veio: interpretá-lo é
     * trabalho do {@code SubscriptionEntitlement}, que é onde a política de tolerância vive para
     * os três provedores.
     */
    private VerifiedSubscription status(String originalTransactionId, String environment) {
        final String baseUrl = SANDBOX.equalsIgnoreCase(environment) ? SANDBOX_URL : PRODUCTION_URL;
        final String url = baseUrl + "/inApps/v1/subscriptions/" + originalTransactionId;

        final JsonNode response;
        try {
            response = restClient.get()
                    .uri(URI.create(url))
                    .header(HttpHeaders.AUTHORIZATION, "Bearer " + tokens.bearer())
                    .retrieve()
                    .body(JsonNode.class);
        } catch (HttpClientErrorException.NotFound e) {
            throw new SubscriptionNotFoundException(originalTransactionId);
        } catch (RestClientException e) {
            // Loja inacessível não é recibo inválido: o app precisa poder tentar de novo, e é o
            // BillingController que traduz isso para a resposta HTTP.
            throw new StoreUnavailableException("App Store Server API indisponível.", e);
        }

        if (response == null) {
            throw new StoreVerificationException("App Store Server API devolveu corpo vazio.");
        }

        final JsonNode last = lastTransaction(response, originalTransactionId);
        final String status = last.path("status").asText();
        if (status.isBlank()) {
            throw new StoreVerificationException("Resposta da Apple sem status.");
        }

        // A transação assinada é a fonte da validade e de quem comprou — e é verificada de novo
        // aqui. A resposta da Server API chega por TLS, mas o que ela carrega é assinado pela
        // Apple; ler o conteúdo sem conferir seria trocar uma prova por uma promessa.
        final String signed = last.path("signedTransactionInfo").asText(null);
        final JsonNode transaction = signed == null || signed.isBlank() ? null : decode(signed);

        return new VerifiedSubscription(
                originalTransactionId,
                status,
                expiresAt(transaction),
                null,
                accountId(transaction));
    }

    /**
     * O {@code appAccountToken} que o app mandou na compra, quando mandou.
     *
     * <p>Compras feitas por versões anteriores do app não têm nenhum — e é por isso que ele
     * nunca pode ser a única forma de encontrar o dono da assinatura, só a segunda.
     */
    static String accountId(JsonNode transaction) {
        if (transaction == null) {
            return null;
        }
        final String token = transaction.path("appAccountToken").asText(null);
        return token == null || token.isBlank() ? null : token;
    }

    /**
     * A Apple filtra pelo identificador que pedimos, mas devolve um array de grupos: procurar a
     * entrada certa é mais barato que confiar na ordem, e evita conceder o estado de uma
     * assinatura vizinha se um dia o filtro mudar.
     */
    private static JsonNode lastTransaction(JsonNode response, String originalTransactionId) {
        for (final JsonNode group : response.path("data")) {
            for (final JsonNode transaction : group.path("lastTransactions")) {
                if (originalTransactionId.equals(
                        transaction.path("originalTransactionId").asText())) {
                    return transaction;
                }
            }
        }
        throw new SubscriptionNotFoundException(originalTransactionId);
    }

    /** A data de expiração, em milissegundos, como a Apple a escreve dentro da transação. */
    static OffsetDateTime expiresAt(JsonNode transaction) {
        if (transaction == null) {
            return null;
        }
        final long expiresMillis = transaction.path("expiresDate").asLong(0);
        return expiresMillis <= 0
                ? null
                : OffsetDateTime.ofInstant(Instant.ofEpochMilli(expiresMillis), ZoneOffset.UTC);
    }

    /** Verifica a assinatura do JWS e devolve o payload, já traduzindo a falha para o chamador. */
    private JsonNode decode(String jws) {
        try {
            return signedData.read(jws);
        } catch (InvalidSignedDataException e) {
            log.warn("Dado assinado da Apple recusado: {}", e.getMessage());
            throw new StoreVerificationException("Recibo da Apple inválido.", e);
        }
    }

    /** A Apple não conhece esta assinatura — pode ser ambiente errado, pode ser recibo inventado. */
    static class SubscriptionNotFoundException extends StoreVerificationException {

        SubscriptionNotFoundException(String originalTransactionId) {
            super("Assinatura desconhecida na Apple: " + originalTransactionId);
        }
    }
}
