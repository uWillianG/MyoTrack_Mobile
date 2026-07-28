package com.myotrack.domain.service;

import static org.assertj.core.api.Assertions.assertThat;

import com.myotrack.domain.CalorieGoal;
import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.LocalDate;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.CsvSource;

/**
 * Porte de MyoTrack.Tests/TdeeCalculatorTests.cs. Os valores esperados são os mesmos —
 * é o que prova que a reescrita não mexeu na prescrição.
 *
 * <p>As comparações usam {@code isEqualByComparingTo} porque {@code BigDecimal.equals} leva a
 * escala em conta e {@code 1780} não seria igual a {@code 1780.00}; o decimal do C# ignora isso.
 */
class TdeeCalculatorTest {

    @Test
    @DisplayName("TMB masculina por Mifflin-St Jeor")
    void bmrMifflinStJeorMale() {
        // 10*80 + 6.25*180 - 5*30 + 5 = 800 + 1125 - 150 + 5
        BigDecimal bmr = TdeeCalculator.calculateBmr("M", new BigDecimal("80"), new BigDecimal("180"), 30);
        assertThat(bmr).isEqualByComparingTo("1780");
    }

    @Test
    @DisplayName("TMB feminina por Mifflin-St Jeor")
    void bmrMifflinStJeorFemale() {
        // 10*60 + 6.25*165 - 5*25 - 161
        BigDecimal bmr = TdeeCalculator.calculateBmr("F", new BigDecimal("60"), new BigDecimal("165"), 25);
        assertThat(bmr).isEqualByComparingTo("1345.25");
    }

    @ParameterizedTest
    @CsvSource({ "0, 1.2", "3, 1.375", "5, 1.55", "6, 1.725" })
    void activityFactorByTrainingDays(int days, String expected) {
        assertThat(TdeeCalculator.activityFactor(days)).isEqualByComparingTo(expected);
    }

    @Test
    void deficitReduces20Percent() {
        MacroTargets targets = TdeeCalculator.calculateTargets(
                "M", new BigDecimal("80"), new BigDecimal("180"), 30, 4, CalorieGoal.DEFICIT);
        BigDecimal tdee = TdeeCalculator.calculateTdee("M", new BigDecimal("80"), new BigDecimal("180"), 30, 4);

        BigDecimal expected = tdee.multiply(new BigDecimal("0.80")).setScale(0, RoundingMode.HALF_EVEN);
        assertThat(targets.kcal()).isEqualByComparingTo(expected);
    }

    @Test
    @DisplayName("Déficit nunca prescreve abaixo da TMB")
    void deficitNeverGoesBelowBmr() {
        // Pessoa leve e sedentária: 80% do TDEE ficaria abaixo da TMB sem o guard-rail.
        MacroTargets targets = TdeeCalculator.calculateTargets(
                "F", new BigDecimal("50"), new BigDecimal("160"), 40, 0, CalorieGoal.DEFICIT);
        BigDecimal bmr = TdeeCalculator.calculateBmr("F", new BigDecimal("50"), new BigDecimal("160"), 40);

        BigDecimal floor = bmr.setScale(0, RoundingMode.HALF_EVEN).subtract(BigDecimal.ONE);
        assertThat(targets.kcal()).isGreaterThanOrEqualTo(floor);
    }

    @Test
    void deficitProteinIs2gPerKg() {
        MacroTargets targets = TdeeCalculator.calculateTargets(
                "M", new BigDecimal("80"), new BigDecimal("180"), 30, 4, CalorieGoal.DEFICIT);
        assertThat(targets.proteinG()).isEqualByComparingTo("160");
    }

    @Test
    @DisplayName("Soma dos macros fica a ±3% das kcal alvo")
    void macrosSumApproximatesKcal() {
        MacroTargets t = TdeeCalculator.calculateTargets(
                "M", new BigDecimal("80"), new BigDecimal("180"), 30, 4, CalorieGoal.MAINTENANCE);

        BigDecimal kcalFromMacros = t.proteinG().multiply(BigDecimal.valueOf(4))
                .add(t.carbsG().multiply(BigDecimal.valueOf(4)))
                .add(t.fatG().multiply(BigDecimal.valueOf(9)));

        assertThat(kcalFromMacros)
                .isBetween(t.kcal().multiply(new BigDecimal("0.97")), t.kcal().multiply(new BigDecimal("1.03")));
    }

    @Test
    @DisplayName("Idade desconta o aniversário ainda não ocorrido no ano")
    void ageRespectsBirthdayNotYetReached() {
        assertThat(TdeeCalculator.calculateAge(LocalDate.of(1996, 12, 1), LocalDate.of(2026, 7, 12))).isEqualTo(29);
        assertThat(TdeeCalculator.calculateAge(LocalDate.of(1996, 7, 12), LocalDate.of(2026, 7, 12))).isEqualTo(30);
    }
}
