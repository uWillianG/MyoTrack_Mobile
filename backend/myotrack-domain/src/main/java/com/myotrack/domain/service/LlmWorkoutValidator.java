package com.myotrack.domain.service;

import com.myotrack.domain.entity.Exercise;
import com.myotrack.domain.service.WorkoutGeneration.GeneratedDay;
import com.myotrack.domain.service.WorkoutGeneration.GeneratedExercise;
import com.myotrack.domain.service.WorkoutGeneration.GeneratedWorkout;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.Optional;
import java.util.function.Function;
import java.util.stream.Collectors;

/**
 * Valida o treino devolvido pelo LLM antes de ele virar plano.
 *
 * <p><b>O modelo é tratado como entrada não confiável.</b> Ele pode inventar um id de
 * exercício, propor 12 séries, sugerir algo contraindicado para a lesão do usuário ou
 * devolver menos dias que o pedido. Nada disso pode chegar ao banco — e o custo de um erro
 * aqui é uma pessoa se machucando, não um dado errado numa tela.
 *
 * <p>Reprovar é sempre seguro: o chamador mantém o esqueleto do {@link WorkoutRuleEngine},
 * que já é um treino válido. Por isso a validação é tudo-ou-nada — um exercício suspeito
 * descarta a resposta inteira em vez de tentar consertá-la.
 */
public final class LlmWorkoutValidator {

    /** Faixas seguras — as mesmas prometidas ao modelo no prompt. */
    private static final int MIN_SETS = 2;
    private static final int MAX_SETS = 5;
    private static final int MIN_REPS = 5;
    private static final int MAX_REPS = 30;
    private static final int MIN_REST_SECONDS = 30;
    private static final int MAX_REST_SECONDS = 240;

    private LlmWorkoutValidator() {
    }

    /** Treino proposto pelo LLM, no formato do JSON Schema pedido a ele. */
    public record LlmWorkout(List<LlmDay> days) {
    }

    public record LlmDay(int order, String label, List<LlmExercise> exercises) {
    }

    public record LlmExercise(
            int exerciseId, int sets, int repsMin, int repsMax, int restSeconds, String notes) {
    }

    /**
     * Devolve o treino validado, ou vazio se a proposta violar qualquer regra.
     *
     * @param proposal o que o LLM respondeu
     * @param skeleton o treino gerado por regras — define o split e o número de dias
     * @param catalog catálogo completo de exercícios
     * @param injuryTags lesões do usuário; exercícios contraindicados são recusados mesmo
     *     que existam no catálogo
     */
    public static Optional<GeneratedWorkout> validate(
            LlmWorkout proposal,
            GeneratedWorkout skeleton,
            List<Exercise> catalog,
            List<String> injuryTags) {

        if (proposal == null || proposal.days() == null) {
            return Optional.empty();
        }
        // Mudar o número de dias quebraria o split acordado com o usuário no onboarding.
        if (proposal.days().size() != skeleton.days().size()) {
            return Optional.empty();
        }

        final List<String> lowerInjuries = injuryTags == null
                ? List.of()
                : injuryTags.stream().map(t -> t.toLowerCase(Locale.ROOT)).toList();

        // O catálogo permitido já exclui o que é contraindicado: assim um id existente mas
        // perigoso para a lesão do usuário também é recusado.
        final Map<Integer, Exercise> allowed = catalog.stream()
                .filter(e -> !hasContraindication(e, lowerInjuries))
                .collect(Collectors.toMap(Exercise::getId, Function.identity()));

        final List<GeneratedDay> days = new ArrayList<>();

        for (final LlmDay day : proposal.days().stream()
                .sorted(Comparator.comparingInt(LlmDay::order))
                .toList()) {

            if (day.exercises() == null || day.exercises().isEmpty()) {
                return Optional.empty();
            }

            final List<GeneratedExercise> exercises = new ArrayList<>();
            for (final LlmExercise e : day.exercises()) {
                final Exercise exercise = allowed.get(e.exerciseId());
                if (exercise == null) {
                    return Optional.empty();
                }
                if (e.sets() < MIN_SETS || e.sets() > MAX_SETS) {
                    return Optional.empty();
                }
                if (e.repsMin() < MIN_REPS || e.repsMax() > MAX_REPS || e.repsMin() > e.repsMax()) {
                    return Optional.empty();
                }
                if (e.restSeconds() < MIN_REST_SECONDS || e.restSeconds() > MAX_REST_SECONDS) {
                    return Optional.empty();
                }

                exercises.add(new GeneratedExercise(
                        e.exerciseId(),
                        // O nome vem do catálogo, não do modelo: exibir um nome inventado ao
                        // lado de um id real confundiria o usuário na hora do treino.
                        exercise.getName(),
                        e.sets(),
                        e.repsMin(),
                        e.repsMax(),
                        e.restSeconds(),
                        e.notes()));
            }

            days.add(new GeneratedDay(
                    day.order(),
                    day.label() == null || day.label().isBlank()
                            ? "Dia %d".formatted(day.order())
                            : day.label(),
                    exercises));
        }

        // O split fica o do esqueleto: quem decide isso são os dias por semana do perfil.
        return Optional.of(new GeneratedWorkout(skeleton.split(), days));
    }

    private static boolean hasContraindication(Exercise exercise, List<String> lowerInjuries) {
        for (final String tag : exercise.getContraindicationTags()) {
            if (lowerInjuries.contains(tag.toLowerCase(Locale.ROOT))) {
                return true;
            }
        }
        return false;
    }
}
