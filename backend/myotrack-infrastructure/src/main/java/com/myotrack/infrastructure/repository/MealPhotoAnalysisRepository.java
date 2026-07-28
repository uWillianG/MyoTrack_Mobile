package com.myotrack.infrastructure.repository;

import com.myotrack.domain.entity.MealPhotoAnalysis;
import java.time.OffsetDateTime;
import java.util.List;
import java.util.Optional;
import java.util.UUID;
import org.springframework.data.domain.Limit;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;

public interface MealPhotoAnalysisRepository extends JpaRepository<MealPhotoAnalysis, UUID> {

    Optional<MealPhotoAnalysis> findByIdAndUserId(UUID id, UUID userId);

    List<MealPhotoAnalysis> findByUserIdOrderByCreatedAtDesc(UUID userId, Limit limit);

    List<MealPhotoAnalysis> findByMediaExpiredAtIsNullAndCreatedAtBefore(
            OffsetDateTime cutoff, Limit limit);

    /** Usuários que registraram alguma refeição no diário dentro do intervalo. */
    @Query("""
            select distinct a.userId from MealPhotoAnalysis a
            where a.excludedFromDiary = false and a.createdAt >= :start and a.createdAt < :end
            """)
    List<UUID> findUserIdsWithDiaryActivity(OffsetDateTime start, OffsetDateTime end);

    /** Usado na exclusão de conta (LGPD). */
    void deleteByUserId(UUID userId);
}
