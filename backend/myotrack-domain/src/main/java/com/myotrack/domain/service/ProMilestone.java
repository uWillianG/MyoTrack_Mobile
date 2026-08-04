package com.myotrack.domain.service;

import java.util.Arrays;
import java.util.List;
import java.util.Optional;

/**
 * As marcas de constância que rendem Pro, e por quantos dias.
 *
 * <p><b>Só constância de treino.</b> Aderência à dieta ficou de fora de propósito: a régua da
 * nutrição é o consumo declarado pelo próprio usuário, e pendurar valor econômico nela cria o
 * incentivo exato que um produto de saúde não pode criar — registrar refeição que não houve,
 * ou restringir para bater a faixa. Semana treinada é um comportamento que só melhora
 * repetindo, e é verificável contra sessões que o servidor guardou.
 *
 * <p>O identificador espelha o do catálogo de conquistas do app. Renomear um deles quebra a
 * correspondência entre o selo que a pessoa vê e a concessão que o servidor registrou.
 */
public enum ProMilestone {

    /** Quatro semanas seguidas: uma semana de Pro. O gosto, não o prêmio. */
    FOUR_WEEKS("quatro-semanas", 4, 7),

    /** Doze semanas seguidas — um bloco de treino inteiro: um mês de Pro. */
    TWELVE_WEEKS("doze-semanas", 12, 30);

    private final String id;
    private final int requiredWeeks;
    private final int proDays;

    ProMilestone(String id, int requiredWeeks, int proDays) {
        this.id = id;
        this.requiredWeeks = requiredWeeks;
        this.proDays = proDays;
    }

    public String id() {
        return id;
    }

    public int requiredWeeks() {
        return requiredWeeks;
    }

    public int proDays() {
        return proDays;
    }

    public boolean reachedBy(int streakWeeks) {
        return streakWeeks >= requiredWeeks;
    }

    public static Optional<ProMilestone> byId(String id) {
        return Arrays.stream(values()).filter(m -> m.id.equals(id)).findFirst();
    }

    /** Da mais fácil para a mais difícil — a ordem em que se conquistam. */
    public static List<ProMilestone> ordered() {
        return Arrays.stream(values())
                .sorted(java.util.Comparator.comparingInt(ProMilestone::requiredWeeks))
                .toList();
    }
}
