package com.myotrack.domain;

import com.fasterxml.jackson.annotation.JsonCreator;
import com.fasterxml.jackson.annotation.JsonValue;

public enum FitnessGoal implements WireEnum {

    HYPERTROPHY(1, "Hypertrophy"),
    WEIGHT_LOSS(2, "WeightLoss"),
    CONDITIONING(3, "Conditioning"),
    AESTHETICS(4, "Aesthetics");

    private final int value;
    private final String wireName;

    FitnessGoal(int value, String wireName) {
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
    public static FitnessGoal fromWireName(String name) {
        return WireEnums.fromWireName(FitnessGoal.class, name);
    }

    public static FitnessGoal fromValue(int value) {
        return WireEnums.fromValue(FitnessGoal.class, value);
    }
}
