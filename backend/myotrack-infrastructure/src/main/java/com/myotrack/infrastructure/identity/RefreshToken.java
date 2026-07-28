package com.myotrack.infrastructure.identity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import jakarta.persistence.Transient;
import java.time.OffsetDateTime;
import java.util.UUID;
import lombok.Getter;
import lombok.Setter;

@Entity
@Table(name = "RefreshTokens")
@Getter
@Setter
public class RefreshToken {

    @Id
    @GeneratedValue
    @Column(name = "Id")
    private UUID id;

    @Column(name = "UserId", nullable = false)
    private UUID userId;

    /** Hash SHA-256 do token — o valor bruto nunca é persistido. */
    @Column(name = "TokenHash", nullable = false)
    private String tokenHash;

    @Column(name = "ExpiresAt", nullable = false)
    private OffsetDateTime expiresAt;

    @Column(name = "CreatedAt", nullable = false)
    private OffsetDateTime createdAt = OffsetDateTime.now();

    @Column(name = "RevokedAt")
    private OffsetDateTime revokedAt;

    @Transient
    public boolean isActive() {
        return revokedAt == null && OffsetDateTime.now().isBefore(expiresAt);
    }
}
