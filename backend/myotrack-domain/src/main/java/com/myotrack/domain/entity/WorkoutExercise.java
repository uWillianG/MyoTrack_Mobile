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
@Table(name = "WorkoutExercises")
@Getter
@Setter
public class WorkoutExercise {

    @Id
    @GeneratedValue
    @Column(name = "Id")
    private UUID id;

    @JsonIgnore
    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "WorkoutDayId", nullable = false)
    private WorkoutDay workoutDay;

    @ManyToOne(fetch = FetchType.EAGER, optional = false)
    @JoinColumn(name = "ExerciseId", nullable = false)
    private Exercise exercise;

    @Column(name = "Order", nullable = false)
    private int order;

    @Column(name = "Sets", nullable = false)
    private int sets;

    @Column(name = "RepsMin", nullable = false)
    private int repsMin;

    @Column(name = "RepsMax", nullable = false)
    private int repsMax;

    @Column(name = "SuggestedLoadKg")
    private BigDecimal suggestedLoadKg;

    @Column(name = "RestSeconds", nullable = false)
    private int restSeconds;

    @Column(name = "Notes")
    private String notes;

    /** A coluna é a FK; o app usa o id sem precisar carregar o exercício inteiro. */
    public Integer getExerciseId() {
        return exercise == null ? null : exercise.getId();
    }
}
