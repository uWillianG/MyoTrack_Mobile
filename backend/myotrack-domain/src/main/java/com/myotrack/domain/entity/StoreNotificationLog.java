package com.myotrack.domain.entity;

import com.myotrack.domain.SubscriptionProvider;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import java.time.OffsetDateTime;
import lombok.Getter;
import lombok.Setter;

/**
 * Notificações de assinatura já processadas — mesmo papel que {@link StripeEventLog} cumpre para
 * o Stripe.
 *
 * <p>Apple e Google reentregam a notificação até receberem um 2xx, então receber o mesmo evento
 * duas vezes é o caso comum, não a exceção. Sem este registro, uma reentrega de "renovou"
 * estenderia o período de novo, e uma de "cancelou" poderia desfazer uma reativação posterior.
 */
@Entity
@Table(name = "StoreNotificationLogs")
@Getter
@Setter
public class StoreNotificationLog {

    /** Chave natural do provedor: {@code notificationUUID} (Apple) ou o messageId do Pub/Sub (Google). */
    @Id
    @Column(name = "Id", length = 255)
    private String id;

    @Column(name = "Provider", nullable = false)
    private SubscriptionProvider provider;

    @Column(name = "Type", nullable = false, length = 100)
    private String type;

    @Column(name = "ProcessedAt", nullable = false)
    private OffsetDateTime processedAt = OffsetDateTime.now();
}
