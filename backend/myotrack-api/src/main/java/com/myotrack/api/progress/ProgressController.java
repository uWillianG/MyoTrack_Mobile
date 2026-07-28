package com.myotrack.api.progress;

import com.myotrack.api.security.CurrentUser;
import com.myotrack.domain.PlanStatus;
import com.myotrack.domain.entity.BodyMeasurement;
import com.myotrack.domain.entity.SetLog;
import com.myotrack.domain.entity.WorkoutDay;
import com.myotrack.domain.entity.WorkoutExercise;
import com.myotrack.domain.entity.WorkoutPlan;
import com.myotrack.domain.entity.WorkoutSession;
import com.myotrack.domain.service.ProgressionCalculator;
import com.myotrack.domain.service.ProgressionSuggestion;
import com.myotrack.domain.service.SetPerformance;
import com.myotrack.infrastructure.repository.BodyMeasurementRepository;
import com.myotrack.infrastructure.repository.WorkoutPlanRepository;
import com.myotrack.infrastructure.repository.WorkoutSessionRepository;
import java.math.BigDecimal;
import java.time.DayOfWeek;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.TreeMap;
import java.util.UUID;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

/**
 * Evolução do usuário. Porte de MyoTrack.Api/Controllers/ProgressController.cs.
 *
 * <p>Tudo aqui é <b>determinístico, sem LLM</b>. A sugestão de progressão em especial: ela diz
 * a alguém quanto peso pôr na barra na próxima série, e isso não pode depender do que um
 * modelo estimou. Quem calcula é o {@link ProgressionCalculator}, que já existia neste
 * repositório, com testes, e até agora não tinha nada que o expusesse — a sugestão nunca
 * chegava ao usuário.
 */
@RestController
@RequestMapping("/api/progress")
public class ProgressController {

    /** Janela do histórico considerado na sugestão. Mais que isso é forma antiga. */
    private static final int SUGGESTION_LOOKBACK_MONTHS = 6;

    private final WorkoutSessionRepository sessions;
    private final BodyMeasurementRepository measurements;
    private final WorkoutPlanRepository plans;

    public ProgressController(
            WorkoutSessionRepository sessions,
            BodyMeasurementRepository measurements,
            WorkoutPlanRepository plans) {
        this.sessions = sessions;
        this.measurements = measurements;
        this.plans = plans;
    }

    /** Exercícios que o usuário já registrou — popula o seletor do gráfico. */
    @GetMapping("/exercises")
    @Transactional(readOnly = true)
    public List<LoggedExercise> loggedExercises() {
        final Map<Integer, String> names = new LinkedHashMap<>();
        final Map<Integer, java.util.Set<UUID>> sessionsByExercise = new LinkedHashMap<>();

        forEachSet(CurrentUser.id(), (session, set) -> {
            final Integer id = exerciseIdOf(set);
            if (id == null) {
                return;
            }
            names.putIfAbsent(id, set.getExercise().getName());
            sessionsByExercise
                    .computeIfAbsent(id, k -> new java.util.LinkedHashSet<>())
                    .add(session.getId());
        });

        return names.entrySet().stream()
                .map(e -> new LoggedExercise(
                        e.getKey(), e.getValue(), sessionsByExercise.get(e.getKey()).size()))
                .sorted(Comparator.comparingInt(LoggedExercise::sessions).reversed())
                .toList();
    }

    /** Carga máxima e volume por sessão, para um exercício. */
    @GetMapping("/exercises/{exerciseId}")
    @Transactional(readOnly = true)
    public List<ExercisePoint> byExercise(@PathVariable Integer exerciseId) {
        final Map<LocalDate, BigDecimal> maxLoad = new TreeMap<>();
        final Map<LocalDate, BigDecimal> volume = new TreeMap<>();

        forEachSet(CurrentUser.id(), (session, set) -> {
            if (!exerciseId.equals(exerciseIdOf(set)) || session.getDate() == null) {
                return;
            }
            final BigDecimal load = loadOf(set);
            maxLoad.merge(session.getDate(), load, (a, b) -> a.max(b));
            volume.merge(session.getDate(), volumeOf(set), BigDecimal::add);
        });

        return maxLoad.keySet().stream()
                .map(date -> new ExercisePoint(date, maxLoad.get(date), volume.get(date)))
                .toList();
    }

    /** Volume total por semana (segunda a domingo). */
    @GetMapping("/volume")
    @Transactional(readOnly = true)
    public List<WeeklyVolume> weeklyVolume() {
        final Map<LocalDate, BigDecimal> byWeek = new TreeMap<>();

        forEachSet(CurrentUser.id(), (session, set) -> {
            if (session.getDate() != null) {
                byWeek.merge(weekStartOf(session.getDate()), volumeOf(set), BigDecimal::add);
            }
        });

        return byWeek.entrySet().stream()
                .map(e -> new WeeklyVolume(e.getKey(), e.getValue()))
                .toList();
    }

    /** Série temporal de peso corporal, em ordem crescente de data. */
    @GetMapping("/weight")
    @Transactional(readOnly = true)
    public List<WeightPoint> weight() {
        return measurements.findByUserIdOrderByDateDesc(CurrentUser.id()).stream()
                .filter(m -> m.getWeightKg() != null && m.getDate() != null)
                .sorted(Comparator.comparing(BodyMeasurement::getDate))
                .map(m -> new WeightPoint(m.getDate(), m.getWeightKg()))
                .toList();
    }

    /**
     * Quanto pôr na barra na próxima sessão, para cada exercício do plano ativo.
     *
     * <p>Dupla progressão: sobe as repetições dentro da faixa até o topo, e só então aumenta a
     * carga. Sem plano ativo devolve lista vazia — não há o que sugerir.
     */
    @GetMapping("/suggestions")
    @Transactional(readOnly = true)
    public List<Suggestion> suggestions() {
        final UUID userId = CurrentUser.id();

        final WorkoutPlan plan = plans
                .findFirstByUserIdAndStatusOrderByCreatedAtDesc(userId, PlanStatus.ACTIVE)
                .orElse(null);
        if (plan == null) {
            return List.of();
        }

        final LocalDate since = LocalDate.now().minusMonths(SUGGESTION_LOOKBACK_MONTHS);

        // Séries por exercício, do histórico recente, agrupadas pela data da sessão.
        final Map<Integer, Map<LocalDate, List<SetLog>>> history = new LinkedHashMap<>();
        forEachSet(userId, (session, set) -> {
            final Integer id = exerciseIdOf(set);
            if (id == null || session.getDate() == null || session.getDate().isBefore(since)) {
                return;
            }
            history
                    .computeIfAbsent(id, k -> new TreeMap<>())
                    .computeIfAbsent(session.getDate(), k -> new ArrayList<>())
                    .add(set);
        });

        final List<Suggestion> result = new ArrayList<>();
        for (final WorkoutDay day : plan.getDays().stream()
                .sorted(Comparator.comparingInt(WorkoutDay::getOrder))
                .toList()) {

            for (final WorkoutExercise item : day.getExercises().stream()
                    .sorted(Comparator.comparingInt(WorkoutExercise::getOrder))
                    .toList()) {

                result.add(suggestionFor(day, item, history));
            }
        }
        return result;
    }

    private Suggestion suggestionFor(
            WorkoutDay day,
            WorkoutExercise item,
            Map<Integer, Map<LocalDate, List<SetLog>>> history) {

        final Integer exerciseId = item.getExercise() == null ? null : item.getExercise().getId();
        final Map<LocalDate, List<SetLog>> byDate =
                exerciseId == null ? Map.of() : history.getOrDefault(exerciseId, Map.of());

        // A sugestão olha só a ÚLTIMA sessão do exercício: é ela que diz se as repetições do
        // topo da faixa já foram alcançadas com a carga atual.
        final LocalDate lastDate = byDate.keySet().stream().max(Comparator.naturalOrder())
                .orElse(null);

        final List<SetPerformance> lastSets = lastDate == null
                ? List.of()
                : byDate.get(lastDate).stream()
                        .sorted(Comparator.comparingInt(SetLog::getSetNumber))
                        .map(s -> new SetPerformance(s.getReps(), loadOf(s)))
                        .toList();

        final BigDecimal increment = ProgressionCalculator.incrementFor(
                item.getExercise() == null ? null : item.getExercise().getPrimaryMuscleGroup());

        final ProgressionSuggestion suggestion = ProgressionCalculator.suggest(
                lastSets, item.getRepsMin(), item.getRepsMax(), increment);

        return new Suggestion(
                day.getId(),
                day.getLabel(),
                exerciseId,
                item.getExercise() == null ? "" : item.getExercise().getName(),
                item.getSets(),
                item.getRepsMin(),
                item.getRepsMax(),
                item.getRestSeconds(),
                lastDate,
                lastSets.stream().map(s -> new LastSet(s.reps(), s.loadKg())).toList(),
                suggestion.action().getWireName(),
                // Sem histórico o ponto de partida é a carga que o plano sugeriu.
                suggestion.nextLoadKg() == null ? item.getSuggestedLoadKg() : suggestion.nextLoadKg(),
                suggestion.targetReps(),
                increment);
    }

    /** Recordes por exercício: maior carga e melhor 1RM estimado (Epley). */
    @GetMapping("/records")
    @Transactional(readOnly = true)
    public List<Record> records() {
        final Map<Integer, String> names = new LinkedHashMap<>();
        final Map<Integer, List<Attempt>> attempts = new LinkedHashMap<>();

        forEachSet(CurrentUser.id(), (session, set) -> {
            final Integer id = exerciseIdOf(set);
            if (id == null || session.getDate() == null) {
                return;
            }
            names.putIfAbsent(id, set.getExercise().getName());
            attempts.computeIfAbsent(id, k -> new ArrayList<>()).add(
                    new Attempt(session.getDate(), set.getReps(), loadOf(set)));
        });

        return attempts.entrySet().stream()
                .map(entry -> toRecord(entry.getKey(), names.get(entry.getKey()), entry.getValue()))
                .sorted(Comparator.comparing(
                        (Record r) -> r.bestE1RmKg() == null ? r.maxLoadKg() : r.bestE1RmKg())
                        .reversed())
                .toList();
    }

    private static Record toRecord(Integer exerciseId, String name, List<Attempt> attempts) {
        final BigDecimal maxLoad = attempts.stream()
                .map(Attempt::loadKg)
                .max(Comparator.naturalOrder())
                .orElse(BigDecimal.ZERO);

        // Empate na carga máxima fica com a data mais antiga: foi ali que o recorde caiu.
        final LocalDate maxLoadDate = attempts.stream()
                .filter(a -> a.loadKg().compareTo(maxLoad) == 0)
                .map(Attempt::date)
                .min(Comparator.naturalOrder())
                .orElse(null);

        // O melhor 1RM não costuma ser a série mais pesada: 5×100 estima mais que 1×105.
        final Attempt best = attempts.stream()
                .filter(a -> ProgressionCalculator.estimateOneRepMax(a.reps(), a.loadKg()) != null)
                .max(Comparator
                        .comparing((Attempt a) ->
                                ProgressionCalculator.estimateOneRepMax(a.reps(), a.loadKg()))
                        .thenComparing(Comparator.comparing(Attempt::date).reversed()))
                .orElse(null);

        return new Record(
                exerciseId,
                name,
                maxLoad,
                maxLoadDate,
                best == null ? null
                        : ProgressionCalculator.estimateOneRepMax(best.reps(), best.loadKg()),
                best == null ? null : best.reps(),
                best == null ? null : best.loadKg(),
                best == null ? null : best.date());
    }

    /**
     * Percorre todas as séries do usuário.
     *
     * <p>Carrega o histórico e agrega em memória, em vez de uma consulta agregada por
     * endpoint. O volume por usuário é pequeno (séries de treino, não eventos de telemetria),
     * e assim as seis respostas saem das mesmas entidades, sem seis JPQLs para manter em
     * sincronia quando o cálculo mudar.
     */
    private void forEachSet(UUID userId, java.util.function.BiConsumer<WorkoutSession, SetLog> visit) {
        for (final WorkoutSession session : sessions.findByUserIdOrderByDateDesc(userId)) {
            for (final SetLog set : session.getSets()) {
                visit.accept(session, set);
            }
        }
    }

    private static Integer exerciseIdOf(SetLog set) {
        return set.getExercise() == null ? null : set.getExercise().getId();
    }

    /** Carga zero é peso corporal — série válida, volume zero. */
    private static BigDecimal loadOf(SetLog set) {
        return set.getLoadKg() == null ? BigDecimal.ZERO : set.getLoadKg();
    }

    private static BigDecimal volumeOf(SetLog set) {
        return loadOf(set).multiply(BigDecimal.valueOf(set.getReps()));
    }

    /** Segunda-feira da semana da data. */
    private static LocalDate weekStartOf(LocalDate date) {
        return date.minusDays(date.getDayOfWeek().getValue() - DayOfWeek.MONDAY.getValue());
    }

    private record Attempt(LocalDate date, int reps, BigDecimal loadKg) {
    }

    public record LoggedExercise(Integer exerciseId, String name, int sessions) {
    }

    public record ExercisePoint(LocalDate date, BigDecimal maxLoadKg, BigDecimal volumeKg) {
    }

    public record WeeklyVolume(LocalDate weekStart, BigDecimal volumeKg) {
    }

    public record WeightPoint(LocalDate date, BigDecimal weightKg) {
    }

    public record LastSet(int reps, BigDecimal loadKg) {
    }

    public record Suggestion(
            UUID workoutDayId,
            String dayLabel,
            Integer exerciseId,
            String exerciseName,
            int sets,
            int repsMin,
            int repsMax,
            int restSeconds,
            LocalDate lastSessionDate,
            List<LastSet> lastSets,
            String action,
            BigDecimal nextLoadKg,
            int targetReps,
            BigDecimal incrementKg) {
    }

    public record Record(
            Integer exerciseId,
            String name,
            BigDecimal maxLoadKg,
            LocalDate maxLoadDate,
            BigDecimal bestE1RmKg,
            Integer e1RmReps,
            BigDecimal e1RmLoadKg,
            LocalDate e1RmDate) {
    }
}
