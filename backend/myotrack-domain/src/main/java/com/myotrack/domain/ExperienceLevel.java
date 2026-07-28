package com.myotrack.domain;

import com.fasterxml.jackson.annotation.JsonCreator;
import com.fasterxml.jackson.annotation.JsonValue;

public enum ExperienceLevel implements WireEnum {

    BEGINNER(1, "Beginner"),
    INTERMEDIATE(2, "Intermediate"),
    ADVANCED(3, "Advanced");

    private final int value;
    private final String wireName;

    ExperienceLevel(int value, String wireName) {
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
    public static ExperienceLevel fromWireName(String name) {
        return WireEnums.fromWireName(ExperienceLevel.class, name);
    }

    public static ExperienceLevel fromValue(int value) {
        return WireEnums.fromValue(ExperienceLevel.class, value);
    }
}
