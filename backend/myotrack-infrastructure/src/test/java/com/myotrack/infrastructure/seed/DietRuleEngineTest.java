package com.myotrack.infrastructure.seed;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import com.myotrack.domain.entity.FoodItem;
import com.myotrack.domain.service.DietGeneration.DietTotals;
import com.myotrack.domain.service.DietGeneration.GeneratedDiet;
import com.myotrack.domain.service.DietGeneration.GeneratedMealItem;
import com.myotrack.domain.service.DietRuleEngine;
import com.myotrack.domain.service.MacroTargets;
import java.math.BigDecimal;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.function.Function;
import java.util.stream.Collectors;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

/** Porte de MyoTrack.Tests/DietRuleEngineTests.cs. */
class DietRuleEngineTest {

    private static final MacroTargets TARGETS = new MacroTargets(
            new BigDecimal("2500"), new BigDecimal("160"), new BigDecimal("300"), new BigDecimal("70"));

    private static List<FoodItem> catalog() {
        List<FoodItem> items = FoodSeed.items();
        for (int i = 0; i < items.size(); i++) {
            items.get(i).setId(i + 1);
        }
        return items;
    }

    private static List<String> itemNames(GeneratedDiet diet) {
        return diet.meals().stream()
                .flatMap(m -> m.items().stream())
                .map(GeneratedMealItem::name)
                .toList();
    }

    @Test
    void generates4MealsWithItems() {
        GeneratedDiet diet = DietRuleEngine.generate(TARGETS, catalog(), List.of());
        assertThat(diet.meals()).hasSize(4);
        assertThat(diet.meals()).allSatisfy(m -> assertThat(m.items()).isNotEmpty());
    }

    @Test
    @DisplayName("Totais ficam próximos das metas")
    void totalsApproximateTargets() {
        List<FoodItem> catalog = catalog();
        GeneratedDiet diet = DietRuleEngine.generate(TARGETS, catalog, List.of());
        Map<Integer, FoodItem> byId = catalog.stream()
                .collect(Collectors.toMap(FoodItem::getId, Function.identity()));
        DietTotals totals = DietRuleEngine.totals(diet, byId);

        // Montagem por regras simples: tolerância de ±25% nos macros principais.
        assertThat(totals.proteinG()).isBetween(scale(TARGETS.proteinG(), "0.75"), scale(TARGETS.proteinG(), "1.25"));
        assertThat(totals.carbsG()).isBetween(scale(TARGETS.carbsG(), "0.75"), scale(TARGETS.carbsG(), "1.25"));
        assertThat(totals.kcal()).isBetween(scale(TARGETS.kcal(), "0.70"), scale(TARGETS.kcal(), "1.30"));
    }

    @Test
    void restrictionsExcludeMatchingFoods() {
        GeneratedDiet diet = DietRuleEngine.generate(TARGETS, catalog(), List.of("frango", "leite"));
        List<String> names = itemNames(diet);

        assertThat(names).noneMatch(n -> n.toLowerCase(Locale.ROOT).contains("frango"));
        assertThat(names).noneMatch(n -> n.toLowerCase(Locale.ROOT).contains("leite"));
    }

    @Test
    @DisplayName("Restrições impossíveis falham em vez de gerar um plano vazio")
    void impossibleRestrictionsThrowInsteadOfEmptyPlan() {
        List<String> allNames = catalog().stream().map(FoodItem::getName).toList();

        assertThatThrownBy(() -> DietRuleEngine.generate(TARGETS, catalog(), allNames))
                .isInstanceOf(IllegalStateException.class);
    }

    private static BigDecimal scale(BigDecimal value, String factor) {
        return value.multiply(new BigDecimal(factor));
    }
}
