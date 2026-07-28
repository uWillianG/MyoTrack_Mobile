package com.myotrack.domain.entity;

import com.fasterxml.jackson.annotation.JsonIgnore;
import com.myotrack.domain.Biotype;
import com.myotrack.domain.EnumArrays;
import com.myotrack.domain.Equipment;
import com.myotrack.domain.ExperienceLevel;
import com.myotrack.domain.FitnessGoal;
import com.myotrack.domain.MuscleGroup;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import jakarta.persistence.Transient;
import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.OffsetDateTime;
import java.util.List;
import java.util.UUID;
import lombok.Getter;
import lombok.Setter;
import org.hibernate.annotations.JdbcTypeCode;
import org.hibernate.type.SqlTypes;

@Entity
@Table(name = "UserProfiles")
@Getter
@Setter
public class UserProfile {

    @Id
    @GeneratedValue
    @Column(name = "Id")
    private UUID id;

    @Column(name = "UserId", nullable = false)
    private UUID userId;

    @Column(name = "BirthDate")
    private LocalDate birthDate;

    /** "M" | "F". */
    @Column(name = "Sex")
    private String sex;

    @Column(name = "HeightCm")
    private BigDecimal heightCm;

    @Column(name = "Biotype")
    private Biotype biotype;

    @Column(name = "ExperienceLevel", nullable = false)
    private ExperienceLevel experienceLevel = ExperienceLevel.BEGINNER;

    @Column(name = "Goal", nullable = false)
    private FitnessGoal goal = FitnessGoal.HYPERTROPHY;

    @Column(name = "TrainingDaysPerWeek", nullable = false)
    private int trainingDaysPerWeek = 3;

    @JsonIgnore
    @JdbcTypeCode(SqlTypes.ARRAY)
    @Column(name = "PriorityMuscleGroups", nullable = false)
    private Integer[] priorityMuscleGroupValues = new Integer[0];

    /** Lesões/limitações em texto livre + tags estruturadas. */
    @Column(name = "InjuryNotes")
    private String injuryNotes;

    @JdbcTypeCode(SqlTypes.ARRAY)
    @Column(name = "InjuryTags", nullable = false)
    private String[] injuryTags = new String[0];

    @JsonIgnore
    @JdbcTypeCode(SqlTypes.ARRAY)
    @Column(name = "AvailableEquipment", nullable = false)
    private Integer[] availableEquipmentValues = new Integer[0];

    @JdbcTypeCode(SqlTypes.ARRAY)
    @Column(name = "DietaryRestrictions", nullable = false)
    private String[] dietaryRestrictions = new String[0];

    @JdbcTypeCode(SqlTypes.ARRAY)
    @Column(name = "FoodPreferences", nullable = false)
    private String[] foodPreferences = new String[0];

    @Column(name = "CreatedAt", nullable = false)
    private OffsetDateTime createdAt = OffsetDateTime.now();

    @Column(name = "UpdatedAt", nullable = false)
    private OffsetDateTime updatedAt = OffsetDateTime.now();

    /** Grupos musculares priorizados pelo usuário. */
    @Transient
    public List<MuscleGroup> getPriorityMuscleGroups() {
        return EnumArrays.toList(MuscleGroup.class, priorityMuscleGroupValues);
    }

    public void setPriorityMuscleGroups(List<MuscleGroup> groups) {
        this.priorityMuscleGroupValues = EnumArrays.toValues(groups);
    }

    @Transient
    public List<Equipment> getAvailableEquipment() {
        return EnumArrays.toList(Equipment.class, availableEquipmentValues);
    }

    public void setAvailableEquipment(List<Equipment> equipment) {
        this.availableEquipmentValues = EnumArrays.toValues(equipment);
    }
}
