package com.myotrack.domain.service;

import java.math.BigDecimal;
import java.math.MathContext;
import java.math.RoundingMode;
import java.time.LocalDate;
import java.util.Comparator;
import java.util.HashSet;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Set;

/**
 * Números da semana, calculados em código.
 *
 * <p>Mesma divisão de responsabilidades da geração de dieta: <b>os números são do código, a
 * narrativa é do LLM</b>. O modelo escreve o texto que comenta a semana, mas nunca produz uma
 * das métricas — um relatório dizendo "você levantou 12% a mais" com um número estimado por IA
 * seria pior que relatório nenhum, porque o usuário não teria como desconfiar dele.
 *
 * <p>Recebe listas simples, e não entidades, para poder ser testado sem banco.
 */
public final class WeeklyMetrics {

    private static final MathContext MC = MathContext.DECIMAL128;

    private static final BigDecimal HUNDRED = BigDecimal.valueOf(100);

    private WeeklyMetrics() {
    }

    /** Uma sessão de treino reduzida ao que a métrica usa. */
    public record SessionInput(LocalDate date, List<SetInput> sets) {
    }

    public record SetInput(String exerciseName, int reps, BigDecimal loadKg) {
    }

    public record WeightInput(LocalDate date, BigDecimal weightKg) {
    }

    /** Uma refeição analisada e não excluída do diário. */
    public record MealInput(LocalDate date, BigDecimal kcal) {
    }

    /**
     * O resultado, pronto para virar o {@code metricsJson} do relatório.
     *
     * @param volumeChangePercent variação contra a semana anterior; null quando não houve
     *     treino na semana anterior — de zero para qualquer coisa não é "aumento de X%"
     * @param weightChangeKg diferença entre a primeira e a última pesagem da semana; null com
     *     menos de duas, porque uma medida só não descreve variação nenhuma
     */
    public record Result(
            LocalDate weekStart,
            int sessions,
            int totalSets,
            BigDecimal totalVolumeKg,
            BigDecimal volumeChangePercent,
            String topExercise,
            BigDecimal topExerciseVolumeKg,
            BigDecimal weightStartKg,
            BigDecimal weightEndKg,
            BigDecimal weightChangeKg,
            int mealsLogged,
            int daysWithMealLogged,
            BigDecimal avgKcalPerLoggedDay) {
    }

    /**
     * @param weekStart segunda-feira da semana coberta
     * @param sessions sessões da semana
     * @param previousSessions sessões da semana anterior, só para a comparação de volume
     * @param weights pesagens da semana, em qualquer ordem
     * @param meals refeições da semana já filtradas (as excluídas do diário não entram)
     */
    public static Result compute(
            LocalDate weekStart,
            List<SessionInput> sessions,
            List<SessionInput> previousSessions,
            List<WeightInput> weights,
            List<MealInput> meals) {

        final BigDecimal volume = totalVolume(sessions);
        final BigDecimal previousVolume = totalVolume(previousSessions);

        final Map<String, BigDecimal> byExercise = volumeByExercise(sessions);
        final Map.Entry<String, BigDecimal> top = byExercise.entrySet().stream()
                .max(Map.Entry.comparingByValue())
                .orElse(null);

        final List<WeightInput> ordered = weights.stream()
                .filter(w -> w.weightKg() != null && w.weightKg().signum() > 0)
                .sorted(Comparator.comparing(WeightInput::date))
                .toList();

        final BigDecimal first = ordered.isEmpty() ? null : ordered.getFirst().weightKg();
        final BigDecimal last = ordered.isEmpty() ? null : ordered.getLast().weightKg();

        return new Result(
                weekStart,
                sessions.size(),
                sessions.stream().mapToInt(s -> s.sets().size()).sum(),
                round(volume, 1),
                changePercent(previousVolume, volume),
                top == null ? null : top.getKey(),
                top == null ? null : round(top.getValue(), 1),
                first,
                last,
                ordered.size() < 2 ? null : round(last.subtract(first, MC), 1),
                meals.size(),
                distinctDays(meals),
                averageKcalPerDay(meals));
    }

    private static BigDecimal totalVolume(List<SessionInput> sessions) {
        BigDecimal total = BigDecimal.ZERO;
        for (final SessionInput session : sessions) {
            for (final SetInput set : session.sets()) {
                total = total.add(volumeOf(set), MC);
            }
        }
        return total;
    }

    private static Map<String, BigDecimal> volumeByExercise(List<SessionInput> sessions) {
        final Map<String, BigDecimal> byExercise = new LinkedHashMap<>();
        for (final SessionInput session : sessions) {
            for (final SetInput set : session.sets()) {
                final String name = set.exerciseName() == null ? "" : set.exerciseName().trim();
                if (name.isEmpty()) {
                    continue;
                }
                byExercise.merge(name, volumeOf(set), (a, b) -> a.add(b, MC));
            }
        }
        return byExercise;
    }

    /** Repetições × carga. Peso corporal (carga zero) não soma volume, mas a série existiu. */
    private static BigDecimal volumeOf(SetInput set) {
        final BigDecimal load = set.loadKg() == null ? BigDecimal.ZERO : set.loadKg();
        return load.multiply(BigDecimal.valueOf(set.reps()), MC);
    }

    /**
     * Variação percentual de uma semana para a outra.
     *
     * <p>Null quando a base é zero: sair de nenhum treino para algum não é "aumento de X%", é
     * ter voltado a treinar — e é isso que a narrativa deve dizer, em vez de um número que
     * tenderia ao infinito.
     */
    private static BigDecimal changePercent(BigDecimal previous, BigDecimal current) {
        if (previous == null || previous.signum() == 0) {
            return null;
        }
        return round(
                current.subtract(previous, MC).divide(previous, MC).multiply(HUNDRED, MC), 1);
    }

    /**
     * Em quantos dias distintos houve registro de refeição.
     *
     * <p>Conta mais que o total de refeições para medir constância: sete fotos num sábado não
     * são a mesma coisa que uma por dia na semana toda.
     */
    private static int distinctDays(List<MealInput> meals) {
        final Set<LocalDate> days = new HashSet<>();
        for (final MealInput meal : meals) {
            if (meal.date() != null) {
                days.add(meal.date());
            }
        }
        return days.size();
    }

    /**
     * Média de calorias por dia <b>em que houve registro</b>, e não por dia da semana.
     *
     * <p>Dividir por sete puniria quem registrou só três dias com uma média artificialmente
     * baixa, e a leitura "comi 900 kcal por dia" seria falsa.
     */
    private static BigDecimal averageKcalPerDay(List<MealInput> meals) {
        final int days = distinctDays(meals);
        if (days == 0) {
            return null;
        }

        BigDecimal total = BigDecimal.ZERO;
        for (final MealInput meal : meals) {
            if (meal.kcal() != null && meal.kcal().signum() > 0) {
                total = total.add(meal.kcal(), MC);
            }
        }
        return round(total.divide(BigDecimal.valueOf(days), MC), 0);
    }

    private static BigDecimal round(BigDecimal value, int scale) {
        return value.setScale(scale, RoundingMode.HALF_UP);
    }
}
