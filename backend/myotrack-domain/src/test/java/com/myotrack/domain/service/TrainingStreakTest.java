package com.myotrack.domain.service;

import static org.assertj.core.api.Assertions.assertThat;

import java.time.LocalDate;
import java.util.List;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

/**
 * Esta contagem concede Pro. Ela erra de dois jeitos e os dois custam: negar o que a pessoa fez,
 * ou conceder um mês de plano pago a quem não fez. O segundo é o caro — e é o que um cliente
 * malicioso tentaria produzir, razão de a conta viver aqui e não no app.
 */
class TrainingStreakTest {

    /** Uma quarta-feira. A semana dela começa em 2026-07-27. */
    private static final LocalDate WEDNESDAY = LocalDate.of(2026, 7, 29);

    private static LocalDate weeksAgo(int weeks) {
        return WEDNESDAY.minusWeeks(weeks);
    }

    @Test
    @DisplayName("sem sessão, sequência zero")
    void empty() {
        assertThat(TrainingStreak.weeks(List.of(), WEDNESDAY)).isZero();
        assertThat(TrainingStreak.weeks(null, WEDNESDAY)).isZero();
    }

    @Test
    @DisplayName("conta semanas seguidas terminando na corrente")
    void consecutive() {
        final List<LocalDate> dates =
                List.of(weeksAgo(0), weeksAgo(1), weeksAgo(2), weeksAgo(3));

        assertThat(TrainingStreak.weeks(dates, WEDNESDAY)).isEqualTo(4);
    }

    @Test
    @DisplayName("a semana corrente ainda vazia não quebra a sequência")
    void currentWeekEmpty() {
        // É segunda de manhã: a semana corrente está zerada por definição, e as cinco
        // anteriores tiveram treino. Contá-la como falha zeraria a sequência de quem não fez
        // nada de errado.
        final LocalDate monday = LocalDate.of(2026, 8, 3);
        final List<LocalDate> dates = List.of(
                monday.minusWeeks(1),
                monday.minusWeeks(2),
                monday.minusWeeks(3),
                monday.minusWeeks(4),
                monday.minusWeeks(5));

        assertThat(TrainingStreak.weeks(dates, monday)).isEqualTo(5);
    }

    @Test
    @DisplayName("buraco numa semana anterior encerra a contagem")
    void gapEndsStreak() {
        // Treinou nas semanas 0, 1, 2 — e depois só na 4 e na 5. A sequência é 3.
        final List<LocalDate> dates = List.of(
                weeksAgo(0), weeksAgo(1), weeksAgo(2), weeksAgo(4), weeksAgo(5));

        assertThat(TrainingStreak.weeks(dates, WEDNESDAY)).isEqualTo(3);
    }

    @Test
    @DisplayName("duas semanas de buraco também encerram")
    void twoWeekGap() {
        final List<LocalDate> dates = List.of(weeksAgo(0), weeksAgo(3), weeksAgo(4));

        assertThat(TrainingStreak.weeks(dates, WEDNESDAY)).isEqualTo(1);
    }

    @Test
    @DisplayName("vários treinos na mesma semana contam uma vez")
    void sameWeekCountsOnce() {
        // Três sessões na mesma semana são uma semana treinada — não três.
        final List<LocalDate> dates = List.of(
                LocalDate.of(2026, 7, 27), LocalDate.of(2026, 7, 29), LocalDate.of(2026, 7, 31));

        assertThat(TrainingStreak.weeks(dates, WEDNESDAY)).isEqualTo(1);
    }

    @Test
    @DisplayName("sessão futura não infla a sequência")
    void futureSessionIgnored() {
        // Data adiante da referência não pode estender a contagem para trás: a sequência é
        // sempre a que termina em hoje.
        final List<LocalDate> dates = List.of(weeksAgo(-2), weeksAgo(0), weeksAgo(1));

        assertThat(TrainingStreak.weeks(dates, WEDNESDAY)).isEqualTo(2);
    }

    @Test
    @DisplayName("a virada de ano não quebra a semana")
    void acrossNewYear() {
        // 2025-12-29 é uma segunda; a semana atravessa o ano. Um cálculo por número de semana
        // do calendário erraria aqui.
        final LocalDate jan7 = LocalDate.of(2026, 1, 7);
        final List<LocalDate> dates =
                List.of(LocalDate.of(2026, 1, 5), LocalDate.of(2025, 12, 30));

        assertThat(TrainingStreak.weeks(dates, jan7)).isEqualTo(2);
    }

    @Test
    @DisplayName("as marcas exigem a sequência que anunciam")
    void milestones() {
        assertThat(ProMilestone.FOUR_WEEKS.reachedBy(3)).isFalse();
        assertThat(ProMilestone.FOUR_WEEKS.reachedBy(4)).isTrue();
        assertThat(ProMilestone.TWELVE_WEEKS.reachedBy(11)).isFalse();
        assertThat(ProMilestone.TWELVE_WEEKS.reachedBy(12)).isTrue();
        // A ordem é a de conquista — a tela e a concessão dependem dela.
        assertThat(ProMilestone.ordered())
                .containsExactly(ProMilestone.FOUR_WEEKS, ProMilestone.TWELVE_WEEKS);
    }
}
