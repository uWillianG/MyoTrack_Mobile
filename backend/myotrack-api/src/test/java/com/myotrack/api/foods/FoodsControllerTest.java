package com.myotrack.api.foods;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;

import com.myotrack.api.foods.FoodsController.FoodView;
import com.myotrack.domain.entity.FoodItem;
import com.myotrack.infrastructure.repository.FoodItemRepository;
import java.math.BigDecimal;
import java.util.Comparator;
import java.util.List;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

/**
 * A busca do catálogo de alimentos.
 *
 * <p>O que se testa aqui é quase inteiramente o <b>acento</b>. Metade do catálogo brasileiro tem
 * um — pão, açaí, muçarela, feijão — e ninguém digita acento procurando comida no celular. Uma
 * busca sensível a ele responde "nada encontrado" justamente para as palavras mais buscadas que
 * existem, e o usuário conclui que o alimento não está no catálogo e desiste do caminho inteiro.
 */
class FoodsControllerTest {

    private FoodItemRepository foods;
    private FoodsController controller;

    @BeforeEach
    void setUp() {
        foods = mock(FoodItemRepository.class);
        controller = new FoodsController(foods);

        catalogo(
                food("Açaí polpa"),
                food("Arroz branco cozido"),
                food("Farinha de pão"),
                food("Feijão carioca cozido"),
                food("Pão de forma branco"),
                food("Pão francês"),
                food("Queijo muçarela"));
    }

    private void catalogo(FoodItem... items) {
        when(foods.findAllByOrderByNameAsc()).thenReturn(
                java.util.Arrays.stream(items)
                        .sorted(Comparator.comparing(FoodItem::getName))
                        .toList());
    }

    private static FoodItem food(String name) {
        final FoodItem item = new FoodItem();
        item.setName(name);
        item.setKcalPer100g(new BigDecimal("100"));
        item.setProteinPer100g(new BigDecimal("5"));
        item.setCarbsPer100g(new BigDecimal("15"));
        item.setFatPer100g(new BigDecimal("1"));
        return item;
    }

    private List<String> nomes(String q, Integer limit) {
        return controller.search(q, limit).stream().map(FoodView::name).toList();
    }

    @Test
    @DisplayName("acha \"Pão\" digitando \"pao\"")
    void ignoraAcento() {
        assertThat(nomes("pao", null))
                .contains("Pão francês", "Pão de forma branco", "Farinha de pão");
    }

    @Test
    @DisplayName("acha com o acento também, para quem digita com teclado completo")
    void aceitaOAcentoTambem() {
        assertThat(nomes("pão", null)).contains("Pão francês");
        assertThat(nomes("açaí", null)).containsExactly("Açaí polpa");
        assertThat(nomes("acai", null)).containsExactly("Açaí polpa");
    }

    @Test
    @DisplayName("ignora a caixa")
    void ignoraCaixa() {
        assertThat(nomes("FEIJAO", null)).containsExactly("Feijão carioca cozido");
    }

    @Test
    @DisplayName("quem começa com o trecho vem antes de quem só o contém")
    void prefixoPrimeiro() {
        // Procurando "pao", a primeira resposta útil é um pão — não "Farinha de pão", que só
        // menciona a palavra. Numa lista cortada em poucos itens, a ordem é o resultado.
        assertThat(nomes("pao", null))
                .startsWith("Pão de forma branco", "Pão francês")
                .endsWith("Farinha de pão");
    }

    @Test
    @DisplayName("a ordem alfabética não joga os acentuados para o fim")
    void ordemIgnoraAcento() {
        // Comparando as strings cruas, "ç" (ponto de código 231) vem depois de qualquer letra
        // sem acento: "Açaí" cairia atrás de "Arroz" e de "Azeite", e a lista teria um buraco
        // exatamente nos nomes mais brasileiros do catálogo. O repositório aqui devolve na ordem
        // ingênua de propósito — é o que um collation de banco desatento faria.
        assertThat(nomes("", null)).startsWith("Açaí polpa", "Arroz branco cozido");
    }

    @Test
    @DisplayName("busca em branco devolve o começo do catálogo")
    void buscaEmBranco() {
        // É o que a tela mostra antes de o usuário digitar: uma lista vazia pareceria catálogo
        // vazio, e o caminho do catálogo morreria antes da primeira tecla.
        assertThat(nomes(null, 3)).containsExactly(
                "Açaí polpa", "Arroz branco cozido", "Farinha de pão");
        assertThat(nomes("   ", 3)).hasSize(3);
    }

    @Test
    @DisplayName("o limite é respeitado e preso à faixa")
    void limite() {
        assertThat(nomes("", 2)).hasSize(2);
        // Zero e negativo viram 1 em vez de devolver nada — Math.clamp, como na listagem de
        // análises. Um limite absurdo não deve ser um jeito de pedir o catálogo inteiro.
        assertThat(nomes("", 0)).hasSize(1);
        assertThat(nomes("", 9999)).hasSize(7);
    }

    @Test
    @DisplayName("trecho sem correspondência devolve lista vazia, e não o catálogo")
    void semCorrespondencia() {
        assertThat(nomes("jabuticaba", null)).isEmpty();
    }

    @Test
    @DisplayName("os valores saem por 100 g, com o nome do campo dizendo isso")
    void valoresPor100g() {
        final FoodView view = controller.search("arroz", null).getFirst();

        assertThat(view.name()).isEqualTo("Arroz branco cozido");
        assertThat(view.kcalPer100g()).isEqualByComparingTo("100");
        assertThat(view.carbsPer100g()).isEqualByComparingTo("15");
    }
}
