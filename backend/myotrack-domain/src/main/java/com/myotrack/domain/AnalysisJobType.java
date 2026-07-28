package com.myotrack.domain;

import com.fasterxml.jackson.annotation.JsonCreator;
import com.fasterxml.jackson.annotation.JsonValue;

public enum AnalysisJobType implements WireEnum {

    WORKOUT_GENERATION(1, "WorkoutGeneration"),
    DIET_GENERATION(2, "DietGeneration"),
    MEAL_PHOTO(3, "MealPhoto"),
    EXERCISE_VIDEO(4, "ExerciseVideo"),
    COACH_CHAT(5, "CoachChat"),
    WEEKLY_REPORT(6, "WeeklyReport");

    private final int value;
    private final String wireName;

    AnalysisJobType(int value, String wireName) {
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
    public static AnalysisJobType fromWireName(String name) {
        return WireEnums.fromWireName(AnalysisJobType.class, name);
    }

    public static AnalysisJobType fromValue(int value) {
        return WireEnums.fromValue(AnalysisJobType.class, value);
    }
}
