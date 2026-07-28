package com.myotrack.domain.entity;

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
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;
import lombok.Getter;
import lombok.Setter;

/** Execução real de um treino; a progressão de carga deriva dos SetLogs. */
@Entity
@Table(name = "WorkoutSessions")
@Getter
@Setter
public class WorkoutSession {

    @Id
    @GeneratedValue
    @Column(name = "Id")
    private UUID id;

    @Column(name = "UserId", nullable = false)
    private UUID userId;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "WorkoutDayId")
    private WorkoutDay workoutDay;

    @Column(name = "Date", nullable = false)
    private LocalDate date;

    @Column(name = "Notes")
    private String notes;

    @OneToMany(mappedBy = "workoutSession", cascade = CascadeType.ALL, orphanRemoval = true)
    @OrderBy("setNumber ASC")
    private List<SetLog> sets = new ArrayList<>();

    public void addSet(SetLog set) {
        set.setWorkoutSession(this);
        sets.add(set);
    }
}
