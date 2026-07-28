package com.myotrack.domain;

import com.fasterxml.jackson.annotation.JsonCreator;
import com.fasterxml.jackson.annotation.JsonValue;

/**
 * Onde a assinatura foi comprada.
 *
 * <p>Existem três porque as lojas exigem: a App Store recusa app que venda conteúdo digital por
 * fora do seu sistema de compra (diretriz 3.1.1), e o Google Play tem regra equivalente. O Stripe
 * segue atendendo quem assina pela web.
 *
 * <p>Os valores são explícitos porque vão para a coluna {@code integer} — mesma convenção dos
 * demais enums, herdada do backend .NET.
 */
public enum SubscriptionProvider implements WireEnum {

    STRIPE(0, "Stripe"),
    APP_STORE(1, "AppStore"),
    GOOGLE_PLAY(2, "GooglePlay");

    private final int value;
    private final String wireName;

    SubscriptionProvider(int value, String wireName) {
        this.value = value;
        this.wireName = wireName;
    }

    @Override
    public int getValue() {
        return value;
    }

    @Override
    @JsonValue
    public String getWireName() {
        return wireName;
    }

    /**
     * Assinatura de loja não é gerenciada pelo MyoTrack: cancelar e trocar forma de pagamento
     * acontece nos ajustes do aparelho, e a tela precisa saber disso para não oferecer um portal
     * de cobrança que não existe.
     */
    public boolean isManagedByStore() {
        return this != STRIPE;
    }

    @JsonCreator
    public static SubscriptionProvider fromWireName(String name) {
        return WireEnums.fromWireName(SubscriptionProvider.class, name);
    }

    public static SubscriptionProvider fromValue(int value) {
        return WireEnums.fromValue(SubscriptionProvider.class, value);
    }
}
