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
 * Código de uso único que o callback do OAuth entrega ao cliente. O par de tokens
 * nunca viaja na URL de redirecionamento (ficaria no histórico do navegador e nos
 * logs de proxy) — o cliente troca este código por eles num POST.
 */
@Entity
@Table(name = "LoginCodes")
@Getter
@Setter
public class LoginCode {

    @Id
    @GeneratedValue
    @Column(name = "Id")
    private UUID id;

    @Column(name = "UserId", nullable = false)
    private UUID userId;

    /** Hash SHA-256 do código — o valor bruto nunca é persistido. */
    @Column(name = "CodeHash", nullable = false, length = 64)
    private String codeHash;

    @Column(name = "ExpiresAt", nullable = false)
    private OffsetDateTime expiresAt;

    @Column(name = "CreatedAt", nullable = false)
    private OffsetDateTime createdAt = OffsetDateTime.now();

    @Column(name = "UsedAt")
    private OffsetDateTime usedAt;

    @Transient
    public boolean isUsable() {
        return usedAt == null && OffsetDateTime.now().isBefore(expiresAt);
    }
}
