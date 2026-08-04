package com.myotrack.infrastructure.ai;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.util.Locale;
import java.util.Map;
import org.springframework.boot.context.properties.ConfigurationProperties;

/**
 * Quanto custa cada modelo, em dólares por milhão de tokens.
 *
 * <p><b>A tabela é configuração, e não código, porque o preço não é nosso.</b> Os dois provedores
 * mudam a lista quando querem, e uma tabela cravada no jar continuaria somando com o número antigo
 * sem nada indicar que ela envelheceu — o relatório de custo ficaria errado exatamente do jeito
 * mais difícil de perceber, com aparência de certo. Aqui o valor mora ao lado do nome do modelo no
 * {@code application.yml}: quem trocar o modelo vê o preço na linha seguinte.
 *
 * <p><b>Modelo sem preço registrado devolve {@code null}, e não zero.</b> Zero diria que a chamada
 * foi de graça, que é uma afirmação — e falsa. Null diz "não sei", que é a verdade, e deixa a
 * consulta de custo distinguir o que ela somou do que ela não conseguiu somar. É o caso normal
 * logo depois de trocar de modelo, e é por isso que ele não pode derrubar o job.
 *
 * <p>Escrever com {@link BigDecimal} é deliberado: o preço vem de uma tabela publicada em decimal
 * ("0,30 por milhão"), e é assim que ele deve ser conferido contra a fonte.
 */
@ConfigurationProperties(prefix = "myotrack.llm.pricing")
public record LlmPricing(Map<String, ModelPrice> models) {

    /** Dólares por milhão de tokens, como os provedores publicam. */
    public record ModelPrice(BigDecimal inputPerMillion, BigDecimal outputPerMillion) {
    }

    public LlmPricing {
        models = models == null ? Map.of() : models;
    }

    /**
     * O custo da chamada em nano-dólares, ou null se o modelo não tem preço registrado.
     *
     * <p>Nano-dólar (10⁻⁹) e não centavo: uma extração de foto custa frações de centavo, e em
     * centavos inteiros toda chamada individual arredondaria para zero — a soma do mês inteiro
     * daria zero e a tabela pareceria dizer que a IA é gratuita. Em {@code long} o teto é da ordem
     * de nove bilhões de dólares, folgado por várias ordens de grandeza.
     */
    public Long costNanoUsd(String model, long inputTokens, long outputTokens) {
        final ModelPrice price = models.get(model == null ? "" : model.toLowerCase(Locale.ROOT));
        if (price == null || price.inputPerMillion() == null || price.outputPerMillion() == null) {
            return null;
        }

        // custo_usd = preço_por_milhão × tokens ÷ 1e6; em nano-dólares isso é ×1e9, e as duas
        // potências se cancelam em ×1000.
        final BigDecimal nano = price.inputPerMillion()
                .multiply(BigDecimal.valueOf(inputTokens))
                .add(price.outputPerMillion().multiply(BigDecimal.valueOf(outputTokens)))
                .multiply(BigDecimal.valueOf(1000L));

        return nano.setScale(0, RoundingMode.HALF_UP).longValue();
    }
}
