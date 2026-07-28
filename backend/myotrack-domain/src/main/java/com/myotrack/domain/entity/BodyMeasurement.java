package com.myotrack.domain.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.UUID;
import lombok.Getter;
import lombok.Setter;

@Entity
@Table(name = "BodyMeasurements")
@Getter
@Setter
public class BodyMeasurement {

    @Id
    @GeneratedValue
    @Column(name = "Id")
    private UUID id;

    @Column(name = "UserId", nullable = false)
    private UUID userId;

    @Column(name = "Date", nullable = false)
    private LocalDate date;

    @Column(name = "WeightKg")
    private BigDecimal weightKg;

    @Column(name = "BodyFatPercent")
    private BigDecimal bodyFatPercent;

    @Column(name = "WaistCm")
    private BigDecimal waistCm;

    @Column(name = "ChestCm")
    private BigDecimal chestCm;

    @Column(name = "HipCm")
    private BigDecimal hipCm;

    @Column(name = "ArmCm")
    private BigDecimal armCm;

    @Column(name = "ThighCm")
    private BigDecimal thighCm;

    @Column(name = "CalfCm")
    private BigDecimal calfCm;
}
