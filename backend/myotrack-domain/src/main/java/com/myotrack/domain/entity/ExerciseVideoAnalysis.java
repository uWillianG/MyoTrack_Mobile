package com.myotrack.domain.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import java.time.OffsetDateTime;
import java.util.UUID;
import lombok.Getter;
import lombok.Setter;
import org.hibernate.annotations.JdbcTypeCode;
import org.hibernate.type.SqlTypes;

/**
 * Resultado da análise de execução de exercício por vídeo (MediaPipe Pose no serviço vision).
 * Erros detectados e métricas ficam em JSONB para evoluir as heurísticas sem migração.
 */
@Entity
@Table(name = "ExerciseVideoAnalyses")
@Getter
@Setter
public class ExerciseVideoAnalysis {

    @Id
    @GeneratedValue
    @Column(name = "Id")
    private UUID id;

    @Column(name = "UserId", nullable = false)
    private UUID userId;

    @Column(name = "AnalysisJobId", nullable = false)
    private UUID analysisJobId;

    @Column(name = "MediaKey", nullable = false)
    private String mediaKey;

    /** Vídeo com o esqueleto desenhado, gerado pelo serviço vision. */
    @Column(name = "OverlayVideoKey")
    private String overlayVideoKey;

    /** Slug do exercício analisado (squat, deadlift, overhead_press). */
    @Column(name = "AnalyzedExercise", nullable = false, length = 50)
    private String analyzedExercise;

    /** 0–100; null quando a pose não pôde ser avaliada com confiança. */
    @Column(name = "Score")
    private Integer score;

    @Column(name = "RepCount", nullable = false)
    private int repCount;

    /** {issues: [{code, message, timestampsSec[]}], metrics: {...}, notEvaluableReason?}. */
    @JdbcTypeCode(SqlTypes.JSON)
    @Column(name = "ResultJson", nullable = false)
    private String resultJson = "{}";

    @Column(name = "CreatedAt", nullable = false)
    private OffsetDateTime createdAt = OffsetDateTime.now();

    /** Quando a mídia foi apagada do storage pela política de retenção (LGPD). */
    @Column(name = "MediaExpiredAt")
    private OffsetDateTime mediaExpiredAt;
}
