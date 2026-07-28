package com.myotrack.domain.entity;

import com.fasterxml.jackson.annotation.JsonIgnore;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.FetchType;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.Table;
import java.math.BigDecimal;
import java.util.UUID;
import lombok.Getter;
import lombok.Setter;

@Entity
@Table(name = "SetLogs")
@Getter
@Setter
public class SetLog {

    @Id
    @GeneratedValue
    @Column(name = "Id")
    private UUID id;

    @JsonIgnore
    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "WorkoutSessionId", nullable = false)
    private WorkoutSession workoutSession;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "ExerciseId", nullable = false)
    private Exercise exercise;

    @Column(name = "SetNumber", nullable = false)
    private int setNumber;

    @Column(name = "Reps", nullable = false)
    private int reps;

    @Column(name = "LoadKg", nullable = false)
    private BigDecimal loadKg;

    /** Rate of Perceived Exertion (1–10), opcional. */
    @Column(name = "Rpe")
    private Integer rpe;

    public Integer getExerciseId() {
        return exercise == null ? null : exercise.getId();
    }
}
