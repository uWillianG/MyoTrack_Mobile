package com.myotrack.domain.service;

import com.myotrack.domain.entity.FoodItem;
import java.math.BigDecimal;
import java.math.MathContext;

/**
 * Os macros de uma porção de um alimento do catálogo.
 *
 * <p>Uma regra de três, e ainda assim vale um tipo próprio, por causa de <b>onde</b> ela precisa
 * acontecer. Quando o usuário escolhe "arroz branco cozido, 150 g", o cliente sabe fazer a conta
 * — ele acabou de receber os valores por 100 g na busca — e mostrá-la na tela. O que ele não pode
 * é ser <b>a fonte</b> dela: o número que vai para o diário tem de sair do catálogo do servidor,
 * ou o vínculo com o alimento vira decorativo e um cliente com bug (ou alguém curioso com o
 * endpoint) grava 150 g de arroz valendo zero caloria.
 *
 * <p>Não arredonda nada. Quem arredonda é o {@link MealPhotoValidator}, que é por onde todo item
 * passa antes de ser gravado — inclusive estes.
 */
public record FoodPortion(
        BigDecimal kcal, BigDecimal proteinG, BigDecimal carbsG, BigDecimal fatG) {

    private static final MathContext MC = MathContext.DECIMAL128;

    private static final BigDecimal HUNDRED = BigDecimal.valueOf(100);

    /**
     * Escala os valores por 100 g do catálogo para a quantidade informada.
     *
     * @param quantityG gramas consumidas; valor ausente ou não positivo devolve porção zerada,
     *     que o validador descarta em seguida — a checagem de quantidade é dele, e duplicá-la
     *     aqui criaria duas definições de "quantidade válida" para o mesmo item
     */
    public static FoodPortion of(FoodItem food, BigDecimal quantityG) {
        if (food == null || quantityG == null || quantityG.signum() <= 0) {
            return new FoodPortion(
                    BigDecimal.ZERO, BigDecimal.ZERO, BigDecimal.ZERO, BigDecimal.ZERO);
        }

        final BigDecimal factor = quantityG.divide(HUNDRED, MC);

        return new FoodPortion(
                scaled(food.getKcalPer100g(), factor),
                scaled(food.getProteinPer100g(), factor),
                scaled(food.getCarbsPer100g(), factor),
                scaled(food.getFatPer100g(), factor));
    }

    private static BigDecimal scaled(BigDecimal per100g, BigDecimal factor) {
        return per100g == null ? BigDecimal.ZERO : per100g.multiply(factor, MC);
    }
}
