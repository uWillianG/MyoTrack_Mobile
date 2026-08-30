package com.myotrack.domain;

import com.fasterxml.jackson.annotation.JsonCreator;
import com.fasterxml.jackson.annotation.JsonValue;

public enum AnalysisJobType implements WireEnum {

    WORKOUT_GENERATION(1, "WorkoutGeneration"),
    DIET_GENERATION(2, "DietGeneration"),
    MEAL_PHOTO(3, "MealPhoto"),
    EXERCISE_VIDEO(4, "ExerciseVideo"),
    COACH_CHAT(5, "CoachChat"),
    WEEKLY_REPORT(6, "WeeklyReport");

    private final int value;
    private final String wireName;

    AnalysisJobType(int value, String wireName) {
        this.value = value;
        this.wireName = wireName;
    }

    @Override
    public int getValue() {
        return value;
    }

    @Override
    @JsonValue
    public String getWireName() {
        return wireName;
    }

    @JsonCreator
    public static AnalysisJobType fromWireName(String name) {
        return WireEnums.fromWireName(AnalysisJobType.class, name);
    }

    public static AnalysisJobType fromValue(int value) {
        return WireEnums.fromValue(AnalysisJobType.class, value);
    }

    /**
     * Alguém está parado numa tela esperando este job terminar.
     *
     * <p>É o que decide se vale reprocessar a falha. Para um job de fundo, uma segunda tentativa
     * é grátis: ninguém percebe a demora e a oscilação de rede que derrubou a primeira
     * provavelmente já passou. Para um job interativo o cálculo se inverte — o app acompanha por
     * SSE sem prazo, então cada tentativa extra é a barra girando por mais um teto de chamada de
     * IA, e ao fim de três a pessoa esperou minutos para ler o mesmo erro que estava pronto no
     * primeiro segundo. Errar depressa devolve a decisão a quem pode tomá-la: tentar de novo,
     * corrigir a frase, ou desistir.
     *
     * <p>O relatório semanal é o único de fundo. Ele nasce do agendador noturno, e mesmo quando
     * o usuário o pede pelo botão a tela não espera por ele — avisa que o pedido entrou na fila
     * e mostra o relatório quando ele aparecer.
     *
     * <p>Switch exaustivo de propósito: um tipo novo não compila sem que alguém responda a esta
     * pergunta, que é a diferença entre desistir cedo demais e prender uma tela por minutos.
     */
    public boolean isInteractive() {
        return switch (this) {
            case WORKOUT_GENERATION, DIET_GENERATION, MEAL_PHOTO, EXERCISE_VIDEO, COACH_CHAT ->
                    true;
            case WEEKLY_REPORT -> false;
        };
    }
}
