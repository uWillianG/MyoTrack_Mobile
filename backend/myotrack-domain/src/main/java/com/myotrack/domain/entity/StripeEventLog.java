package com.myotrack.domain.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import java.time.OffsetDateTime;
import lombok.Getter;
import lombok.Setter;

/**
 * Eventos do Stripe já processados — o webhook pode reentregar o mesmo evento,
 * e o registro garante idempotência (além de servir como trilha de auditoria).
 */
@Entity
@Table(name = "StripeEventLogs")
@Getter
@Setter
public class StripeEventLog {

    /** Id do evento no Stripe (evt_...). */
    @Id
    @Column(name = "Id", length = 255)
    private String id;

    @Column(name = "Type", nullable = false, length = 100)
    private String type;

    @Column(name = "ProcessedAt", nullable = false)
    private OffsetDateTime processedAt = OffsetDateTime.now();
}
