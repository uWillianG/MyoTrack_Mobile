package com.myotrack.infrastructure.repository;

import com.myotrack.domain.entity.ExerciseVideoAnalysis;
import java.time.OffsetDateTime;
import java.util.List;
import java.util.Optional;
import java.util.UUID;
import org.springframework.data.domain.Limit;
import org.springframework.data.jpa.repository.JpaRepository;

public interface ExerciseVideoAnalysisRepository extends JpaRepository<ExerciseVideoAnalysis, UUID> {

    Optional<ExerciseVideoAnalysis> findByIdAndUserId(UUID id, UUID userId);

    List<ExerciseVideoAnalysis> findByUserIdOrderByCreatedAtDesc(UUID userId, Limit limit);

    /** Candidatos à expiração de mídia: já venceram e ainda têm arquivo no storage. */
    List<ExerciseVideoAnalysis> findByMediaExpiredAtIsNullAndCreatedAtBefore(
            OffsetDateTime cutoff, Limit limit);

    /** Usado na exclusão de conta (LGPD). */
    void deleteByUserId(UUID userId);
}
