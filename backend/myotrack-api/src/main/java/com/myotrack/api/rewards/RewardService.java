package com.myotrack.api.rewards;

import com.myotrack.domain.entity.ProGrant;
import com.myotrack.domain.entity.WorkoutSession;
import com.myotrack.domain.service.ProMilestone;
import com.myotrack.domain.service.TrainingStreak;
import com.myotrack.infrastructure.repository.ProGrantRepository;
import com.myotrack.infrastructure.repository.WorkoutSessionRepository;
import java.time.Clock;
import java.time.LocalDate;
import java.time.OffsetDateTime;
import java.util.Comparator;
import java.util.List;
import java.util.Optional;
import java.util.UUID;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * Avalia a constância do usuário e concede Pro por prazo quando ela fecha uma marca.
 *
 * <p><b>Quem avalia é quem paga.</b> As outras conquistas do app são derivadas no cliente, e
 * isso é barato e correto enquanto elas só pintam um selo. Estas duas valem dinheiro, então a
 * sequência é recontada aqui, a partir das sessões que este servidor guardou. O app nunca
 * afirma ter conquistado nada — ele pergunta, e mostra a resposta.
 *
 * <p>A concessão é <b>uma por marca, para sempre</b>. Doze semanas seguidas continuam
 * verdadeiras por meses; sem essa trava, cada abertura do app renderia mais um mês de Pro.
 */
@Service
public class RewardService {

    private final WorkoutSessionRepository sessions;
    private final ProGrantRepository grants;
    private final Clock clock;

    public RewardService(
            WorkoutSessionRepository sessions, ProGrantRepository grants, Clock clock) {
        this.sessions = sessions;
        this.grants = grants;
        this.clock = clock;
    }

    /**
     * Recalcula a sequência, concede o que houver a conceder e devolve a situação.
     *
     * <p>Escreve numa leitura, o que normalmente seria um cheiro. Aqui é a escolha consciente:
     * a alternativa é um agendador varrendo todos os usuários toda noite para descobrir quem
     * fechou a semana, e ninguém precisa saber que ganhou Pro às três da manhã. Como a
     * concessão é única por marca, chamar isto dez vezes seguidas tem o mesmo efeito de chamar
     * uma.
     */
    @Transactional
    public RewardStatus evaluate(UUID userId) {
        final LocalDate today = LocalDate.now(clock);
        final OffsetDateTime now = OffsetDateTime.now(clock);

        final List<LocalDate> dates = sessions.findByUserIdOrderByDateDesc(userId).stream()
                .map(WorkoutSession::getDate)
                .filter(java.util.Objects::nonNull)
                .toList();

        final int streak = TrainingStreak.weeks(dates, today);

        for (final ProMilestone milestone : ProMilestone.ordered()) {
            if (milestone.reachedBy(streak) && !grants.existsByUserIdAndMilestone(userId, milestone.id())) {
                grant(userId, milestone, streak, now);
            }
        }

        final List<ProGrant> all = grants.findByUserId(userId);
        final Optional<ProGrant> active = all.stream()
                .filter(g -> g.isActiveAt(now))
                .max(Comparator.comparing(ProGrant::getExpiresAt));

        return new RewardStatus(
                streak,
                active.map(g -> new ActiveGrant(g.getMilestone(), g.getExpiresAt())).orElse(null),
                all.stream().map(ProGrant::getMilestone).sorted().toList(),
                ProMilestone.ordered().stream()
                        .map(m -> new Milestone(m.id(), m.requiredWeeks(), m.proDays()))
                        .toList());
    }

    private void grant(UUID userId, ProMilestone milestone, int streak, OffsetDateTime now) {
        final ProGrant grant = new ProGrant();
        grant.setUserId(userId);
        grant.setMilestone(milestone.id());
        grant.setGrantedAt(now);
        grant.setExpiresAt(now.plusDays(milestone.proDays()));
        grant.setStreakWeeks(streak);

        try {
            grants.saveAndFlush(grant);
        } catch (DataIntegrityViolationException alreadyGranted) {
            // Duas requisições do mesmo app em paralelo — a abertura da tela e um refresh —
            // podem chegar juntas. O índice único é quem decide; perder a corrida aqui
            // significa que a outra já concedeu, e isso é sucesso, não erro.
        }
    }

    /** O que o app mostra. */
    public record RewardStatus(
            int streakWeeks, ActiveGrant activeGrant, List<String> granted, List<Milestone> milestones) {
    }

    public record ActiveGrant(String milestone, OffsetDateTime expiresAt) {
    }

    public record Milestone(String id, int requiredWeeks, int proDays) {
    }
}
