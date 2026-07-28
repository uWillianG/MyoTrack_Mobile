package com.myotrack.api.reviews;

import com.myotrack.api.security.CurrentUser;
import com.myotrack.domain.PlanStatus;
import com.myotrack.domain.ReviewStatus;
import com.myotrack.domain.entity.DietPlan;
import com.myotrack.domain.entity.Meal;
import com.myotrack.domain.entity.WorkoutDay;
import com.myotrack.domain.entity.WorkoutExercise;
import com.myotrack.domain.entity.WorkoutPlan;
import com.myotrack.infrastructure.repository.ApplicationUserRepository;
import com.myotrack.infrastructure.repository.DietPlanRepository;
import com.myotrack.infrastructure.repository.WorkoutPlanRepository;
import java.math.BigDecimal;
import java.time.OffsetDateTime;
import java.util.Comparator;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

/**
 * Fila de supervisão humana. Porte de MyoTrack.Api/Controllers/ReviewsController.cs.
 *
 * <p>Treinador revisa treino, nutricionista revisa dieta, e o admin revisa os dois. A
 * separação não é burocracia: quem aprova um plano alimentar assume responsabilidade
 * profissional por ele, e não é o mesmo conselho que responde por prescrição de treino.
 *
 * <p>Este é o único controller do app que não é do próprio dono do dado — por isso todo
 * endpoint carrega {@code @PreAuthorize}. Sem ele, qualquer aluno autenticado leria o plano
 * de todo mundo.
 */
@RestController
@RequestMapping("/api/reviews")
public class ReviewsController {

    private static final String WORKOUT_REVIEWERS =
            "hasAnyRole('Trainer', 'Admin')";
    private static final String DIET_REVIEWERS =
            "hasAnyRole('Nutritionist', 'Admin')";

    /** Teto da fila. Revisar cinquenta planos já é mais do que cabe num dia. */
    private static final int QUEUE_LIMIT = 50;

    private final WorkoutPlanRepository workoutPlans;
    private final DietPlanRepository dietPlans;
    private final ApplicationUserRepository users;

    public ReviewsController(
            WorkoutPlanRepository workoutPlans,
            DietPlanRepository dietPlans,
            ApplicationUserRepository users) {
        this.workoutPlans = workoutPlans;
        this.dietPlans = dietPlans;
        this.users = users;
    }

    // ---------------------------------------------------------------- treino

    /** Treinos ativos ainda não revisados, dos mais antigos para os mais novos. */
    @GetMapping("/workout-plans")
    @PreAuthorize(WORKOUT_REVIEWERS)
    @Transactional(readOnly = true)
    public List<WorkoutQueueItem> pendingWorkouts() {
        return workoutPlans.findAll().stream()
                .filter(ReviewsController::awaitingReview)
                .sorted(Comparator.comparing(WorkoutPlan::getCreatedAt))
                .limit(QUEUE_LIMIT)
                .map(plan -> new WorkoutQueueItem(
                        plan.getId(),
                        plan.getName(),
                        plan.getSplit(),
                        plan.getGoal() == null ? null : plan.getGoal().getWireName(),
                        plan.getVersion(),
                        plan.getCreatedAt(),
                        studentOf(plan.getUserId())))
                .toList();
    }

    @GetMapping("/workout-plans/{id}")
    @PreAuthorize(WORKOUT_REVIEWERS)
    @Transactional(readOnly = true)
    public ResponseEntity<WorkoutDetail> workout(@PathVariable UUID id) {
        return workoutPlans.findById(id)
                .map(plan -> ResponseEntity.ok(new WorkoutDetail(
                        plan.getId(),
                        plan.getName(),
                        plan.getSplit(),
                        plan.getGoal() == null ? null : plan.getGoal().getWireName(),
                        plan.getVersion(),
                        plan.getCreatedAt(),
                        plan.getReviewStatus().getWireName(),
                        plan.getReviewNote(),
                        studentOf(plan.getUserId()),
                        plan.getDays().stream()
                                .sorted(Comparator.comparingInt(WorkoutDay::getOrder))
                                .map(ReviewsController::dayOf)
                                .toList())))
                .orElseGet(() -> ResponseEntity.notFound().build());
    }

    @PostMapping("/workout-plans/{id}")
    @PreAuthorize(WORKOUT_REVIEWERS)
    @Transactional
    public ResponseEntity<?> reviewWorkout(
            @PathVariable UUID id, @RequestBody Decision decision) {

        final ReviewStatus status = decisionOf(decision);
        if (status == null) {
            return ResponseEntity.badRequest().body(Map.of("error", "Decisão inválida."));
        }

        return workoutPlans.findById(id)
                .map(plan -> {
                    plan.setReviewStatus(status);
                    plan.setReviewNote(decision.note());
                    plan.setReviewedByUserId(CurrentUser.id());
                    plan.setReviewedAt(OffsetDateTime.now());
                    workoutPlans.save(plan);
                    return ResponseEntity.noContent().build();
                })
                .orElseGet(() -> ResponseEntity.notFound().build());
    }

    // ----------------------------------------------------------------- dieta

    @GetMapping("/diet-plans")
    @PreAuthorize(DIET_REVIEWERS)
    @Transactional(readOnly = true)
    public List<DietQueueItem> pendingDiets() {
        return dietPlans.findAll().stream()
                .filter(ReviewsController::awaitingDietReview)
                .sorted(Comparator.comparing(DietPlan::getCreatedAt))
                .limit(QUEUE_LIMIT)
                .map(plan -> new DietQueueItem(
                        plan.getId(),
                        plan.getName(),
                        plan.getCalorieGoal() == null
                                ? null : plan.getCalorieGoal().getWireName(),
                        plan.getVersion(),
                        plan.getCreatedAt(),
                        plan.getTargetKcal(),
                        studentOf(plan.getUserId())))
                .toList();
    }

    @GetMapping("/diet-plans/{id}")
    @PreAuthorize(DIET_REVIEWERS)
    @Transactional(readOnly = true)
    public ResponseEntity<DietDetail> diet(@PathVariable UUID id) {
        return dietPlans.findById(id)
                .map(plan -> ResponseEntity.ok(new DietDetail(
                        plan.getId(),
                        plan.getName(),
                        plan.getCalorieGoal() == null
                                ? null : plan.getCalorieGoal().getWireName(),
                        plan.getVersion(),
                        plan.getCreatedAt(),
                        plan.getReviewStatus().getWireName(),
                        plan.getReviewNote(),
                        studentOf(plan.getUserId()),
                        plan.getTargetKcal(),
                        plan.getTargetProteinG(),
                        plan.getTargetCarbsG(),
                        plan.getTargetFatG(),
                        plan.getMeals().stream()
                                .sorted(Comparator.comparingInt(Meal::getOrder))
                                .map(ReviewsController::mealOf)
                                .toList())))
                .orElseGet(() -> ResponseEntity.notFound().build());
    }

    @PostMapping("/diet-plans/{id}")
    @PreAuthorize(DIET_REVIEWERS)
    @Transactional
    public ResponseEntity<?> reviewDiet(
            @PathVariable UUID id, @RequestBody Decision decision) {

        final ReviewStatus status = decisionOf(decision);
        if (status == null) {
            return ResponseEntity.badRequest().body(Map.of("error", "Decisão inválida."));
        }

        return dietPlans.findById(id)
                .map(plan -> {
                    plan.setReviewStatus(status);
                    plan.setReviewNote(decision.note());
                    plan.setReviewedByUserId(CurrentUser.id());
                    plan.setReviewedAt(OffsetDateTime.now());
                    dietPlans.save(plan);
                    return ResponseEntity.noContent().build();
                })
                .orElseGet(() -> ResponseEntity.notFound().build());
    }

    // ----------------------------------------------------------------- apoio

    /**
     * A decisão pedida, ou null quando não serve.
     *
     * <p>{@code NotReviewed} é recusado: é o estado inicial, não uma decisão. Aceitá-lo
     * deixaria o revisor "desrevisar" um plano sem deixar rastro do porquê.
     */
    private static ReviewStatus decisionOf(Decision decision) {
        if (decision == null || decision.status() == null) {
            return null;
        }
        final ReviewStatus status = ReviewStatus.fromWireName(decision.status());
        return status == ReviewStatus.NOT_REVIEWED ? null : status;
    }

    private static boolean awaitingReview(WorkoutPlan plan) {
        return plan.getStatus() == PlanStatus.ACTIVE
                && plan.getReviewStatus() == ReviewStatus.NOT_REVIEWED;
    }

    private static boolean awaitingDietReview(DietPlan plan) {
        return plan.getStatus() == PlanStatus.ACTIVE
                && plan.getReviewStatus() == ReviewStatus.NOT_REVIEWED;
    }

    /**
     * O e-mail do aluno identifica de quem é o plano na fila.
     *
     * <p>É o único dado pessoal que aparece aqui, e aparece porque o revisor precisa saber a
     * quem está respondendo — sem ele a fila seria uma lista de planos anônimos.
     */
    private String studentOf(UUID userId) {
        return users.findById(userId).map(u -> u.getEmail()).orElse(null);
    }

    private static DayView dayOf(WorkoutDay day) {
        return new DayView(
                day.getOrder(),
                day.getLabel(),
                day.getExercises().stream()
                        .sorted(Comparator.comparingInt(WorkoutExercise::getOrder))
                        .map(e -> new ExerciseView(
                                e.getExercise() == null ? "" : e.getExercise().getName(),
                                e.getSets(),
                                e.getRepsMin(),
                                e.getRepsMax(),
                                e.getRestSeconds(),
                                e.getNotes()))
                        .toList());
    }

    private static MealView mealOf(Meal meal) {
        return new MealView(
                meal.getOrder(),
                meal.getName(),
                meal.getItems().stream()
                        .map(item -> new MealItemView(
                                item.getFoodItem() == null ? "" : item.getFoodItem().getName(),
                                item.getQuantityG()))
                        .toList());
    }

    public record Decision(String status, String note) {
    }

    public record WorkoutQueueItem(
            UUID id, String name, String split, String goal, int version,
            OffsetDateTime createdAt, String student) {
    }

    public record ExerciseView(
            String exerciseName, int sets, int repsMin, int repsMax, int restSeconds,
            String notes) {
    }

    public record DayView(int order, String label, List<ExerciseView> exercises) {
    }

    public record WorkoutDetail(
            UUID id, String name, String split, String goal, int version,
            OffsetDateTime createdAt, String reviewStatus, String reviewNote, String student,
            List<DayView> days) {
    }

    public record DietQueueItem(
            UUID id, String name, String calorieGoal, int version,
            OffsetDateTime createdAt, BigDecimal targetKcal, String student) {
    }

    public record MealItemView(String foodName, BigDecimal quantityG) {
    }

    public record MealView(int order, String name, List<MealItemView> items) {
    }

    public record DietDetail(
            UUID id, String name, String calorieGoal, int version,
            OffsetDateTime createdAt, String reviewStatus, String reviewNote, String student,
            BigDecimal targetKcal, BigDecimal targetProteinG, BigDecimal targetCarbsG,
            BigDecimal targetFatG, List<MealView> meals) {
    }
}
