package com.myotrack.domain.entity;

import com.myotrack.domain.CalorieGoal;
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
import java.math.BigDecimal;
import java.time.OffsetDateTime;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;
import lombok.Getter;
import lombok.Setter;
import org.hibernate.annotations.JdbcTypeCode;
import org.hibernate.type.SqlTypes;

@Entity
@Table(name = "DietPlans")
@Getter
@Setter
public class DietPlan {

    @Id
    @GeneratedValue
    @Column(name = "Id")
    private UUID id;

    @Column(name = "UserId", nullable = false)
    private UUID userId;

    @Column(name = "Name", nullable = false)
    private String name;

    @Column(name = "CalorieGoal", nullable = false)
    private CalorieGoal calorieGoal;

    @Column(name = "Status", nullable = false)
    private PlanStatus status = PlanStatus.DRAFT;

    @Column(name = "Version", nullable = false)
    private int version = 1;

    // Metas calculadas deterministicamente (TDEE, macros) — nunca pelo LLM.

    @Column(name = "TargetKcal", nullable = false)
    private BigDecimal targetKcal;

    @Column(name = "TargetProteinG", nullable = false)
    private BigDecimal targetProteinG;

    @Column(name = "TargetCarbsG", nullable = false)
    private BigDecimal targetCarbsG;

    @Column(name = "TargetFatG", nullable = false)
    private BigDecimal targetFatG;

    @JdbcTypeCode(SqlTypes.JSON)
    @Column(name = "GenerationInputJson")
    private String generationInputJson;

    @JdbcTypeCode(SqlTypes.JSON)
    @Column(name = "RawLlmOutputJson")
    private String rawLlmOutputJson;

    @Column(name = "CreatedAt", nullable = false)
    private OffsetDateTime createdAt = OffsetDateTime.now();

    // Supervisão humana (Fase 4): um Nutritionist pode aprovar ou pedir ajustes no plano gerado.

    @Column(name = "ReviewStatus", nullable = false)
    private ReviewStatus reviewStatus = ReviewStatus.NOT_REVIEWED;

    @Column(name = "ReviewedByUserId")
    private UUID reviewedByUserId;

    @Column(name = "ReviewNote")
    private String reviewNote;

    @Column(name = "ReviewedAt")
    private OffsetDateTime reviewedAt;

    @OneToMany(mappedBy = "dietPlan", cascade = CascadeType.ALL, orphanRemoval = true)
    @OrderBy("order ASC")
    private List<Meal> meals = new ArrayList<>();

    public void addMeal(Meal meal) {
        meal.setDietPlan(this);
        meals.add(meal);
    }
}
