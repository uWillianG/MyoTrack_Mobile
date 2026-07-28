package com.myotrack.domain.service;

import static org.assertj.core.api.Assertions.assertThat;

import com.myotrack.domain.service.WeeklyMetrics.MealInput;
import com.myotrack.domain.service.WeeklyMetrics.Result;
import com.myotrack.domain.service.WeeklyMetrics.SessionInput;
import com.myotrack.domain.service.WeeklyMetrics.SetInput;
import com.myotrack.domain.service.WeeklyMetrics.WeightInput;
import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;

class WeeklyMetricsTest {

    private static final LocalDate WEEK = LocalDate.of(2026, 7, 20);

    private static SetInput set(String exercise, int reps, double loadKg) {
        return new SetInput(exercise, reps, BigDecimal.valueOf(loadKg));
    }

    private static SessionInput session(int dayOffset, SetInput... sets) {
        return new SessionInput(WEEK.plusDays(dayOffset), List.of(sets));
    }

    private static Result compute(
            List<SessionInput> sessions,
            List<SessionInput> previous,
            List<WeightInput> weights,
            List<MealInput> meals) {
        return WeeklyMetrics.compute(WEEK, sessions, previous, weights, meals);
    }

    @Nested
    @DisplayName("volume")
    class Volume {

        @Test
        @DisplayName("soma repetições × carga de todas as séries")
        void soma() {
            final Result result = compute(
                    List.of(
                            session(0, set("Supino", 10, 60), set("Supino", 8, 60)),
                            session(2, set("Agachamento", 5, 100))),
                    List.of(), List.of(), List.of());

            // 600 + 480 + 500
            assertThat(result.totalVolumeKg()).isEqualByComparingTo("1580.0");
            assertThat(result.sessions()).isEqualTo(2);
            assertThat(result.totalSets()).isEqualTo(3);
        }

        @Test
        @DisplayName("peso corporal não soma volume, mas a série é contada")
        void pesoCorporal() {
            final Result result = compute(
                    List.of(session(0, set("Barra fixa", 12, 0))),
                    List.of(), List.of(), List.of());

            assertThat(result.totalVolumeKg()).isEqualByComparingTo("0.0");
            assertThat(result.totalSets()).isEqualTo(1);
        }

        @Test
        @DisplayName("compara com a semana anterior em porcentagem")
        void comparacao() {
            final Result result = compute(
                    List.of(session(0, set("Supino", 10, 60))),
                    List.of(session(-7, set("Supino", 10, 50))),
                    List.of(), List.of());

            // 600 contra 500 = +20%
            assertThat(result.volumeChangePercent()).isEqualByComparingTo("20.0");
        }

        @Test
        @DisplayName("queda vira porcentagem negativa")
        void queda() {
            final Result result = compute(
                    List.of(session(0, set("Supino", 5, 60))),
                    List.of(session(-7, set("Supino", 10, 60))),
                    List.of(), List.of());

            assertThat(result.volumeChangePercent()).isEqualByComparingTo("-50.0");
        }

        @Test
        @DisplayName("sem semana anterior, não há porcentagem a informar")
        void semBase() {
            // De zero para algum treino não é "aumento de X%": é ter voltado a treinar, e o
            // número tenderia ao infinito.
            final Result result = compute(
                    List.of(session(0, set("Supino", 10, 60))),
                    List.of(), List.of(), List.of());

            assertThat(result.volumeChangePercent()).isNull();
        }

        @Test
        @DisplayName("aponta o exercício de maior volume na semana")
        void exercicioDestaque() {
            final Result result = compute(
                    List.of(session(0,
                            set("Supino", 10, 60),
                            set("Agachamento", 10, 100))),
                    List.of(), List.of(), List.of());

            assertThat(result.topExercise()).isEqualTo("Agachamento");
            assertThat(result.topExerciseVolumeKg()).isEqualByComparingTo("1000.0");
        }
    }

    @Nested
    @DisplayName("peso corporal")
    class Peso {

        @Test
        @DisplayName("usa a primeira e a última pesagem, em ordem de data")
        void variacao() {
            final Result result = compute(List.of(), List.of(), List.of(
                    new WeightInput(WEEK.plusDays(5), BigDecimal.valueOf(83.1)),
                    new WeightInput(WEEK, BigDecimal.valueOf(84.0))), List.of());

            assertThat(result.weightStartKg()).isEqualByComparingTo("84.0");
            assertThat(result.weightEndKg()).isEqualByComparingTo("83.1");
            assertThat(result.weightChangeKg()).isEqualByComparingTo("-0.9");
        }

        @Test
        @DisplayName("uma pesagem só não descreve variação")
        void umaPesagem() {
            final Result result = compute(List.of(), List.of(),
                    List.of(new WeightInput(WEEK, BigDecimal.valueOf(84))), List.of());

            assertThat(result.weightEndKg()).isEqualByComparingTo("84");
            assertThat(result.weightChangeKg()).isNull();
        }
    }

    @Nested
    @DisplayName("diário alimentar")
    class Diario {

        @Test
        @DisplayName("média por dia registrado, não por dia da semana")
        void mediaPorDiaRegistrado() {
            // Dividir por sete puniria quem registrou só dois dias com uma média falsa de
            // "1000 kcal/dia".
            final Result result = compute(List.of(), List.of(), List.of(), List.of(
                    new MealInput(WEEK, BigDecimal.valueOf(600)),
                    new MealInput(WEEK, BigDecimal.valueOf(900)),
                    new MealInput(WEEK.plusDays(1), BigDecimal.valueOf(2000))));

            assertThat(result.mealsLogged()).isEqualTo(3);
            assertThat(result.daysWithMealLogged()).isEqualTo(2);
            // (600 + 900 + 2000) / 2 dias
            assertThat(result.avgKcalPerLoggedDay()).isEqualByComparingTo("1750");
        }

        @Test
        @DisplayName("sem refeição registrada, não há média")
        void semRefeicao() {
            final Result result = compute(List.of(), List.of(), List.of(), List.of());

            assertThat(result.mealsLogged()).isZero();
            assertThat(result.avgKcalPerLoggedDay()).isNull();
        }
    }

    @Test
    @DisplayName("semana totalmente vazia não quebra nem inventa número")
    void semanaVazia() {
        final Result result = compute(List.of(), List.of(), List.of(), List.of());

        assertThat(result.weekStart()).isEqualTo(WEEK);
        assertThat(result.sessions()).isZero();
        assertThat(result.totalVolumeKg()).isEqualByComparingTo("0.0");
        assertThat(result.topExercise()).isNull();
        assertThat(result.weightStartKg()).isNull();
        assertThat(result.volumeChangePercent()).isNull();
    }
}
