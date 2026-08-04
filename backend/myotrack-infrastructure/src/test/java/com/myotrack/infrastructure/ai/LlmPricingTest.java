package com.myotrack.infrastructure.ai;

import static org.assertj.core.api.Assertions.assertThat;

import com.myotrack.infrastructure.ai.LlmPricing.ModelPrice;
import java.math.BigDecimal;
import java.util.HashMap;
import java.util.Map;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

/**
 * A conversão de preço em custo gravado.
 *
 * <p>O que se protege aqui é a distinção entre <b>não sei</b> e <b>foi de graça</b>. Um custo
 * ausente que virasse zero somaria como gratuito no relatório, e o erro apareceria como uma conta
 * de IA menor do que a real — exatamente o número que existe para não ser subestimado.
 */
class LlmPricingTest {

    private static LlmPricing pricing(String model, String input, String output) {
        return new LlmPricing(Map.of(
                model, new ModelPrice(new BigDecimal(input), new BigDecimal(output))));
    }

    @Test
    @DisplayName("o custo sai em nano-dólares, sem arredondar para zero")
    void computesNanoUsd() {
        // 0,30 e 2,50 por milhão. Uma extração de foto típica: 1.500 de entrada, 400 de saída.
        // 1500×0,30/1e6 + 400×2,50/1e6 = 0,00045 + 0,001 = 0,00145 USD = 1.450.000 nano.
        final LlmPricing pricing = pricing("gemini-3.5-flash", "0.30", "2.50");

        assertThat(pricing.costNanoUsd("gemini-3.5-flash", 1500, 400)).isEqualTo(1_450_000L);
    }

    @Test
    @DisplayName("uma chamada pequena não some na conversão")
    void tinyCallSurvives() {
        // Em centavos inteiros isto seria zero, e a soma do mês inteiro diria que a IA é
        // gratuita. É a razão de a unidade ser nano-dólar.
        final LlmPricing pricing = pricing("gpt-5-mini", "0.25", "2.00");

        assertThat(pricing.costNanoUsd("gpt-5-mini", 10, 1)).isEqualTo(4_500L);
    }

    @Test
    @DisplayName("modelo sem preço devolve null, e não zero")
    void unknownModelIsNullNotZero() {
        final LlmPricing pricing = pricing("gemini-3.5-flash", "0.30", "2.50");

        // É o caso normal logo depois de trocar de modelo: a configuração ainda não acompanhou.
        assertThat(pricing.costNanoUsd("modelo-que-ninguem-cadastrou", 1000, 500)).isNull();
    }

    @Test
    @DisplayName("tabela vazia não quebra — só não sabe o custo de nada")
    void emptyTableIsUsable() {
        // É o estado com que o app é entregue: preço é dado externo e não vem cravado no jar.
        final LlmPricing pricing = new LlmPricing(null);

        assertThat(pricing.models()).isEmpty();
        assertThat(pricing.costNanoUsd("gemini-3.5-flash", 1000, 500)).isNull();
    }

    @Test
    @DisplayName("o nome do modelo não depende de caixa")
    void modelLookupIsCaseInsensitive() {
        final LlmPricing pricing = pricing("gpt-5-mini", "1", "1");

        assertThat(pricing.costNanoUsd("GPT-5-Mini", 1_000_000, 0)).isEqualTo(1_000_000_000L);
    }

    @Test
    @DisplayName("preço pela metade só de um lado ainda é preço desconhecido")
    void halfFilledPriceIsUnknown() {
        // Um yaml preenchido pela metade produziria um custo que parece certo e conta só a
        // entrada. Melhor não saber do que saber pela metade sem avisar.
        final Map<String, ModelPrice> models = new HashMap<>();
        models.put("gpt-5-mini", new ModelPrice(new BigDecimal("0.25"), null));

        assertThat(new LlmPricing(models).costNanoUsd("gpt-5-mini", 1000, 1000)).isNull();
    }
}
