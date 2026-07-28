package com.myotrack.domain.service;

import com.myotrack.domain.entity.FoodItem;
import com.myotrack.domain.service.DietGeneration.DietTotals;
import com.myotrack.domain.service.DietGeneration.GeneratedDiet;
import com.myotrack.domain.service.DietGeneration.GeneratedMeal;
import com.myotrack.domain.service.DietGeneration.GeneratedMealItem;
import java.math.BigDecimal;
import java.math.MathContext;
import java.math.RoundingMode;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.Optional;
import java.util.function.Function;
import java.util.stream.Collectors;

/**
 * Valida e ajusta o plano alimentar devolvido pelo LLM.
 *
 * <p><b>O modelo é tratado como entrada não confiável</b>, pelas mesmas razões do
 * {@link LlmWorkoutValidator} — e aqui há uma a mais: <b>restrição alimentar pode ser
 * alergia</b>. Um item que o usuário declarou evitar não pode entrar no plano por descuido do
 * modelo, mesmo que exista no catálogo.
 *
 * <p>A validação é tudo-ou-nada: reprovar devolve o controle a quem chamou, que fica com a
 * dieta montada pelo {@link DietRuleEngine} — já válida e dentro das metas.
 *
 * <p>Depois de aprovar, as quantidades são <b>reescaladas</b> para as calorias baterem com a
 * meta: o modelo escolhe bem os alimentos, mas erra a aritmética. Quem garante os números é o
 * código.
 */
public final class LlmDietValidator {

    private static final MathContext MC = MathContext.DECIMAL128;

    private static final BigDecimal MIN_QUANTITY_G = BigDecimal.TEN;
    private static final BigDecimal MAX_QUANTITY_G = BigDecimal.valueOf(500);
    private static final BigDecimal FIVE = BigDecimal.valueOf(5);

    /** Menos de 3 refeições concentra demais; mais de 6 vira lista de lanches. */
    private static final int MIN_MEALS = 3;
    private static final int MAX_MEALS = 6;

    /** Limites do reescalonamento: fora disso a proposta está longe demais para consertar. */
    private static final BigDecimal MIN_FACTOR = new BigDecimal("0.5");
    private static final BigDecimal MAX_FACTOR = new BigDecimal("2.0");

    /** Abaixo de 5% de diferença não vale mexer — só afastaria as quantidades dos números redondos. */
    private static final BigDecimal FACTOR_TOLERANCE = new BigDecimal("0.05");

    private LlmDietValidator() {
    }

    /** Dieta proposta pelo LLM, no formato do JSON Schema pedido a ele. */
    public record LlmDiet(List<LlmMeal> meals) {
    }

    public record LlmMeal(int order, String name, List<LlmMealItem> items) {
    }

    public record LlmMealItem(int foodItemId, BigDecimal quantityG) {
    }

    /**
     * Devolve a dieta validada e reescalada, ou vazio se a proposta violar qualquer regra.
     *
     * @param proposal o que o LLM respondeu
     * @param targets metas calculadas pelo {@link TdeeCalculator} — nunca pelo modelo
     * @param catalog catálogo completo de alimentos
     * @param restrictions restrições alimentares do perfil; casam por trecho do nome, como no
     *     {@link DietRuleEngine}
     */
    public static Optional<GeneratedDiet> validate(
            LlmDiet proposal,
            MacroTargets targets,
            List<FoodItem> catalog,
            List<String> restrictions) {

        if (proposal == null || proposal.meals() == null) {
            return Optional.empty();
        }
        if (proposal.meals().size() < MIN_MEALS || proposal.meals().size() > MAX_MEALS) {
            return Optional.empty();
        }

        final List<String> lowerRestrictions = restrictions == null
                ? List.of()
                : restrictions.stream().map(r -> r.toLowerCase(Locale.ROOT)).toList();

        final Map<Integer, FoodItem> byId = catalog.stream()
                .collect(Collectors.toMap(FoodItem::getId, Function.identity()));

        final List<GeneratedMeal> meals = new ArrayList<>();
        int order = 1;

        for (final LlmMeal meal : proposal.meals().stream()
                .sorted(Comparator.comparingInt(LlmMeal::order))
                .toList()) {

            if (meal.items() == null || meal.items().isEmpty()) {
                return Optional.empty();
            }

            final List<GeneratedMealItem> items = new ArrayList<>();
            for (final LlmMealItem item : meal.items()) {
                final FoodItem food = byId.get(item.foodItemId());
                if (food == null) {
                    return Optional.empty();
                }
                if (item.quantityG() == null
                        || item.quantityG().compareTo(MIN_QUANTITY_G) < 0
                        || item.quantityG().compareTo(MAX_QUANTITY_G) > 0) {
                    return Optional.empty();
                }
                // Restrição alimentar pode ser alergia: recusar a proposta inteira é a única
                // resposta segura, e o fallback por regras já respeita a mesma lista.
                if (violatesRestriction(food, lowerRestrictions)) {
                    return Optional.empty();
                }

                // O nome vem do catálogo, não do modelo — é o que o usuário vai comprar.
                items.add(new GeneratedMealItem(food.getId(), food.getName(), item.quantityG()));
            }

            meals.add(new GeneratedMeal(
                    order,
                    meal.name() == null || meal.name().isBlank()
                            ? "Refeição %d".formatted(order)
                            : meal.name(),
                    items));
            order++;
        }

        return Optional.of(adjustQuantities(new GeneratedDiet(meals), targets, byId));
    }

    /**
     * Escala as quantidades para aproximar as calorias da meta.
     *
     * <p>O LLM sugere; o código garante os números. Sem isto uma dieta bem montada poderia
     * entregar 1.400 kcal para quem precisa de 2.600.
     */
    static GeneratedDiet adjustQuantities(
            GeneratedDiet diet, MacroTargets targets, Map<Integer, FoodItem> foodsById) {

        final DietTotals totals = DietRuleEngine.totals(diet, foodsById);
        if (totals.kcal().signum() <= 0) {
            return diet;
        }

        final BigDecimal factor = targets.kcal()
                .divide(totals.kcal(), MC)
                .max(MIN_FACTOR)
                .min(MAX_FACTOR);

        if (factor.subtract(BigDecimal.ONE).abs().compareTo(FACTOR_TOLERANCE) < 0) {
            return diet;
        }

        final List<GeneratedMeal> meals = diet.meals().stream()
                .map(meal -> new GeneratedMeal(
                        meal.order(),
                        meal.name(),
                        meal.items().stream()
                                .map(item -> new GeneratedMealItem(
                                        item.foodItemId(),
                                        item.name(),
                                        scale(item.quantityG(), factor)))
                                .toList()))
                .toList();

        return new GeneratedDiet(meals);
    }

    /** Múltiplos de 5 g: "137 g de arroz" não é uma instrução que alguém siga na cozinha. */
    private static BigDecimal scale(BigDecimal quantityG, BigDecimal factor) {
        return quantityG.multiply(factor, MC)
                .divide(FIVE, MC)
                .setScale(0, RoundingMode.HALF_EVEN)
                .multiply(FIVE)
                .max(MIN_QUANTITY_G)
                .min(MAX_QUANTITY_G);
    }

    private static boolean violatesRestriction(FoodItem food, List<String> lowerRestrictions) {
        final String name = food.getName().toLowerCase(Locale.ROOT);
        return lowerRestrictions.stream().anyMatch(name::contains);
    }
}
