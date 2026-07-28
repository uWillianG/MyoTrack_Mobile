package com.myotrack.api.billing;

import com.myotrack.domain.SubscriptionPlanType;
import com.myotrack.infrastructure.repository.UserSubscriptionRepository;
import java.util.UUID;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * Resolve o plano do usuário (Free/Pro) e os limites de uso de IA correspondentes.
 *
 * <p>Porte de MyoTrack.Api/Services/EntitlementService.cs. <b>Não mudou com a entrada das
 * lojas</b>: continua lendo apenas {@code isActive} + {@code plan} da assinatura, sem saber se
 * ela veio do Stripe, da Apple ou do Google. Toda a complexidade de provedor fica contida no
 * {@link SubscriptionService}.
 */
@Service
public class EntitlementService {

    private final UserSubscriptionRepository subscriptions;
    private final LimitsProperties limits;

    public EntitlementService(UserSubscriptionRepository subscriptions, LimitsProperties limits) {
        this.subscriptions = subscriptions;
        this.limits = limits;
    }

    @Transactional(readOnly = true)
    public Entitlements get(UUID userId) {
        final boolean isPro = subscriptions.findByUserId(userId)
                .filter(s -> s.isActive() && s.getPlan() == SubscriptionPlanType.PRO)
                .isPresent();

        final LimitsProperties.PlanLimits plan = isPro ? limits.pro() : limits.free();

        return new Entitlements(
                isPro ? SubscriptionPlanType.PRO : SubscriptionPlanType.FREE,
                plan.maxMealAnalysesPerDay(),
                plan.maxVideoAnalysesPerDay(),
                plan.maxCoachMessagesPerDay());
    }

    public record Entitlements(
            SubscriptionPlanType plan,
            int maxMealAnalysesPerDay,
            int maxVideoAnalysesPerDay,
            int maxCoachMessagesPerDay) {

        public boolean isPro() {
            return plan == SubscriptionPlanType.PRO;
        }

        /**
         * Mensagem de limite atingido. Só oferece o Pro a quem ainda não tem — dizer "assine o
         * Pro" para um assinante seria confuso e um pouco insultuoso.
         */
        public String limitMessage(String what, int limit) {
            return isPro()
                    ? "Limite diário de %d %s atingido.".formatted(limit, what)
                    : "Limite diário de %d %s atingido. Assine o Pro para ampliar.".formatted(limit, what);
        }
    }
}
