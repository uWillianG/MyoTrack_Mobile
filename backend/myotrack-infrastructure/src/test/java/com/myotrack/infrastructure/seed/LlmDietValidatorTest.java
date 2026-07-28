package com.myotrack.infrastructure.seed;

import static org.assertj.core.api.Assertions.assertThat;

import com.myotrack.domain.entity.FoodItem;
import com.myotrack.domain.service.DietGeneration.DietTotals;
import com.myotrack.domain.service.DietGeneration.GeneratedDiet;
import com.myotrack.domain.service.DietGeneration.GeneratedMealItem;
import com.myotrack.domain.service.DietRuleEngine;
import com.myotrack.domain.service.LlmDietValidator;
import com.myotrack.domain.service.LlmDietValidator.LlmDiet;
import com.myotrack.domain.service.LlmDietValidator.LlmMeal;
import com.myotrack.domain.service.LlmDietValidator.LlmMealItem;
import com.myotrack.domain.service.MacroTargets;
import java.math.BigDecimal;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.function.Function;
import java.util.stream.Collectors;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.ValueSource;

/**
 * A saída do LLM é entrada não confiável. Aqui há um risco a mais que no treino: restrição
 * alimentar pode ser alergia, então um item proibido que passe é um dano real, não um
 * incômodo.
 */
class LlmDietValidatorTest {

    private static final MacroTargets TARGETS = new MacroTargets(
            new BigDecimal("2500"),
            new BigDecimal("160"),
            new BigDecimal("300"),
            new BigDecimal("70"));

    private List<FoodItem> catalog;
    private Map<Integer, FoodItem> byId;

    @BeforeEach
    void setUp() {
        catalog = FoodSeed.items();
        for (int i = 0; i < catalog.size(); i++) {
            catalog.get(i).setId(i + 1);
        }
        byId = catalog.stream().collect(Collectors.toMap(FoodItem::getId, Function.identity()));
    }

    private FoodItem food(String fragment) {
        return catalog.stream()
                .filter(f -> f.getName().toLowerCase().contains(fragment.toLowerCase()))
                .findFirst()
                .orElseThrow(() -> new AssertionError("Alimento não encontrado no seed: " + fragment));
    }

    private static LlmMealItem item(FoodItem food, int grams) {
        return new LlmMealItem(food.getId(), BigDecimal.valueOf(grams));
    }

    /** Três refeições válidas com o que for pedido na primeira. */
    private LlmDiet dietWith(List<LlmMealItem> firstMeal) {
        final LlmMealItem filler = item(catalog.get(0), 100);
        return new LlmDiet(List.of(
                new LlmMeal(1, "Café da manhã", firstMeal),
                new LlmMeal(2, "Almoço", List.of(filler)),
                new LlmMeal(3, "Jantar", List.of(filler))));
    }

    private Optional<GeneratedDiet> validate(LlmDiet proposal, List<String> restrictions) {
        return LlmDietValidator.validate(proposal, TARGETS, catalog, restrictions);
    }

    @Test
    @DisplayName("Proposta válida é aceita e mantém as refeições")
    void acceptsValidProposal() {
        final var result = validate(dietWith(List.of(item(catalog.get(1), 150))), List.of());

        assertThat(result).isPresent();
        assertThat(result.get().meals()).hasSize(3);
        assertThat(result.get().meals().get(0).name()).isEqualTo("Café da manhã");
    }

    @Test
    @DisplayName("foodItemId inexistente reprova — o modelo inventou um alimento")
    void rejectsUnknownFood() {
        final var proposal = dietWith(List.of(new LlmMealItem(999_999, BigDecimal.valueOf(100))));

        assertThat(validate(proposal, List.of())).isEmpty();
    }

    @Test
    @DisplayName("Alimento restrito reprova a proposta inteira")
    void rejectsRestrictedFood() {
        final FoodItem leite = food("Leite");
        final var proposal = dietWith(List.of(item(leite, 200)));

        // Sem restrição, passa.
        assertThat(validate(proposal, List.of())).isPresent();

        // Com "leite" na lista de restrições, não. Consertar a refeição removendo o item
        // seria pior: o resto do plano foi montado contando com aquelas calorias.
        assertThat(validate(proposal, List.of("leite"))).isEmpty();
        // A comparação ignora caixa — a restrição é texto livre digitado pelo usuário.
        assertThat(validate(proposal, List.of("LEITE"))).isEmpty();
    }

    @Test
    @DisplayName("A restrição casa por trecho do nome, como no motor de regras")
    void restrictionMatchesSubstring() {
        final FoodItem leite = food("Leite");
        assertThat(leite.getName().toLowerCase()).contains("leite");

        // "leite integral" não bate com "Leite desnatado", mas "leite" bate com os dois.
        assertThat(validate(dietWith(List.of(item(leite, 200))), List.of("lei"))).isEmpty();
    }

    @ParameterizedTest
    @ValueSource(ints = {9, 501, 0})
    @DisplayName("Quantidades fora de 10–500 g reprovam")
    void rejectsOutOfRangeQuantity(int grams) {
        assertThat(validate(dietWith(List.of(item(catalog.get(1), grams))), List.of())).isEmpty();
    }

    @Test
    void acceptsBoundaryQuantities() {
        assertThat(validate(dietWith(List.of(item(catalog.get(1), 10))), List.of())).isPresent();
        assertThat(validate(dietWith(List.of(item(catalog.get(1), 500))), List.of())).isPresent();
    }

    @Test
    @DisplayName("Menos de 3 ou mais de 6 refeições reprova")
    void rejectsBadMealCount() {
        final LlmMealItem filler = item(catalog.get(0), 100);
        final LlmMeal meal = new LlmMeal(1, "Refeição", List.of(filler));

        assertThat(validate(new LlmDiet(List.of(meal, meal)), List.of())).isEmpty();
        assertThat(validate(
                new LlmDiet(List.of(meal, meal, meal, meal, meal, meal, meal)), List.of()))
                .isEmpty();
    }

    @Test
    void rejectsEmptyMeal() {
        final LlmMealItem filler = item(catalog.get(0), 100);
        final var proposal = new LlmDiet(List.of(
                new LlmMeal(1, "Café", List.of()),
                new LlmMeal(2, "Almoço", List.of(filler)),
                new LlmMeal(3, "Jantar", List.of(filler))));

        assertThat(validate(proposal, List.of())).isEmpty();
    }

    @Test
    void rejectsNullProposalOrMeals() {
        assertThat(validate(null, List.of())).isEmpty();
        assertThat(validate(new LlmDiet(null), List.of())).isEmpty();
    }

    @Test
    @DisplayName("O nome do alimento vem do catálogo, não do modelo")
    void foodNameComesFromCatalog() {
        final FoodItem first = catalog.get(1);
        final var result = validate(dietWith(List.of(item(first, 150))), List.of()).orElseThrow();

        assertThat(result.meals().get(0).items().get(0).name()).isEqualTo(first.getName());
    }

    @Test
    @DisplayName("Refeição sem nome ganha um padrão em vez de ir vazia para a tela")
    void blankNameGetsDefault() {
        final LlmMealItem filler = item(catalog.get(0), 100);
        final var proposal = new LlmDiet(List.of(
                new LlmMeal(1, "  ", List.of(filler)),
                new LlmMeal(2, null, List.of(filler)),
                new LlmMeal(3, "Jantar", List.of(filler))));

        final var result = validate(proposal, List.of()).orElseThrow();

        assertThat(result.meals().get(0).name()).isEqualTo("Refeição 1");
        assertThat(result.meals().get(1).name()).isEqualTo("Refeição 2");
        assertThat(result.meals().get(2).name()).isEqualTo("Jantar");
    }

    @Test
    @DisplayName("Refeições fora de ordem são renumeradas em sequência")
    void mealsAreSortedAndRenumbered() {
        final LlmMealItem filler = item(catalog.get(0), 100);
        final var proposal = new LlmDiet(List.of(
                new LlmMeal(9, "Jantar", List.of(filler)),
                new LlmMeal(1, "Café", List.of(filler)),
                new LlmMeal(5, "Almoço", List.of(filler))));

        final var result = validate(proposal, List.of()).orElseThrow();

        assertThat(result.meals().stream().map(m -> m.name()))
                .containsExactly("Café", "Almoço", "Jantar");
        // A ordem gravada é 1..n: o "9" do modelo não pode virar buraco na numeração.
        assertThat(result.meals().stream().map(m -> m.order())).containsExactly(1, 2, 3);
    }

    @Test
    @DisplayName("Dieta muito abaixo da meta é reescalada para perto das calorias alvo")
    void rescalesUnderTargetDiet() {
        // Uma refeição minúscula por vez: sem reescalonamento o dia inteiro daria poucas kcal.
        final FoodItem arroz = food("Arroz");
        final FoodItem frango = food("Frango");
        final var proposal = new LlmDiet(List.of(
                new LlmMeal(1, "Café", List.of(item(arroz, 20))),
                new LlmMeal(2, "Almoço", List.of(item(arroz, 20), item(frango, 20))),
                new LlmMeal(3, "Jantar", List.of(item(frango, 20)))));

        final var raw = validateWithoutAdjust(proposal);
        final var adjusted = validate(proposal, List.of()).orElseThrow();

        final BigDecimal before = DietRuleEngine.totals(raw, byId).kcal();
        final BigDecimal after = DietRuleEngine.totals(adjusted, byId).kcal();

        assertThat(before).isLessThan(after);
        // O fator é limitado a 2x: uma proposta absurdamente pequena não chega à meta em um
        // passo, e forçar isso criaria porções irreais.
        assertThat(after).isLessThanOrEqualTo(before.multiply(BigDecimal.valueOf(2)));
    }

    @Test
    @DisplayName("Dieta já próxima da meta não é mexida")
    void keepsQuantitiesWhenCloseEnough() {
        // Monta pelo motor de regras, que já bate as metas, e devolve como se fosse do LLM.
        final GeneratedDiet fromRules = DietRuleEngine.generate(TARGETS, catalog, List.of());
        final DietTotals totals = DietRuleEngine.totals(fromRules, byId);

        final var proposal = new LlmDiet(fromRules.meals().stream()
                .map(m -> new LlmMeal(
                        m.order(),
                        m.name(),
                        m.items().stream()
                                .map(i -> new LlmMealItem(i.foodItemId(), i.quantityG()))
                                .toList()))
                .toList());

        final var result = validate(proposal, List.of()).orElseThrow();

        assertThat(DietRuleEngine.totals(result, byId).kcal()).isEqualTo(totals.kcal());
    }

    @Test
    @DisplayName("As quantidades reescaladas ficam em múltiplos de 5 g")
    void rescaledQuantitiesAreRoundNumbers() {
        final FoodItem arroz = food("Arroz");
        final var proposal = new LlmDiet(List.of(
                new LlmMeal(1, "Café", List.of(item(arroz, 33))),
                new LlmMeal(2, "Almoço", List.of(item(arroz, 47))),
                new LlmMeal(3, "Jantar", List.of(item(arroz, 61)))));

        final var result = validate(proposal, List.of()).orElseThrow();

        // "137 g de arroz" não é uma instrução que alguém siga na cozinha.
        assertThat(result.meals().stream().flatMap(m -> m.items().stream()))
                .allSatisfy(i -> assertThat(
                        i.quantityG().remainder(BigDecimal.valueOf(5)).signum())
                        .isZero());
    }

    @Test
    @DisplayName("O reescalonamento respeita o teto de 500 g por item")
    void rescalingRespectsMaxQuantity() {
        final FoodItem alface = food("Alface");
        // Alface tem pouquíssimas kcal: o fator sobe ao teto e as quantidades encostam no
        // limite — o que não pode é passar dele.
        final var proposal = new LlmDiet(List.of(
                new LlmMeal(1, "Café", List.of(item(alface, 400))),
                new LlmMeal(2, "Almoço", List.of(item(alface, 400))),
                new LlmMeal(3, "Jantar", List.of(item(alface, 400)))));

        final var result = validate(proposal, List.of()).orElseThrow();

        assertThat(result.meals().stream().flatMap(m -> m.items().stream()))
                .allSatisfy(i -> assertThat(i.quantityG())
                        .isLessThanOrEqualTo(BigDecimal.valueOf(500)));
    }

    /** A dieta como o modelo mandou, sem o ajuste de quantidades — só para comparar. */
    private GeneratedDiet validateWithoutAdjust(LlmDiet proposal) {
        return new GeneratedDiet(proposal.meals().stream()
                .map(m -> new com.myotrack.domain.service.DietGeneration.GeneratedMeal(
                        m.order(),
                        m.name(),
                        m.items().stream()
                                .map(i -> new GeneratedMealItem(
                                        i.foodItemId(),
                                        byId.get(i.foodItemId()).getName(),
                                        i.quantityG()))
                                .toList()))
                .toList());
    }
}
