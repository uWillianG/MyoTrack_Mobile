package com.myotrack.api.workout;

import com.myotrack.api.security.CurrentUser;
import com.myotrack.domain.AnalysisJobType;
import com.myotrack.domain.JobStatus;
import com.myotrack.domain.PlanStatus;
import com.myotrack.domain.entity.AnalysisJob;
import com.myotrack.domain.entity.WorkoutDay;
import com.myotrack.domain.entity.WorkoutExercise;
import com.myotrack.domain.entity.WorkoutPlan;
import com.myotrack.infrastructure.repository.AnalysisJobRepository;
import com.myotrack.infrastructure.repository.UserProfileRepository;
import com.myotrack.infrastructure.repository.WorkoutPlanRepository;
import java.time.OffsetDateTime;
import java.util.Comparator;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

/** Porte de MyoTrack.Api/Controllers/WorkoutPlansController.cs. */
@RestController
@RequestMapping("/api/workout-plans")
public class WorkoutPlansController {

    private final WorkoutPlanRepository plans;
    private final UserProfileRepository profiles;
    private final AnalysisJobRepository jobs;

    public WorkoutPlansController(
            WorkoutPlanRepository plans,
            UserProfileRepository profiles,
            AnalysisJobRepository jobs) {
        this.plans = plans;
        this.profiles = profiles;
        this.jobs = jobs;
    }

    /** Enfileira a geração; o cliente acompanha o job por {@code /api/jobs/&#123;id&#125;}. */
    @PostMapping("/generate")
    @Transactional
    public ResponseEntity<?> generate() {
        final UUID userId = CurrentUser.id();

        if (profiles.findByUserId(userId).isEmpty()) {
            return ResponseEntity.badRequest()
                    .body(Map.of("error", "Complete o onboarding antes de gerar o treino."));
        }

        // Sem esta trava, tocar duas vezes no botão gastaria duas chamadas de LLM e
        // produziria dois planos, o segundo arquivando o primeiro na hora.
        final boolean pending = jobs.findAll().stream().anyMatch(j ->
                j.getUserId().equals(userId)
                        && j.getType() == AnalysisJobType.WORKOUT_GENERATION
                        && (j.getStatus() == JobStatus.PENDING
                                || j.getStatus() == JobStatus.PROCESSING));
        if (pending) {
            return ResponseEntity.status(HttpStatus.CONFLICT)
                    .body(Map.of("error", "Já existe uma geração de treino em andamento."));
        }

        final AnalysisJob job = new AnalysisJob();
        job.setUserId(userId);
        job.setType(AnalysisJobType.WORKOUT_GENERATION);

        return ResponseEntity.accepted().body(Map.of("jobId", jobs.save(job).getId()));
    }

    /** Plano ativo com dias e exercícios. 404 quando ainda não há treino gerado. */
    @GetMapping("/active")
    @Transactional(readOnly = true)
    public ResponseEntity<PlanView> active() {
        return plans
                .findFirstByUserIdAndStatusOrderByCreatedAtDesc(CurrentUser.id(), PlanStatus.ACTIVE)
                .map(plan -> ResponseEntity.ok(PlanView.from(plan)))
                .orElseGet(() -> ResponseEntity.notFound().build());
    }

    /** Histórico enxuto — a tela lista as versões sem carregar os exercícios de cada uma. */
    @GetMapping
    @Transactional(readOnly = true)
    public List<PlanSummary> list() {
        return plans.findByUserIdOrderByCreatedAtDesc(CurrentUser.id()).stream()
                .sorted(Comparator.comparingInt(WorkoutPlan::getVersion).reversed())
                .map(PlanSummary::from)
                .toList();
    }

    public record PlanSummary(
            UUID id,
            String name,
            String split,
            String status,
            int version,
            OffsetDateTime createdAt) {

        static PlanSummary from(WorkoutPlan plan) {
            return new PlanSummary(
                    plan.getId(),
                    plan.getName(),
                    plan.getSplit(),
                    plan.getStatus().getWireName(),
                    plan.getVersion(),
                    plan.getCreatedAt());
        }
    }

    public record PlanView(
            UUID id,
            String name,
            String split,
            String goal,
            int version,
            OffsetDateTime createdAt,
            String reviewStatus,
            String reviewNote,
            OffsetDateTime reviewedAt,
            List<DayView> days) {

        static PlanView from(WorkoutPlan plan) {
            return new PlanView(
                    plan.getId(),
                    plan.getName(),
                    plan.getSplit(),
                    plan.getGoal().getWireName(),
                    plan.getVersion(),
                    plan.getCreatedAt(),
                    plan.getReviewStatus().getWireName(),
                    plan.getReviewNote(),
                    plan.getReviewedAt(),
                    plan.getDays().stream()
                            .sorted(Comparator.comparingInt(WorkoutDay::getOrder))
                            .map(DayView::from)
                            .toList());
        }
    }

    public record DayView(UUID id, int order, String label, List<ExerciseView> exercises) {

        static DayView from(WorkoutDay day) {
            return new DayView(
                    day.getId(),
                    day.getOrder(),
                    day.getLabel(),
                    day.getExercises().stream()
                            .sorted(Comparator.comparingInt(WorkoutExercise::getOrder))
                            .map(ExerciseView::from)
                            .toList());
        }
    }

    public record ExerciseView(
            UUID id,
            Integer exerciseId,
            String exerciseName,
            String muscleGroup,
            String tutorialVideoUrl,
            int sets,
            int repsMin,
            int repsMax,
            int restSeconds,
            String notes) {

        static ExerciseView from(WorkoutExercise item) {
            return new ExerciseView(
                    item.getId(),
                    item.getExerciseId(),
                    item.getExercise().getName(),
                    item.getExercise().getPrimaryMuscleGroup().getWireName(),
                    item.getExercise().getTutorialVideoUrl(),
                    item.getSets(),
                    item.getRepsMin(),
                    item.getRepsMax(),
                    item.getRestSeconds(),
                    item.getNotes());
        }
    }
}
