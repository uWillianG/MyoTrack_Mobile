package com.myotrack.api.foods;

import com.myotrack.domain.entity.FoodItem;
import com.myotrack.infrastructure.repository.FoodItemRepository;
import java.math.BigDecimal;
import java.text.Normalizer;
import java.util.Comparator;
import java.util.List;
import java.util.Locale;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

/**
 * Catálogo nutricional, com valores por 100 g.
 *
 * <p>É o terceiro caminho da entrada manual de refeição — digitar tudo, deixar a IA estimar, ou
 * escolher aqui. Os três produzem a mesma linha do diário; este é o único com número conferido em
 * tabela, e por isso é o que o servidor recalcula na hora de salvar (ver
 * {@code MealAnalysesController.manual}). O que sai daqui é para a tela mostrar enquanto a pessoa
 * escolhe a quantidade.
 *
 * <p>Como {@code /api/exercises}, é o mesmo catálogo para todo mundo.
 */
@RestController
@RequestMapping("/api/foods")
public class FoodsController {

    private static final int DEFAULT_LIMIT = 30;
    private static final int MAX_LIMIT = 100;

    /** Marcas de acento no NFD: o que sobra depois de decompor "ã" em "a" + til. */
    private static final java.util.regex.Pattern ACCENTS =
            java.util.regex.Pattern.compile("\\p{M}+");

    private final FoodItemRepository foods;

    public FoodsController(FoodItemRepository foods) {
        this.foods = foods;
    }

    /**
     * Busca por trecho do nome, ignorando caixa <b>e acento</b>.
     *
     * <p>O acento é o ponto todo. Metade do catálogo brasileiro tem um — pão, açaí, muçarela,
     * feijão —, e ninguém digita acento procurando comida no celular: uma busca sensível a ele
     * responderia "nada encontrado" para as palavras mais buscadas que existem, e o usuário
     * concluiria que o alimento não está no catálogo. Resolver isso no Postgres pediria a extensão
     * {@code unaccent}, cuja criação exige superusuário e não está disponível em todo ambiente
     * gerenciado; com duas centenas de linhas, comparar em memória custa menos que essa
     * dependência.
     *
     * @param q trecho procurado; ausente ou em branco devolve o começo do catálogo, que é o que a
     *     tela mostra antes de o usuário digitar qualquer coisa
     */
    @GetMapping
    @Transactional(readOnly = true)
    public List<FoodView> search(
            @RequestParam(required = false) String q,
            @RequestParam(required = false) Integer limit) {

        final int size = limit == null ? DEFAULT_LIMIT : Math.clamp(limit, 1, MAX_LIMIT);
        final String needle = q == null ? "" : fold(q.trim());

        final List<FoodItem> catalog = foods.findAllByOrderByNameAsc();
        if (needle.isEmpty()) {
            return catalog.stream()
                    .sorted(ALFABETICA)
                    .limit(size)
                    .map(FoodView::from)
                    .toList();
        }

        // Quem começa com o que foi digitado vem antes de quem só contém: procurando "pao", a
        // primeira resposta útil é "Pão francês", não "Farinha de pão".
        return catalog.stream()
                .filter(food -> fold(food.getName()).contains(needle))
                .sorted(Comparator
                        .comparing((FoodItem food) -> fold(food.getName()).startsWith(needle) ? 0 : 1)
                        .thenComparing(ALFABETICA))
                .limit(size)
                .map(FoodView::from)
                .toList();
    }

    /**
     * Ordem alfabética pelo nome <b>sem acento</b>.
     *
     * <p>A mesma normalização que decide o que casa decide onde cada coisa fica, e não é
     * cosmético: comparar as strings cruas usa ponto de código, onde "ç" (231) vem depois de
     * qualquer letra sem acento — "Açaí" cairia atrás de "Azeite", e a lista alfabética teria um
     * buraco exatamente nos nomes mais brasileiros do catálogo.
     *
     * <p>Ordenar aqui, e não deixar por conta do {@code ORDER BY} do Postgres, também tira a
     * lista da dependência do collation do banco — que varia entre a máquina de quem desenvolve e
     * o servidor, e faria a mesma consulta responder em ordens diferentes nos dois.
     */
    private static final Comparator<FoodItem> ALFABETICA =
            Comparator.comparing(food -> fold(food.getName()));

    /** Minúsculas e sem acento: "Pão" e "pao" viram a mesma coisa. */
    private static String fold(String value) {
        final String decomposed = Normalizer.normalize(value, Normalizer.Form.NFD);
        return ACCENTS.matcher(decomposed).replaceAll("").toLowerCase(Locale.ROOT);
    }

    /**
     * Os valores são <b>por 100 g</b>, e o nome de cada campo diz isso — a multiplicação pela
     * porção acontece na tela para o usuário ver, e de novo no servidor na hora de salvar. Sem o
     * sufixo, o campo {@code kcal} de um alimento seria confundido com o {@code kcal} de um item
     * de refeição, que já é a porção inteira.
     */
    public record FoodView(
            Integer id,
            String name,
            BigDecimal kcalPer100g,
            BigDecimal proteinPer100g,
            BigDecimal carbsPer100g,
            BigDecimal fatPer100g,
            BigDecimal fiberPer100g,
            String source) {

        static FoodView from(FoodItem food) {
            return new FoodView(
                    food.getId(),
                    food.getName(),
                    food.getKcalPer100g(),
                    food.getProteinPer100g(),
                    food.getCarbsPer100g(),
                    food.getFatPer100g(),
                    food.getFiberPer100g(),
                    food.getSource());
        }
    }
}
