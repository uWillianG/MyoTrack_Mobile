package com.myotrack.domain;

import com.fasterxml.jackson.annotation.JsonCreator;
import com.fasterxml.jackson.annotation.JsonValue;

public enum Biotype implements WireEnum {

    ECTOMORPH(1, "Ectomorph"),
    MESOMORPH(2, "Mesomorph"),
    ENDOMORPH(3, "Endomorph");

    private final int value;
    private final String wireName;

    Biotype(int value, String wireName) {
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
    public static Biotype fromWireName(String name) {
        return WireEnums.fromWireName(Biotype.class, name);
    }

    public static Biotype fromValue(int value) {
        return WireEnums.fromValue(Biotype.class, value);
    }
}
