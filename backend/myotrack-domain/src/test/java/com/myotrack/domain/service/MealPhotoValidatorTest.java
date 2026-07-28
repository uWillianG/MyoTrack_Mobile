package com.myotrack.domain.service;

import static org.assertj.core.api.Assertions.assertThat;

import com.myotrack.domain.service.MealPhotoValidator.AnalyzedMeal;
import com.myotrack.domain.service.MealPhotoValidator.LlmDetectedItem;
import com.myotrack.domain.service.MealPhotoValidator.LlmMealPhoto;
import java.math.BigDecimal;
import java.util.List;
import java.util.Optional;
import java.util.Set;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;

class MealPhotoValidatorTest {

    private static final Set<String> ANY = Set.of();

    private static LlmDetectedItem item(
            String description, double quantityG, double kcal,
            double protein, double carbs, double fat) {
        return new LlmDetectedItem(
                description,
                null,
                BigDecimal.valueOf(quantityG),
                BigDecimal.valueOf(kcal),
                BigDecimal.valueOf(protein),
                BigDecimal.valueOf(carbs),
                BigDecimal.valueOf(fat));
    }

    private static Optional<AnalyzedMeal> validate(LlmDetectedItem... items) {
        return MealPhotoValidator.validate(new LlmMealPhoto(List.of(items)), Set.of());
    }

    @Nested
    @DisplayName("proposta sem nada aproveitável")
    class Rejeitadas {

        @Test
        @DisplayName("lista vazia: foto sem comida não vira refeição de zero caloria")
        void listaVazia() {
            // O modelo é instruído a devolver lista vazia quando não há comida. Gravar uma
            // análise vazia poluiria o diário com uma refeição fantasma.
            assertThat(MealPhotoValidator.validate(new LlmMealPhoto(List.of()), Set.of()))
                    .isEmpty();
            assertThat(MealPhotoValidator.validate(new LlmMealPhoto(null), Set.of())).isEmpty();
            assertThat(MealPhotoValidator.validate(null, Set.of())).isEmpty();
        }

        @Test
        @DisplayName("item sem descrição é descartado")
        void semDescricao() {
            assertThat(validate(item("  ", 100, 150, 5, 20, 3))).isEmpty();
        }

        @Test
        @DisplayName("item sem peso é descartado — não haveria o que corrigir depois")
        void semPeso() {
            // A tela oferece ajustar a quantidade; um item sem gramas seria um número que o
            // usuário vê e não consegue mexer.
            assertThat(validate(item("Arroz", 0, 150, 3, 30, 1))).isEmpty();
        }
    }

    @Nested
    @DisplayName("saneamento por item")
    class Saneamento {

        @Test
        @DisplayName("quantidade absurda é presa à faixa")
        void quantidadePresaAFaixa() {
            final var meal = validate(item("Arroz", 9000, 200, 4, 44, 1)).orElseThrow();

            assertThat(meal.items().getFirst().quantityG())
                    .isEqualByComparingTo(BigDecimal.valueOf(2000));
        }

        @Test
        @DisplayName("macro negativo vira zero")
        void macroNegativo() {
            final var meal = validate(item("Salada", 100, 20, -5, 4, 0)).orElseThrow();

            assertThat(meal.items().getFirst().proteinG()).isEqualByComparingTo(BigDecimal.ZERO);
        }

        @Test
        @DisplayName("descrição longa é truncada")
        void descricaoLonga() {
            final var meal = validate(item("x".repeat(300), 100, 100, 1, 1, 1)).orElseThrow();

            assertThat(meal.items().getFirst().description()).hasSize(120);
        }

        @Test
        @DisplayName("foodItemId inexistente no catálogo vira null")
        void idInventado() {
            // Um id que não existe é pior que nenhum: quem consumir depois acharia que há
            // vínculo com o catálogo.
            final var proposal = new LlmMealPhoto(List.of(new LlmDetectedItem(
                    "Arroz", 999, BigDecimal.valueOf(150),
                    BigDecimal.valueOf(195), BigDecimal.valueOf(3.6),
                    BigDecimal.valueOf(42), BigDecimal.valueOf(0.3))));

            final var meal = MealPhotoValidator.validate(proposal, Set.of(1, 2, 3)).orElseThrow();

            assertThat(meal.items().getFirst().foodItemId()).isNull();
        }

        @Test
        @DisplayName("foodItemId existente é preservado")
        void idValido() {
            final var proposal = new LlmMealPhoto(List.of(new LlmDetectedItem(
                    "Arroz", 2, BigDecimal.valueOf(150),
                    BigDecimal.valueOf(195), BigDecimal.valueOf(3.6),
                    BigDecimal.valueOf(42), BigDecimal.valueOf(0.3))));

            final var meal = MealPhotoValidator.validate(proposal, Set.of(1, 2, 3)).orElseThrow();

            assertThat(meal.items().getFirst().foodItemId()).isEqualTo(2);
        }

        @Test
        @DisplayName("mais de 20 itens: o excedente é cortado")
        void muitosItens() {
            final var many = new LlmDetectedItem[40];
            for (int i = 0; i < many.length; i++) {
                many[i] = item("Item %d".formatted(i), 50, 100, 5, 10, 2);
            }

            assertThat(validate(many).orElseThrow().items()).hasSize(20);
        }
    }

    @Nested
    @DisplayName("coerência entre calorias e macros")
    class Calorias {

        @Test
        @DisplayName("kcal informada que bate com os macros é mantida")
        void kcalCoerente() {
            // 4*10 + 4*30 + 9*5 = 205; informar 200 está dentro da tolerância.
            final var meal = validate(item("Prato", 200, 200, 10, 30, 5)).orElseThrow();

            assertThat(meal.items().getFirst().kcal())
                    .isEqualByComparingTo(BigDecimal.valueOf(200));
        }

        @Test
        @DisplayName("kcal que contradiz os macros é recalculada por Atwater")
        void kcalIncoerente() {
            // O erro clássico do modelo: macros plausíveis e caloria que não vem deles.
            // 4*10 + 4*30 + 9*5 = 205, e ele respondeu 900.
            final var meal = validate(item("Prato", 200, 900, 10, 30, 5)).orElseThrow();

            assertThat(meal.items().getFirst().kcal())
                    .isEqualByComparingTo(BigDecimal.valueOf(205));
        }

        @Test
        @DisplayName("kcal zerada com macros presentes é derivada")
        void kcalAusente() {
            final var meal = validate(item("Prato", 200, 0, 10, 30, 5)).orElseThrow();

            assertThat(meal.items().getFirst().kcal())
                    .isEqualByComparingTo(BigDecimal.valueOf(205));
        }

        @Test
        @DisplayName("sem macros, a kcal informada é respeitada")
        void semMacros() {
            // Café preto e refrigerante zero existem: derivar daria zero e apagaria o dado.
            final var meal = validate(item("Café preto", 200, 5, 0, 0, 0)).orElseThrow();

            assertThat(meal.items().getFirst().kcal()).isEqualByComparingTo(BigDecimal.valueOf(5));
        }
    }

    @Nested
    @DisplayName("totais")
    class Totais {

        @Test
        @DisplayName("somam os itens já corrigidos, não os informados")
        void somaDosItens() {
            final var meal = validate(
                    item("Arroz", 150, 195, 3.6, 42, 0.3),
                    // kcal absurda: entra no total já recalculada (4*30 = 120).
                    item("Frango", 120, 5000, 30, 0, 0)).orElseThrow();

            assertThat(meal.items()).hasSize(2);
            assertThat(meal.totalProteinG()).isEqualByComparingTo(BigDecimal.valueOf(33.6));
            assertThat(meal.totalCarbsG()).isEqualByComparingTo(BigDecimal.valueOf(42));
            // 195 (coerente com 3.6/42/0.3 → 196.7, dentro da tolerância) + 120.
            assertThat(meal.totalKcal()).isEqualByComparingTo(BigDecimal.valueOf(315));
        }

        @Test
        @DisplayName("totalsOf recalcula uma lista já validada — é o caminho da correção manual")
        void recalculo() {
            final var original = validate(
                    item("Arroz", 150, 195, 3.6, 42, 0.3),
                    item("Frango", 120, 120, 30, 0, 0)).orElseThrow();

            final var apenasUm = MealPhotoValidator.totalsOf(List.of(original.items().getFirst()));

            assertThat(apenasUm.items()).hasSize(1);
            assertThat(apenasUm.totalProteinG()).isEqualByComparingTo(BigDecimal.valueOf(3.6));
        }
    }
}
