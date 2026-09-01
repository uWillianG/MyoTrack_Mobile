package com.myotrack.api.billing;

import com.myotrack.domain.SubscriptionPlanType;
import com.myotrack.domain.entity.ProGrant;
import com.myotrack.infrastructure.repository.ProGrantRepository;
import com.myotrack.infrastructure.repository.UserSubscriptionRepository;
import java.time.Clock;
import java.time.OffsetDateTime;
import java.util.Optional;
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
    private final ProGrantRepository grants;
    private final LimitsProperties limits;
    private final Clock clock;

    public EntitlementService(
            UserSubscriptionRepository subscriptions,
            ProGrantRepository grants,
            LimitsProperties limits,
            Clock clock) {
        this.subscriptions = subscriptions;
        this.grants = grants;
        this.limits = limits;
        this.clock = clock;
    }

    /**
     * O plano efetivo e os limites dele.
     *
     * <p>Duas origens de Pro, e a ordem entre elas não importa porque o resultado é o mesmo:
     * assinatura ativa da loja, ou concessão por constância dentro do prazo. O que <b>não</b>
     * se mistura é de onde ele veio — a assinatura continua sendo a única resposta para "quem
     * pagou", e a concessão vive na própria tabela. Um usuário com as duas coisas é Pro uma
     * vez só; quando a concessão vence, ele continua Pro pela assinatura, sem transição.
     */
    @Transactional(readOnly = true)
    public Entitlements get(UUID userId) {
        final boolean paid = subscriptions.findByUserId(userId)
                .filter(s -> s.isActive() && s.getPlan() == SubscriptionPlanType.PRO)
                .isPresent();
        final boolean granted =
                grants.existsByUserIdAndExpiresAtAfter(userId, OffsetDateTime.now(clock));
        final boolean isPro = paid || granted;

        final LimitsProperties.PlanLimits plan = isPro ? limits.pro() : limits.free();

        return new Entitlements(
                isPro ? SubscriptionPlanType.PRO : SubscriptionPlanType.FREE,
                plan.maxMealAnalysesPerDay(),
                plan.maxVideoAnalysesPerDay(),
                plan.maxCoachMessagesPerDay(),
                granted && !paid);
    }

    /**
     * Quando o Pro por constância acaba, ou vazio quando não há concessão valendo.
     *
     * <p>Fora de {@link #get(UUID)} de propósito: aquele roda em toda checagem de limite de IA
     * e responde com um {@code exists}, que é barato. Esta pergunta é da tela de assinatura,
     * que precisa da data para dizer até quando — e é a única que a faz.
     */
    @Transactional(readOnly = true)
    public Optional<OffsetDateTime> grantExpiry(UUID userId) {
        return grants
                .findFirstByUserIdAndExpiresAtAfterOrderByExpiresAtDesc(
                        userId, OffsetDateTime.now(clock))
                .map(ProGrant::getExpiresAt);
    }

    /**
     * Os limites do Pro, valha ele para este usuário ou não.
     *
     * <p>Existe para a tela de assinatura poder comparar. Ela não montava a comparação porque
     * o servidor só dizia os limites <b>do usuário</b>, e escrever "50" no app seria inventar
     * um número que a configuração do ambiente pode desmentir — o mesmo defeito que
     * {@link LimitsProperties} existe para evitar. Agora a comparação é palavra do servidor.
     *
     * <p>Fica aqui, e não no controller, para que continue havendo um dono só da pergunta
     * "quanto cabe em cada plano".
     */
    public LimitsProperties.PlanLimits proLimits() {
        return limits.pro();
    }

    public record Entitlements(
            SubscriptionPlanType plan,
            int maxMealAnalysesPerDay,
            int maxVideoAnalysesPerDay,
            int maxCoachMessagesPerDay,
            /**
             * O Pro veio de uma concessão por constância, e não de pagamento. A tela de
             * assinatura usa isto para não oferecer o portal de cobrança a quem não tem
             * cobrança nenhuma — e para dizer quando o prêmio acaba.
             */
            boolean isGranted) {

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
