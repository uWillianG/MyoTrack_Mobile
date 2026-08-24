package com.myotrack.api.billing;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.myotrack.api.billing.AppleSignedData.InvalidSignedDataException;
import com.myotrack.api.billing.StoreReceiptVerifier.StoreUnavailableException;
import com.myotrack.api.billing.StoreReceiptVerifier.StoreVerificationException;
import com.myotrack.api.billing.StoreReceiptVerifier.VerifiedSubscription;
import com.myotrack.domain.SubscriptionProvider;
import com.myotrack.infrastructure.repository.ApplicationUserRepository;
import java.util.Base64;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import java.util.stream.Collectors;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

/**
 * O que as lojas contam depois da compra: renovou, falhou, cancelou, foi reembolsada.
 *
 * <p><b>Sem isto a assinatura só sabe do primeiro dia.</b> A validação do recibo grava o estado
 * do momento da compra; tudo o que acontece depois — e é quase tudo, porque assinatura é uma
 * sequência de renovações — chega por aqui. Sem estes dois endpoints, um cancelamento só
 * apareceria no servidor quando o app fosse aberto, e um reembolso, nunca.
 *
 * <p><b>A ordem dos passos não é acidental.</b> Primeiro se apura o estado (verificando
 * assinatura, no caso da Apple; perguntando à API, no caso do Google), depois se escreve, e só
 * então a notificação é marcada como processada. Marcar na entrada seria mais simples e estaria
 * errado: a entrega que chega antes de a compra ter sido registrada, ou durante um incidente da
 * loja, consumiria a marca e a reentrega seguinte — a que funcionaria — seria descartada como
 * repetida. Os códigos de resposta seguem a mesma lógica: 2xx encerra, 5xx pede para reentregar.
 *
 * <p>As duas rotas são públicas, e cada loja prova quem é de um jeito. A Apple assina a
 * notificação inteira, e a assinatura é conferida contra a raiz dela. O Google não assina nada:
 * a autenticidade vem do segredo na URL de push do Pub/Sub — e, mesmo que ele vaze, o estado
 * aplicado é o que a Play Developer API responder, não o que a notificação afirmar.
 */
@RestController
@RequestMapping("/api/billing")
public class StoreNotificationsController {

    private static final Logger log = LoggerFactory.getLogger(StoreNotificationsController.class);

    private static final ObjectMapper MAPPER = new ObjectMapper();

    private final SubscriptionService subscriptions;
    private final ApplicationUserRepository users;
    private final AppleSignedData appleSignedData;
    private final AppStoreProperties appleProperties;
    private final PlayStoreProperties googleProperties;
    private final Map<SubscriptionProvider, StoreReceiptVerifier> verifiers;

    public StoreNotificationsController(
            SubscriptionService subscriptions,
            ApplicationUserRepository users,
            AppleSignedData appleSignedData,
            AppStoreProperties appleProperties,
            PlayStoreProperties googleProperties,
            List<StoreReceiptVerifier> verifiers) {
        this.subscriptions = subscriptions;
        this.users = users;
        this.appleSignedData = appleSignedData;
        this.appleProperties = appleProperties;
        this.googleProperties = googleProperties;
        this.verifiers = verifiers.stream()
                .collect(Collectors.toMap(StoreReceiptVerifier::provider, v -> v));
    }

    /**
     * App Store Server Notifications V2.
     *
     * <p>A notificação vem inteira dentro de um JWS assinado pela Apple, e dentro dela vem outro
     * JWS com a transação. Os dois são verificados: o de fora prova que a Apple mandou, o de
     * dentro prova o que ela disse sobre a assinatura.
     */
    @PostMapping("/apple/notifications")
    public ResponseEntity<Void> apple(@RequestBody AppleNotification body) {
        final JsonNode payload;
        try {
            payload = appleSignedData.read(body.signedPayload());
        } catch (InvalidSignedDataException e) {
            // 401 e não 400: quem mandou isto não provou ser a Apple. Se for mesmo ela, o
            // problema é nosso (raiz errada, relógio fora de hora) e o log é onde isso aparece.
            log.warn("Notificação da Apple com assinatura inválida: {}", e.getMessage());
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).build();
        }

        final JsonNode data = payload.path("data");
        final String bundleId = data.path("bundleId").asText();
        if (!appleProperties.bundleId().equals(bundleId)) {
            log.warn("Notificação da Apple para outro app ({}) — ignorando.", bundleId);
            return ResponseEntity.badRequest().build();
        }

        final String notificationUUID = payload.path("notificationUUID").asText();
        final String type = notificationType(payload);

        if (subscriptions.alreadyProcessed(notificationUUID)) {
            log.info("Notificação {} da Apple já processada — ignorando reentrega.", notificationUUID);
            return ResponseEntity.ok().build();
        }

        final String signedTransaction = data.path("signedTransactionInfo").asText(null);
        if (signedTransaction == null || signedTransaction.isBlank()) {
            // Existem notificações sem transação (pedido de consumo, por exemplo). Não há o que
            // escrever, e insistir só faria a Apple reentregar algo que nunca vai encaixar.
            log.info("Notificação {} da Apple ({}) sem transação — nada a aplicar.",
                    notificationUUID, type);
            subscriptions.markProcessed(notificationUUID, SubscriptionProvider.APP_STORE, type);
            return ResponseEntity.ok().build();
        }

        final JsonNode transaction;
        try {
            transaction = appleSignedData.read(signedTransaction);
        } catch (InvalidSignedDataException e) {
            log.warn("Transação da notificação {} não confere: {}", notificationUUID, e.getMessage());
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).build();
        }

        final String originalTransactionId = transaction.path("originalTransactionId").asText();
        if (originalTransactionId.isBlank()) {
            log.warn("Notificação {} da Apple sem originalTransactionId.", notificationUUID);
            return ResponseEntity.badRequest().build();
        }

        final VerifiedSubscription verified;
        try {
            verified = appleState(payload, transaction, originalTransactionId);
        } catch (StoreUnavailableException e) {
            log.warn("Apple indisponível ao apurar a notificação {}: {}",
                    notificationUUID, e.getMessage());
            return ResponseEntity.status(HttpStatus.SERVICE_UNAVAILABLE).build();
        } catch (StoreVerificationException e) {
            log.warn("Notificação {} da Apple recusada: {}", notificationUUID, e.getMessage());
            return ResponseEntity.badRequest().build();
        }

        return applyAndAcknowledge(
                SubscriptionProvider.APP_STORE, notificationUUID, type, verified);
    }

    /**
     * Real-time developer notifications do Google Play, entregues por push do Pub/Sub.
     *
     * <p>A notificação diz o que mudou e para qual {@code purchaseToken} — e nada além disso. O
     * estado vem da Play Developer API: interpretar o tipo do evento seria reconstruir a verdade
     * a partir de avisos que se repetem e chegam fora de ordem.
     */
    @PostMapping("/google/notifications")
    public ResponseEntity<Void> google(
            @RequestBody JsonNode body, @RequestParam(required = false) String token) {

        if (!googleProperties.notificationsToken().isBlank()
                && !googleProperties.notificationsToken().equals(token)) {
            log.warn("Notificação do Google com segredo de push inválido.");
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).build();
        }

        final JsonNode message = body.path("message");
        // O Pub/Sub já mandou este campo nas duas grafias ao longo do tempo, e a diferença
        // apareceria como notificação sem identificador — que é o que desliga a deduplicação.
        final String messageId = message.hasNonNull("messageId")
                ? message.path("messageId").asText()
                : message.path("message_id").asText();

        final JsonNode notification;
        try {
            notification = MAPPER.readTree(
                    Base64.getDecoder().decode(message.path("data").asText()));
        } catch (Exception e) {
            log.warn("Notificação do Google ilegível: {}", e.getMessage());
            return ResponseEntity.badRequest().build();
        }

        // Corpo vazio não explode no readTree — devolve nó nulo ou ausente, e o erro só
        // apareceria três linhas abaixo, como algo que não parece ter a ver com o corpo.
        if (notification == null || !notification.isObject()) {
            log.warn("Notificação do Google sem conteúdo.");
            return ResponseEntity.badRequest().build();
        }

        final String packageName = notification.path("packageName").asText();
        if (!googleProperties.packageName().equals(packageName)) {
            log.warn("Notificação do Google para outro pacote ({}) — ignorando.", packageName);
            return ResponseEntity.badRequest().build();
        }

        if (notification.has("testNotification")) {
            // O botão "enviar notificação de teste" do Play Console. Responder 200 é o que ele
            // espera; escrever qualquer coisa não é.
            log.info("Notificação de teste do Google recebida.");
            return ResponseEntity.ok().build();
        }

        final JsonNode subscription = notification.path("subscriptionNotification");
        final JsonNode voided = notification.path("voidedPurchaseNotification");

        final String purchaseToken = subscription.hasNonNull("purchaseToken")
                ? subscription.path("purchaseToken").asText()
                : voided.path("purchaseToken").asText(null);

        if (purchaseToken == null || purchaseToken.isBlank()) {
            // Notificação de produto avulso ou de outro tipo que não nos diz respeito.
            log.info("Notificação do Google sem purchaseToken — nada a aplicar.");
            return ResponseEntity.ok().build();
        }

        final String type = subscription.hasNonNull("notificationType")
                ? subscription.path("notificationType").asText()
                : "voided";

        if (subscriptions.alreadyProcessed(messageId)) {
            log.info("Notificação {} do Google já processada — ignorando reentrega.", messageId);
            return ResponseEntity.ok().build();
        }

        final StoreReceiptVerifier verifier = verifiers.get(SubscriptionProvider.GOOGLE_PLAY);
        if (verifier == null || !verifier.isConfigured()) {
            // Sem credencial não há como apurar. 503 mantém a notificação na fila do Google até
            // alguém configurar — perdê-la seria perder a renovação que ela anunciava.
            log.error("Notificação do Google recebida sem a Play Developer API configurada.");
            return ResponseEntity.status(HttpStatus.SERVICE_UNAVAILABLE).build();
        }

        final VerifiedSubscription verified;
        try {
            verified = verifier.refresh(purchaseToken);
        } catch (StoreUnavailableException e) {
            log.warn("Google indisponível ao apurar a notificação {}: {}", messageId, e.getMessage());
            return ResponseEntity.status(HttpStatus.SERVICE_UNAVAILABLE).build();
        } catch (StoreVerificationException e) {
            // O Google não reconhece o token. Reentregar não muda isso.
            log.warn("Notificação {} do Google recusada: {}", messageId, e.getMessage());
            subscriptions.markProcessed(messageId, SubscriptionProvider.GOOGLE_PLAY, type);
            return ResponseEntity.ok().build();
        }

        return applyAndAcknowledge(SubscriptionProvider.GOOGLE_PLAY, messageId, type, verified);
    }

    /**
     * Escreve o estado e só então registra a notificação.
     *
     * <p>Quando a assinatura não está na tabela, ainda há uma carta na manga: o identificador de
     * conta que o app mandou na compra e a loja devolveu. É o que resgata a compra cuja
     * validação nunca chegou ao servidor — o aparelho ficou sem rede na hora, o app foi
     * desinstalado antes de reabrir — e que, sem isto, só apareceria por aqui como uma renovação
     * de dono desconhecido, para sempre.
     *
     * <p>Sem esse identificador, 503 de propósito: o caso normal é a notificação chegar antes de
     * o app ter mandado o recibo, e é a reentrega da loja — minutos depois — que encontra a
     * linha já criada. Encerrar com 200 aqui deixaria a primeira renovação sem registro.
     */
    private ResponseEntity<Void> applyAndAcknowledge(
            SubscriptionProvider provider,
            String notificationId,
            String type,
            VerifiedSubscription verified) {

        final boolean applied = subscriptions.applyFromStore(
                provider,
                verified.providerSubscriptionId(),
                verified.linkedProviderSubscriptionId(),
                verified.status(),
                verified.expiresAt()).isPresent();

        if (!applied && !adopt(provider, verified)) {
            return ResponseEntity.status(HttpStatus.SERVICE_UNAVAILABLE).build();
        }

        subscriptions.markProcessed(notificationId, provider, type);
        return ResponseEntity.ok().build();
    }

    /**
     * Liga a assinatura ao usuário que o identificador de conta aponta.
     *
     * <p>O identificador chega dentro de dado que a loja assinou (Apple) ou que veio da API dela
     * (Google), mas quem o escolheu foi o app, no aparelho. Isso limita o que ele permite: no
     * pior caso alguém compra o Pro informando o UUID de outra pessoa, e o presenteia. Não há
     * como usá-lo para tomar assinatura alheia — a linha adotada aponta para quem o identificador
     * diz, e quem paga é quem comprou.
     *
     * <p>A existência do usuário é conferida porque a tabela não tem chave estrangeira: um UUID
     * inventado viraria uma assinatura de ninguém, invisível e permanente.
     */
    private boolean adopt(SubscriptionProvider provider, VerifiedSubscription verified) {
        final UUID userId = accountId(verified.accountId());
        if (userId == null) {
            return false;
        }

        if (!users.existsById(userId)) {
            log.warn("Identificador de conta {} de uma notificação de {} não existe — ignorando.",
                    userId, provider);
            return false;
        }

        log.info("Assinatura órfã de {} adotada pelo identificador de conta do usuário {}.",
                provider, userId);

        subscriptions.apply(
                userId,
                provider,
                verified.providerSubscriptionId(),
                verified.status(),
                verified.expiresAt());
        return true;
    }

    /** Identificador de conta que é mesmo um dos nossos; qualquer outra coisa vira null. */
    private static UUID accountId(String accountId) {
        if (accountId == null || accountId.isBlank()) {
            return null;
        }
        try {
            return UUID.fromString(accountId.trim());
        } catch (IllegalArgumentException e) {
            return null;
        }
    }

    /**
     * O estado que a notificação da Apple carrega — e, quando ela não carrega, o que a Apple
     * responder.
     *
     * <p>{@code data.status} vem na maioria das notificações de assinatura e evita uma chamada
     * de rede. Quando falta, perguntar é melhor que deduzir do tipo do evento: o mesmo
     * {@code DID_FAIL_TO_RENEW} significa "em retentativa" ou "em período de graça" conforme o
     * subtipo, e errar aí é cortar o acesso de quem ainda tem direito.
     */
    private VerifiedSubscription appleState(
            JsonNode payload, JsonNode transaction, String originalTransactionId) {

        final JsonNode status = payload.path("data").path("status");
        if (status.isMissingNode() || status.isNull()) {
            return verifiers.get(SubscriptionProvider.APP_STORE).refresh(originalTransactionId);
        }

        return new VerifiedSubscription(
                originalTransactionId,
                status.asText(),
                AppleReceiptVerifier.expiresAt(transaction),
                null,
                AppleReceiptVerifier.accountId(transaction));
    }

    /** Tipo e subtipo juntos: é o par que descreve o evento, e é assim que a Apple documenta. */
    private static String notificationType(JsonNode payload) {
        final String type = payload.path("notificationType").asText("");
        final String subtype = payload.path("subtype").asText("");
        final String full = subtype.isBlank() ? type : type + "." + subtype;

        // A coluna tem 100 caracteres; nenhum par chega perto, mas truncar aqui é mais barato
        // que descobrir o contrário com uma escrita rejeitada no meio de uma renovação.
        return full.length() <= 100 ? full : full.substring(0, 100);
    }

    /** Corpo da notificação da Apple: um campo só, com tudo dentro. */
    public record AppleNotification(String signedPayload) {
    }
}
