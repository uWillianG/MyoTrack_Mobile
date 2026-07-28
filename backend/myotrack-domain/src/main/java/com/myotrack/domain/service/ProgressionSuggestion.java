package com.myotrack.domain.service;

import java.math.BigDecimal;

/** Sugestão para a próxima sessão: ação, carga alvo e repetições alvo. */
public record ProgressionSuggestion(ProgressionAction action, BigDecimal nextLoadKg, int targetReps) {
}
