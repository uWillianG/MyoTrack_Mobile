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

/**
 * Token de redefinição de senha, válido por 24 h e de uso único.
 *
 * <p>Substitui o {@code DataProtectionTokenProvider} do Identity, que assinava o token com a
 * chave de Data Protection do .NET em vez de persistir. Ver V2__password_reset_tokens.sql.
 */
@Entity
@Table(name = "PasswordResetTokens")
@Getter
@Setter
public class PasswordResetToken {

    @Id
    @GeneratedValue
    @Column(name = "Id")
    private UUID id;

    @Column(name = "UserId", nullable = false)
    private UUID userId;

    /** Hash SHA-256 do token — o valor bruto só existe dentro do link enviado por e-mail. */
    @Column(name = "TokenHash", nullable = false, length = 64)
    private String tokenHash;

    @Column(name = "CreatedAt", nullable = false)
    private OffsetDateTime createdAt = OffsetDateTime.now();

    @Column(name = "ExpiresAt", nullable = false)
    private OffsetDateTime expiresAt;

    @Column(name = "UsedAt")
    private OffsetDateTime usedAt;

    @Transient
    public boolean isUsable() {
        return usedAt == null && OffsetDateTime.now().isBefore(expiresAt);
    }
}
