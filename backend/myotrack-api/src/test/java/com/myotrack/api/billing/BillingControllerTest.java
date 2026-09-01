package com.myotrack.api.billing;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import com.myotrack.domain.SubscriptionPlanType;
import com.myotrack.domain.SubscriptionProvider;
import com.myotrack.domain.entity.ProGrant;
import com.myotrack.domain.entity.UserSubscription;
import com.myotrack.infrastructure.repository.ProGrantRepository;
import com.myotrack.infrastructure.repository.UserSubscriptionRepository;
import java.time.Clock;
import java.time.Instant;
import java.time.OffsetDateTime;
import java.time.ZoneOffset;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.UUID;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.security.oauth2.server.resource.authentication.JwtAuthenticationToken;

/**
 * O que {@code GET /api/billing} conta à tela de assinatura.
 *
 * <p>O assunto destes testes é o bloco {@code pro}, que existe para a tela poder comparar os
 * dois planos. Ela não comparava porque a resposta só trazia os limites <b>do usuário</b>, e
 * escrever "50" no app seria inventar um número que a configuração do ambiente desmente.
 *
 * <p>Por isso o {@link EntitlementService} aqui é <b>real</b>, com um {@link LimitsProperties}
 * de números propositalmente estranhos: um mock devolveria o que o teste mandasse e provaria
 * apenas que o controller sabe copiar. O que precisa ficar preso é o caminho inteiro —
 * configuração, serviço, corpo da resposta —, porque é justamente ele que uma constante
 * escrita no controller cortaria sem quebrar nada.
 */
class BillingControllerTest {

    private static final UUID USER_ID = UUID.fromString("22222222-2222-2222-2222-222222222222");

    /** Nada de 10/5/10 nem 50/20/50: com os padrões, um valor cravado passaria despercebido. */
    private static final LimitsProperties LIMITS = new LimitsProperties(
            new LimitsProperties.PlanLimits(2, 1, 3),
            new LimitsProperties.PlanLimits(7, 4, 9));

    private UserSubscriptionRepository subscriptions;
    private ProGrantRepository grants;
    private BillingController controller;

    @BeforeEach
    void setUp() {
        subscriptions = mock(UserSubscriptionRepository.class);
        grants = mock(ProGrantRepository.class);

        final EntitlementService entitlements = new EntitlementService(
                subscriptions,
                grants,
                LIMITS,
                Clock.fixed(Instant.parse("2026-08-31T12:00:00Z"), ZoneOffset.UTC));

        controller = new BillingController(
                entitlements,
                mock(SubscriptionService.class),
                subscriptions,
                List.of());

        when(subscriptions.findByUserId(any())).thenReturn(Optional.empty());
        when(grants.existsByUserIdAndExpiresAtAfter(any(), any())).thenReturn(false);

        final Jwt jwt = Jwt.withTokenValue("t")
                .header("alg", "none")
                .subject(USER_ID.toString())
                .build();
        SecurityContextHolder.getContext()
                .setAuthentication(new JwtAuthenticationToken(jwt, List.of()));
    }

    @AfterEach
    void tearDown() {
        SecurityContextHolder.clearContext();
    }

    @Test
    @DisplayName("no plano gratuito, a resposta traz os limites de hoje e os do Pro")
    void freeCarriesBothSides() {
        final Map<String, Object> body = controller.status();

        assertThat(body.get("plan")).isEqualTo("Free");
        assertThat(body.get("maxMealAnalysesPerDay")).isEqualTo(2);
        assertThat(body.get("maxVideoAnalysesPerDay")).isEqualTo(1);
        assertThat(body.get("maxCoachMessagesPerDay")).isEqualTo(3);

        assertThat(body.get("pro")).isEqualTo(Map.of(
                "maxMealAnalysesPerDay", 7,
                "maxVideoAnalysesPerDay", 4,
                "maxCoachMessagesPerDay", 9));
    }

    @Test
    @DisplayName("o bloco do Pro também vai para quem já é Pro")
    void proAlsoGetsTheBlock() {
        final UserSubscription subscription = new UserSubscription();
        subscription.setPlan(SubscriptionPlanType.PRO);
        subscription.setActive(true);
        subscription.setProvider(SubscriptionProvider.GOOGLE_PLAY);
        subscription.setProviderStatus("active");
        subscription.setCurrentPeriodEnd(OffsetDateTime.parse("2026-09-30T00:00:00Z"));
        when(subscriptions.findByUserId(any())).thenReturn(Optional.of(subscription));

        final Map<String, Object> body = controller.status();

        // Ele é configuração do servidor, não estado do usuário: quem decide se vale mostrar
        // "7 → 7" é a tela, e ela já não mostra.
        assertThat(body.get("plan")).isEqualTo("Pro");
        assertThat(body.get("maxMealAnalysesPerDay")).isEqualTo(7);
        assertThat(body.get("pro")).isEqualTo(Map.of(
                "maxMealAnalysesPerDay", 7,
                "maxVideoAnalysesPerDay", 4,
                "maxCoachMessagesPerDay", 9));
    }

    // O Pro por constância não tem cobrança por trás. A tela usa isto para dizer quando o
    // prêmio acaba — e, o que importa mais, para continuar oferecendo a assinatura a quem só
    // tem o prazo.
    @Test
    @DisplayName("o Pro por constância se identifica e diz quando acaba")
    void grantedProSaysWhenItEnds() {
        final OffsetDateTime expiry = OffsetDateTime.parse("2026-09-07T12:00:00Z");
        final ProGrant grant = new ProGrant();
        grant.setMilestone("four-weeks");
        grant.setExpiresAt(expiry);

        when(grants.existsByUserIdAndExpiresAtAfter(any(), any())).thenReturn(true);
        when(grants.findFirstByUserIdAndExpiresAtAfterOrderByExpiresAtDesc(any(), any()))
                .thenReturn(Optional.of(grant));

        final Map<String, Object> body = controller.status();

        assertThat(body.get("plan")).isEqualTo("Pro");
        assertThat(body.get("isGranted")).isEqualTo(true);
        assertThat(body.get("grantExpiresAt")).isEqualTo(expiry);
        // Sem assinatura não há renovação: a tela que mostrasse esta data como "renova em"
        // estaria prometendo uma cobrança que não vai acontecer.
        assertThat(body.get("currentPeriodEnd")).isNull();
        assertThat(body.get("maxMealAnalysesPerDay")).isEqualTo(7);
    }

    @Test
    @DisplayName("quem paga não é 'concedido', e não paga uma consulta a mais por isso")
    void paidProIsNotGranted() {
        final UserSubscription subscription = new UserSubscription();
        subscription.setPlan(SubscriptionPlanType.PRO);
        subscription.setActive(true);
        subscription.setProvider(SubscriptionProvider.APP_STORE);
        when(subscriptions.findByUserId(any())).thenReturn(Optional.of(subscription));

        final Map<String, Object> body = controller.status();

        assertThat(body.get("isGranted")).isEqualTo(false);
        assertThat(body.get("grantExpiresAt")).isNull();
        // A data do prêmio só é buscada quando há prêmio. Perguntá-la sempre poria uma consulta
        // a mais em toda abertura da tela para responder null à esmagadora maioria.
        verify(grants, never())
                .findFirstByUserIdAndExpiresAtAfterOrderByExpiresAtDesc(any(), any());
    }
}
