package com.myotrack.api.billing;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.myotrack.api.billing.StoreNotificationsController.AppleNotification;
import com.myotrack.api.billing.StoreReceiptVerifier.StoreUnavailableException;
import com.myotrack.api.billing.StoreReceiptVerifier.VerifiedSubscription;
import com.myotrack.domain.SubscriptionProvider;
import com.myotrack.domain.entity.UserSubscription;
import com.myotrack.infrastructure.repository.ApplicationUserRepository;
import java.nio.charset.StandardCharsets;
import java.time.OffsetDateTime;
import java.time.ZoneOffset;
import java.util.Base64;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.UUID;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;

/**
 * As notificações das lojas — o que mantém a assinatura viva depois do primeiro dia.
 *
 * <p>Os testes daqui são quase todos sobre <b>quando não escrever</b>, porque é aí que mora o
 * dano: aplicar uma notificação que ninguém provou ter vindo da loja, ou consumir a marca de
 * processamento de uma entrega que ainda não podia dar certo — deixando a renovação seguinte
 * sem registro e um assinante pagante no plano gratuito.
 *
 * <p>O par código de resposta/marca é a regra que amarra tudo: 2xx só sai quando não há mais
 * nada a fazer com aquela notificação, e a marca só é gravada junto com um 2xx.
 */
class StoreNotificationsControllerTest {

    private static final ObjectMapper MAPPER = new ObjectMapper();

    private static final String BUNDLE_ID = "com.myotrack.app";
    private static final String PACKAGE_NAME = "com.myotrack.app";
    private static final String PUSH_TOKEN = "segredo-do-pubsub";

    private static final String NOTIFICATION_UUID = "8a1b0d54-4c2f-4a35-9d0d-1f1c1b0f0a01";
    private static final String ORIGINAL_TRANSACTION_ID = "2000000123456789";
    private static final String PURCHASE_TOKEN = "token-da-compra";

    /** O identificador de conta que o app manda na compra: o `sub` do JWT de quem comprou. */
    private static final UUID ANA = UUID.fromString("3f2504e0-4f89-41d3-9a0c-0305e82c3301");

    private static final String NOTIFICATION_JWS = "jws-da-notificacao";
    private static final String TRANSACTION_JWS = "jws-da-transacao";

    /** 2026-09-23T12:00:00Z. */
    private static final long EXPIRES_MILLIS = 1790164800000L;

    private SubscriptionService subscriptions;
    private ApplicationUserRepository users;
    private StoreReceiptVerifier googleVerifier;
    private Map<String, String> signedPayloads;
    private StoreNotificationsController controller;

    @BeforeEach
    void setUp() {
        subscriptions = mock(SubscriptionService.class);
        when(subscriptions.alreadyProcessed(any())).thenReturn(false);
        when(subscriptions.applyFromStore(any(), any(), any(), any(), any()))
                .thenReturn(Optional.of(new UserSubscription()));

        users = mock(ApplicationUserRepository.class);
        when(users.existsById(any())).thenReturn(true);

        signedPayloads = new HashMap<>();
        signedPayloads.put(NOTIFICATION_JWS, appleNotification("DID_RENEW", "\"status\": 1,"));
        signedPayloads.put(TRANSACTION_JWS, """
                {
                  "originalTransactionId": "%s",
                  "productId": "myotrack.pro.monthly",
                  "expiresDate": %d,
                  "appAccountToken": "%s"
                }
                """.formatted(ORIGINAL_TRANSACTION_ID, EXPIRES_MILLIS, ANA));

        final AppleSignedData signedData = jws -> {
            final String json = signedPayloads.get(jws);
            if (json == null) {
                throw new AppleSignedData.InvalidSignedDataException("JWS desconhecido: " + jws);
            }
            return read(json);
        };

        final StoreReceiptVerifier appleVerifier = mock(StoreReceiptVerifier.class);
        when(appleVerifier.provider()).thenReturn(SubscriptionProvider.APP_STORE);

        googleVerifier = mock(StoreReceiptVerifier.class);
        when(googleVerifier.provider()).thenReturn(SubscriptionProvider.GOOGLE_PLAY);
        when(googleVerifier.isConfigured()).thenReturn(true);

        controller = new StoreNotificationsController(
                subscriptions,
                users,
                signedData,
                new AppStoreProperties("issuer", "key", "chave", BUNDLE_ID),
                new PlayStoreProperties(PACKAGE_NAME, "{}", PUSH_TOKEN),
                List.of(appleVerifier, googleVerifier));
    }

    private static String appleNotification(String type, String statusField) {
        return """
                {
                  "notificationType": "%s",
                  "subtype": "",
                  "notificationUUID": "%s",
                  "data": {
                    "bundleId": "%s",
                    "environment": "Production",
                    %s
                    "signedTransactionInfo": "%s"
                  }
                }
                """.formatted(type, NOTIFICATION_UUID, BUNDLE_ID, statusField, TRANSACTION_JWS);
    }

    private static JsonNode read(String json) {
        try {
            return MAPPER.readTree(json);
        } catch (Exception e) {
            throw new IllegalStateException(e);
        }
    }

    private static JsonNode pubSub(String messageId, String notification) {
        final String data = Base64.getEncoder()
                .encodeToString(notification.getBytes(StandardCharsets.UTF_8));
        return read("""
                {
                  "message": {"data": "%s", "messageId": "%s"},
                  "subscription": "projects/myotrack/subscriptions/rtdn"
                }
                """.formatted(data, messageId));
    }

    private static String subscriptionNotification() {
        return """
                {
                  "version": "1.0",
                  "packageName": "%s",
                  "eventTimeMillis": "1790000000000",
                  "subscriptionNotification": {
                    "version": "1.0",
                    "notificationType": 2,
                    "purchaseToken": "%s",
                    "subscriptionId": "myotrack.pro.monthly"
                  }
                }
                """.formatted(PACKAGE_NAME, PURCHASE_TOKEN);
    }

    @Test
    @DisplayName("Apple: renovação aplica o estado assinado e só então marca a notificação")
    void appleAplicaERegistra() {
        final ResponseEntity<Void> response =
                controller.apple(new AppleNotification(NOTIFICATION_JWS));

        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.OK);
        verify(subscriptions).applyFromStore(
                SubscriptionProvider.APP_STORE,
                ORIGINAL_TRANSACTION_ID,
                null,
                "1",
                OffsetDateTime.of(2026, 9, 23, 12, 0, 0, 0, ZoneOffset.UTC));
        verify(subscriptions).markProcessed(
                NOTIFICATION_UUID, SubscriptionProvider.APP_STORE, "DID_RENEW");
    }

    @Test
    @DisplayName("Apple: notificação que não prova ser da Apple não escreve nada")
    void appleAssinaturaInvalida() {
        final ResponseEntity<Void> response =
                controller.apple(new AppleNotification("jws-forjado"));

        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.UNAUTHORIZED);
        verify(subscriptions, never()).applyFromStore(any(), any(), any(), any(), any());
        verify(subscriptions, never()).markProcessed(any(), any(), any());
    }

    @Test
    @DisplayName("Apple: notificação de outro app é recusada")
    void appleDeOutroApp() {
        signedPayloads.put(NOTIFICATION_JWS,
                signedPayloads.get(NOTIFICATION_JWS).replace(BUNDLE_ID, "com.outro.app"));

        final ResponseEntity<Void> response =
                controller.apple(new AppleNotification(NOTIFICATION_JWS));

        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.BAD_REQUEST);
        verify(subscriptions, never()).applyFromStore(any(), any(), any(), any(), any());
    }

    @Test
    @DisplayName("Apple: reentrega da mesma notificação não reescreve")
    void appleReentrega() {
        when(subscriptions.alreadyProcessed(NOTIFICATION_UUID)).thenReturn(true);

        final ResponseEntity<Void> response =
                controller.apple(new AppleNotification(NOTIFICATION_JWS));

        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.OK);
        verify(subscriptions, never()).applyFromStore(any(), any(), any(), any(), any());
    }

    @Test
    @DisplayName("Apple: sem status no aviso, pergunta em vez de deduzir do tipo do evento")
    void appleSemStatusPergunta() {
        signedPayloads.put(NOTIFICATION_JWS, appleNotification("DID_FAIL_TO_RENEW", ""));

        final StoreReceiptVerifier appleVerifier = mock(StoreReceiptVerifier.class);
        when(appleVerifier.provider()).thenReturn(SubscriptionProvider.APP_STORE);
        when(appleVerifier.refresh(ORIGINAL_TRANSACTION_ID)).thenReturn(
                new VerifiedSubscription(ORIGINAL_TRANSACTION_ID, "4", null));

        controller = new StoreNotificationsController(
                subscriptions,
                users,
                jws -> read(signedPayloads.get(jws)),
                new AppStoreProperties("issuer", "key", "chave", BUNDLE_ID),
                new PlayStoreProperties(PACKAGE_NAME, "{}", PUSH_TOKEN),
                List.of(appleVerifier, googleVerifier));

        final ResponseEntity<Void> response =
                controller.apple(new AppleNotification(NOTIFICATION_JWS));

        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.OK);
        // "4" é período de graça: cortar aqui puniria quem só precisa trocar o cartão.
        verify(subscriptions).applyFromStore(
                SubscriptionProvider.APP_STORE, ORIGINAL_TRANSACTION_ID, null, "4", null);
    }

    @Test
    @DisplayName("assinatura desconhecida e sem identificador de conta pede reentrega")
    void assinaturaDesconhecidaPedeReentrega() {
        // Compra feita por uma versão do app anterior ao appAccountToken: não há por onde
        // descobrir o dono, e a única saída é esperar a reentrega.
        signedPayloads.put(TRANSACTION_JWS, """
                {
                  "originalTransactionId": "%s",
                  "productId": "myotrack.pro.monthly",
                  "expiresDate": %d
                }
                """.formatted(ORIGINAL_TRANSACTION_ID, EXPIRES_MILLIS));
        when(subscriptions.applyFromStore(any(), any(), any(), any(), any()))
                .thenReturn(Optional.empty());

        final ResponseEntity<Void> response =
                controller.apple(new AppleNotification(NOTIFICATION_JWS));

        // A compra pode não ter terminado de ser registrada. A reentrega da loja, minutos
        // depois, encontra a linha — e por isso a marca não pode ser gravada agora.
        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.SERVICE_UNAVAILABLE);
        verify(subscriptions, never()).markProcessed(any(), any(), any());
    }

    @Test
    @DisplayName("Apple: assinatura órfã é adotada pelo identificador de conta da compra")
    void appleAdotaOrfa() {
        when(subscriptions.applyFromStore(any(), any(), any(), any(), any()))
                .thenReturn(Optional.empty());

        final ResponseEntity<Void> response =
                controller.apple(new AppleNotification(NOTIFICATION_JWS));

        // É o resgate da compra cuja validação nunca chegou: sem isto, a assinatura seria uma
        // renovação de dono desconhecido para sempre.
        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.OK);
        verify(subscriptions).apply(
                ANA,
                SubscriptionProvider.APP_STORE,
                ORIGINAL_TRANSACTION_ID,
                "1",
                OffsetDateTime.of(2026, 9, 23, 12, 0, 0, 0, ZoneOffset.UTC));
        verify(subscriptions).markProcessed(
                NOTIFICATION_UUID, SubscriptionProvider.APP_STORE, "DID_RENEW");
    }

    @Test
    @DisplayName("identificador de conta que não existe não vira assinatura de ninguém")
    void naoAdotaContaInexistente() {
        when(subscriptions.applyFromStore(any(), any(), any(), any(), any()))
                .thenReturn(Optional.empty());
        when(users.existsById(any())).thenReturn(false);

        final ResponseEntity<Void> response =
                controller.apple(new AppleNotification(NOTIFICATION_JWS));

        // A tabela não tem chave estrangeira: um UUID inventado viraria uma assinatura
        // invisível e permanente.
        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.SERVICE_UNAVAILABLE);
        verify(subscriptions, never()).apply(any(), any(), any(), any(), any());
        verify(subscriptions, never()).markProcessed(any(), any(), any());
    }

    @Test
    @DisplayName("Google: a órfã também é adotada, pelo obfuscatedAccountId")
    void googleAdotaOrfa() {
        when(subscriptions.applyFromStore(any(), any(), any(), any(), any()))
                .thenReturn(Optional.empty());
        when(googleVerifier.refresh(PURCHASE_TOKEN)).thenReturn(new VerifiedSubscription(
                PURCHASE_TOKEN,
                "SUBSCRIPTION_STATE_ACTIVE",
                OffsetDateTime.of(2026, 9, 23, 12, 0, 0, 0, ZoneOffset.UTC),
                null,
                ANA.toString()));

        final ResponseEntity<Void> response =
                controller.google(pubSub("m-6", subscriptionNotification()), PUSH_TOKEN);

        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.OK);
        verify(subscriptions).apply(
                ANA,
                SubscriptionProvider.GOOGLE_PLAY,
                PURCHASE_TOKEN,
                "SUBSCRIPTION_STATE_ACTIVE",
                OffsetDateTime.of(2026, 9, 23, 12, 0, 0, 0, ZoneOffset.UTC));
    }

    @Test
    @DisplayName("Google: sem o segredo do push, nada é aceito")
    void googleSegredoErrado() {
        final ResponseEntity<Void> response =
                controller.google(pubSub("1", subscriptionNotification()), "outro-segredo");

        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.UNAUTHORIZED);
        verify(subscriptions, never()).applyFromStore(any(), any(), any(), any(), any());
    }

    @Test
    @DisplayName("Google: apura o estado na API e aplica com o token anterior junto")
    void googleAplica() {
        when(googleVerifier.refresh(PURCHASE_TOKEN)).thenReturn(new VerifiedSubscription(
                PURCHASE_TOKEN,
                "SUBSCRIPTION_STATE_ACTIVE",
                OffsetDateTime.of(2026, 9, 23, 12, 0, 0, 0, ZoneOffset.UTC),
                "token-anterior",
                null));

        final ResponseEntity<Void> response =
                controller.google(pubSub("m-1", subscriptionNotification()), PUSH_TOKEN);

        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.OK);
        verify(subscriptions).applyFromStore(
                SubscriptionProvider.GOOGLE_PLAY,
                PURCHASE_TOKEN,
                "token-anterior",
                "SUBSCRIPTION_STATE_ACTIVE",
                OffsetDateTime.of(2026, 9, 23, 12, 0, 0, 0, ZoneOffset.UTC));
        verify(subscriptions).markProcessed("m-1", SubscriptionProvider.GOOGLE_PLAY, "2");
    }

    @Test
    @DisplayName("Google: notificação de teste do console não escreve nada")
    void googleNotificacaoDeTeste() {
        final String test = """
                {
                  "version": "1.0",
                  "packageName": "%s",
                  "eventTimeMillis": "1790000000000",
                  "testNotification": {"version": "1.0"}
                }
                """.formatted(PACKAGE_NAME);

        final ResponseEntity<Void> response = controller.google(pubSub("m-2", test), PUSH_TOKEN);

        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.OK);
        verify(subscriptions, never()).applyFromStore(any(), any(), any(), any(), any());
    }

    @Test
    @DisplayName("Google: API fora do ar pede reentrega e não consome a notificação")
    void googleApiForaDoAr() {
        when(googleVerifier.refresh(PURCHASE_TOKEN))
                .thenThrow(new StoreUnavailableException("fora do ar", null));

        final ResponseEntity<Void> response =
                controller.google(pubSub("m-3", subscriptionNotification()), PUSH_TOKEN);

        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.SERVICE_UNAVAILABLE);
        verify(subscriptions, never()).markProcessed(any(), any(), any());
    }

    @Test
    @DisplayName("Google: notificação de outro pacote é recusada")
    void googleDeOutroPacote() {
        final String outro = subscriptionNotification().replace(PACKAGE_NAME, "com.outro.app");

        final ResponseEntity<Void> response = controller.google(pubSub("m-4", outro), PUSH_TOKEN);

        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.BAD_REQUEST);
        verify(subscriptions, never()).applyFromStore(any(), any(), any(), any(), any());
    }

    @Test
    @DisplayName("Google: reembolso chega pelo aviso de compra anulada e vale o mesmo caminho")
    void googleReembolso() {
        final String voided = """
                {
                  "version": "1.0",
                  "packageName": "%s",
                  "eventTimeMillis": "1790000000000",
                  "voidedPurchaseNotification": {
                    "purchaseToken": "%s",
                    "orderId": "GPA.0000-0000-0000-00000",
                    "productType": 1,
                    "refundType": 1
                  }
                }
                """.formatted(PACKAGE_NAME, PURCHASE_TOKEN);

        when(googleVerifier.refresh(PURCHASE_TOKEN)).thenReturn(new VerifiedSubscription(
                PURCHASE_TOKEN, "SUBSCRIPTION_STATE_EXPIRED", null));

        final ResponseEntity<Void> response = controller.google(pubSub("m-5", voided), PUSH_TOKEN);

        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.OK);
        verify(subscriptions).applyFromStore(
                eq(SubscriptionProvider.GOOGLE_PLAY), eq(PURCHASE_TOKEN), any(),
                eq("SUBSCRIPTION_STATE_EXPIRED"), any());
    }
}
