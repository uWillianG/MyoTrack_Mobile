package com.myotrack.domain.service;

import java.math.BigDecimal;

/** Metas diárias calculadas em código — nunca pelo LLM. */
public record MacroTargets(BigDecimal kcal, BigDecimal proteinG, BigDecimal carbsG, BigDecimal fatG) {
}
