package com.myotrack.domain;

import com.fasterxml.jackson.annotation.JsonCreator;
import com.fasterxml.jackson.annotation.JsonValue;

public enum Equipment implements WireEnum {

    NONE(0, "None"),
    BARBELL(1, "Barbell"),
    DUMBBELL(2, "Dumbbell"),
    MACHINE(3, "Machine"),
    CABLE(4, "Cable"),
    KETTLEBELL(5, "Kettlebell"),
    RESISTANCE_BAND(6, "ResistanceBand"),
    BODYWEIGHT(7, "Bodyweight"),
    // 99 é o motivo de não dar para usar a ordinal do Java como valor persistido.
    OTHER(99, "Other");

    private final int value;
    private final String wireName;

    Equipment(int value, String wireName) {
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
    public static Equipment fromWireName(String name) {
        return WireEnums.fromWireName(Equipment.class, name);
    }

    public static Equipment fromValue(int value) {
        return WireEnums.fromValue(Equipment.class, value);
    }
}
