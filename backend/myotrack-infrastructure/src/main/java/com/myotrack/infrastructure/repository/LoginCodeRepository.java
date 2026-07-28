package com.myotrack.infrastructure.repository;

import com.myotrack.infrastructure.identity.LoginCode;
import java.util.Optional;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;

public interface LoginCodeRepository extends JpaRepository<LoginCode, UUID> {

    Optional<LoginCode> findByCodeHash(String codeHash);

    void deleteByUserId(UUID userId);
}
