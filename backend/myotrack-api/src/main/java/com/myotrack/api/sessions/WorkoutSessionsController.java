package com.myotrack.api.sessions;

import com.myotrack.api.security.CurrentUser;
import com.myotrack.domain.entity.Exercise;
import com.myotrack.domain.entity.SetLog;
import com.myotrack.domain.entity.WorkoutSession;
import com.myotrack.infrastructure.repository.ExerciseRepository;
import com.myotrack.infrastructure.repository.WorkoutSessionRepository;
import java.math.BigDecimal;
import java.math.MathContext;
import java.time.LocalDate;
import java.util.Comparator;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.UUID;
import java.util.stream.Collectors;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.ResponseEntity;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

/**
 * Sessões de treino executadas. Porte de MyoTrack.Api/Controllers/WorkoutSessionsController.cs.
 *
 * <p>É a origem de tudo que é progressão no app: dashboard, recordes, sugestão de carga e o
 * histórico que entra no prompt da regeneração de treino saem daqui.
 */
@RestController
@RequestMapping("/api/sessions")
public class WorkoutSessionsController {

    /** Teto do histórico: 100 sessões cobrem mais de um ano de treino 2x por semana. */
    private static final int MAX_SESSIONS = 100;

    private static final int MIN_REPS = 1;
    private static final int MAX_REPS = 100;
    private static final BigDecimal MAX_LOAD_KG = BigDecimal.valueOf(1000);

    private final WorkoutSessionRepository sessions;
    private final ExerciseRepository exercises;

    public WorkoutSessionsController(
            WorkoutSessionRepository sessions, ExerciseRepository exercises) {
        this.sessions = sessions;
        this.exercises = exercises;
    }

    @PostMapping
    @Transactional
    public ResponseEntity<?> create(@RequestBody SessionRequest request) {
        if (request.sets() == null || request.sets().isEmpty()) {
            return ResponseEntity.badRequest()
                    .body(Map.of("error", "Registre pelo menos uma série."));
        }

        // Faixas amplas de propósito: elas existem para barrar erro de digitação
        // ("1000 kg" no lugar de "100 kg"), não para julgar o treino de ninguém.
        final boolean outOfRange = request.sets().stream().anyMatch(s ->
                s.reps() < MIN_REPS
                        || s.reps() > MAX_REPS
                        || s.loadKg() == null
                        || s.loadKg().signum() < 0
                        || s.loadKg().compareTo(MAX_LOAD_KG) > 0);
        if (outOfRange) {
            return ResponseEntity.badRequest()
                    .body(Map.of("error", "Série com repetições ou carga fora da faixa válida."));
        }

        final Set<Integer> requestedIds = request.sets().stream()
                .map(SetLogRequest::exerciseId)
                .collect(Collectors.toSet());
        final Map<Integer, Exercise> found = exercises.findAllById(requestedIds).stream()
                .collect(Collectors.toMap(Exercise::getId, e -> e));
        if (found.size() != requestedIds.size()) {
            return ResponseEntity.badRequest()
                    .body(Map.of("error", "Exercício inexistente na sessão."));
        }

        final WorkoutSession session = new WorkoutSession();
        session.setUserId(CurrentUser.id());
        session.setDate(request.date() == null ? LocalDate.now() : request.date());
        session.setNotes(request.notes());

        for (final SetLogRequest item : request.sets()) {
            final SetLog set = new SetLog();
            set.setExercise(found.get(item.exerciseId()));
            set.setSetNumber(item.setNumber());
            set.setReps(item.reps());
            set.setLoadKg(item.loadKg());
            set.setRpe(item.rpe());
            session.addSet(set);
        }

        return ResponseEntity.ok(Map.of("id", sessions.save(session).getId()));
    }

    @GetMapping("/{id}")
    @Transactional(readOnly = true)
    public ResponseEntity<SessionView> byId(@PathVariable UUID id) {
        return sessions
                .findByIdAndUserId(id, CurrentUser.id())
                .map(session -> ResponseEntity.ok(SessionView.from(session)))
                .orElseGet(() -> ResponseEntity.notFound().build());
    }

    @GetMapping
    @Transactional(readOnly = true)
    public List<SessionView> list(
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE)
            LocalDate from,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE)
            LocalDate to) {

        return sessions.findByUserIdOrderByDateDesc(CurrentUser.id()).stream()
                .filter(s -> from == null || !s.getDate().isBefore(from))
                .filter(s -> to == null || !s.getDate().isAfter(to))
                .limit(MAX_SESSIONS)
                .map(SessionView::from)
                .toList();
    }

    public record SetLogRequest(
            int exerciseId, int setNumber, int reps, BigDecimal loadKg, Integer rpe) {
    }

    public record SessionRequest(
            LocalDate date, UUID workoutDayId, String notes, List<SetLogRequest> sets) {
    }

    public record SessionView(
            UUID id,
            LocalDate date,
            UUID workoutDayId,
            String notes,
            BigDecimal totalVolumeKg,
            List<SetView> sets) {

        static SessionView from(WorkoutSession session) {
            final List<SetView> sets = session.getSets().stream()
                    .sorted(Comparator.comparing((SetLog s) -> s.getExercise().getId())
                            .thenComparingInt(SetLog::getSetNumber))
                    .map(SetView::from)
                    .toList();

            // Volume = Σ (reps × carga). É a métrica que o dashboard plota e a que o usuário
            // compara entre semanas — calculada aqui para web e app nunca divergirem.
            final BigDecimal volume = sets.stream()
                    .map(s -> s.loadKg().multiply(BigDecimal.valueOf(s.reps()), MathContext.DECIMAL128))
                    .reduce(BigDecimal.ZERO, BigDecimal::add);

            return new SessionView(
                    session.getId(),
                    session.getDate(),
                    session.getWorkoutDay() == null ? null : session.getWorkoutDay().getId(),
                    session.getNotes(),
                    volume,
                    sets);
        }
    }

    public record SetView(
            UUID id,
            Integer exerciseId,
            String exerciseName,
            int setNumber,
            int reps,
            BigDecimal loadKg,
            Integer rpe) {

        static SetView from(SetLog set) {
            return new SetView(
                    set.getId(),
                    set.getExercise().getId(),
                    set.getExercise().getName(),
                    set.getSetNumber(),
                    set.getReps(),
                    set.getLoadKg(),
                    set.getRpe());
        }
    }
}
