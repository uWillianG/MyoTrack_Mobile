package com.myotrack.infrastructure.repository;

import com.myotrack.domain.entity.WorkoutSession;
import java.time.LocalDate;
import java.util.List;
import java.util.Optional;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;

public interface WorkoutSessionRepository extends JpaRepository<WorkoutSession, UUID> {

    Optional<WorkoutSession> findByIdAndUserId(UUID id, UUID userId);

    List<WorkoutSession> findByUserIdOrderByDateDesc(UUID userId);

    @Query("""
            select distinct s.userId from WorkoutSession s
            where s.date >= :start and s.date < :end
            """)
    List<UUID> findUserIdsWithSessionsBetween(LocalDate start, LocalDate end);

    /** Usado na exclusão de conta (LGPD). */
    void deleteByUserId(UUID userId);
}
