package com.myotrack.infrastructure.repository;

import com.myotrack.domain.entity.SetLog;
import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;
import java.util.UUID;
import org.springframework.data.domain.Limit;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;

public interface SetLogRepository extends JpaRepository<SetLog, UUID> {

    /**
     * Resumo por exercício das últimas semanas: melhor carga, volume total e nº de sessões.
     *
     * <p>É o que entra no prompt do LLM para que a regeneração de treino continue de onde o
     * aluno parou, em vez de começar do zero toda vez. Ordenado por volume: com muitos
     * exercícios, os de maior volume são os que definem a rotina de verdade.
     */
    @Query("""
            select new com.myotrack.infrastructure.repository.SetLogRepository$ExerciseProgression(
                s.exercise.name,
                max(s.loadKg),
                sum(s.loadKg * s.reps),
                count(distinct s.workoutSession.id))
            from SetLog s
            where s.workoutSession.userId = :userId and s.workoutSession.date >= :since
            group by s.exercise.id, s.exercise.name
            order by sum(s.loadKg * s.reps) desc
            """)
    List<ExerciseProgression> summarizeProgression(UUID userId, LocalDate since, Limit limit);

    /** Séries da última sessão de um exercício — base da sugestão de progressão de carga. */
    @Query("""
            select s from SetLog s
            where s.workoutSession.userId = :userId and s.exercise.id = :exerciseId
            order by s.workoutSession.date desc, s.setNumber asc
            """)
    List<SetLog> findRecentForExercise(UUID userId, Integer exerciseId, Limit limit);

    record ExerciseProgression(
            String exerciseName,
            BigDecimal bestLoadKg,
            BigDecimal volumeTotalKg,
            long sessions) {
    }
}
