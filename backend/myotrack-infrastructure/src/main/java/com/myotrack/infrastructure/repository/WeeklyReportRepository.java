package com.myotrack.infrastructure.repository;

import com.myotrack.domain.entity.WeeklyReport;
import java.time.LocalDate;
import java.util.List;
import java.util.Optional;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;

public interface WeeklyReportRepository extends JpaRepository<WeeklyReport, UUID> {

    Optional<WeeklyReport> findByUserIdAndWeekStart(UUID userId, LocalDate weekStart);

    Optional<WeeklyReport> findFirstByUserIdOrderByWeekStartDesc(UUID userId);

    @Query("""
            select r.userId from WeeklyReport r
            where r.weekStart = :weekStart and r.userId in :userIds
            """)
    List<UUID> findUserIdsWithReportFor(LocalDate weekStart, List<UUID> userIds);

    /** Usado na exclusão de conta (LGPD). */
    void deleteByUserId(UUID userId);
}
