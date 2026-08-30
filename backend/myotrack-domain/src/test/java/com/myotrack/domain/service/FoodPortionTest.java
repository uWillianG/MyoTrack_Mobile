package com.myotrack.domain.service;

import static org.assertj.core.api.Assertions.assertThat;

import com.myotrack.domain.entity.FoodItem;
import java.math.BigDecimal;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

/**
 * A regra de três que liga o catálogo ao prato.
 *
 * <p>Ela é curta e mesmo assim é ela que decide se o vínculo com o alimento significa alguma
 * coisa. Quando o usuário escolhe "arroz branco cozido, 150 g", o número que vai para o diário
 * sai daqui — não do que o cliente calculou e mandou junto.
 */
class FoodPortionTest {

    /** Arroz branco cozido, por 100 g, como está no catálogo. */
    private static FoodItem arroz() {
        final FoodItem food = new FoodItem();
        food.setId(1);
        food.setName("Arroz branco cozido");
        food.setKcalPer100g(new BigDecimal("128"));
        food.setProteinPer100g(new BigDecimal("2.5"));
        food.setCarbsPer100g(new BigDecimal("28.1"));
        food.setFatPer100g(new BigDecimal("0.2"));
        return food;
    }

    @Test
    @DisplayName("escala os valores por 100 g para a porção informada")
    void escalaPelaPorcao() {
        final FoodPortion portion = FoodPortion.of(arroz(), new BigDecimal("150"));

        assertThat(portion.kcal()).isEqualByComparingTo("192");
        assertThat(portion.proteinG()).isEqualByComparingTo("3.75");
        assertThat(portion.carbsG()).isEqualByComparingTo("42.15");
        assertThat(portion.fatG()).isEqualByComparingTo("0.3");
    }

    @Test
    @DisplayName("porção menor que 100 g não vira número inteiro pelo caminho")
    void naoArredondaAqui() {
        // O arredondamento é do MealPhotoValidator, que é por onde todo item passa antes de ser
        // gravado. Arredondar aqui também faria a mesma conta duas vezes, com resultados
        // ligeiramente diferentes, e o desencontro apareceria como total que não fecha.
        final FoodPortion portion = FoodPortion.of(arroz(), new BigDecimal("30"));

        assertThat(portion.kcal()).isEqualByComparingTo("38.4");
    }

    @Test
    @DisplayName("quantidade ausente ou não positiva devolve porção zerada")
    void quantidadeInvalida() {
        // Zerada, e não exceção: quem decide que uma quantidade não serve é o validador, e ele
        // descarta o item logo em seguida. Duas definições de "quantidade válida" divergiriam.
        assertThat(FoodPortion.of(arroz(), null).kcal()).isEqualByComparingTo("0");
        assertThat(FoodPortion.of(arroz(), BigDecimal.ZERO).kcal()).isEqualByComparingTo("0");
        assertThat(FoodPortion.of(arroz(), new BigDecimal("-50")).kcal()).isEqualByComparingTo("0");
    }

    @Test
    @DisplayName("alimento sem algum macro no catálogo conta como zero, e não estoura")
    void macroAusenteNoCatalogo() {
        // FiberPer100g é anulável no schema; os demais não são, mas uma linha vinda de importação
        // futura pode chegar incompleta, e um NullPointerException aqui derrubaria a gravação da
        // refeição inteira por causa de um campo que ninguém soma.
        final FoodItem incompleto = arroz();
        incompleto.setFatPer100g(null);

        assertThat(FoodPortion.of(incompleto, new BigDecimal("100")).fatG())
                .isEqualByComparingTo("0");
    }
}
