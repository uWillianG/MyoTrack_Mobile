package com.myotrack.domain.entity;

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
 * Pro concedido por constância de treino, com prazo.
 *
 * <p>Separado de {@link UserSubscription} de propósito: aquela é o cache do que a loja diz, e o
 * webhook a reescreve. Misturar as duas transformaria uma cortesia em "assinante" para qualquer
 * relatório de receita — e a primeira notificação da loja apagaria a concessão.
 */
@Entity
@Table(name = "ProGrants")
@Getter
@Setter
public class ProGrant {

    @Id
    @GeneratedValue
    @Column(name = "Id")
    private UUID id;

    @Column(name = "UserId", nullable = false)
    private UUID userId;

    /** O id da marca no catálogo — espelha {@code ProMilestone.id()} e o selo que o app mostra. */
    @Column(name = "Milestone", nullable = false, length = 50)
    private String milestone;

    @Column(name = "GrantedAt", nullable = false)
    private OffsetDateTime grantedAt = OffsetDateTime.now();

    @Column(name = "ExpiresAt", nullable = false)
    private OffsetDateTime expiresAt;

    /** A sequência no momento da concessão. Só para auditoria; não decide nada. */
    @Column(name = "StreakWeeks", nullable = false)
    private int streakWeeks;

    public boolean isActiveAt(OffsetDateTime moment) {
        return expiresAt != null && expiresAt.isAfter(moment);
    }
}
