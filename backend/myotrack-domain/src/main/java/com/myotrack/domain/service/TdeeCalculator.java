package com.myotrack.domain.service;

import com.myotrack.domain.CalorieGoal;
import java.math.BigDecimal;
import java.math.MathContext;
import java.math.RoundingMode;
import java.time.LocalDate;

/**
 * Cálculo determinístico de gasto energético e macros — nunca delegado ao LLM.
 * TMB por Mifflin-St Jeor; guard-rail: a meta calórica nunca fica abaixo da TMB.
 *
 * <p>Porte de MyoTrack.Domain/Services/TdeeCalculator.cs. O original usa {@code decimal} do C#,
 * então aqui é {@link BigDecimal} — com {@code double} os arredondamentos divergiriam. Pelo mesmo
 * motivo os arredondamentos usam {@link RoundingMode#HALF_EVEN}, que é o padrão do
 * {@code Math.Round} do .NET.
 */
public final class TdeeCalculator {

    /** ~34 dígitos significativos, o mais próximo dos 28–29 do decimal do C#. */
    private static final MathContext MC = MathContext.DECIMAL128;

    private static final BigDecimal TEN = BigDecimal.valueOf(10);
    private static final BigDecimal SIX_TWENTY_FIVE = new BigDecimal("6.25");
    private static final BigDecimal FIVE = BigDecimal.valueOf(5);
    private static final BigDecimal MALE_OFFSET = BigDecimal.valueOf(5);
    private static final BigDecimal FEMALE_OFFSET = BigDecimal.valueOf(161);

    private static final BigDecimal DEFICIT_FACTOR = new BigDecimal("0.80");
    private static final BigDecimal SURPLUS_FACTOR = new BigDecimal("1.10");
    private static final BigDecimal FAT_SHARE = new BigDecimal("0.25");
    private static final BigDecimal KCAL_PER_G_FAT = BigDecimal.valueOf(9);
    private static final BigDecimal KCAL_PER_G_PROTEIN_CARB = BigDecimal.valueOf(4);
    private static final BigDecimal PROTEIN_PER_KG_DEFICIT = new BigDecimal("2.0");
    private static final BigDecimal PROTEIN_PER_KG_DEFAULT = new BigDecimal("1.8");

    private TdeeCalculator() {
    }

    public static BigDecimal calculateBmr(String sex, BigDecimal weightKg, BigDecimal heightCm, int ageYears) {
        BigDecimal base = TEN.multiply(weightKg, MC)
                .add(SIX_TWENTY_FIVE.multiply(heightCm, MC), MC)
                .subtract(FIVE.multiply(BigDecimal.valueOf(ageYears), MC), MC);
        return "F".equalsIgnoreCase(sex) ? base.subtract(FEMALE_OFFSET, MC) : base.add(MALE_OFFSET, MC);
    }

    /** Fator de atividade aproximado a partir dos dias de treino por semana. */
    public static BigDecimal activityFactor(int trainingDaysPerWeek) {
        if (trainingDaysPerWeek <= 1) {
            return new BigDecimal("1.2");
        }
        if (trainingDaysPerWeek <= 3) {
            return new BigDecimal("1.375");
        }
        if (trainingDaysPerWeek <= 5) {
            return new BigDecimal("1.55");
        }
        return new BigDecimal("1.725");
    }

    public static BigDecimal calculateTdee(
            String sex, BigDecimal weightKg, BigDecimal heightCm, int ageYears, int trainingDaysPerWeek) {
        return calculateBmr(sex, weightKg, heightCm, ageYears)
                .multiply(activityFactor(trainingDaysPerWeek), MC);
    }

    public static MacroTargets calculateTargets(
            String sex,
            BigDecimal weightKg,
            BigDecimal heightCm,
            int ageYears,
            int trainingDaysPerWeek,
            CalorieGoal goal) {

        BigDecimal bmr = calculateBmr(sex, weightKg, heightCm, ageYears);
        BigDecimal tdee = bmr.multiply(activityFactor(trainingDaysPerWeek), MC);

        BigDecimal kcal = switch (goal) {
            case DEFICIT -> tdee.multiply(DEFICIT_FACTOR, MC);
            case SURPLUS -> tdee.multiply(SURPLUS_FACTOR, MC);
            case MAINTENANCE -> tdee;
        };

        // Guard-rail de segurança: nunca prescrever abaixo da TMB.
        kcal = kcal.max(bmr);

        // Proteína 2 g/kg (déficit) ou 1.8 g/kg; gordura 25% das kcal; carbo fecha o restante.
        BigDecimal proteinG = weightKg.multiply(
                goal == CalorieGoal.DEFICIT ? PROTEIN_PER_KG_DEFICIT : PROTEIN_PER_KG_DEFAULT, MC);
        BigDecimal fatG = kcal.multiply(FAT_SHARE, MC).divide(KCAL_PER_G_FAT, MC);
        BigDecimal carbsG = kcal
                .subtract(proteinG.multiply(KCAL_PER_G_PROTEIN_CARB, MC), MC)
                .subtract(fatG.multiply(KCAL_PER_G_FAT, MC), MC)
                .divide(KCAL_PER_G_PROTEIN_CARB, MC)
                .max(BigDecimal.ZERO);

        return new MacroTargets(round0(kcal), round0(proteinG), round0(carbsG), round0(fatG));
    }

    public static int calculateAge(LocalDate birthDate, LocalDate today) {
        int age = today.getYear() - birthDate.getYear();
        if (today.isBefore(birthDate.plusYears(age))) {
            age--;
        }
        return age;
    }

    private static BigDecimal round0(BigDecimal value) {
        return value.setScale(0, RoundingMode.HALF_EVEN);
    }
}
