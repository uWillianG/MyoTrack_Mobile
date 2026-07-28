package com.myotrack.domain.entity;

import com.myotrack.domain.AnalysisJobType;
import com.myotrack.domain.JobStatus;
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
 * Fila de jobs de IA persistida no Postgres (consumida com FOR UPDATE SKIP LOCKED).
 * Cobre gerações via LLM e análises de mídia.
 */
@Entity
@Table(name = "AnalysisJobs")
@Getter
@Setter
public class AnalysisJob {

    @Id
    @GeneratedValue
    @Column(name = "Id")
    private UUID id;

    @Column(name = "UserId", nullable = false)
    private UUID userId;

    @Column(name = "Type", nullable = false)
    private AnalysisJobType type;

    @Column(name = "Status", nullable = false)
    private JobStatus status = JobStatus.PENDING;

    /** Chave do objeto no MinIO (vídeo/foto), quando aplicável. */
    @Column(name = "MediaKey")
    private String mediaKey;

    /** Payload de entrada específico do tipo de job (JSON). */
    @JdbcTypeCode(SqlTypes.JSON)
    @Column(name = "InputJson")
    private String inputJson;

    /** Resultado do processamento (JSON). */
    @JdbcTypeCode(SqlTypes.JSON)
    @Column(name = "ResultJson")
    private String resultJson;

    @Column(name = "Attempts", nullable = false)
    private int attempts;

    @Column(name = "LastError")
    private String lastError;

    @Column(name = "CreatedAt", nullable = false)
    private OffsetDateTime createdAt = OffsetDateTime.now();

    @Column(name = "StartedAt")
    private OffsetDateTime startedAt;

    @Column(name = "CompletedAt")
    private OffsetDateTime completedAt;
}
