package com.myotrack.infrastructure.repository;

import com.myotrack.domain.entity.BodyMeasurement;
import java.time.LocalDate;
import java.util.List;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;

public interface BodyMeasurementRepository extends JpaRepository<BodyMeasurement, UUID> {

    List<BodyMeasurement> findByUserIdOrderByDateDesc(UUID userId);

    @Query("""
            select distinct m.userId from BodyMeasurement m
            where m.date >= :start and m.date < :end
            """)
    List<UUID> findUserIdsWithMeasurementsBetween(LocalDate start, LocalDate end);

    /** Usado na exclusão de conta (LGPD). */
    void deleteByUserId(UUID userId);
}
