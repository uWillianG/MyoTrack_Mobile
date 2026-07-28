package com.myotrack.domain.entity;

import com.fasterxml.jackson.annotation.JsonProperty;
import com.myotrack.domain.SubscriptionPlanType;
import com.myotrack.domain.SubscriptionProvider;
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
 * Assinatura do usuário. Sem registro (ou inativa) = plano Free.
 * O Stripe é a fonte da verdade; esta tabela é o cache local mantido pelo webhook.
 */
@Entity
@Table(name = "UserSubscriptions")
@Getter
@Setter
public class UserSubscription {

    @Id
    @GeneratedValue
    @Column(name = "Id")
    private UUID id;

    @Column(name = "UserId", nullable = false)
    private UUID userId;

    @Column(name = "Plan", nullable = false)
    private SubscriptionPlanType plan = SubscriptionPlanType.FREE;

    // Mesmo motivo do Exercise.isCompound: o getter do Lombok renomearia para "active".
    @JsonProperty("isActive")
    @Column(name = "IsActive", nullable = false)
    private boolean isActive;

    /** Onde a assinatura foi comprada: Stripe (web), App Store ou Google Play. */
    @Column(name = "Provider", nullable = false)
    private SubscriptionProvider provider = SubscriptionProvider.STRIPE;

    /**
     * Identificador da assinatura no provedor — {@code sub_...} no Stripe,
     * {@code originalTransactionId} na Apple, {@code purchaseToken} no Google.
     * É por ele que uma notificação da loja encontra o usuário.
     */
    @Column(name = "ProviderSubscriptionId")
    private String providerSubscriptionId;

    /** Status bruto do provedor ("active", "SUBSCRIBED", "EXPIRED"…). */
    @Column(name = "ProviderStatus", length = 50)
    private String providerStatus;

    // Campos específicos do Stripe. Continuam preenchidos para as assinaturas web e para o
    // portal de cobrança, que só existe lá.

    @Column(name = "StripeCustomerId")
    private String stripeCustomerId;

    @Column(name = "StripeSubscriptionId")
    private String stripeSubscriptionId;

    /** Status bruto do Stripe (active, trialing, past_due, canceled…) para diagnóstico e UI. */
    @Column(name = "StripeStatus", length = 50)
    private String stripeStatus;

    @Column(name = "CurrentPeriodEnd")
    private OffsetDateTime currentPeriodEnd;

    @Column(name = "CreatedAt", nullable = false)
    private OffsetDateTime createdAt = OffsetDateTime.now();

    @Column(name = "UpdatedAt", nullable = false)
    private OffsetDateTime updatedAt = OffsetDateTime.now();
}
