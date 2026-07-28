package com.myotrack.infrastructure.seed;

import static org.assertj.core.api.Assertions.assertThat;

import com.myotrack.domain.Equipment;
import com.myotrack.domain.ExperienceLevel;
import com.myotrack.domain.FitnessGoal;
import com.myotrack.domain.MuscleGroup;
import com.myotrack.domain.entity.Exercise;
import com.myotrack.domain.service.WorkoutGeneration.GeneratedExercise;
import com.myotrack.domain.service.WorkoutGeneration.GeneratedWorkout;
import com.myotrack.domain.service.WorkoutGeneration.Input;
import com.myotrack.domain.service.WorkoutRuleEngine;
import java.util.List;
import java.util.Map;
import java.util.function.Function;
import java.util.stream.Collectors;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.CsvSource;
import org.junit.jupiter.params.provider.EnumSource;

/**
 * Porte de MyoTrack.Tests/WorkoutRuleEngineTests.cs. Vive no módulo de infrastructure porque
 * depende do seed, exatamente como o projeto de testes do .NET dependia de MyoTrack.Infrastructure.
 */
class WorkoutRuleEngineTest {

    /** O seed não define ids (o banco gera); aqui recebem um sequencial, como no teste original. */
    private static List<Exercise> catalog() {
        List<Exercise> items = ExerciseSeed.items();
        for (int i = 0; i < items.size(); i++) {
            items.get(i).setId(i + 1);
        }
        return items;
    }

    private static Map<Integer, Exercise> catalogById() {
        return catalog().stream().collect(Collectors.toMap(Exercise::getId, Function.identity()));
    }

    private static Input input(int days, ExperienceLevel level, FitnessGoal goal,
            List<String> injuries, List<Equipment> equipment, List<MuscleGroup> priorities) {
        return new Input(goal, level, days, priorities, injuries, equipment);
    }

    private static Input input(int days) {
        return input(days, ExperienceLevel.INTERMEDIATE, FitnessGoal.HYPERTROPHY, List.of(), List.of(), List.of());
    }

    private static List<GeneratedExercise> allExercises(GeneratedWorkout plan) {
        return plan.days().stream().flatMap(d -> d.exercises().stream()).toList();
    }

    @ParameterizedTest
    @CsvSource({ "2, FullBody, 2", "3, ABC, 3", "4, ABCD, 4", "5, PPL, 5", "6, PPL, 5" })
    void splitMatchesDaysPerWeek(int days, String expectedSplit, int expectedDayCount) {
        GeneratedWorkout plan = WorkoutRuleEngine.generate(input(days), catalog());
        assertThat(plan.split()).isEqualTo(expectedSplit);
        assertThat(plan.days()).hasSize(expectedDayCount);
    }

    @Test
    @DisplayName("Tags de lesão excluem os exercícios contraindicados")
    void injuryTagsExcludeContraindicatedExercises() {
        GeneratedWorkout plan = WorkoutRuleEngine.generate(
                input(5, ExperienceLevel.INTERMEDIATE, FitnessGoal.HYPERTROPHY,
                        List.of("knee"), List.of(), List.of()),
                catalog());
        Map<Integer, Exercise> byId = catalogById();

        assertThat(allExercises(plan))
                .noneMatch(e -> List.of(byId.get(e.exerciseId()).getContraindicationTags()).contains("knee"));

        // Ainda deve haver treino de pernas com opções seguras.
        assertThat(plan.days())
                .anyMatch(d -> !d.exercises().isEmpty() && d.label().contains("Legs"));
    }

    @Test
    void equipmentFilterOnlyAllowedEquipmentOrBodyweight() {
        GeneratedWorkout plan = WorkoutRuleEngine.generate(
                input(3, ExperienceLevel.INTERMEDIATE, FitnessGoal.HYPERTROPHY,
                        List.of(), List.of(Equipment.DUMBBELL), List.of()),
                catalog());
        Map<Integer, Exercise> byId = catalogById();

        for (GeneratedExercise e : allExercises(plan)) {
            Equipment eq = byId.get(e.exerciseId()).getEquipment();
            assertThat(eq)
                    .as("%s usa %s, não permitido", e.name(), eq)
                    .isIn(Equipment.DUMBBELL, Equipment.BODYWEIGHT, Equipment.NONE);
        }
    }

    @Test
    void beginnerHasFewerExercisesThanAdvanced() {
        GeneratedWorkout beginner = WorkoutRuleEngine.generate(
                input(3, ExperienceLevel.BEGINNER, FitnessGoal.HYPERTROPHY, List.of(), List.of(), List.of()),
                catalog());
        GeneratedWorkout advanced = WorkoutRuleEngine.generate(
                input(3, ExperienceLevel.ADVANCED, FitnessGoal.HYPERTROPHY, List.of(), List.of(), List.of()),
                catalog());

        assertThat(allExercises(beginner).size()).isLessThan(allExercises(advanced).size());
        assertThat(allExercises(beginner)).allMatch(e -> e.sets() == 3);
        assertThat(allExercises(advanced)).allMatch(e -> e.sets() == 4);
    }

    @Test
    void goalDefinesRepRangeAndRest() {
        GeneratedExercise hypertrophy = WorkoutRuleEngine
                .generate(input(3), catalog())
                .days().get(0).exercises().get(0);
        assertThat(hypertrophy.repsMin()).isEqualTo(8);
        assertThat(hypertrophy.repsMax()).isEqualTo(12);
        assertThat(hypertrophy.restSeconds()).isEqualTo(90);

        GeneratedExercise conditioning = WorkoutRuleEngine
                .generate(input(3, ExperienceLevel.INTERMEDIATE, FitnessGoal.CONDITIONING,
                        List.of(), List.of(), List.of()), catalog())
                .days().get(0).exercises().get(0);
        assertThat(conditioning.repsMin()).isEqualTo(15);
        assertThat(conditioning.repsMax()).isEqualTo(20);
        assertThat(conditioning.restSeconds()).isEqualTo(45);
    }

    @Test
    void priorityGroupGetsExtraExercise() {
        Map<Integer, Exercise> byId = catalogById();
        GeneratedWorkout without = WorkoutRuleEngine.generate(input(3), catalog());
        GeneratedWorkout with = WorkoutRuleEngine.generate(
                input(3, ExperienceLevel.INTERMEDIATE, FitnessGoal.HYPERTROPHY,
                        List.of(), List.of(), List.of(MuscleGroup.CHEST)),
                catalog());

        assertThat(chestCount(with, byId)).isGreaterThan(chestCount(without, byId));
    }

    private static long chestCount(GeneratedWorkout plan, Map<Integer, Exercise> byId) {
        return allExercises(plan).stream()
                .filter(e -> byId.get(e.exerciseId()).getPrimaryMuscleGroup() == MuscleGroup.CHEST)
                .count();
    }

    @ParameterizedTest
    @EnumSource(value = MuscleGroup.class, names = { "FOREARMS", "TRAPS", "CALVES", "LOWER_BACK" })
    @DisplayName("Grupos pequenos aparecem em todos os splits")
    void smallGroupsAppearInAllSplits(MuscleGroup group) {
        Map<Integer, Exercise> byId = catalogById();
        for (int days : new int[] { 2, 3, 4, 5 }) {
            GeneratedWorkout plan = WorkoutRuleEngine.generate(input(days), catalog());
            assertThat(allExercises(plan))
                    .as("split de %d dias", days)
                    .anyMatch(e -> byId.get(e.exerciseId()).getPrimaryMuscleGroup() == group);
        }
    }

    @Test
    @DisplayName("Dias full-body ficam em 1 exercício por grupo")
    void fullBodyDaysCapOneExercisePerGroup() {
        Map<Integer, Exercise> byId = catalogById();
        GeneratedWorkout plan = WorkoutRuleEngine.generate(
                input(2, ExperienceLevel.ADVANCED, FitnessGoal.HYPERTROPHY, List.of(), List.of(), List.of()),
                catalog());

        for (var day : plan.days()) {
            Map<MuscleGroup, Long> perGroup = day.exercises().stream()
                    .collect(Collectors.groupingBy(
                            e -> byId.get(e.exerciseId()).getPrimaryMuscleGroup(), Collectors.counting()));
            assertThat(perGroup.values()).allMatch(count -> count == 1L);
        }
    }

    @Test
    void noDuplicateExerciseWithinSameDay() {
        GeneratedWorkout plan = WorkoutRuleEngine.generate(
                input(5, ExperienceLevel.ADVANCED, FitnessGoal.HYPERTROPHY, List.of(), List.of(), List.of()),
                catalog());

        for (var day : plan.days()) {
            List<Integer> ids = day.exercises().stream().map(GeneratedExercise::exerciseId).toList();
            assertThat(ids).doesNotHaveDuplicates();
        }
    }
}
