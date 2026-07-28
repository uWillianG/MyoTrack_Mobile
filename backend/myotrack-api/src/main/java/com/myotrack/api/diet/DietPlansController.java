package com.myotrack.api.diet;

import com.myotrack.api.security.CurrentUser;
import com.myotrack.domain.AnalysisJobType;
import com.myotrack.domain.JobStatus;
import com.myotrack.domain.PlanStatus;
import com.myotrack.domain.entity.AnalysisJob;
import com.myotrack.domain.entity.DietPlan;
import com.myotrack.domain.entity.FoodItem;
import com.myotrack.domain.entity.Meal;
import com.myotrack.domain.entity.MealItem;
import com.myotrack.infrastructure.repository.AnalysisJobRepository;
import com.myotrack.infrastructure.repository.BodyMeasurementRepository;
import com.myotrack.infrastructure.repository.DietPlanRepository;
import com.myotrack.infrastructure.repository.UserProfileRepository;
import java.math.BigDecimal;
import java.math.MathContext;
import java.math.RoundingMode;
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

/** Porte de MyoTrack.Api/Controllers/DietPlansController.cs. */
@RestController
@RequestMapping("/api/diet-plans")
public class DietPlansController {

    private final DietPlanRepository plans;
    private final UserProfileRepository profiles;
    private final BodyMeasurementRepository measurements;
    private final AnalysisJobRepository jobs;

    public DietPlansController(
            DietPlanRepository plans,
            UserProfileRepository profiles,
            BodyMeasurementRepository measurements,
            AnalysisJobRepository jobs) {
        this.plans = plans;
        this.profiles = profiles;
        this.measurements = measurements;
        this.jobs = jobs;
    }

    /**
     * Enfileira a geração; o cliente acompanha por {@code /api/jobs/&#123;id&#125;}.
     *
     * <p>As pré-condições são checadas aqui, e não só no worker, para o usuário receber um
     * "falta registrar seu peso" na hora — e não um job que falha um minuto depois.
     */
    @PostMapping("/generate")
    @Transactional
    public ResponseEntity<?> generate() {
        final UUID userId = CurrentUser.id();

        final var profile = profiles.findByUserId(userId).orElse(null);
        if (profile == null) {
            return ResponseEntity.badRequest()
                    .body(Map.of("error", "Complete o onboarding antes de gerar a dieta."));
        }
        if (profile.getBirthDate() == null
                || profile.getSex() == null
                || profile.getHeightCm() == null) {
            return ResponseEntity.badRequest().body(Map.of(
                    "error", "Perfil incompleto: informe data de nascimento, sexo e altura."));
        }

        // A meta calórica vem do peso atual; sem ele não há o que calcular.
        final boolean hasWeight = measurements.findByUserIdOrderByDateDesc(userId).stream()
                .anyMatch(m -> m.getWeightKg() != null);
        if (!hasWeight) {
            return ResponseEntity.badRequest()
                    .body(Map.of("error", "Registre seu peso corporal antes de gerar a dieta."));
        }

        // Sem esta trava, tocar duas vezes no botão gastaria duas chamadas de LLM e
        // produziria dois planos, o segundo arquivando o primeiro na hora.
        final boolean pending = jobs.findAll().stream().anyMatch(j ->
                j.getUserId().equals(userId)
                        && j.getType() == AnalysisJobType.DIET_GENERATION
                        && (j.getStatus() == JobStatus.PENDING
                                || j.getStatus() == JobStatus.PROCESSING));
        if (pending) {
            return ResponseEntity.status(HttpStatus.CONFLICT)
                    .body(Map.of("error", "Já existe uma geração de dieta em andamento."));
        }

        final AnalysisJob job = new AnalysisJob();
        job.setUserId(userId);
        job.setType(AnalysisJobType.DIET_GENERATION);

        return ResponseEntity.accepted().body(Map.of("jobId", jobs.save(job).getId()));
    }

    /** Dieta ativa com refeições, itens e totais. 404 quando ainda não há dieta gerada. */
    @GetMapping("/active")
    @Transactional(readOnly = true)
    public ResponseEntity<PlanView> active() {
        return plans
                .findFirstByUserIdAndStatusOrderByCreatedAtDesc(CurrentUser.id(), PlanStatus.ACTIVE)
                .map(plan -> ResponseEntity.ok(PlanView.from(plan)))
                .orElseGet(() -> ResponseEntity.notFound().build());
    }

    /** Histórico enxuto — a tela lista as versões sem carregar as refeições de cada uma. */
    @GetMapping
    @Transactional(readOnly = true)
    public List<PlanSummary> list() {
        return plans.findByUserIdOrderByCreatedAtDesc(CurrentUser.id()).stream()
                .sorted(Comparator.comparingInt(DietPlan::getVersion).reversed())
                .map(PlanSummary::from)
                .toList();
    }

    public record PlanSummary(
            UUID id,
            String name,
            String calorieGoal,
            String status,
            int version,
            BigDecimal targetKcal,
            OffsetDateTime createdAt) {

        static PlanSummary from(DietPlan plan) {
            return new PlanSummary(
                    plan.getId(),
                    plan.getName(),
                    plan.getCalorieGoal().getWireName(),
                    plan.getStatus().getWireName(),
                    plan.getVersion(),
                    plan.getTargetKcal(),
                    plan.getCreatedAt());
        }
    }

    public record PlanView(
            UUID id,
            String name,
            String calorieGoal,
            int version,
            OffsetDateTime createdAt,
            String reviewStatus,
            String reviewNote,
            OffsetDateTime reviewedAt,
            Macros targets,
            Macros totals,
            List<MealView> meals) {

        static PlanView from(DietPlan plan) {
            final List<MealView> meals = plan.getMeals().stream()
                    .sorted(Comparator.comparingInt(Meal::getOrder))
                    .map(MealView::from)
                    .toList();

            return new PlanView(
                    plan.getId(),
                    plan.getName(),
                    plan.getCalorieGoal().getWireName(),
                    plan.getVersion(),
                    plan.getCreatedAt(),
                    plan.getReviewStatus().getWireName(),
                    plan.getReviewNote(),
                    plan.getReviewedAt(),
                    new Macros(
                            plan.getTargetKcal(),
                            plan.getTargetProteinG(),
                            plan.getTargetCarbsG(),
                            plan.getTargetFatG()),
                    // Somar os itens já arredondados, e não recalcular do zero, mantém o total
                    // igual à conta que o usuário faz olhando a tela.
                    sumOf(meals),
                    meals);
        }

        private static Macros sumOf(List<MealView> meals) {
            BigDecimal kcal = BigDecimal.ZERO;
            BigDecimal protein = BigDecimal.ZERO;
            BigDecimal carbs = BigDecimal.ZERO;
            BigDecimal fat = BigDecimal.ZERO;

            for (final MealView meal : meals) {
                for (final ItemView item : meal.items()) {
                    kcal = kcal.add(item.kcal());
                    protein = protein.add(item.proteinG());
                    carbs = carbs.add(item.carbsG());
                    fat = fat.add(item.fatG());
                }
            }
            return new Macros(kcal, protein, carbs, fat);
        }
    }

    public record Macros(BigDecimal kcal, BigDecimal proteinG, BigDecimal carbsG, BigDecimal fatG) {
    }

    public record MealView(UUID id, int order, String name, List<ItemView> items) {

        static MealView from(Meal meal) {
            return new MealView(
                    meal.getId(),
                    meal.getOrder(),
                    meal.getName(),
                    meal.getItems().stream().map(ItemView::from).toList());
        }
    }

    public record ItemView(
            UUID id,
            Integer foodItemId,
            String foodName,
            BigDecimal quantityG,
            BigDecimal kcal,
            BigDecimal proteinG,
            BigDecimal carbsG,
            BigDecimal fatG) {

        private static final MathContext MC = MathContext.DECIMAL128;
        private static final BigDecimal HUNDRED = BigDecimal.valueOf(100);

        static ItemView from(MealItem item) {
            final FoodItem food = item.getFoodItem();
            final BigDecimal factor = item.getQuantityG().divide(HUNDRED, MC);

            return new ItemView(
                    item.getId(),
                    food.getId(),
                    food.getName(),
                    item.getQuantityG(),
                    // Caloria inteira; macros com uma casa. Espelha o DTO do .NET, e é o que
                    // a SPA já mostra — divergir aqui faria o mesmo plano exibir números
                    // diferentes na web e no app.
                    scale(food.getKcalPer100g(), factor, 0),
                    scale(food.getProteinPer100g(), factor, 1),
                    scale(food.getCarbsPer100g(), factor, 1),
                    scale(food.getFatPer100g(), factor, 1));
        }

        private static BigDecimal scale(BigDecimal per100g, BigDecimal factor, int decimals) {
            return per100g.multiply(factor, MC).setScale(decimals, RoundingMode.HALF_EVEN);
        }
    }
}
