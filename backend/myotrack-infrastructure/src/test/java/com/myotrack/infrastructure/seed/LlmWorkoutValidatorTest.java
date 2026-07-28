package com.myotrack.infrastructure.seed;

import static org.assertj.core.api.Assertions.assertThat;

import com.myotrack.domain.ExperienceLevel;
import com.myotrack.domain.FitnessGoal;
import com.myotrack.domain.entity.Exercise;
import com.myotrack.domain.service.LlmWorkoutValidator;
import com.myotrack.domain.service.LlmWorkoutValidator.LlmDay;
import com.myotrack.domain.service.LlmWorkoutValidator.LlmExercise;
import com.myotrack.domain.service.LlmWorkoutValidator.LlmWorkout;
import com.myotrack.domain.service.WorkoutGeneration.GeneratedWorkout;
import com.myotrack.domain.service.WorkoutGeneration.Input;
import com.myotrack.domain.service.WorkoutRuleEngine;
import java.util.ArrayList;
import java.util.List;
import java.util.Optional;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.CsvSource;

/**
 * A saída do LLM é tratada como entrada não confiável. Reprovar é sempre seguro — o chamador
 * fica com o esqueleto por regras, que já é um treino válido. O que não pode acontecer é uma
 * proposta inválida virar plano.
 */
class LlmWorkoutValidatorTest {

    private List<Exercise> catalog;
    private GeneratedWorkout skeleton;

    private static List<Exercise> catalogWithIds() {
        final List<Exercise> items = ExerciseSeed.items();
        for (int i = 0; i < items.size(); i++) {
            items.get(i).setId(i + 1);
        }
        return items;
    }

    @BeforeEach
    void setUp() {
        catalog = catalogWithIds();
        skeleton = WorkoutRuleEngine.generate(
                new Input(FitnessGoal.HYPERTROPHY, ExperienceLevel.INTERMEDIATE, 3,
                        List.of(), List.of(), List.of()),
                catalog);
    }

    /** Converte o esqueleto numa proposta idêntica — o caso "o LLM não mudou nada". */
    private LlmWorkout proposalFromSkeleton() {
        final List<LlmDay> days = new ArrayList<>();
        for (final var day : skeleton.days()) {
            final List<LlmExercise> exercises = day.exercises().stream()
                    .map(e -> new LlmExercise(
                            e.exerciseId(), e.sets(), e.repsMin(), e.repsMax(),
                            e.restSeconds(), e.notes()))
                    .toList();
            days.add(new LlmDay(day.order(), day.label(), exercises));
        }
        return new LlmWorkout(days);
    }

    private Optional<GeneratedWorkout> validate(LlmWorkout proposal) {
        return LlmWorkoutValidator.validate(proposal, skeleton, catalog, List.of());
    }

    @Test
    @DisplayName("Proposta válida é aceita e mantém o split do esqueleto")
    void acceptsValidProposal() {
        final Optional<GeneratedWorkout> result = validate(proposalFromSkeleton());

        assertThat(result).isPresent();
        assertThat(result.get().split()).isEqualTo(skeleton.split());
        assertThat(result.get().days()).hasSameSizeAs(skeleton.days());
    }

    @Test
    @DisplayName("exerciseId inexistente reprova — o modelo inventou um exercício")
    void rejectsUnknownExerciseId() {
        final var proposal = new LlmWorkout(List.of(
                new LlmDay(1, "A", List.of(new LlmExercise(999_999, 3, 8, 12, 90, null))),
                new LlmDay(2, "B", List.of(new LlmExercise(1, 3, 8, 12, 90, null))),
                new LlmDay(3, "C", List.of(new LlmExercise(1, 3, 8, 12, 90, null)))));

        assertThat(validate(proposal)).isEmpty();
    }

    @Test
    @DisplayName("Exercício contraindicado reprova, mesmo existindo no catálogo")
    void rejectsContraindicatedExercise() {
        // "Agachamento livre com barra" tem a tag knee.
        final Exercise agachamento = catalog.stream()
                .filter(e -> e.getName().startsWith("Agachamento livre"))
                .findFirst()
                .orElseThrow();
        assertThat(agachamento.getContraindicationTags()).contains("knee");

        final var proposal = new LlmWorkout(List.of(
                new LlmDay(1, "A", List.of(new LlmExercise(agachamento.getId(), 3, 8, 12, 90, null))),
                new LlmDay(2, "B", List.of(new LlmExercise(1, 3, 8, 12, 90, null))),
                new LlmDay(3, "C", List.of(new LlmExercise(1, 3, 8, 12, 90, null)))));

        // Sem lesão declarada, passa.
        assertThat(LlmWorkoutValidator.validate(proposal, skeleton, catalog, List.of())).isPresent();

        // Com lesão no joelho, o mesmo exercício reprova a proposta inteira.
        assertThat(LlmWorkoutValidator.validate(proposal, skeleton, catalog, List.of("knee")))
                .isEmpty();
        // A comparação ignora caixa — a tag pode vir em qualquer formato do perfil.
        assertThat(LlmWorkoutValidator.validate(proposal, skeleton, catalog, List.of("KNEE")))
                .isEmpty();
    }

    @ParameterizedTest
    @CsvSource({
        // séries fora de 2..5
        "1, 8, 12, 90",
        "6, 8, 12, 90",
        "0, 8, 12, 90",
        // repetições fora de 5..30
        "3, 4, 12, 90",
        "3, 8, 31, 90",
        // faixa invertida
        "3, 12, 8, 90",
        // descanso fora de 30..240
        "3, 8, 12, 29",
        "3, 8, 12, 241",
    })
    @DisplayName("Valores fora das faixas seguras reprovam")
    void rejectsOutOfRangeValues(int sets, int repsMin, int repsMax, int rest) {
        final var proposal = new LlmWorkout(List.of(
                new LlmDay(1, "A", List.of(new LlmExercise(1, sets, repsMin, repsMax, rest, null))),
                new LlmDay(2, "B", List.of(new LlmExercise(1, 3, 8, 12, 90, null))),
                new LlmDay(3, "C", List.of(new LlmExercise(1, 3, 8, 12, 90, null)))));

        assertThat(validate(proposal)).isEmpty();
    }

    @Test
    @DisplayName("Número de dias diferente reprova — quebraria o split combinado no onboarding")
    void rejectsDifferentDayCount() {
        final var doisDias = new LlmWorkout(List.of(
                new LlmDay(1, "A", List.of(new LlmExercise(1, 3, 8, 12, 90, null))),
                new LlmDay(2, "B", List.of(new LlmExercise(1, 3, 8, 12, 90, null)))));

        assertThat(validate(doisDias)).isEmpty();
    }

    @Test
    void rejectsEmptyDay() {
        final var proposal = new LlmWorkout(List.of(
                new LlmDay(1, "A", List.of()),
                new LlmDay(2, "B", List.of(new LlmExercise(1, 3, 8, 12, 90, null))),
                new LlmDay(3, "C", List.of(new LlmExercise(1, 3, 8, 12, 90, null)))));

        assertThat(validate(proposal)).isEmpty();
    }

    @Test
    void rejectsNullProposalOrDays() {
        assertThat(validate(null)).isEmpty();
        assertThat(validate(new LlmWorkout(null))).isEmpty();
    }

    @Test
    @DisplayName("O nome do exercício vem do catálogo, não do modelo")
    void exerciseNameComesFromCatalog() {
        final Exercise first = catalog.get(0);
        final var proposal = new LlmWorkout(List.of(
                new LlmDay(1, "A", List.of(new LlmExercise(first.getId(), 3, 8, 12, 90, "obs"))),
                new LlmDay(2, "B", List.of(new LlmExercise(first.getId(), 3, 8, 12, 90, null))),
                new LlmDay(3, "C", List.of(new LlmExercise(first.getId(), 3, 8, 12, 90, null)))));

        final var result = validate(proposal).orElseThrow();

        // Mostrar um nome inventado ao lado de um id real confundiria quem está treinando.
        assertThat(result.days().get(0).exercises().get(0).name()).isEqualTo(first.getName());
        // As observações do modelo são preservadas — é o valor que ele agrega.
        assertThat(result.days().get(0).exercises().get(0).notes()).isEqualTo("obs");
    }

    @Test
    @DisplayName("Rótulo em branco ganha um padrão em vez de ir vazio para a tela")
    void blankLabelGetsDefault() {
        final var proposal = new LlmWorkout(List.of(
                new LlmDay(1, "  ", List.of(new LlmExercise(1, 3, 8, 12, 90, null))),
                new LlmDay(2, null, List.of(new LlmExercise(1, 3, 8, 12, 90, null))),
                new LlmDay(3, "C", List.of(new LlmExercise(1, 3, 8, 12, 90, null)))));

        final var result = validate(proposal).orElseThrow();

        assertThat(result.days().get(0).label()).isEqualTo("Dia 1");
        assertThat(result.days().get(1).label()).isEqualTo("Dia 2");
        assertThat(result.days().get(2).label()).isEqualTo("C");
    }

    @Test
    @DisplayName("Dias fora de ordem são reordenados")
    void daysAreSortedByOrder() {
        final var proposal = new LlmWorkout(List.of(
                new LlmDay(3, "C", List.of(new LlmExercise(1, 3, 8, 12, 90, null))),
                new LlmDay(1, "A", List.of(new LlmExercise(1, 3, 8, 12, 90, null))),
                new LlmDay(2, "B", List.of(new LlmExercise(1, 3, 8, 12, 90, null)))));

        final var result = validate(proposal).orElseThrow();

        assertThat(result.days().stream().map(d -> d.label())).containsExactly("A", "B", "C");
    }

    @Test
    @DisplayName("Os limites das faixas são inclusivos")
    void boundariesAreInclusive() {
        final var proposal = new LlmWorkout(List.of(
                new LlmDay(1, "A", List.of(new LlmExercise(1, 2, 5, 30, 30, null))),
                new LlmDay(2, "B", List.of(new LlmExercise(1, 5, 5, 30, 240, null))),
                new LlmDay(3, "C", List.of(new LlmExercise(1, 3, 8, 12, 90, null)))));

        assertThat(validate(proposal)).isPresent();
    }
}
