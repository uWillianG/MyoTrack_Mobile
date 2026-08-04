package com.myotrack.api.rewards;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import com.myotrack.api.rewards.RewardService.RewardStatus;
import com.myotrack.domain.entity.ProGrant;
import com.myotrack.domain.entity.WorkoutSession;
import com.myotrack.infrastructure.repository.ProGrantRepository;
import com.myotrack.infrastructure.repository.WorkoutSessionRepository;
import java.time.Clock;
import java.time.Instant;
import java.time.LocalDate;
import java.time.OffsetDateTime;
import java.time.ZoneOffset;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.mockito.ArgumentCaptor;
import org.springframework.dao.DataIntegrityViolationException;

/**
 * A concessão de Pro por constância.
 *
 * <p>O que se testa aqui é o que custa dinheiro. Duas falhas importam de verdade: conceder a
 * quem não fez — que é a que um cliente malicioso tentaria produzir, e o motivo de a sequência
 * ser recontada no servidor — e conceder <b>de novo</b> a quem já ganhou, que é a falha
 * silenciosa: doze semanas seguidas continuam verdadeiras por meses, e sem a trava cada abertura
 * do app renderia mais um mês de plano pago.
 */
class RewardServiceTest {

    private static final UUID ANA = UUID.fromString("11111111-1111-1111-1111-111111111111");

    /** Uma quarta-feira; a semana dela começa em 2026-07-27. */
    private static final LocalDate TODAY = LocalDate.of(2026, 7, 29);

    private WorkoutSessionRepository sessions;
    private ProGrantRepository grants;
    private RewardService service;
    private List<ProGrant> saved;

    @BeforeEach
    void setUp() {
        sessions = mock(WorkoutSessionRepository.class);
        grants = mock(ProGrantRepository.class);
        saved = new ArrayList<>();

        final Clock clock = Clock.fixed(
                TODAY.atStartOfDay(ZoneOffset.UTC).toInstant(), ZoneOffset.UTC);
        service = new RewardService(sessions, grants, clock);

        when(grants.existsByUserIdAndMilestone(any(), any())).thenReturn(false);
        when(grants.saveAndFlush(any(ProGrant.class))).thenAnswer(invocation -> {
            final ProGrant grant = invocation.getArgument(0);
            saved.add(grant);
            return grant;
        });
        when(grants.findByUserId(ANA)).thenAnswer(invocation -> List.copyOf(saved));
    }

    /** Sessões nas últimas {@code weeks} semanas, uma por semana, terminando na corrente. */
    private void trainedFor(int weeks) {
        final List<WorkoutSession> list = new ArrayList<>();
        for (int i = 0; i < weeks; i++) {
            final WorkoutSession session = new WorkoutSession();
            session.setDate(TODAY.minusWeeks(i));
            list.add(session);
        }
        when(sessions.findByUserIdOrderByDateDesc(ANA)).thenReturn(list);
    }

    @Test
    @DisplayName("três semanas não concedem nada")
    void belowFirstMilestone() {
        trainedFor(3);

        final RewardStatus status = service.evaluate(ANA);

        assertThat(status.streakWeeks()).isEqualTo(3);
        assertThat(status.activeGrant()).isNull();
        verify(grants, never()).saveAndFlush(any(ProGrant.class));
    }

    @Test
    @DisplayName("quatro semanas concedem uma semana de Pro")
    void firstMilestone() {
        trainedFor(4);

        final RewardStatus status = service.evaluate(ANA);

        final ArgumentCaptor<ProGrant> captor = ArgumentCaptor.forClass(ProGrant.class);
        verify(grants).saveAndFlush(captor.capture());

        final ProGrant grant = captor.getValue();
        assertThat(grant.getMilestone()).isEqualTo("quatro-semanas");
        assertThat(grant.getStreakWeeks()).isEqualTo(4);
        assertThat(grant.getExpiresAt())
                .isEqualTo(OffsetDateTime.ofInstant(
                                Instant.parse("2026-07-29T00:00:00Z"), ZoneOffset.UTC)
                        .plusDays(7));
        assertThat(status.activeGrant().milestone()).isEqualTo("quatro-semanas");
    }

    @Test
    @DisplayName("doze semanas concedem as duas marcas de uma vez")
    void bothMilestonesAtOnce() {
        // Quem só abre o app depois de três meses não pode perder a marca de quatro semanas —
        // ela foi conquistada no caminho, ainda que ninguém estivesse olhando.
        trainedFor(12);

        final RewardStatus status = service.evaluate(ANA);

        assertThat(saved).extracting(ProGrant::getMilestone)
                .containsExactly("quatro-semanas", "doze-semanas");
        // A ativa é a que dura mais: o mês, e não a semana.
        assertThat(status.activeGrant().milestone()).isEqualTo("doze-semanas");
        assertThat(status.granted()).containsExactly("doze-semanas", "quatro-semanas");
    }

    @Test
    @DisplayName("uma marca já concedida não concede de novo")
    void grantedOnlyOnce() {
        // A falha silenciosa: a sequência permanece verdadeira, e sem esta checagem cada
        // abertura do app somaria mais um mês de plano pago.
        trainedFor(12);
        when(grants.existsByUserIdAndMilestone(ANA, "quatro-semanas")).thenReturn(true);
        when(grants.existsByUserIdAndMilestone(ANA, "doze-semanas")).thenReturn(true);

        service.evaluate(ANA);

        verify(grants, never()).saveAndFlush(any(ProGrant.class));
    }

    @Test
    @DisplayName("perder a corrida do índice único não é erro")
    void concurrentGrantIsNotAnError() {
        // Duas requisições do mesmo app podem chegar juntas — a abertura da tela e um refresh.
        // O índice único decide; quem perde constata que a outra já concedeu.
        trainedFor(4);
        when(grants.saveAndFlush(any(ProGrant.class)))
                .thenThrow(new DataIntegrityViolationException("unique violation"));

        final RewardStatus status = service.evaluate(ANA);

        assertThat(status.streakWeeks()).isEqualTo(4);
    }

    @Test
    @DisplayName("concessão vencida não conta como ativa")
    void expiredGrantIsNotActive() {
        trainedFor(1);
        when(grants.existsByUserIdAndMilestone(any(), any())).thenReturn(true);

        final ProGrant expired = new ProGrant();
        expired.setMilestone("quatro-semanas");
        expired.setExpiresAt(OffsetDateTime.parse("2026-07-01T00:00:00Z"));
        when(grants.findByUserId(ANA)).thenReturn(List.of(expired));

        final RewardStatus status = service.evaluate(ANA);

        assertThat(status.activeGrant()).isNull();
        // Mas continua no histórico: é o que impede que ela seja concedida de novo.
        assertThat(status.granted()).containsExactly("quatro-semanas");
    }

    @Test
    @DisplayName("sem treino nenhum, sequência zero e nada concedido")
    void noSessions() {
        when(sessions.findByUserIdOrderByDateDesc(ANA)).thenReturn(List.of());

        final RewardStatus status = service.evaluate(ANA);

        assertThat(status.streakWeeks()).isZero();
        assertThat(status.activeGrant()).isNull();
        verify(grants, never()).saveAndFlush(any(ProGrant.class));
    }

    @Test
    @DisplayName("as marcas anunciadas ao app batem com as do domínio")
    void milestonesExposed() {
        trainedFor(0);
        when(sessions.findByUserIdOrderByDateDesc(ANA)).thenReturn(List.of());

        final RewardStatus status = service.evaluate(ANA);

        assertThat(status.milestones())
                .extracting(RewardService.Milestone::id, RewardService.Milestone::requiredWeeks)
                .containsExactly(
                        org.assertj.core.api.Assertions.tuple("quatro-semanas", 4),
                        org.assertj.core.api.Assertions.tuple("doze-semanas", 12));
        verify(grants, never()).existsByUserIdAndMilestone(any(), eq("nao-existe"));
    }
}
