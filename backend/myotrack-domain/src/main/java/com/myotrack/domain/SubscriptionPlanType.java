package com.myotrack.domain;

import com.fasterxml.jackson.annotation.JsonCreator;
import com.fasterxml.jackson.annotation.JsonValue;

public enum SubscriptionPlanType implements WireEnum {

    FREE(0, "Free"),
    PRO(1, "Pro");

    private final int value;
    private final String wireName;

    SubscriptionPlanType(int value, String wireName) {
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
    public static SubscriptionPlanType fromWireName(String name) {
        return WireEnums.fromWireName(SubscriptionPlanType.class, name);
    }

    public static SubscriptionPlanType fromValue(int value) {
        return WireEnums.fromValue(SubscriptionPlanType.class, value);
    }
}
