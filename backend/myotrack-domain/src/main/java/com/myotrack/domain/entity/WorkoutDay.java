package com.myotrack.domain.entity;

import com.fasterxml.jackson.annotation.JsonIgnore;
import jakarta.persistence.CascadeType;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.FetchType;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.OneToMany;
import jakarta.persistence.OrderBy;
import jakarta.persistence.Table;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;
import lombok.Getter;
import lombok.Setter;

@Entity
@Table(name = "WorkoutDays")
@Getter
@Setter
public class WorkoutDay {

    @Id
    @GeneratedValue
    @Column(name = "Id")
    private UUID id;

    @JsonIgnore
    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "WorkoutPlanId", nullable = false)
    private WorkoutPlan workoutPlan;

    @Column(name = "Order", nullable = false)
    private int order;

    /** Ex.: "A — Peito/Tríceps". */
    @Column(name = "Label", nullable = false)
    private String label;

    @OneToMany(mappedBy = "workoutDay", cascade = CascadeType.ALL, orphanRemoval = true)
    @OrderBy("order ASC")
    private List<WorkoutExercise> exercises = new ArrayList<>();

    public void addExercise(WorkoutExercise exercise) {
        exercise.setWorkoutDay(this);
        exercises.add(exercise);
    }
}
