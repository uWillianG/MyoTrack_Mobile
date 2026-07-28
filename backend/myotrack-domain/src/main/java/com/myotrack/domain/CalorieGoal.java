package com.myotrack.domain;

import com.fasterxml.jackson.annotation.JsonCreator;
import com.fasterxml.jackson.annotation.JsonValue;

public enum CalorieGoal implements WireEnum {

    DEFICIT(1, "Deficit"),
    MAINTENANCE(2, "Maintenance"),
    SURPLUS(3, "Surplus");

    private final int value;
    private final String wireName;

    CalorieGoal(int value, String wireName) {
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
    public static CalorieGoal fromWireName(String name) {
        return WireEnums.fromWireName(CalorieGoal.class, name);
    }

    public static CalorieGoal fromValue(int value) {
        return WireEnums.fromValue(CalorieGoal.class, value);
    }
}
