package com.myotrack.domain.service;

import java.math.BigDecimal;

/** Uma série da última sessão do exercício. */
public record SetPerformance(int reps, BigDecimal loadKg) {
}
