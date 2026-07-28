package com.myotrack.infrastructure.repository;

import com.myotrack.infrastructure.identity.RefreshToken;
import java.time.OffsetDateTime;
import java.util.Optional;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;

public interface RefreshTokenRepository extends JpaRepository<RefreshToken, UUID> {

    Optional<RefreshToken> findByTokenHash(String tokenHash);

    /**
     * Encerra todas as sessões abertas do usuário. Chamado ao redefinir a senha: quem tomou a
     * conta não pode continuar dentro com um refresh token antigo.
     */
    @Modifying
    @Query("""
            update RefreshToken t
            set t.revokedAt = :revokedAt
            where t.userId = :userId and t.revokedAt is null
            """)
    int revokeAllForUser(UUID userId, OffsetDateTime revokedAt);

    void deleteByUserId(UUID userId);
}
