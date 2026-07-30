package com.myotrack.domain;

import com.fasterxml.jackson.annotation.JsonCreator;
import com.fasterxml.jackson.annotation.JsonValue;

/**
 * Sistema do aparelho que registrou o token de push.
 *
 * <p>Não é informação de diagnóstico: a mensagem do FCM v1 tem um bloco {@code android} e um
 * bloco {@code apns} com chaves diferentes e incompatíveis entre si — canal de notificação de um
 * lado, cabeçalhos e {@code interruption-level} do outro. Preencher o bloco errado não dá erro;
 * o provedor aceita a mensagem e entrega sem som, ou não entrega, dependendo do estado do
 * aparelho.
 *
 * <p>Valores explícitos porque vão para a coluna {@code integer}, como nos demais enums.
 */
public enum DevicePlatform implements WireEnum {

    ANDROID(0, "Android"),
    IOS(1, "iOS");

    private final int value;
    private final String wireName;

    DevicePlatform(int value, String wireName) {
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

    @JsonCreator
    public static DevicePlatform fromWireName(String name) {
        return WireEnums.fromWireName(DevicePlatform.class, name);
    }

    public static DevicePlatform fromValue(int value) {
        return WireEnums.fromValue(DevicePlatform.class, value);
    }
}
