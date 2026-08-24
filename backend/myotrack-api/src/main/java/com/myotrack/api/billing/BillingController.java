package com.myotrack.api.billing;

import com.myotrack.api.billing.EntitlementService.Entitlements;
import com.myotrack.api.billing.StoreReceiptVerifier.StoreUnavailableException;
import com.myotrack.api.billing.StoreReceiptVerifier.StoreVerificationException;
import com.myotrack.api.billing.StoreReceiptVerifier.VerifiedSubscription;
import com.myotrack.api.security.CurrentUser;
import com.myotrack.domain.SubscriptionProvider;
import com.myotrack.domain.entity.UserSubscription;
import com.myotrack.domain.service.SubscriptionEntitlement;
import com.myotrack.infrastructure.repository.UserSubscriptionRepository;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.UUID;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

/**
 * Assinatura do plano Pro.
 *
 * <p>Porte de MyoTrack.Api/Controllers/BillingController.cs, estendido para as lojas. O fluxo do
 * Stripe (checkout e portal) continua existindo para a web; o app usa {@code /apple/verify} e
 * {@code /google/verify}, porque as duas lojas proíbem cobrar conteúdo digital por fora do
 * sistema delas.
 */
@RestController
@RequestMapping("/api/billing")
public class BillingController {

    private static final Logger log = LoggerFactory.getLogger(BillingController.class);

    /** Identificador do produto nas duas lojas — precisa bater com o cadastrado no console. */
    private static final String PRO_PRODUCT_ID = "myotrack.pro.monthly";

    private final EntitlementService entitlements;
    private final SubscriptionService subscriptions;
    private final UserSubscriptionRepository repository;
    private final Map<SubscriptionProvider, StoreReceiptVerifier> verifiers;

    public BillingController(
            EntitlementService entitlements,
            SubscriptionService subscriptions,
            UserSubscriptionRepository repository,
            List<StoreReceiptVerifier> verifiers) {
        this.entitlements = entitlements;
        this.subscriptions = subscriptions;
        this.repository = repository;
        this.verifiers = verifiers.stream().collect(
                java.util.stream.Collectors.toMap(StoreReceiptVerifier::provider, v -> v));
    }

    /** Plano atual e limites — o que a tela de assinatura mostra. */
    @GetMapping
    public Map<String, Object> status() {
        final UUID userId = CurrentUser.id();
        final Entitlements entitlement = entitlements.get(userId);
        final Optional<UserSubscription> subscription = repository.findByUserId(userId);

        final java.util.Map<String, Object> body = new java.util.LinkedHashMap<>();
        body.put("plan", entitlement.plan().getWireName());
        body.put("maxMealAnalysesPerDay", entitlement.maxMealAnalysesPerDay());
        body.put("maxVideoAnalysesPerDay", entitlement.maxVideoAnalysesPerDay());
        body.put("maxCoachMessagesPerDay", entitlement.maxCoachMessagesPerDay());
        body.put("currentPeriodEnd", subscription.map(UserSubscription::getCurrentPeriodEnd).orElse(null));

        final SubscriptionProvider provider =
                subscription.map(UserSubscription::getProvider).orElse(null);
        body.put("provider", provider == null ? null : provider.getWireName());

        // Aviso de falha de cobrança enquanto o acesso ainda vale.
        body.put("paymentPastDue", subscription
                .map(s -> SubscriptionEntitlement.isInGracePeriod(s.getProvider(), s.getProviderStatus()))
                .orElse(false));

        // Assinatura de loja é cancelada nos ajustes do aparelho, não por aqui — a tela precisa
        // saber disso para mostrar a instrução certa em vez de um botão que não funciona.
        body.put("managedByStore", provider != null && provider.isManagedByStore());

        return body;
    }

    /**
     * Valida um recibo de compra e ativa o Pro.
     *
     * <p>Chamado pelo app logo após a loja confirmar a compra. A decisão é sempre do servidor:
     * sem verificador configurado, responde 503 em vez de conceder o benefício.
     */
    @PostMapping("/{store}/verify")
    public ResponseEntity<?> verifyReceipt(
            @PathVariable String store, @RequestBody VerifyReceiptRequest request) {

        final SubscriptionProvider provider = switch (store.toLowerCase(java.util.Locale.ROOT)) {
            case "apple" -> SubscriptionProvider.APP_STORE;
            case "google" -> SubscriptionProvider.GOOGLE_PLAY;
            default -> null;
        };
        if (provider == null) {
            return ResponseEntity.badRequest().body(Map.of("error", "Loja desconhecida."));
        }

        if (request.receipt() == null || request.receipt().isBlank()) {
            return ResponseEntity.badRequest().body(Map.of("error", "Recibo ausente."));
        }

        final StoreReceiptVerifier verifier = verifiers.get(provider);
        if (verifier == null || !verifier.isConfigured()) {
            return ResponseEntity.status(HttpStatus.SERVICE_UNAVAILABLE)
                    .body(Map.of("error", "Pagamentos ainda não estão disponíveis neste ambiente."));
        }

        final VerifiedSubscription verified;
        try {
            verified = verifier.verify(
                    request.receipt(),
                    request.productId() == null ? PRO_PRODUCT_ID : request.productId());
        } catch (StoreUnavailableException e) {
            // 5xx de propósito: o app só finaliza a compra quando a recusa é definitiva, e uma
            // loja fora do ar não é recusa. Deixando pendente, a própria loja reentrega o recibo
            // na próxima abertura — que é como uma compra paga sobrevive a um incidente nosso.
            log.warn("Loja {} indisponível ao validar recibo: {}", provider, e.getMessage());
            return ResponseEntity.status(HttpStatus.SERVICE_UNAVAILABLE)
                    .body(Map.of("error", "A loja não respondeu. Tente de novo em instantes."));
        } catch (StoreVerificationException e) {
            log.warn("Recibo de {} recusado: {}", provider, e.getMessage());
            return ResponseEntity.badRequest()
                    .body(Map.of("error", "Não foi possível validar a compra."));
        }

        final UUID userId = CurrentUser.id();

        // O identificador que o app mandou na compra deveria ser o desta sessão. Quando não é,
        // pode ser recibo reaproveitado — mas também é o que acontece com quem trocou de conta e
        // restaurou uma compra antiga, ou com uma assinatura compartilhada em família. Vira log
        // e não recusa: bloquear aqui impediria alguém de recuperar o que já pagou, e o dano do
        // outro lado é dar Pro a quem tem o recibo em mãos de qualquer forma.
        if (verified.accountId() != null
                && !verified.accountId().equalsIgnoreCase(userId.toString())) {
            log.warn("Recibo de {} com identificador de conta {} validado pelo usuário {}.",
                    provider, verified.accountId(), userId);
        }

        subscriptions.apply(
                userId,
                provider,
                verified.providerSubscriptionId(),
                verified.status(),
                verified.expiresAt());

        return ResponseEntity.ok(status());
    }

    public record VerifyReceiptRequest(String receipt, String productId) {
    }
}
