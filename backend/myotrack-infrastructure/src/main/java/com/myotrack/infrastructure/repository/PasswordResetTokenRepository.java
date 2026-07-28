package com.myotrack.infrastructure.repository;

import com.myotrack.infrastructure.identity.PasswordResetToken;
import java.time.OffsetDateTime;
import java.util.Optional;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;

public interface PasswordResetTokenRepository extends JpaRepository<PasswordResetToken, UUID> {

    Optional<PasswordResetToken> findByTokenHash(String tokenHash);

    /** Limpeza oportunista: um token vencido não serve para nada e a tabela não deve crescer. */
    @Modifying
    @Query("delete from PasswordResetToken t where t.expiresAt < :now")
    int deleteExpired(OffsetDateTime now);

    void deleteByUserId(UUID userId);
}
