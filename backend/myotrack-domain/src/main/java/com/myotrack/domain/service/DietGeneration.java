package com.myotrack.domain.service;

import java.math.BigDecimal;
import java.util.List;

/** Contratos de saída do {@link DietRuleEngine}. */
public final class DietGeneration {

    private DietGeneration() {
    }

    public record GeneratedMealItem(int foodItemId, String name, BigDecimal quantityG) {
    }

    public record GeneratedMeal(int order, String name, List<GeneratedMealItem> items) {
    }

    public record GeneratedDiet(List<GeneratedMeal> meals) {
    }

    public record DietTotals(BigDecimal kcal, BigDecimal proteinG, BigDecimal carbsG, BigDecimal fatG) {
    }
}
