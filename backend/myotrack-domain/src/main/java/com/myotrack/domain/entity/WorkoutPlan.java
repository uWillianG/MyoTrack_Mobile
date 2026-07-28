package com.myotrack.domain.entity;

import com.myotrack.domain.FitnessGoal;
import com.myotrack.domain.PlanStatus;
import com.myotrack.domain.ReviewStatus;
import jakarta.persistence.CascadeType;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.Id;
import jakarta.persistence.OneToMany;
import jakarta.persistence.OrderBy;
import jakarta.persistence.Table;
import java.time.OffsetDateTime;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;
import lombok.Getter;
import lombok.Setter;
import org.hibernate.annotations.JdbcTypeCode;
import org.hibernate.type.SqlTypes;

@Entity
@Table(name = "WorkoutPlans")
@Getter
@Setter
public class WorkoutPlan {

    @Id
    @GeneratedValue
    @Column(name = "Id")
    private UUID id;

    @Column(name = "UserId", nullable = false)
    private UUID userId;

    @Column(name = "Name", nullable = false)
    private String name;

    @Column(name = "Goal", nullable = false)
    private FitnessGoal goal;

    /** Ex.: "ABC", "ABCD", "PPL", "FullBody". */
    @Column(name = "Split", nullable = false)
    private String split;

    @Column(name = "Status", nullable = false)
    private PlanStatus status = PlanStatus.DRAFT;

    @Column(name = "Version", nullable = false)
    private int version = 1;

    /** Snapshot JSON do perfil/inputs usados na geração (auditoria e cache). */
    @JdbcTypeCode(SqlTypes.JSON)
    @Column(name = "GenerationInputJson")
    private String generationInputJson;

    /** Resposta bruta do LLM (auditoria). */
    @JdbcTypeCode(SqlTypes.JSON)
    @Column(name = "RawLlmOutputJson")
    private String rawLlmOutputJson;

    @Column(name = "CreatedAt", nullable = false)
    private OffsetDateTime createdAt = OffsetDateTime.now();

    // Supervisão humana (Fase 4): um Trainer pode aprovar ou pedir ajustes no plano gerado.

    @Column(name = "ReviewStatus", nullable = false)
    private ReviewStatus reviewStatus = ReviewStatus.NOT_REVIEWED;

    @Column(name = "ReviewedByUserId")
    private UUID reviewedByUserId;

    @Column(name = "ReviewNote")
    private String reviewNote;

    @Column(name = "ReviewedAt")
    private OffsetDateTime reviewedAt;

    @OneToMany(mappedBy = "workoutPlan", cascade = CascadeType.ALL, orphanRemoval = true)
    @OrderBy("order ASC")
    private List<WorkoutDay> days = new ArrayList<>();

    public void addDay(WorkoutDay day) {
        day.setWorkoutPlan(this);
        days.add(day);
    }
}
