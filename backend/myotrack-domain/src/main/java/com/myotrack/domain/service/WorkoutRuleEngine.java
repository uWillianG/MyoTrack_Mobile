package com.myotrack.domain.service;

import com.myotrack.domain.Equipment;
import com.myotrack.domain.ExperienceLevel;
import com.myotrack.domain.FitnessGoal;
import com.myotrack.domain.MuscleGroup;
import com.myotrack.domain.entity.Exercise;
import com.myotrack.domain.service.WorkoutGeneration.GeneratedDay;
import com.myotrack.domain.service.WorkoutGeneration.GeneratedExercise;
import com.myotrack.domain.service.WorkoutGeneration.GeneratedWorkout;
import com.myotrack.domain.service.WorkoutGeneration.Input;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.HashSet;
import java.util.List;
import java.util.Locale;
import java.util.Set;

/**
 * Gera o esqueleto de treino por regras determinísticas: split conforme dias/semana,
 * volume conforme nível, filtro de contraindicações e equipamento.
 * O LLM apenas personaliza/anota dentro deste esqueleto — nunca cria exercícios.
 *
 * <p>Porte de MyoTrack.Domain/Services/WorkoutRuleEngine.cs.
 */
public final class WorkoutRuleEngine {

    private WorkoutRuleEngine() {
    }

    private record DayTemplate(String label, List<MuscleGroup> groups) {
    }

    private record Split(String name, List<DayTemplate> days) {
    }

    private record Prescription(int repsMin, int repsMax, int restSeconds) {
    }

    private static Split splitFor(int daysPerWeek) {
        if (daysPerWeek <= 2) {
            return new Split("FullBody", List.of(
                    new DayTemplate("A — Corpo inteiro", List.of(
                            MuscleGroup.QUADRICEPS, MuscleGroup.CALVES, MuscleGroup.CHEST, MuscleGroup.BACK,
                            MuscleGroup.SHOULDERS, MuscleGroup.TRAPS, MuscleGroup.ABS)),
                    new DayTemplate("B — Corpo inteiro", List.of(
                            MuscleGroup.HAMSTRINGS, MuscleGroup.GLUTES, MuscleGroup.LOWER_BACK, MuscleGroup.BACK,
                            MuscleGroup.CHEST, MuscleGroup.BICEPS, MuscleGroup.TRICEPS, MuscleGroup.FOREARMS))));
        }
        if (daysPerWeek == 3) {
            return new Split("ABC", List.of(
                    new DayTemplate("A — Peito/Ombros/Trapézio/Tríceps", List.of(
                            MuscleGroup.CHEST, MuscleGroup.SHOULDERS, MuscleGroup.TRAPS, MuscleGroup.TRICEPS)),
                    new DayTemplate("B — Costas/Bíceps/Antebraços", List.of(
                            MuscleGroup.BACK, MuscleGroup.BICEPS, MuscleGroup.FOREARMS, MuscleGroup.ABS)),
                    new DayTemplate("C — Pernas", List.of(
                            MuscleGroup.QUADRICEPS, MuscleGroup.HAMSTRINGS, MuscleGroup.GLUTES,
                            MuscleGroup.LOWER_BACK, MuscleGroup.CALVES))));
        }
        if (daysPerWeek == 4) {
            return new Split("ABCD", List.of(
                    new DayTemplate("A — Peito/Tríceps", List.of(MuscleGroup.CHEST, MuscleGroup.TRICEPS)),
                    new DayTemplate("B — Costas/Bíceps/Antebraços", List.of(
                            MuscleGroup.BACK, MuscleGroup.BICEPS, MuscleGroup.FOREARMS)),
                    new DayTemplate("C — Pernas", List.of(
                            MuscleGroup.QUADRICEPS, MuscleGroup.HAMSTRINGS, MuscleGroup.GLUTES, MuscleGroup.CALVES)),
                    new DayTemplate("D — Ombros/Trapézio/Core", List.of(
                            MuscleGroup.SHOULDERS, MuscleGroup.TRAPS, MuscleGroup.ABS, MuscleGroup.LOWER_BACK))));
        }
        return new Split("PPL", List.of(
                new DayTemplate("A — Push (Peito/Ombros/Tríceps)", List.of(
                        MuscleGroup.CHEST, MuscleGroup.SHOULDERS, MuscleGroup.TRICEPS)),
                new DayTemplate("B — Pull (Costas/Trapézio/Bíceps)", List.of(
                        MuscleGroup.BACK, MuscleGroup.TRAPS, MuscleGroup.BICEPS)),
                new DayTemplate("C — Legs (Pernas)", List.of(
                        MuscleGroup.QUADRICEPS, MuscleGroup.HAMSTRINGS, MuscleGroup.GLUTES,
                        MuscleGroup.LOWER_BACK, MuscleGroup.CALVES)),
                new DayTemplate("D — Push (variação)", List.of(
                        MuscleGroup.CHEST, MuscleGroup.SHOULDERS, MuscleGroup.TRICEPS)),
                new DayTemplate("E — Pull + Abdômen", List.of(
                        MuscleGroup.BACK, MuscleGroup.BICEPS, MuscleGroup.FOREARMS, MuscleGroup.ABS))));
    }

    private static Prescription prescriptionFor(FitnessGoal goal) {
        return switch (goal) {
            case HYPERTROPHY -> new Prescription(8, 12, 90);
            case WEIGHT_LOSS -> new Prescription(12, 15, 60);
            case CONDITIONING -> new Prescription(15, 20, 45);
            case AESTHETICS -> new Prescription(10, 15, 75);
        };
    }

    private static int setsFor(ExperienceLevel level) {
        return switch (level) {
            case BEGINNER, INTERMEDIATE -> 3;
            case ADVANCED -> 4;
        };
    }

    // Dias full-body tocam muitos grupos de uma vez: 1 exercício por grupo,
    // senão a sessão de intermediário/avançado passa de 14 exercícios.
    private static int exercisesPerGroup(ExperienceLevel level, boolean isPriority, boolean fullBodyDay) {
        int base = (fullBodyDay || level == ExperienceLevel.BEGINNER) ? 1 : 2;
        return base + (isPriority ? 1 : 0);
    }

    public static GeneratedWorkout generate(Input input, List<Exercise> catalog) {
        List<String> injuryTags = input.injuryTags().stream()
                .map(t -> t.toLowerCase(Locale.ROOT))
                .toList();

        List<Exercise> eligible = catalog.stream()
                .filter(e -> !hasContraindication(e, injuryTags))
                .filter(e -> isEquipmentAllowed(e, input.availableEquipment()))
                .toList();

        Split split = splitFor(input.daysPerWeek());
        Prescription prescription = prescriptionFor(input.goal());
        int sets = setsFor(input.level());
        boolean fullBody = "FullBody".equals(split.name());

        List<WorkoutGeneration.GeneratedDay> days = new ArrayList<>();
        for (int dayIndex = 0; dayIndex < split.days().size(); dayIndex++) {
            DayTemplate template = split.days().get(dayIndex);
            Set<Integer> used = new HashSet<>();
            List<GeneratedExercise> exercises = new ArrayList<>();

            for (MuscleGroup group : template.groups()) {
                boolean isPriority = input.priorityMuscleGroups().contains(group);
                int limit = exercisesPerGroup(input.level(), isPriority, fullBody);

                List<Exercise> candidates = eligible.stream()
                        .filter(e -> e.getPrimaryMuscleGroup() == group && !used.contains(e.getId()))
                        // Compostos primeiro; o id desempata para a geração ser reproduzível.
                        .sorted(Comparator.comparing(Exercise::isCompound).reversed()
                                .thenComparing(Exercise::getId))
                        .limit(limit)
                        .toList();

                for (Exercise exercise : candidates) {
                    used.add(exercise.getId());
                    exercises.add(new GeneratedExercise(
                            exercise.getId(), exercise.getName(), sets,
                            prescription.repsMin(), prescription.repsMax(), prescription.restSeconds(),
                            isPriority ? "Grupo priorizado" : null));
                }
            }

            days.add(new GeneratedDay(dayIndex + 1, template.label(), exercises));
        }

        return new GeneratedWorkout(split.name(), days);
    }

    private static boolean hasContraindication(Exercise exercise, List<String> injuryTags) {
        for (String tag : exercise.getContraindicationTags()) {
            if (injuryTags.contains(tag.toLowerCase(Locale.ROOT))) {
                return true;
            }
        }
        return false;
    }

    /** Lista vazia = academia completa. Peso corporal e "sem equipamento" passam sempre. */
    private static boolean isEquipmentAllowed(Exercise exercise, List<Equipment> available) {
        return available.isEmpty()
                || exercise.getEquipment() == Equipment.BODYWEIGHT
                || exercise.getEquipment() == Equipment.NONE
                || available.contains(exercise.getEquipment());
    }
}
