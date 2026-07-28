package com.myotrack.infrastructure.repository;

import com.myotrack.domain.AnalysisJobType;
import com.myotrack.domain.entity.AnalysisJob;
import java.time.OffsetDateTime;
import java.util.List;
import java.util.Optional;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;

public interface AnalysisJobRepository extends JpaRepository<AnalysisJob, UUID> {

    /**
     * Reserva o job pendente mais antigo.
     *
     * <p>{@code FOR UPDATE SKIP LOCKED} é o que permite rodar várias instâncias do worker sem
     * processamento duplicado: cada transação tranca a linha que pegou e as demais pulam para a
     * próxima em vez de bloquear. É a mesma SQL do backend .NET — o comportamento é do Postgres,
     * não do ORM.
     */
    @Query(value = """
            SELECT * FROM "AnalysisJobs"
            WHERE "Status" = :status
            ORDER BY "CreatedAt"
            LIMIT 1
            FOR UPDATE SKIP LOCKED
            """, nativeQuery = true)
    Optional<AnalysisJob> lockNextPending(int status);

    /** Uso do dia por tipo de job — é o que os limites diários por plano consultam. */
    long countByUserIdAndTypeAndCreatedAtGreaterThanEqual(
            UUID userId, AnalysisJobType type, OffsetDateTime since);

    @Query("""
            select distinct j.userId from AnalysisJob j
            where j.type = com.myotrack.domain.AnalysisJobType.WEEKLY_REPORT
              and j.status in (com.myotrack.domain.JobStatus.PENDING, com.myotrack.domain.JobStatus.PROCESSING)
              and j.userId in :userIds
            """)
    List<UUID> findUsersWithOpenWeeklyReportJob(List<UUID> userIds);

    /** Usado na exclusão de conta (LGPD). */
    void deleteByUserId(UUID userId);
}
