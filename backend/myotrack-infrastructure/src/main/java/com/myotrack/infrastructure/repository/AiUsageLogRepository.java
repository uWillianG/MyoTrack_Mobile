package com.myotrack.infrastructure.repository;

import com.myotrack.domain.entity.AiUsageLog;
import java.util.List;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;

public interface AiUsageLogRepository extends JpaRepository<AiUsageLog, UUID> {

    List<AiUsageLog> findByUserIdOrderByCreatedAtDesc(UUID userId);

    void deleteByUserId(UUID userId);
}
