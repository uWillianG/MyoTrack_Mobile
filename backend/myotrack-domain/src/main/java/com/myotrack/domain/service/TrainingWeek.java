package com.myotrack.domain.service;

import java.time.DayOfWeek;
import java.time.LocalDate;

/**
 * A semana de treino: segunda a domingo.
 *
 * <p>Existe para haver <b>uma</b> definição de "começo da semana" no sistema. Ela aparece em
 * lugares que precisam concordar — o gráfico de volume por semana, o agendador do relatório e o
 * handler que o gera — e são justamente os que o usuário compara entre si. Duas
 * implementações que divergissem num domingo fariam o relatório da semana e o gráfico da
 * semana somarem treinos diferentes, sem nada indicando qual estava certo.
 *
 * <p>Segunda-feira e não domingo porque é assim que se conta bloco de treino, e é o que a SPA
 * já fazia.
 */
public final class TrainingWeek {

    private TrainingWeek() {
    }

    /** Segunda-feira da semana que contém a data. */
    public static LocalDate startOf(LocalDate date) {
        return date.minusDays(date.getDayOfWeek().getValue() - DayOfWeek.MONDAY.getValue());
    }
}
