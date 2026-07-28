package com.myotrack.infrastructure.repository;

import com.myotrack.domain.entity.ConsentRecord;
import java.util.List;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;

public interface ConsentRecordRepository extends JpaRepository<ConsentRecord, UUID> {

    /** Trilha de consentimento, do mais recente para o mais antigo. */
    List<ConsentRecord> findByUserIdOrderByGrantedAtDesc(UUID userId);

    void deleteByUserId(UUID userId);
}
