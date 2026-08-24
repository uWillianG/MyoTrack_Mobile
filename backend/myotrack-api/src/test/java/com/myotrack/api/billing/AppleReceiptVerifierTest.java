package com.myotrack.api.billing;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.springframework.test.web.client.match.MockRestRequestMatchers.header;
import static org.springframework.test.web.client.match.MockRestRequestMatchers.method;
import static org.springframework.test.web.client.match.MockRestRequestMatchers.requestTo;
import static org.springframework.test.web.client.response.MockRestResponseCreators.withResourceNotFound;
import static org.springframework.test.web.client.response.MockRestResponseCreators.withServerError;
import static org.springframework.test.web.client.response.MockRestResponseCreators.withSuccess;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.myotrack.api.billing.StoreReceiptVerifier.StoreUnavailableException;
import com.myotrack.api.billing.StoreReceiptVerifier.StoreVerificationException;
import com.myotrack.api.billing.StoreReceiptVerifier.VerifiedSubscription;
import java.time.Clock;
import java.time.OffsetDateTime;
import java.time.ZoneOffset;
import java.util.HashMap;
import java.util.Map;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.http.HttpMethod;
import org.springframework.http.MediaType;
import org.springframework.test.web.client.MockRestServiceServer;
import org.springframework.web.client.RestClient;

/**
 * A verificação de compras da App Store.
 *
 * <p>O que importa aqui é o que separa uma compra de um acesso grátis. Um recibo pode ser
 * legítimo e ainda assim não valer nada para nós — por ser de outro app, de outro produto, ou de
 * uma assinatura que expirou depois de emitido. As três recusas estão testadas, e junto com elas
 * a distinção entre "a loja disse não" e "a loja não respondeu": a segunda vira 5xx lá na frente,
 * e é o que impede o app de descartar uma compra paga durante um incidente.
 *
 * <p>A verificação da assinatura criptográfica não é exercitada aqui — forjar uma cadeia que
 * termina na raiz da Apple não é possível, e um teste que precisasse disso teria que desligar
 * justamente a parte que não pode ser desligada.
 */
class AppleReceiptVerifierTest {

    private static final ObjectMapper MAPPER = new ObjectMapper();

    private static final String BUNDLE_ID = "com.myotrack.app";
    private static final String PRODUCT_ID = "myotrack.pro.monthly";
    private static final String ORIGINAL_TRANSACTION_ID = "2000000123456789";

    /** O `appAccountToken` que o app mandou na compra: o `sub` do JWT de quem comprou. */
    private static final String ACCOUNT_ID = "3f2504e0-4f89-41d3-9a0c-0305e82c3301";

    /** 2026-09-23T12:00:00Z em milissegundos, como a Apple manda. */
    private static final long EXPIRES_MILLIS = 1790164800000L;

    private static final String RECEIPT = "jws-do-recibo";
    private static final String LAST_TRANSACTION = "jws-da-ultima-transacao";

    private record Fixture(AppleReceiptVerifier verifier, MockRestServiceServer server) {
    }

    private static Fixture fixture(Map<String, String> signedPayloads) {
        final RestClient.Builder builder = RestClient.builder();
        final MockRestServiceServer server = MockRestServiceServer.bindTo(builder).build();

        final AppStoreProperties properties =
                new AppStoreProperties("issuer", "key", "chave-de-teste", BUNDLE_ID);

        final AppleSignedData signedData = jws -> {
            final String json = signedPayloads.get(jws);
            if (json == null) {
                throw new AppleSignedData.InvalidSignedDataException("JWS desconhecido: " + jws);
            }
            return read(json);
        };

        final AppStoreServerTokens tokens = new AppStoreServerTokens(properties, Clock.systemUTC()) {
            @Override
            public String bearer() {
                return "token-de-teste";
            }
        };

        return new Fixture(
                new AppleReceiptVerifier(properties, signedData, tokens, builder), server);
    }

    /** Recibo do nosso app, do nosso produto — o caso feliz, e a base dos casos infelizes. */
    private static Map<String, String> signedPayloads(String bundleId, String productId) {
        final Map<String, String> payloads = new HashMap<>();
        payloads.put(RECEIPT, """
                {
                  "bundleId": "%s",
                  "productId": "%s",
                  "originalTransactionId": "%s",
                  "environment": "Production"
                }
                """.formatted(bundleId, productId, ORIGINAL_TRANSACTION_ID));
        payloads.put(LAST_TRANSACTION, """
                {
                  "originalTransactionId": "%s",
                  "productId": "%s",
                  "expiresDate": %d,
                  "appAccountToken": "%s"
                }
                """.formatted(ORIGINAL_TRANSACTION_ID, productId, EXPIRES_MILLIS, ACCOUNT_ID));
        return payloads;
    }

    private static String subscriptionStatuses(int status) {
        return """
                {
                  "environment": "Production",
                  "bundleId": "%s",
                  "data": [
                    {
                      "subscriptionGroupIdentifier": "20000001",
                      "lastTransactions": [
                        {
                          "originalTransactionId": "%s",
                          "status": %d,
                          "signedTransactionInfo": "%s"
                        }
                      ]
                    }
                  ]
                }
                """.formatted(BUNDLE_ID, ORIGINAL_TRANSACTION_ID, status, LAST_TRANSACTION);
    }

    private static String url(String baseUrl) {
        return baseUrl + "/inApps/v1/subscriptions/" + ORIGINAL_TRANSACTION_ID;
    }

    private static JsonNode read(String json) {
        try {
            return MAPPER.readTree(json);
        } catch (Exception e) {
            throw new IllegalStateException(e);
        }
    }

    @Test
    @DisplayName("pergunta o estado atual à Apple em vez de acreditar no recibo")
    void consultaEstadoAtual() {
        final Fixture fixture = fixture(signedPayloads(BUNDLE_ID, PRODUCT_ID));
        fixture.server()
                .expect(requestTo(url(AppleReceiptVerifier.PRODUCTION_URL)))
                .andExpect(method(HttpMethod.GET))
                .andExpect(header("Authorization", "Bearer token-de-teste"))
                .andRespond(withSuccess(subscriptionStatuses(1), MediaType.APPLICATION_JSON));

        final VerifiedSubscription verified = fixture.verifier().verify(RECEIPT, PRODUCT_ID);

        assertThat(verified.providerSubscriptionId()).isEqualTo(ORIGINAL_TRANSACTION_ID);
        // O status sai como veio: quem decide o que "1" significa é o SubscriptionEntitlement.
        assertThat(verified.status()).isEqualTo("1");
        assertThat(verified.expiresAt())
                .isEqualTo(OffsetDateTime.of(2026, 9, 23, 12, 0, 0, 0, ZoneOffset.UTC));
        // A Apple nunca troca o identificador da assinatura.
        assertThat(verified.linkedProviderSubscriptionId()).isNull();
        // E devolve quem comprou — é o que salva a assinatura que ficaria órfã.
        assertThat(verified.accountId()).isEqualTo(ACCOUNT_ID);
        fixture.server().verify();
    }

    @Test
    @DisplayName("recibo de sandbox é consultado no host de sandbox")
    void recibodeSandboxVaiParaSandbox() {
        final Map<String, String> payloads = signedPayloads(BUNDLE_ID, PRODUCT_ID);
        payloads.put(RECEIPT, payloads.get(RECEIPT).replace("Production", "Sandbox"));

        final Fixture fixture = fixture(payloads);
        fixture.server()
                .expect(requestTo(url(AppleReceiptVerifier.SANDBOX_URL)))
                .andRespond(withSuccess(subscriptionStatuses(1), MediaType.APPLICATION_JSON));

        assertThat(fixture.verifier().verify(RECEIPT, PRODUCT_ID).status()).isEqualTo("1");
        fixture.server().verify();
    }

    @Test
    @DisplayName("recibo de outro app não vira Pro aqui")
    void recusaOutroApp() {
        final Fixture fixture = fixture(signedPayloads("com.outro.app", PRODUCT_ID));

        assertThatThrownBy(() -> fixture.verifier().verify(RECEIPT, PRODUCT_ID))
                .isInstanceOf(StoreVerificationException.class)
                .hasMessageContaining("com.outro.app");

        // E nem chega a perguntar à Apple: o recibo já está descartado antes disso.
        fixture.server().verify();
    }

    @Test
    @DisplayName("recibo de outro produto é recusado")
    void recusaOutroProduto() {
        final Fixture fixture = fixture(signedPayloads(BUNDLE_ID, "myotrack.outra.coisa"));

        assertThatThrownBy(() -> fixture.verifier().verify(RECEIPT, PRODUCT_ID))
                .isInstanceOf(StoreVerificationException.class);
        fixture.server().verify();
    }

    @Test
    @DisplayName("JWS que não é da Apple é recusado sem consultar nada")
    void recusaJwsDesconhecido() {
        final Fixture fixture = fixture(signedPayloads(BUNDLE_ID, PRODUCT_ID));

        assertThatThrownBy(() -> fixture.verifier().verify("jws-forjado", PRODUCT_ID))
                .isInstanceOf(StoreVerificationException.class);
        fixture.server().verify();
    }

    @Test
    @DisplayName("Apple fora do ar não é recusa de recibo")
    void lojaForaDoArNaoEhRecusa() {
        final Fixture fixture = fixture(signedPayloads(BUNDLE_ID, PRODUCT_ID));
        fixture.server()
                .expect(requestTo(url(AppleReceiptVerifier.PRODUCTION_URL)))
                .andRespond(withServerError());

        // A distinção existe para o app não finalizar — e perder — uma compra já paga.
        assertThatThrownBy(() -> fixture.verifier().verify(RECEIPT, PRODUCT_ID))
                .isInstanceOf(StoreUnavailableException.class);
        fixture.server().verify();
    }

    @Test
    @DisplayName("sem saber o ambiente, tenta produção e cai para sandbox")
    void refreshTentaOsDoisAmbientes() {
        final Fixture fixture = fixture(signedPayloads(BUNDLE_ID, PRODUCT_ID));
        fixture.server()
                .expect(requestTo(url(AppleReceiptVerifier.PRODUCTION_URL)))
                .andRespond(withResourceNotFound());
        fixture.server()
                .expect(requestTo(url(AppleReceiptVerifier.SANDBOX_URL)))
                .andRespond(withSuccess(subscriptionStatuses(4), MediaType.APPLICATION_JSON));

        assertThat(fixture.verifier().refresh(ORIGINAL_TRANSACTION_ID).status()).isEqualTo("4");
        fixture.server().verify();
    }
}
