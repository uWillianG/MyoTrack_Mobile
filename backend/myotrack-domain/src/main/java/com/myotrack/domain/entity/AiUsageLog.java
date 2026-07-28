package com.myotrack.domain.entity;

import com.myotrack.domain.AnalysisJobType;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import java.time.OffsetDateTime;
import java.util.UUID;
import lombok.Getter;
import lombok.Setter;

/** Trilha de consumo de IA por usuário — base para limites e controle de custo. */
@Entity
@Table(name = "AiUsageLogs")
@Getter
@Setter
public class AiUsageLog {

    @Id
    @GeneratedValue
    @Column(name = "Id")
    private UUID id;

    @Column(name = "UserId", nullable = false)
    private UUID userId;

    @Column(name = "Operation", nullable = false)
    private AnalysisJobType operation;

    @Column(name = "Model", nullable = false)
    private String model;

    @Column(name = "InputTokens", nullable = false)
    private long inputTokens;

    @Column(name = "OutputTokens", nullable = false)
    private long outputTokens;

    @Column(name = "CreatedAt", nullable = false)
    private OffsetDateTime createdAt = OffsetDateTime.now();
}
