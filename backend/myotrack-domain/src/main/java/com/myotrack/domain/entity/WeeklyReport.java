package com.myotrack.domain.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import java.time.LocalDate;
import java.time.OffsetDateTime;
import java.util.UUID;
import lombok.Getter;
import lombok.Setter;
import org.hibernate.annotations.JdbcTypeCode;
import org.hibernate.type.SqlTypes;

/**
 * Relatório semanal do usuário: métricas calculadas em código (treinos, volume,
 * recordes, aderência à dieta, peso) + narrativa curta gerada pelo LLM.
 * Um por usuário por semana (semana ISO em UTC, começando na segunda-feira).
 */
@Entity
@Table(name = "WeeklyReports")
@Getter
@Setter
public class WeeklyReport {

    @Id
    @GeneratedValue
    @Column(name = "Id")
    private UUID id;

    @Column(name = "UserId", nullable = false)
    private UUID userId;

    /** Segunda-feira (UTC) da semana coberta. */
    @Column(name = "WeekStart", nullable = false)
    private LocalDate weekStart;

    /** Métricas determinísticas da semana (JSONB) — a fonte dos números. */
    @JdbcTypeCode(SqlTypes.JSON)
    @Column(name = "MetricsJson", nullable = false)
    private String metricsJson = "{}";

    /**
     * Narrativa do LLM: { summary, highlights[], recommendations[] } (JSONB).
     * Null quando a IA está indisponível — o relatório vale pelos números.
     */
    @JdbcTypeCode(SqlTypes.JSON)
    @Column(name = "NarrativeJson")
    private String narrativeJson;

    @Column(name = "CreatedAt", nullable = false)
    private OffsetDateTime createdAt = OffsetDateTime.now();
}
