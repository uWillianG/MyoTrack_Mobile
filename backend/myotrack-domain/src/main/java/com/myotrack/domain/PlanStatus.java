package com.myotrack.domain;

import com.fasterxml.jackson.annotation.JsonCreator;
import com.fasterxml.jackson.annotation.JsonValue;

public enum PlanStatus implements WireEnum {

    DRAFT(0, "Draft"),
    ACTIVE(1, "Active"),
    ARCHIVED(2, "Archived");

    private final int value;
    private final String wireName;

    PlanStatus(int value, String wireName) {
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
    public static PlanStatus fromWireName(String name) {
        return WireEnums.fromWireName(PlanStatus.class, name);
    }

    public static PlanStatus fromValue(int value) {
        return WireEnums.fromValue(PlanStatus.class, value);
    }
}
