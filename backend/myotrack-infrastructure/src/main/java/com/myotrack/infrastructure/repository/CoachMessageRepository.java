package com.myotrack.infrastructure.repository;

import com.myotrack.domain.entity.CoachMessage;
import java.time.OffsetDateTime;
import java.util.List;
import java.util.UUID;
import org.springframework.data.domain.Limit;
import org.springframework.data.jpa.repository.JpaRepository;

public interface CoachMessageRepository extends JpaRepository<CoachMessage, UUID> {

    List<CoachMessage> findByUserIdOrderByCreatedAtDesc(UUID userId, Limit limit);

    List<CoachMessage> findByUserIdOrderByCreatedAtAsc(UUID userId);

    /** Conta as mensagens do usuário no dia — base do limite diário por plano. */
    long countByUserIdAndFromUserTrueAndCreatedAtGreaterThanEqual(
            UUID userId, OffsetDateTime since);

    void deleteByUserId(UUID userId);
}
