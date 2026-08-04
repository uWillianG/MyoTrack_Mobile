package com.myotrack.infrastructure.repository;

import com.myotrack.domain.entity.ProGrant;
import java.time.OffsetDateTime;
import java.util.List;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;

public interface ProGrantRepository extends JpaRepository<ProGrant, UUID> {

    List<ProGrant> findByUserId(UUID userId);

    /** A pergunta quente: há concessão valendo agora? Roda em toda checagem de limite de IA. */
    boolean existsByUserIdAndExpiresAtAfter(UUID userId, OffsetDateTime moment);

    boolean existsByUserIdAndMilestone(UUID userId, String milestone);

    /** Usado na exclusão de conta (LGPD). */
    void deleteByUserId(UUID userId);
}
