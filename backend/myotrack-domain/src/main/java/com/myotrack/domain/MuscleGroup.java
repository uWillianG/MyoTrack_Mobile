package com.myotrack.domain;

import com.fasterxml.jackson.annotation.JsonCreator;
import com.fasterxml.jackson.annotation.JsonValue;

public enum MuscleGroup implements WireEnum {

    CHEST(1, "Chest"),
    BACK(2, "Back"),
    SHOULDERS(3, "Shoulders"),
    BICEPS(4, "Biceps"),
    TRICEPS(5, "Triceps"),
    FOREARMS(6, "Forearms"),
    QUADRICEPS(7, "Quadriceps"),
    HAMSTRINGS(8, "Hamstrings"),
    GLUTES(9, "Glutes"),
    CALVES(10, "Calves"),
    ABS(11, "Abs"),
    LOWER_BACK(12, "LowerBack"),
    FULL_BODY(13, "FullBody"),
    CARDIO(14, "Cardio"),
    TRAPS(15, "Traps");

    private final int value;
    private final String wireName;

    MuscleGroup(int value, String wireName) {
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
    public static MuscleGroup fromWireName(String name) {
        return WireEnums.fromWireName(MuscleGroup.class, name);
    }

    public static MuscleGroup fromValue(int value) {
        return WireEnums.fromValue(MuscleGroup.class, value);
    }
}
