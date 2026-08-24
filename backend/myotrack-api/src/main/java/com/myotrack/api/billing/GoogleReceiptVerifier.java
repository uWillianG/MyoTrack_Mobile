package com.myotrack.api.billing;

import com.fasterxml.jackson.databind.JsonNode;
import com.myotrack.domain.SubscriptionProvider;
import java.net.URI;
import java.nio.charset.StandardCharsets;
import java.time.OffsetDateTime;
import java.util.Objects;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.HttpHeaders;
import org.springframework.stereotype.Component;
import org.springframework.web.client.HttpClientErrorException;
import org.springframework.web.client.RestClient;
import org.springframework.web.client.RestClientException;
import org.springframework.web.util.UriUtils;

/**
 * Verifica compras do Google Play contra a Play Developer API (subscriptions v2).
 *
 * <p>Aqui não há dado assinado para conferir: o {@code purchaseToken} que o app manda é um
 * identificador opaco e nada mais. Toda a prova está na resposta do Google — <b>é ele quem diz
 * se o token existe, para qual produto, e em que estado</b>. Um token inventado devolve 404, e é
 * por isso que a verificação não pode ser pulada nem "otimizada" com cache local: sem a
 * pergunta, não há resposta nenhuma.
 *
 * <p>Confirmar a compra (o {@code acknowledge} que o Google exige em até três dias, sob pena de
 * estorno automático) é feito no app, pelo {@code completePurchase} do plugin. Não é esquecimento
 * ter ficado de fora daqui: o SDK do Play já faz isso no aparelho, e um segundo caminho pelo
 * servidor só criaria duas verdades sobre o mesmo passo.
 */
@Component
public class GoogleReceiptVerifier implements StoreReceiptVerifier {

    private static final Logger log = LoggerFactory.getLogger(GoogleReceiptVerifier.class);

    static final String BASE_URL = "https://androidpublisher.googleapis.com/androidpublisher/v3";

    private final PlayStoreProperties properties;
    private final GoogleAccessTokens tokens;
    private final RestClient restClient;

    public GoogleReceiptVerifier(
            PlayStoreProperties properties,
            GoogleAccessTokens tokens,
            RestClient.Builder restClientBuilder) {
        this.properties = properties;
        this.tokens = tokens;
        this.restClient = restClientBuilder.build();
    }

    @Override
    public SubscriptionProvider provider() {
        return SubscriptionProvider.GOOGLE_PLAY;
    }

    @Override
    public boolean isConfigured() {
        return properties.isConfigured();
    }

    @Override
    public VerifiedSubscription verify(String receipt, String productId) {
        final JsonNode purchase = get(receipt);

        if (productId != null && !hasProduct(purchase, productId)) {
            throw new StoreVerificationException("Compra de outro produto: " + productId);
        }

        return toVerified(receipt, purchase);
    }

    @Override
    public VerifiedSubscription refresh(String providerSubscriptionId) {
        return toVerified(providerSubscriptionId, get(providerSubscriptionId));
    }

    private JsonNode get(String purchaseToken) {
        if (purchaseToken == null || purchaseToken.isBlank()) {
            throw new StoreVerificationException("purchaseToken ausente.");
        }

        // O caminho é montado e codificado aqui, e entregue como URI pronta: o `uri(String)` do
        // RestClient trataria a string como template e codificaria de novo o que já foi
        // codificado — um purchaseToken com caractere especial viraria outro token.
        final String url = "%s/applications/%s/purchases/subscriptionsv2/tokens/%s".formatted(
                BASE_URL,
                UriUtils.encodePathSegment(properties.packageName(), StandardCharsets.UTF_8),
                UriUtils.encodePathSegment(purchaseToken, StandardCharsets.UTF_8));

        try {
            final JsonNode purchase = restClient.get()
                    .uri(URI.create(url))
                    .header(HttpHeaders.AUTHORIZATION, "Bearer " + tokens.bearer())
                    .retrieve()
                    .body(JsonNode.class);

            if (purchase == null) {
                throw new StoreVerificationException("Play Developer API devolveu corpo vazio.");
            }
            return purchase;
        } catch (HttpClientErrorException e) {
            // 400 e 404 são o token que o Google não reconhece; 401/403 são a nossa credencial
            // errada. Os dois viram recusa aqui, mas só o segundo é problema nosso — e é o que
            // o log precisa deixar claro para quem for investigar.
            if (e.getStatusCode().value() == 401 || e.getStatusCode().value() == 403) {
                log.error("Play Developer API recusou nossa conta de serviço: {}", e.getMessage());
            }
            if (e.getStatusCode().value() == 429) {
                // Cota estourada é problema de agora, não recibo inválido.
                throw new StoreUnavailableException("Play Developer API sem cota.", e);
            }
            throw new StoreVerificationException("Compra não reconhecida pelo Google.", e);
        } catch (RestClientException e) {
            throw new StoreUnavailableException("Play Developer API indisponível.", e);
        }
    }

    private static boolean hasProduct(JsonNode purchase, String productId) {
        for (final JsonNode item : purchase.path("lineItems")) {
            if (productId.equals(item.path("productId").asText())) {
                return true;
            }
        }
        return false;
    }

    /**
     * O {@code subscriptionState} sai daqui como veio ({@code SUBSCRIPTION_STATE_ACTIVE} e
     * companhia): quem decide o que cada estado significa é o {@code SubscriptionEntitlement} —
     * inclusive o {@code CANCELED}, que no Google mantém o acesso até o fim do período pago.
     *
     * <p>A validade é a maior entre os itens da assinatura. Hoje há um só, mas o campo é uma
     * lista porque o Google permite mais de um item na mesma assinatura, e cortar o acesso pela
     * data do primeiro seria cortar antes do que foi pago.
     */
    private static VerifiedSubscription toVerified(String purchaseToken, JsonNode purchase) {
        final String state = purchase.path("subscriptionState").asText();
        if (state.isBlank()) {
            throw new StoreVerificationException("Resposta do Google sem subscriptionState.");
        }

        OffsetDateTime expiresAt = null;
        for (final JsonNode item : purchase.path("lineItems")) {
            final String expiry = item.path("expiryTime").asText(null);
            if (expiry == null || expiry.isBlank()) {
                continue;
            }
            final OffsetDateTime candidate = OffsetDateTime.parse(expiry);
            if (expiresAt == null || candidate.isAfter(expiresAt)) {
                expiresAt = candidate;
            }
        }

        final String linked = purchase.path("linkedPurchaseToken").asText(null);

        // O que o app mandou como obfuscatedAccountId na compra. O Google o devolve num objeto
        // à parte, junto do identificador de perfil — que não usamos.
        final String accountId = purchase.path("externalAccountIdentifiers")
                .path("obfuscatedExternalAccountId")
                .asText(null);

        return new VerifiedSubscription(
                purchaseToken,
                state,
                expiresAt,
                Objects.equals(linked, purchaseToken) ? null : linked,
                accountId == null || accountId.isBlank() ? null : accountId);
    }
}
