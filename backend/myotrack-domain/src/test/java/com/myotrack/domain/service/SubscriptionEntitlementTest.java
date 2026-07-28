package com.myotrack.domain.service;

import static com.myotrack.domain.SubscriptionProvider.APP_STORE;
import static com.myotrack.domain.SubscriptionProvider.GOOGLE_PLAY;
import static com.myotrack.domain.SubscriptionProvider.STRIPE;
import static org.assertj.core.api.Assertions.assertThat;

import com.myotrack.domain.SubscriptionProvider;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.NullAndEmptySource;
import org.junit.jupiter.params.provider.ValueSource;

class SubscriptionEntitlementTest {

    @Nested
    @DisplayName("Stripe")
    class Stripe {

        @ParameterizedTest
        @ValueSource(strings = {"active", "trialing", "past_due", "ACTIVE", " active "})
        void entitledStatuses(String status) {
            assertThat(SubscriptionEntitlement.isEntitled(STRIPE, status)).isTrue();
        }

        @ParameterizedTest
        @ValueSource(strings = {"canceled", "unpaid", "incomplete", "incomplete_expired", "paused"})
        void notEntitledStatuses(String status) {
            assertThat(SubscriptionEntitlement.isEntitled(STRIPE, status)).isFalse();
        }

        @Test
        @DisplayName("past_due mantém o acesso, mas sinalizado como falha de cobrança")
        void pastDueIsGrace() {
            assertThat(SubscriptionEntitlement.isEntitled(STRIPE, "past_due")).isTrue();
            assertThat(SubscriptionEntitlement.isInGracePeriod(STRIPE, "past_due")).isTrue();
            assertThat(SubscriptionEntitlement.isInGracePeriod(STRIPE, "active")).isFalse();
        }
    }

    @Nested
    @DisplayName("App Store")
    class AppStore {

        @Test
        @DisplayName("Active(1), Billing Retry(3) e Grace Period(4) dão acesso")
        void entitledStatuses() {
            assertThat(SubscriptionEntitlement.isEntitled(APP_STORE, "1")).isTrue();
            assertThat(SubscriptionEntitlement.isEntitled(APP_STORE, "3")).isTrue();
            assertThat(SubscriptionEntitlement.isEntitled(APP_STORE, "4")).isTrue();
        }

        @Test
        @DisplayName("Expired(2) e Revoked(5) cortam o acesso")
        void notEntitledStatuses() {
            assertThat(SubscriptionEntitlement.isEntitled(APP_STORE, "2")).isFalse();
            // Revoked é reembolso ou remoção do compartilhamento familiar: corta na hora.
            assertThat(SubscriptionEntitlement.isEntitled(APP_STORE, "5")).isFalse();
        }

        @Test
        void billingRetryAndGraceAreFlaggedAsGrace() {
            assertThat(SubscriptionEntitlement.isInGracePeriod(APP_STORE, "3")).isTrue();
            assertThat(SubscriptionEntitlement.isInGracePeriod(APP_STORE, "4")).isTrue();
            assertThat(SubscriptionEntitlement.isInGracePeriod(APP_STORE, "1")).isFalse();
        }
    }

    @Nested
    @DisplayName("Google Play")
    class GooglePlay {

        @Test
        @DisplayName("CANCELED ainda dá acesso — no Google significa 'não renova', não 'acabou'")
        void canceledKeepsAccessUntilPeriodEnd() {
            // Cortar aqui tiraria dias que o usuário já pagou.
            assertThat(SubscriptionEntitlement.isEntitled(GOOGLE_PLAY, "SUBSCRIPTION_STATE_CANCELED"))
                    .isTrue();
            // Mas não é período de graça: o pagamento está em dia.
            assertThat(SubscriptionEntitlement.isInGracePeriod(GOOGLE_PLAY, "SUBSCRIPTION_STATE_CANCELED"))
                    .isFalse();
        }

        @ParameterizedTest
        @ValueSource(strings = {
            "SUBSCRIPTION_STATE_ACTIVE",
            "SUBSCRIPTION_STATE_IN_GRACE_PERIOD",
            "subscription_state_active",
        })
        void entitledStatuses(String status) {
            assertThat(SubscriptionEntitlement.isEntitled(GOOGLE_PLAY, status)).isTrue();
        }

        @ParameterizedTest
        @ValueSource(strings = {
            "SUBSCRIPTION_STATE_EXPIRED",
            // ON_HOLD: a própria loja já suspendeu o acesso.
            "SUBSCRIPTION_STATE_ON_HOLD",
            "SUBSCRIPTION_STATE_PAUSED",
            "SUBSCRIPTION_STATE_PENDING",
        })
        void notEntitledStatuses(String status) {
            assertThat(SubscriptionEntitlement.isEntitled(GOOGLE_PLAY, status)).isFalse();
        }
    }

    @ParameterizedTest
    @NullAndEmptySource
    @ValueSource(strings = {"   ", "estado_que_nao_existe", "ACTIVE_MAYBE"})
    @DisplayName("Status ausente ou desconhecido nunca concede acesso pago")
    void unknownStatusNeverGrantsAccess(String status) {
        for (final SubscriptionProvider provider : SubscriptionProvider.values()) {
            assertThat(SubscriptionEntitlement.isEntitled(provider, status))
                    .as("provider %s, status '%s'", provider, status)
                    .isFalse();
            assertThat(SubscriptionEntitlement.isInGracePeriod(provider, status)).isFalse();
        }
    }

    @Test
    @DisplayName("Assinatura de loja não oferece portal de cobrança — é gerida no aparelho")
    void storeSubscriptionsAreManagedByTheStore() {
        assertThat(STRIPE.isManagedByStore()).isFalse();
        assertThat(APP_STORE.isManagedByStore()).isTrue();
        assertThat(GOOGLE_PLAY.isManagedByStore()).isTrue();
    }
}
