package com.myotrack.api.billing;

import com.myotrack.domain.SubscriptionPlanType;
import com.myotrack.domain.SubscriptionProvider;
import com.myotrack.domain.entity.StoreNotificationLog;
import com.myotrack.domain.entity.UserSubscription;
import com.myotrack.domain.service.SubscriptionEntitlement;
import com.myotrack.infrastructure.repository.StoreNotificationLogRepository;
import com.myotrack.infrastructure.repository.UserSubscriptionRepository;
import java.time.OffsetDateTime;
import java.util.Optional;
import java.util.UUID;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Propagation;
import org.springframework.transaction.annotation.Transactional;

/**
 * Aplica mudanças de estado de assinatura, venha de onde vier.
 *
 * <p>É o único lugar que escreve em {@code UserSubscriptions}. Os três provedores entram por
 * aqui com um vocabulário já normalizado, e a decisão de conceder ou cortar o Pro é sempre
 * delegada ao {@link SubscriptionEntitlement}.
 */
@Service
public class SubscriptionService {

    private static final Logger log = LoggerFactory.getLogger(SubscriptionService.class);

    private final UserSubscriptionRepository subscriptions;
    private final StoreNotificationLogRepository notifications;

    public SubscriptionService(
            UserSubscriptionRepository subscriptions,
            StoreNotificationLogRepository notifications) {
        this.subscriptions = subscriptions;
        this.notifications = notifications;
    }

    /**
     * Registra ou atualiza a assinatura de um usuário conhecido.
     *
     * <p>Usado na compra: o app manda o recibo, o servidor valida com a loja e chama aqui.
     */
    @Transactional
    public UserSubscription apply(
            UUID userId,
            SubscriptionProvider provider,
            String providerSubscriptionId,
            String providerStatus,
            OffsetDateTime currentPeriodEnd) {

        final UserSubscription subscription = subscriptions.findByUserId(userId)
                .orElseGet(() -> {
                    final UserSubscription created = new UserSubscription();
                    created.setUserId(userId);
                    return created;
                });

        return write(subscription, provider, providerSubscriptionId, providerStatus, currentPeriodEnd);
    }

    /**
     * Atualiza a assinatura a partir de uma notificação da loja.
     *
     * <p>A notificação não diz quem é o usuário — só traz o identificador da assinatura. Se ele
     * não for encontrado, o evento é ignorado com log: acontece legitimamente quando a compra
     * ainda não terminou de ser registrada, e a loja vai reentregar.
     */
    @Transactional
    public Optional<UserSubscription> applyFromStore(
            SubscriptionProvider provider,
            String providerSubscriptionId,
            String providerStatus,
            OffsetDateTime currentPeriodEnd) {

        return applyFromStore(
                provider, providerSubscriptionId, null, providerStatus, currentPeriodEnd);
    }

    /**
     * Idem, para quando a loja trocou o identificador da assinatura.
     *
     * <p>É o caso do Google: mudar de plano ou reassinar emite um {@code purchaseToken} novo e
     * informa o anterior. Procurar só pelo novo não acharia nada, e a notificação seria
     * descartada como "assinatura desconhecida" — deixando um assinante pagante no plano
     * gratuito até alguém reinstalar o app.
     */
    @Transactional
    public Optional<UserSubscription> applyFromStore(
            SubscriptionProvider provider,
            String providerSubscriptionId,
            String previousProviderSubscriptionId,
            String providerStatus,
            OffsetDateTime currentPeriodEnd) {

        final Optional<UserSubscription> found =
                subscriptions.findByProviderAndProviderSubscriptionId(provider, providerSubscriptionId)
                        .or(() -> previous(provider, previousProviderSubscriptionId));

        if (found.isEmpty()) {
            log.warn("Notificação de {} para assinatura desconhecida {} — ignorando.",
                    provider, providerSubscriptionId);
            return Optional.empty();
        }

        return Optional.of(write(
                found.get(), provider, providerSubscriptionId, providerStatus, currentPeriodEnd));
    }

    /** A linha do identificador antigo, quando há um e ele encontra alguém. */
    private Optional<UserSubscription> previous(SubscriptionProvider provider, String previousId) {
        if (previousId == null || previousId.isBlank()) {
            return Optional.empty();
        }

        final Optional<UserSubscription> found =
                subscriptions.findByProviderAndProviderSubscriptionId(provider, previousId);
        found.ifPresent(subscription -> log.info(
                "Assinatura de {} do usuário {} mudou de identificador — migrando.",
                provider, subscription.getUserId()));
        return found;
    }

    private UserSubscription write(
            UserSubscription subscription,
            SubscriptionProvider provider,
            String providerSubscriptionId,
            String providerStatus,
            OffsetDateTime currentPeriodEnd) {

        final boolean entitled = SubscriptionEntitlement.isEntitled(provider, providerStatus);

        subscription.setProvider(provider);
        subscription.setProviderSubscriptionId(providerSubscriptionId);
        subscription.setProviderStatus(providerStatus);
        subscription.setActive(entitled);
        subscription.setPlan(entitled ? SubscriptionPlanType.PRO : SubscriptionPlanType.FREE);
        subscription.setCurrentPeriodEnd(currentPeriodEnd);
        subscription.setUpdatedAt(OffsetDateTime.now());

        // As colunas do Stripe seguem preenchidas para as assinaturas web: é delas que o
        // portal de cobrança depende.
        if (provider == SubscriptionProvider.STRIPE) {
            subscription.setStripeSubscriptionId(providerSubscriptionId);
            subscription.setStripeStatus(providerStatus);
        }

        final UserSubscription saved = subscriptions.save(subscription);
        log.info("Assinatura do usuário {} sincronizada: {} status={} ativa={}",
                saved.getUserId(), provider, providerStatus, entitled);
        return saved;
    }

    /**
     * Esta notificação já foi processada?
     *
     * <p>Consulta separada de {@link #markProcessed} porque a marca é feita <b>depois</b> de a
     * notificação ter surtido efeito, e não antes: marcar na entrada faria uma falha transitória
     * — a loja fora do ar, a assinatura ainda não registrada pela compra — consumir a única
     * entrega útil, e a reentrega seguinte seria descartada como repetida.
     */
    @Transactional(readOnly = true)
    public boolean alreadyProcessed(String notificationId) {
        return notificationId != null
                && !notificationId.isBlank()
                && notifications.existsById(notificationId);
    }

    /**
     * Marca a notificação como processada; devolve {@code false} se ela já tinha sido.
     *
     * <p>Roda em transação própria para que o registro sobreviva mesmo se o processamento
     * seguinte falhar e sofrer rollback — do contrário uma falha transitória viraria
     * reprocessamento infinito, já que as lojas reentregam até receber 2xx.
     */
    @Transactional(propagation = Propagation.REQUIRES_NEW)
    public boolean markProcessed(String notificationId, SubscriptionProvider provider, String type) {
        if (notificationId == null || notificationId.isBlank()) {
            // Sem identificador não há como deduplicar; processa e deixa o log avisar.
            log.warn("Notificação de {} sem identificador — processando sem deduplicação.", provider);
            return true;
        }

        if (notifications.existsById(notificationId)) {
            log.info("Notificação {} já processada — ignorando reentrega.", notificationId);
            return false;
        }

        final StoreNotificationLog entry = new StoreNotificationLog();
        entry.setId(notificationId);
        entry.setProvider(provider);
        entry.setType(type == null ? "" : type);

        try {
            notifications.save(entry);
            return true;
        } catch (DataIntegrityViolationException e) {
            // Duas entregas simultâneas da mesma notificação: a chave primária resolve.
            log.info("Notificação {} processada em paralelo — ignorando.", notificationId);
            return false;
        }
    }
}
