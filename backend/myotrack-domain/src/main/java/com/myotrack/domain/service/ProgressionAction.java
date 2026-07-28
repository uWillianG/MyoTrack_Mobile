package com.myotrack.domain.service;

import com.fasterxml.jackson.annotation.JsonCreator;
import com.fasterxml.jackson.annotation.JsonValue;

/** O que fazer com a carga na próxima sessão de um exercício. */
public enum ProgressionAction {

    /** Sem histórico — começar com a carga sugerida do plano. */
    START("Start"),
    /** Fechou todas as séries no teto de repetições — subir a carga. */
    INCREASE("Increase"),
    /** Dentro da faixa — manter a carga e buscar o teto de repetições. */
    PROGRESS_REPS("ProgressReps"),
    /** Alguma série abaixo do mínimo — manter a carga e consolidar. */
    CONSOLIDATE("Consolidate");

    private final String wireName;

    ProgressionAction(String wireName) {
        this.wireName = wireName;
    }

    @JsonValue
    public String getWireName() {
        return wireName;
    }

    @JsonCreator
    public static ProgressionAction fromWireName(String name) {
        for (ProgressionAction candidate : values()) {
            if (candidate.wireName.equalsIgnoreCase(name) || candidate.name().equalsIgnoreCase(name)) {
                return candidate;
            }
        }
        throw new IllegalArgumentException("'%s' não é uma ProgressionAction.".formatted(name));
    }
}
