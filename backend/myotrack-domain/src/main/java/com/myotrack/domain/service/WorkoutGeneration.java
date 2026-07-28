package com.myotrack.domain.service;

import com.myotrack.domain.Equipment;
import com.myotrack.domain.ExperienceLevel;
import com.myotrack.domain.FitnessGoal;
import com.myotrack.domain.MuscleGroup;
import java.util.List;

/** Contratos de entrada e saída do {@link WorkoutRuleEngine}. */
public final class WorkoutGeneration {

    private WorkoutGeneration() {
    }

    public record Input(
            FitnessGoal goal,
            ExperienceLevel level,
            int daysPerWeek,
            List<MuscleGroup> priorityMuscleGroups,
            List<String> injuryTags,
            List<Equipment> availableEquipment) {
    }

    public record GeneratedExercise(
            int exerciseId,
            String name,
            int sets,
            int repsMin,
            int repsMax,
            int restSeconds,
            String notes) {
    }

    public record GeneratedDay(int order, String label, List<GeneratedExercise> exercises) {
    }

    public record GeneratedWorkout(String split, List<GeneratedDay> days) {
    }
}
