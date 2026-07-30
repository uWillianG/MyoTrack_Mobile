package com.myotrack.domain.entity;

import com.myotrack.domain.DevicePlatform;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import java.time.OffsetDateTime;
import java.util.UUID;
import lombok.Getter;
import lombok.Setter;

/**
 * Endereço de push de uma instalação do app.
 *
 * <p>A linha pertence ao aparelho, não à pessoa: o token sobrevive à troca de conta no mesmo
 * aparelho, então entrar com outro login <b>reatribui</b> o {@code userId} desta linha em vez de
 * criar outra. Ver o comentário de {@code V4__device_tokens.sql}.
 */
@Entity
@Table(name = "DeviceTokens")
@Getter
@Setter
public class DeviceToken {

    @Id
    @GeneratedValue
    @Column(name = "Id")
    private UUID id;

    @Column(name = "UserId", nullable = false)
    private UUID userId;

    /** Token de registro emitido pelo FCM. Único no sistema. */
    @Column(name = "Token", nullable = false)
    private String token;

    @Column(name = "Platform", nullable = false)
    private DevicePlatform platform;

    @Column(name = "CreatedAt", nullable = false)
    private OffsetDateTime createdAt = OffsetDateTime.now();

    /**
     * Último registro vindo do app, que o refaz a cada abertura.
     *
     * <p>É o único sinal de vida disponível: o provedor só revela que um token morreu no momento
     * em que se tenta enviar para ele.
     */
    @Column(name = "LastSeenAt", nullable = false)
    private OffsetDateTime lastSeenAt = OffsetDateTime.now();
}
