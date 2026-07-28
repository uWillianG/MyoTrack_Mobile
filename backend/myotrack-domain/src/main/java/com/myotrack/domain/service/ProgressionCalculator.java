package com.myotrack.domain.service;

import com.myotrack.domain.MuscleGroup;
import java.math.BigDecimal;
import java.math.MathContext;
import java.math.RoundingMode;
import java.util.List;

/**
 * Progressão de carga por dupla progressão, calculada em código (nunca LLM):
 * primeiro progridem as repetições dentro da faixa do plano; ao fechar todas
 * as séries no teto, sobe a carga um incremento e volta ao piso de repetições.
 *
 * <p>Porte de MyoTrack.Domain/Services/ProgressionCalculator.cs.
 */
public final class ProgressionCalculator {

    private static final MathContext MC = MathContext.DECIMAL128;
    private static final BigDecimal THIRTY = BigDecimal.valueOf(30);

    /** Membros inferiores e levantamentos de corpo inteiro toleram saltos maiores. */
    private static final BigDecimal INCREMENT_LOWER_BODY = new BigDecimal("5");
    private static final BigDecimal INCREMENT_UPPER_BODY = new BigDecimal("2.5");

    private ProgressionCalculator() {
    }

    /**
     * 1RM estimado (fórmula de Epley). Null acima de 12 repetições — a
     * estimativa perde sentido em séries longas.
     */
    public static BigDecimal estimateOneRepMax(int reps, BigDecimal loadKg) {
        if (reps < 1 || reps > 12 || loadKg == null || loadKg.signum() <= 0) {
            return null;
        }
        // Uma repetição única já É o 1RM — Epley superestimaria (carga × 1,033).
        if (reps == 1) {
            return loadKg;
        }
        BigDecimal factor = BigDecimal.ONE.add(BigDecimal.valueOf(reps).divide(THIRTY, MC), MC);
        return loadKg.multiply(factor, MC).setScale(1, RoundingMode.HALF_EVEN);
    }

    /**
     * Incremento conservador por grupo muscular: membros inferiores e levantamentos
     * de corpo inteiro toleram saltos maiores que os pequenos grupos do tronco.
     */
    public static BigDecimal incrementFor(MuscleGroup group) {
        return switch (group) {
            case QUADRICEPS, HAMSTRINGS, GLUTES, CALVES, LOWER_BACK, FULL_BODY -> INCREMENT_LOWER_BODY;
            default -> INCREMENT_UPPER_BODY;
        };
    }

    public static ProgressionSuggestion suggest(
            List<SetPerformance> lastSets, int repsMin, int repsMax, BigDecimal incrementKg) {

        if (lastSets == null || lastSets.isEmpty()) {
            return new ProgressionSuggestion(ProgressionAction.START, null, repsMin);
        }

        // Carga de trabalho da sessão: a maior usada (séries de aquecimento não atrapalham).
        BigDecimal load = lastSets.stream()
                .map(SetPerformance::loadKg)
                .max(BigDecimal::compareTo)
                .orElseThrow();

        List<SetPerformance> workSets = lastSets.stream()
                .filter(s -> s.loadKg().compareTo(load) == 0)
                .toList();

        if (workSets.stream().allMatch(s -> s.reps() >= repsMax)) {
            return new ProgressionSuggestion(ProgressionAction.INCREASE, load.add(incrementKg, MC), repsMin);
        }
        if (workSets.stream().allMatch(s -> s.reps() >= repsMin)) {
            return new ProgressionSuggestion(ProgressionAction.PROGRESS_REPS, load, repsMax);
        }
        return new ProgressionSuggestion(ProgressionAction.CONSOLIDATE, load, repsMin);
    }
}
