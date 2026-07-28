package com.myotrack.api.exercises;

import com.myotrack.domain.entity.Exercise;
import com.myotrack.infrastructure.repository.ExerciseRepository;
import java.util.Comparator;
import java.util.List;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

/**
 * Catálogo de exercícios. Porte de MyoTrack.Api/Controllers/ExercisesController.cs.
 *
 * <p>É o mesmo catálogo para todo mundo — o app baixa uma vez e guarda offline, que é o que
 * permite registrar treino na academia sem sinal.
 */
@RestController
@RequestMapping("/api/exercises")
public class ExercisesController {

    private final ExerciseRepository exercises;

    public ExercisesController(ExerciseRepository exercises) {
        this.exercises = exercises;
    }

    @GetMapping
    public List<ExerciseView> list() {
        return exercises.findAll().stream()
                .sorted(Comparator
                        .comparing((Exercise e) -> e.getPrimaryMuscleGroup().getValue())
                        .thenComparing(Exercise::getName))
                .map(ExerciseView::from)
                .toList();
    }

    public record ExerciseView(
            Integer id, String name, String muscleGroup, String equipment, boolean isCompound) {

        static ExerciseView from(Exercise exercise) {
            return new ExerciseView(
                    exercise.getId(),
                    exercise.getName(),
                    exercise.getPrimaryMuscleGroup().getWireName(),
                    exercise.getEquipment().getWireName(),
                    exercise.isCompound());
        }
    }
}
