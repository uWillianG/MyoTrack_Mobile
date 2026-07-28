package com.myotrack.domain.entity;

import com.fasterxml.jackson.annotation.JsonIgnore;
import com.fasterxml.jackson.annotation.JsonProperty;
import com.myotrack.domain.EnumArrays;
import com.myotrack.domain.Equipment;
import com.myotrack.domain.MuscleGroup;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import jakarta.persistence.Transient;
import java.util.List;
import lombok.Getter;
import lombok.Setter;
import org.hibernate.annotations.JdbcTypeCode;
import org.hibernate.type.SqlTypes;

/** Catálogo global de exercícios. */
@Entity
@Table(name = "Exercises")
@Getter
@Setter
public class Exercise {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "Id")
    private Integer id;

    @Column(name = "Name", nullable = false, length = 200)
    private String name;

    @Column(name = "PrimaryMuscleGroup", nullable = false)
    private MuscleGroup primaryMuscleGroup;

    @JsonIgnore
    @JdbcTypeCode(SqlTypes.ARRAY)
    @Column(name = "SecondaryMuscleGroups", nullable = false)
    private Integer[] secondaryMuscleGroupValues = new Integer[0];

    @Column(name = "Equipment", nullable = false)
    private Equipment equipment;

    @Column(name = "Instructions")
    private String instructions;

    /** Tags de contraindicação cruzadas com UserProfile.injuryTags (ex.: "knee", "lower-back", "shoulder"). */
    @JdbcTypeCode(SqlTypes.ARRAY)
    @Column(name = "ContraindicationTags", nullable = false)
    private String[] contraindicationTags = new String[0];

    @Column(name = "MediaUrl")
    private String mediaUrl;

    /** Vídeo explicativo (TikTok) resolvido uma única vez e compartilhado por todos os usuários. */
    @Column(name = "TutorialVideoUrl", length = 500)
    private String tutorialVideoUrl;

    // Sem o @JsonProperty, o getter isCompound() do Lombok viraria a propriedade "compound"
    // no JSON — o .NET emite "isCompound" e o app lê esse nome.
    @JsonProperty("isCompound")
    @Column(name = "IsCompound", nullable = false)
    private boolean isCompound;

    @Transient
    public List<MuscleGroup> getSecondaryMuscleGroups() {
        return EnumArrays.toList(MuscleGroup.class, secondaryMuscleGroupValues);
    }

    public void setSecondaryMuscleGroups(List<MuscleGroup> groups) {
        this.secondaryMuscleGroupValues = EnumArrays.toValues(groups);
    }
}
