package com.myotrack.infrastructure.repository;

import com.myotrack.domain.SubscriptionProvider;
import com.myotrack.domain.entity.UserSubscription;
import java.util.Optional;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;

public interface UserSubscriptionRepository extends JpaRepository<UserSubscription, UUID> {

    Optional<UserSubscription> findByUserId(UUID userId);

    /** Caminho de entrada das notificações das lojas: elas não conhecem o usuário, só a assinatura. */
    Optional<UserSubscription> findByProviderAndProviderSubscriptionId(
            SubscriptionProvider provider, String providerSubscriptionId);

    Optional<UserSubscription> findByStripeSubscriptionId(String stripeSubscriptionId);

    boolean existsByUserIdAndIsActiveTrue(UUID userId);

    /** Usado na exclusão de conta (LGPD). */
    void deleteByUserId(UUID userId);
}
