package com.myotrack.api.billing;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.springframework.test.web.client.match.MockRestRequestMatchers.header;
import static org.springframework.test.web.client.match.MockRestRequestMatchers.method;
import static org.springframework.test.web.client.match.MockRestRequestMatchers.requestTo;
import static org.springframework.test.web.client.response.MockRestResponseCreators.withResourceNotFound;
import static org.springframework.test.web.client.response.MockRestResponseCreators.withServerError;
import static org.springframework.test.web.client.response.MockRestResponseCreators.withSuccess;

import com.myotrack.api.billing.StoreReceiptVerifier.StoreUnavailableException;
import com.myotrack.api.billing.StoreReceiptVerifier.StoreVerificationException;
import com.myotrack.api.billing.StoreReceiptVerifier.VerifiedSubscription;
import java.time.Clock;
import java.time.OffsetDateTime;
import java.time.ZoneOffset;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.http.HttpMethod;
import org.springframework.http.MediaType;
import org.springframework.test.web.client.MockRestServiceServer;
import org.springframework.web.client.RestClient;

/**
 * A verificação de compras do Google Play.
 *
 * <p>Diferente da Apple, aqui não há nada assinado para conferir: o {@code purchaseToken} é
 * opaco e toda a prova vem da resposta do Google. Por isso os testes se concentram em três
 * coisas — que a pergunta é feita ao endereço certo, que a resposta é traduzida sem
 * interpretação (o estado sai como veio, para o {@code SubscriptionEntitlement} decidir), e que
 * a troca de {@code purchaseToken} numa mudança de plano não perde a assinatura de vista.
 */
class GoogleReceiptVerifierTest {

    private static final String PACKAGE_NAME = "com.myotrack.app";
    private static final String PRODUCT_ID = "myotrack.pro.monthly";
    private static final String PURCHASE_TOKEN = "token-da-compra";

    /** O `obfuscatedAccountId` que o app mandou na compra: o `sub` do JWT de quem comprou. */
    private static final String ACCOUNT_ID = "3f2504e0-4f89-41d3-9a0c-0305e82c3301";

    private record Fixture(GoogleReceiptVerifier verifier, MockRestServiceServer server) {
    }

    private static Fixture fixture() {
        final RestClient.Builder builder = RestClient.builder();
        final MockRestServiceServer server = MockRestServiceServer.bindTo(builder).build();

        final PlayStoreProperties properties =
                new PlayStoreProperties(PACKAGE_NAME, "{\"client_email\":\"conta@teste\"}", "");

        final GoogleAccessTokens tokens =
                new GoogleAccessTokens(properties, Clock.systemUTC(), RestClient.builder()) {
                    @Override
                    public String bearer() {
                        return "token-de-teste";
                    }
                };

        return new Fixture(new GoogleReceiptVerifier(properties, tokens, builder), server);
    }

    private static String purchase(String state, String productId, String expiry, String linked) {
        return """
                {
                  "subscriptionState": "%s",
                  "latestOrderId": "GPA.0000-0000-0000-00000",
                  "externalAccountIdentifiers": {
                    "obfuscatedExternalAccountId": "%s"
                  },
                  %s
                  "lineItems": [
                    {"productId": "%s", "expiryTime": "%s"}
                  ]
                }
                """.formatted(
                        state,
                        ACCOUNT_ID,
                        linked == null ? "" : "\"linkedPurchaseToken\": \"%s\",".formatted(linked),
                        productId,
                        expiry);
    }

    private static String url() {
        return GoogleReceiptVerifier.BASE_URL
                + "/applications/" + PACKAGE_NAME
                + "/purchases/subscriptionsv2/tokens/" + PURCHASE_TOKEN;
    }

    @Test
    @DisplayName("pergunta ao Google e devolve o estado sem interpretar")
    void consultaEstado() {
        final Fixture fixture = fixture();
        fixture.server()
                .expect(requestTo(url()))
                .andExpect(method(HttpMethod.GET))
                .andExpect(header("Authorization", "Bearer token-de-teste"))
                .andRespond(withSuccess(
                        purchase("SUBSCRIPTION_STATE_ACTIVE", PRODUCT_ID,
                                "2026-09-23T12:00:00Z", null),
                        MediaType.APPLICATION_JSON));

        final VerifiedSubscription verified = fixture.verifier().verify(PURCHASE_TOKEN, PRODUCT_ID);

        assertThat(verified.providerSubscriptionId()).isEqualTo(PURCHASE_TOKEN);
        assertThat(verified.status()).isEqualTo("SUBSCRIPTION_STATE_ACTIVE");
        assertThat(verified.expiresAt())
                .isEqualTo(OffsetDateTime.of(2026, 9, 23, 12, 0, 0, 0, ZoneOffset.UTC));
        // Quem comprou, para a notificação de renovação achar o dono se a validação se perdeu.
        assertThat(verified.accountId()).isEqualTo(ACCOUNT_ID);
        fixture.server().verify();
    }

    @Test
    @DisplayName("cancelada continua sendo o que o Google disse — quem decide o acesso é o domínio")
    void canceladaChegaComoVeio() {
        final Fixture fixture = fixture();
        fixture.server()
                .expect(requestTo(url()))
                .andRespond(withSuccess(
                        purchase("SUBSCRIPTION_STATE_CANCELED", PRODUCT_ID,
                                "2026-09-23T12:00:00Z", null),
                        MediaType.APPLICATION_JSON));

        assertThat(fixture.verifier().verify(PURCHASE_TOKEN, PRODUCT_ID).status())
                .isEqualTo("SUBSCRIPTION_STATE_CANCELED");
        fixture.server().verify();
    }

    @Test
    @DisplayName("mudança de plano traz o token anterior, que é como a linha antiga é reencontrada")
    void trazTokenAnterior() {
        final Fixture fixture = fixture();
        fixture.server()
                .expect(requestTo(url()))
                .andRespond(withSuccess(
                        purchase("SUBSCRIPTION_STATE_ACTIVE", PRODUCT_ID,
                                "2026-09-23T12:00:00Z", "token-anterior"),
                        MediaType.APPLICATION_JSON));

        assertThat(fixture.verifier().refresh(PURCHASE_TOKEN).linkedProviderSubscriptionId())
                .isEqualTo("token-anterior");
        fixture.server().verify();
    }

    @Test
    @DisplayName("compra de outro produto é recusada")
    void recusaOutroProduto() {
        final Fixture fixture = fixture();
        fixture.server()
                .expect(requestTo(url()))
                .andRespond(withSuccess(
                        purchase("SUBSCRIPTION_STATE_ACTIVE", "myotrack.outra.coisa",
                                "2026-09-23T12:00:00Z", null),
                        MediaType.APPLICATION_JSON));

        assertThatThrownBy(() -> fixture.verifier().verify(PURCHASE_TOKEN, PRODUCT_ID))
                .isInstanceOf(StoreVerificationException.class);
        fixture.server().verify();
    }

    @Test
    @DisplayName("token que o Google não conhece é recusa definitiva")
    void tokenDesconhecido() {
        final Fixture fixture = fixture();
        fixture.server()
                .expect(requestTo(url()))
                .andRespond(withResourceNotFound());

        assertThatThrownBy(() -> fixture.verifier().verify(PURCHASE_TOKEN, PRODUCT_ID))
                .isInstanceOf(StoreVerificationException.class)
                .isNotInstanceOf(StoreUnavailableException.class);
        fixture.server().verify();
    }

    @Test
    @DisplayName("Google fora do ar não é recusa de compra")
    void lojaForaDoAr() {
        final Fixture fixture = fixture();
        fixture.server()
                .expect(requestTo(url()))
                .andRespond(withServerError());

        assertThatThrownBy(() -> fixture.verifier().verify(PURCHASE_TOKEN, PRODUCT_ID))
                .isInstanceOf(StoreUnavailableException.class);
        fixture.server().verify();
    }
}
