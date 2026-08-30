package com.myotrack.worker.handlers;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.myotrack.domain.AnalysisJobType;
import com.myotrack.domain.CalorieGoal;
import com.myotrack.domain.FitnessGoal;
import com.myotrack.domain.PlanStatus;
import com.myotrack.domain.entity.AnalysisJob;
import com.myotrack.domain.entity.BodyMeasurement;
import com.myotrack.domain.entity.DietPlan;
import com.myotrack.domain.entity.FoodItem;
import com.myotrack.domain.entity.Meal;
import com.myotrack.domain.entity.MealItem;
import com.myotrack.domain.entity.UserProfile;
import com.myotrack.domain.service.DietGeneration.GeneratedDiet;
import com.myotrack.domain.service.DietRuleEngine;
import com.myotrack.domain.service.LlmDietValidator;
import com.myotrack.domain.service.LlmDietValidator.LlmDiet;
import com.myotrack.domain.service.MacroTargets;
import com.myotrack.domain.service.TdeeCalculator;
import com.myotrack.infrastructure.ai.AiUsageRecorder;
import com.myotrack.infrastructure.ai.LlmJsonClient;
import com.myotrack.infrastructure.ai.LlmJsonClient.LlmJsonResult;
import com.myotrack.infrastructure.repository.BodyMeasurementRepository;
import com.myotrack.infrastructure.repository.DietPlanRepository;
import com.myotrack.infrastructure.repository.FoodItemRepository;
import com.myotrack.infrastructure.repository.UserProfileRepository;
import com.myotrack.worker.JobHandler;
import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.Comparator;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.UUID;
import java.util.function.Function;
import java.util.stream.Collectors;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

/**
 * Gera o plano alimentar. Porte de MyoTrack.Infrastructure/Ai/DietGenerationService.cs.
 *
 * <p>A divisão de responsabilidades é o ponto central e não deve ser afrouxada:
 *
 * <ul>
 *   <li><b>TDEE e macros são calculados em código</b> ({@link TdeeCalculator}), nunca pelo LLM.
 *       São números que dizem quanto uma pessoa vai comer todo dia — não podem depender do que
 *       um modelo estimou.</li>
 *   <li>O LLM só <b>escolhe e combina</b> alimentos do catálogo, respeitando restrições e
 *       preferências.</li>
 *   <li>O {@link LlmDietValidator} confere a resposta e <b>reescala as quantidades</b> para as
 *       calorias baterem com a meta.</li>
 * </ul>
 *
 * <p>Sem LLM, ou com resposta inválida, fica a dieta do {@link DietRuleEngine}.
 */
@Component
public class DietGenerationHandler implements JobHandler {

    private static final Logger log = LoggerFactory.getLogger(DietGenerationHandler.class);

    private static final ObjectMapper MAPPER = new ObjectMapper();

    private final UserProfileRepository profiles;
    private final BodyMeasurementRepository measurements;
    private final FoodItemRepository foods;
    private final DietPlanRepository plans;
    private final AiUsageRecorder aiUsage;
    private final LlmJsonClient llm;

    public DietGenerationHandler(
            UserProfileRepository profiles,
            BodyMeasurementRepository measurements,
            FoodItemRepository foods,
            DietPlanRepository plans,
            AiUsageRecorder aiUsage,
            LlmJsonClient llm) {
        this.profiles = profiles;
        this.measurements = measurements;
        this.foods = foods;
        this.plans = plans;
        this.aiUsage = aiUsage;
        this.llm = llm;
    }

    @Override
    public AnalysisJobType type() {
        return AnalysisJobType.DIET_GENERATION;
    }

    @Override
    @Transactional
    public String handle(AnalysisJob job) {
        final UUID userId = job.getUserId();

        // IllegalStateException = erro de negócio: o poller falha o job sem reprocessar,
        // porque tentar de novo daria exatamente o mesmo resultado.
        final UserProfile profile = profiles.findByUserId(userId).orElseThrow(
                () -> new IllegalStateException(
                        "Perfil não encontrado. Complete o onboarding antes de gerar a dieta."));

        if (profile.getBirthDate() == null
                || profile.getSex() == null
                || profile.getHeightCm() == null) {
            throw new IllegalStateException(
                    "Perfil incompleto: data de nascimento, sexo e altura são necessários "
                            + "para calcular as metas.");
        }

        final BigDecimal weightKg = latestWeight(userId).orElseThrow(
                () -> new IllegalStateException(
                        "Registre seu peso corporal antes de gerar a dieta."));

        final CalorieGoal calorieGoal = calorieGoalFor(profile.getGoal());
        final int age = TdeeCalculator.calculateAge(profile.getBirthDate(), LocalDate.now());
        final MacroTargets targets = TdeeCalculator.calculateTargets(
                profile.getSex(),
                weightKg,
                profile.getHeightCm(),
                age,
                profile.getTrainingDaysPerWeek(),
                calorieGoal);

        // Não é o catálogo inteiro: o do diário inclui açúcar, refrigerante, coxinha e whey em
        // pó, porque é o que a pessoa come. O motor escolhe pelo macro dominante, e para ele
        // esses são os melhores candidatos que existem — nada tem mais carboidrato por grama que
        // açúcar refinado. Ver FoodItem.usableInDiet.
        final List<FoodItem> catalog = foods.findByUsableInDietTrue();
        final List<String> restrictions = List.of(profile.getDietaryRestrictions());

        GeneratedDiet diet = DietRuleEngine.generate(targets, catalog, restrictions);
        String rawLlmOutput = null;

        if (llm.isConfigured()) {
            final LlmJsonResult result = assemble(profile, targets, catalog);
            if (result != null) {
                rawLlmOutput = result.json();
                recordUsage(userId, result);

                final Optional<GeneratedDiet> refined =
                        parseAndValidate(rawLlmOutput, targets, catalog, restrictions);
                if (refined.isPresent()) {
                    diet = refined.get();
                } else {
                    log.warn("Saída do LLM inválida para o usuário {}; usando a dieta por regras.",
                            userId);
                }
            }
        }

        final DietPlan entity =
                persist(userId, calorieGoal, targets, diet, catalog, rawLlmOutput);

        return "{\"dietPlanId\":\"%s\"}".formatted(entity.getId());
    }

    /** Peso mais recente registrado. É ele — não o do onboarding — que dita as metas. */
    private Optional<BigDecimal> latestWeight(UUID userId) {
        return measurements.findByUserIdOrderByDateDesc(userId).stream()
                .filter(m -> m.getWeightKg() != null)
                .max(Comparator.comparing(BodyMeasurement::getDate))
                .map(BodyMeasurement::getWeightKg);
    }

    private static CalorieGoal calorieGoalFor(FitnessGoal goal) {
        return switch (goal) {
            case WEIGHT_LOSS -> CalorieGoal.DEFICIT;
            case HYPERTROPHY -> CalorieGoal.SURPLUS;
            default -> CalorieGoal.MAINTENANCE;
        };
    }

    private DietPlan persist(
            UUID userId,
            CalorieGoal calorieGoal,
            MacroTargets targets,
            GeneratedDiet diet,
            List<FoodItem> catalog,
            String rawLlmOutput) {

        // Só pode haver uma dieta ativa por usuário: é ela que o diário compara com o consumo.
        final List<DietPlan> previous = plans.findByUserIdOrderByCreatedAtDesc(userId).stream()
                .filter(p -> p.getStatus() == PlanStatus.ACTIVE)
                .toList();
        previous.forEach(p -> p.setStatus(PlanStatus.ARCHIVED));
        plans.saveAll(previous);

        final int version = plans.findByUserIdOrderByCreatedAtDesc(userId).size() + 1;

        final DietPlan entity = new DietPlan();
        entity.setUserId(userId);
        entity.setName("Dieta v%d".formatted(version));
        entity.setCalorieGoal(calorieGoal);
        entity.setStatus(PlanStatus.ACTIVE);
        entity.setVersion(version);
        entity.setTargetKcal(targets.kcal());
        entity.setTargetProteinG(targets.proteinG());
        entity.setTargetCarbsG(targets.carbsG());
        entity.setTargetFatG(targets.fatG());
        entity.setGenerationInputJson(toJson(Map.of(
                "targets", targets,
                "calorieGoal", calorieGoal.getWireName())));
        entity.setRawLlmOutputJson(rawLlmOutput);

        final Map<Integer, FoodItem> byId = catalog.stream()
                .collect(Collectors.toMap(FoodItem::getId, Function.identity()));

        for (final var meal : diet.meals()) {
            final Meal mealEntity = new Meal();
            mealEntity.setOrder(meal.order());
            mealEntity.setName(meal.name());

            for (final var item : meal.items()) {
                final MealItem itemEntity = new MealItem();
                itemEntity.setFoodItem(byId.get(item.foodItemId()));
                itemEntity.setQuantityG(item.quantityG());
                mealEntity.addItem(itemEntity);
            }
            entity.addMeal(mealEntity);
        }

        return plans.save(entity);
    }

    private LlmJsonResult assemble(
            UserProfile profile, MacroTargets targets, List<FoodItem> catalog) {

        // Prompt copiado literalmente do backend .NET: mudá-lo muda o comportamento da IA em
        // produção, e o texto foi ajustado contra saídas reais.
        final String system = """
                Você é um nutricionista. Monte um plano alimentar de um dia com 4 a 6 refeições usando
                SOMENTE alimentos da lista fornecida (foodItemId). Respeite restrições e preferências do usuário.
                Aproxime-se das metas de calorias e macros; quantidades em gramas entre 10 e 500.
                Nomes de refeições em português (ex.: "Café da manhã", "Almoço").
                """;

        final Map<String, Object> metas = new LinkedHashMap<>();
        metas.put("kcal", targets.kcal());
        metas.put("proteinaG", targets.proteinG());
        metas.put("carboidratoG", targets.carbsG());
        metas.put("gorduraG", targets.fatG());

        final Map<String, Object> user = new LinkedHashMap<>();
        user.put("metas", metas);
        user.put("restricoes", profile.getDietaryRestrictions());
        user.put("preferencias", profile.getFoodPreferences());
        user.put("alimentos", catalog.stream().map(f -> {
            final Map<String, Object> item = new LinkedHashMap<>();
            item.put("foodItemId", f.getId());
            item.put("nome", f.getName());
            item.put("kcal100g", f.getKcalPer100g());
            item.put("proteina100g", f.getProteinPer100g());
            item.put("carbo100g", f.getCarbsPer100g());
            item.put("gordura100g", f.getFatPer100g());
            return item;
        }).toList());

        return llm.generateJson(system, toJson(user), dietSchema());
    }

    private Optional<GeneratedDiet> parseAndValidate(
            String json, MacroTargets targets, List<FoodItem> catalog, List<String> restrictions) {
        try {
            final LlmDiet proposal = MAPPER.readValue(json, LlmDiet.class);
            return LlmDietValidator.validate(proposal, targets, catalog, restrictions);
        } catch (Exception e) {
            // JSON malformado é o mesmo caso de conteúdo inválido: fica a dieta por regras.
            log.warn("Resposta do LLM não pôde ser lida: {}", e.getMessage());
            return Optional.empty();
        }
    }

    private void recordUsage(UUID userId, LlmJsonResult result) {
        aiUsage.record(userId, AnalysisJobType.DIET_GENERATION, llm, result);
    }

    private static String toJson(Object value) {
        try {
            return MAPPER.writeValueAsString(value);
        } catch (Exception e) {
            throw new IllegalStateException("Falha ao serializar o payload da geração.", e);
        }
    }

    /** JSON Schema da resposta, copiado do .NET. */
    private static Map<String, Object> dietSchema() {
        final String schema = """
                {
                  "type": "object",
                  "properties": {
                    "meals": {
                      "type": "array",
                      "items": {
                        "type": "object",
                        "properties": {
                          "order": { "type": "integer" },
                          "name": { "type": "string" },
                          "items": {
                            "type": "array",
                            "items": {
                              "type": "object",
                              "properties": {
                                "foodItemId": { "type": "integer" },
                                "quantityG": { "type": "number" }
                              },
                              "required": ["foodItemId", "quantityG"],
                              "additionalProperties": false
                            }
                          }
                        },
                        "required": ["order", "name", "items"],
                        "additionalProperties": false
                      }
                    }
                  },
                  "required": ["meals"],
                  "additionalProperties": false
                }
                """;
        try {
            @SuppressWarnings("unchecked")
            final Map<String, Object> parsed = MAPPER.readValue(schema, Map.class);
            return parsed;
        } catch (Exception e) {
            throw new IllegalStateException("Schema da dieta inválido.", e);
        }
    }
}
