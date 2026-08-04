package com.myotrack.domain.service;

import java.time.LocalDate;
import java.util.Collection;
import java.util.Set;
import java.util.stream.Collectors;

/**
 * Quantas semanas seguidas o usuário treinou, contando de trás para frente.
 *
 * <p><b>Vive no domínio, e não no app, porque agora vale dinheiro.</b> Enquanto a sequência só
 * pintava um selo, calculá-la em Dart a partir de {@code /api/progress/volume} era barato e
 * inofensivo. Desde que ela passou a conceder Pro, quem a calcula precisa ser quem paga por
 * ela: um cliente que afirma "tenho doze semanas" é um cliente que qualquer pessoa com um
 * proxy HTTP reescreve. O app continua exibindo a sequência — mas exibe o número que <b>este
 * método</b> devolveu.
 *
 * <p>Fica ao lado de {@link TrainingWeek} pelo mesmo motivo que ele existe: uma definição só de
 * "semana" no sistema inteiro.
 */
public final class TrainingStreak {

    private TrainingStreak() {
    }

    /**
     * A sequência que termina na semana de {@code today}.
     *
     * <p>A semana corrente <b>só quebra a sequência depois de terminar</b>. Numa segunda-feira
     * de manhã ela está vazia por definição, e contá-la como falha zeraria a sequência de
     * alguém que não fez nada de errado — apenas ainda não treinou hoje. Um buraco em qualquer
     * semana anterior, esse sim, encerra a contagem.
     *
     * @param sessionDates datas de treino, em qualquer ordem; repetidas não contam duas vezes
     * @param today a data de referência, injetada para o cálculo ser testável sem relógio
     */
    public static int weeks(Collection<LocalDate> sessionDates, LocalDate today) {
        if (sessionDates == null || sessionDates.isEmpty() || today == null) {
            return 0;
        }

        final Set<LocalDate> trainedWeeks = sessionDates.stream()
                .filter(java.util.Objects::nonNull)
                .map(TrainingWeek::startOf)
                .collect(Collectors.toSet());

        final LocalDate currentWeek = TrainingWeek.startOf(today);
        int streak = 0;
        LocalDate week = currentWeek;

        // A semana corrente vazia é pulada uma única vez; da anterior em diante, vazio é fim.
        if (!trainedWeeks.contains(week)) {
            week = week.minusWeeks(1);
        }

        while (trainedWeeks.contains(week)) {
            streak++;
            week = week.minusWeeks(1);
        }

        return streak;
    }
}
