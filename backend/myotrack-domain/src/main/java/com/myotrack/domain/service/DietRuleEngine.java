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

/**
 * Montagem determinística de plano alimentar a partir do catálogo, usada como
 * fallback sem LLM e como base que o LLM apenas re-arranja (trocas por preferência).
 * Classifica alimentos pelo macro dominante e escala quantidades para bater as metas.
 *
 * <p>Porte de MyoTrack.Domain/Services/DietRuleEngine.cs.
 */
public final class DietRuleEngine {

    private static final MathContext MC = MathContext.DECIMAL128;

    private static final BigDecimal HUNDRED = BigDecimal.valueOf(100);
    private static final BigDecimal FIVE = BigDecimal.valueOf(5);
    private static final BigDecimal MIN_QUANTITY_G = BigDecimal.valueOf(10);
    private static final BigDecimal MAX_QUANTITY_G = BigDecimal.valueOf(500);

    private static final List<String> MEAL_NAMES =
            List.of("Café da manhã", "Almoço", "Lanche da tarde", "Jantar");

    /** Distribuição das metas por refeição: 20% / 35% / 15% / 30%. */
    private static final List<BigDecimal> SHARES = List.of(
            new BigDecimal("0.20"), new BigDecimal("0.35"), new BigDecimal("0.15"), new BigDecimal("0.30"));

    private DietRuleEngine() {
    }

    private static boolean isProteinSource(FoodItem f) {
        return f.getProteinPer100g().compareTo(BigDecimal.TEN) >= 0
                && f.getProteinPer100g().multiply(BigDecimal.valueOf(4), MC)
                        .compareTo(f.getKcalPer100g().multiply(new BigDecimal("0.4"), MC)) >= 0;
    }

    private static boolean isCarbSource(FoodItem f) {
        return f.getCarbsPer100g().compareTo(BigDecimal.valueOf(15)) >= 0
                && f.getFatPer100g().compareTo(BigDecimal.TEN) < 0
                && !isProteinSource(f);
    }

    private static boolean isFatSource(FoodItem f) {
        return f.getFatPer100g().compareTo(BigDecimal.valueOf(20)) >= 0;
    }

    private static boolean isVegetable(FoodItem f) {
        return f.getKcalPer100g().compareTo(BigDecimal.valueOf(40)) <= 0
                && f.getCarbsPer100g().compareTo(BigDecimal.TEN) < 0;
    }

    public static GeneratedDiet generate(MacroTargets targets, List<FoodItem> catalog, List<String> restrictions) {
        List<FoodItem> allowed = catalog.stream()
                .filter(f -> restrictions.stream().noneMatch(r -> containsIgnoreCase(f.getName(), r)))
                .toList();

        List<FoodItem> proteins = allowed.stream()
                .filter(DietRuleEngine::isProteinSource)
                .sorted(Comparator.comparing(FoodItem::getProteinPer100g).reversed())
                .toList();
        List<FoodItem> carbs = allowed.stream()
                .filter(DietRuleEngine::isCarbSource)
                .sorted(Comparator.comparing(FoodItem::getFatPer100g))
                .toList();
        List<FoodItem> fats = allowed.stream()
                .filter(DietRuleEngine::isFatSource)
                .sorted(Comparator.comparing(FoodItem::getFatPer100g).reversed())
                .toList();
        List<FoodItem> vegetables = allowed.stream().filter(DietRuleEngine::isVegetable).toList();

        if (proteins.isEmpty() || carbs.isEmpty()) {
            throw new IllegalStateException(
                    "Catálogo insuficiente para montar a dieta com as restrições informadas.");
        }

        List<GeneratedMeal> meals = new ArrayList<>();
        for (int i = 0; i < MEAL_NAMES.size(); i++) {
            List<GeneratedMealItem> items = new ArrayList<>();
            BigDecimal share = SHARES.get(i);

            FoodItem protein = proteins.get(i % proteins.size());
            FoodItem carb = carbs.get(i % carbs.size());
            FoodItem fat = fats.isEmpty() ? null : fats.get(i % fats.size());

            BigDecimal proteinQty = quantity(
                    targets.proteinG().multiply(share, MC), protein.getProteinPer100g());
            BigDecimal carbQty = quantity(
                    targets.carbsG().multiply(share, MC), carb.getCarbsPer100g());

            items.add(new GeneratedMealItem(protein.getId(), protein.getName(), proteinQty));
            items.add(new GeneratedMealItem(carb.getId(), carb.getName(), carbQty));

            // Gordura embutida nas fontes de proteína/carbo conta pouco aqui; a fonte
            // dedicada cobre ~60% da meta de gordura da refeição para não estourar kcal.
            if (fat != null) {
                BigDecimal fatQty = quantity(
                        targets.fatG().multiply(share, MC).multiply(new BigDecimal("0.6"), MC),
                        fat.getFatPer100g());
                items.add(new GeneratedMealItem(fat.getId(), fat.getName(), fatQty));
            }

            // Vegetais nas refeições principais.
            if (!vegetables.isEmpty() && (i == 1 || i == 3)) {
                FoodItem vegetable = vegetables.get(i % vegetables.size());
                items.add(new GeneratedMealItem(vegetable.getId(), vegetable.getName(), HUNDRED));
            }

            meals.add(new GeneratedMeal(i + 1, MEAL_NAMES.get(i), items));
        }

        return new GeneratedDiet(meals);
    }

    /** Gramas necessárias para atingir a meta do macro, em múltiplos de 5 g (mín. 10 g, máx. 500 g). */
    private static BigDecimal quantity(BigDecimal targetMacroG, BigDecimal macroPer100g) {
        if (macroPer100g.signum() <= 0) {
            return BigDecimal.ZERO;
        }
        BigDecimal grams = targetMacroG.divide(macroPer100g, MC).multiply(HUNDRED, MC);
        BigDecimal rounded = grams.divide(FIVE, MC).setScale(0, RoundingMode.HALF_EVEN).multiply(FIVE);
        return rounded.max(MIN_QUANTITY_G).min(MAX_QUANTITY_G);
    }

    public static DietTotals totals(GeneratedDiet diet, Map<Integer, FoodItem> foodsById) {
        BigDecimal kcal = BigDecimal.ZERO;
        BigDecimal protein = BigDecimal.ZERO;
        BigDecimal carbs = BigDecimal.ZERO;
        BigDecimal fat = BigDecimal.ZERO;

        for (GeneratedMeal meal : diet.meals()) {
            for (GeneratedMealItem item : meal.items()) {
                FoodItem food = foodsById.get(item.foodItemId());
                BigDecimal factor = item.quantityG().divide(HUNDRED, MC);
                kcal = kcal.add(food.getKcalPer100g().multiply(factor, MC), MC);
                protein = protein.add(food.getProteinPer100g().multiply(factor, MC), MC);
                carbs = carbs.add(food.getCarbsPer100g().multiply(factor, MC), MC);
                fat = fat.add(food.getFatPer100g().multiply(factor, MC), MC);
            }
        }

        return new DietTotals(round0(kcal), round0(protein), round0(carbs), round0(fat));
    }

    private static boolean containsIgnoreCase(String haystack, String needle) {
        return haystack.toLowerCase(Locale.ROOT).contains(needle.toLowerCase(Locale.ROOT));
    }

    private static BigDecimal round0(BigDecimal value) {
        return value.setScale(0, RoundingMode.HALF_EVEN);
    }
}
