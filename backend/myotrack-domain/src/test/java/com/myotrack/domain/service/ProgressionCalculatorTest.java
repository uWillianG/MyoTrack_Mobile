package com.myotrack.domain.service;

import static org.assertj.core.api.Assertions.assertThat;

import com.myotrack.domain.MuscleGroup;
import java.math.BigDecimal;
import java.util.List;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.CsvSource;

/** Porte de MyoTrack.Tests/ProgressionCalculatorTests.cs. */
class ProgressionCalculatorTest {

    private static SetPerformance set(int reps, String loadKg) {
        return new SetPerformance(reps, new BigDecimal(loadKg));
    }

    @Test
    void e1rmEpley() {
        // 100 * (1 + 8/30) = 126.666… → 126.7
        assertThat(ProgressionCalculator.estimateOneRepMax(8, new BigDecimal("100")))
                .isEqualByComparingTo("126.7");
    }

    @Test
    @DisplayName("Uma repetição única já é o 1RM")
    void e1rmSingleRepIsTheLoadItself() {
        assertThat(ProgressionCalculator.estimateOneRepMax(1, new BigDecimal("100")))
                .isEqualByComparingTo("100");
    }

    @ParameterizedTest
    @CsvSource({ "13, 100", "0, 100", "8, 0" })
    void e1rmOutOfRangeReturnsNull(int reps, String load) {
        assertThat(ProgressionCalculator.estimateOneRepMax(reps, new BigDecimal(load))).isNull();
    }

    @ParameterizedTest
    @CsvSource({
        "QUADRICEPS, 5",
        "GLUTES, 5",
        "LOWER_BACK, 5",
        "CHEST, 2.5",
        "BICEPS, 2.5"
    })
    void incrementByMuscleGroup(MuscleGroup group, String expected) {
        assertThat(ProgressionCalculator.incrementFor(group)).isEqualByComparingTo(expected);
    }

    @Test
    void noHistorySuggestsStart() {
        ProgressionSuggestion s = ProgressionCalculator.suggest(List.of(), 8, 12, new BigDecimal("2.5"));
        assertThat(s.action()).isEqualTo(ProgressionAction.START);
        assertThat(s.nextLoadKg()).isNull();
        assertThat(s.targetReps()).isEqualTo(8);
    }

    @Test
    @DisplayName("Todas as séries no teto da faixa sobem a carga e voltam ao piso de reps")
    void allSetsAtTopOfRangeSuggestsIncrease() {
        ProgressionSuggestion s = ProgressionCalculator.suggest(
                List.of(set(12, "40"), set(12, "40"), set(13, "40")), 8, 12, new BigDecimal("2.5"));

        assertThat(s.action()).isEqualTo(ProgressionAction.INCREASE);
        assertThat(s.nextLoadKg()).isEqualByComparingTo("42.5");
        assertThat(s.targetReps()).isEqualTo(8);
    }

    @Test
    void withinRangeSuggestsProgressReps() {
        ProgressionSuggestion s = ProgressionCalculator.suggest(
                List.of(set(12, "40"), set(10, "40"), set(9, "40")), 8, 12, new BigDecimal("2.5"));

        assertThat(s.action()).isEqualTo(ProgressionAction.PROGRESS_REPS);
        assertThat(s.nextLoadKg()).isEqualByComparingTo("40");
        assertThat(s.targetReps()).isEqualTo(12);
    }

    @Test
    void belowMinimumSuggestsConsolidate() {
        ProgressionSuggestion s = ProgressionCalculator.suggest(
                List.of(set(8, "40"), set(7, "40"), set(6, "40")), 8, 12, new BigDecimal("2.5"));

        assertThat(s.action()).isEqualTo(ProgressionAction.CONSOLIDATE);
        assertThat(s.nextLoadKg()).isEqualByComparingTo("40");
        assertThat(s.targetReps()).isEqualTo(8);
    }

    @Test
    @DisplayName("Séries de aquecimento não bloqueiam a progressão")
    void warmupSetsDoNotBlockIncrease() {
        // Só as séries na carga de trabalho (a maior) contam.
        ProgressionSuggestion s = ProgressionCalculator.suggest(
                List.of(set(15, "20"), set(12, "40"), set(12, "40")), 8, 12, new BigDecimal("2.5"));

        assertThat(s.action()).isEqualTo(ProgressionAction.INCREASE);
        assertThat(s.nextLoadKg()).isEqualByComparingTo("42.5");
    }
}
