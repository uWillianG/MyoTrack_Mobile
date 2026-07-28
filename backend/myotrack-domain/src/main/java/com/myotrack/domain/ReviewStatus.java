package com.myotrack.domain;

import com.fasterxml.jackson.annotation.JsonCreator;
import com.fasterxml.jackson.annotation.JsonValue;

/** Supervisão humana (Trainer/Nutritionist) sobre planos gerados por IA. */
public enum ReviewStatus implements WireEnum {

    NOT_REVIEWED(0, "NotReviewed"),
    APPROVED(1, "Approved"),
    CHANGES_REQUESTED(2, "ChangesRequested");

    private final int value;
    private final String wireName;

    ReviewStatus(int value, String wireName) {
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
    public static ReviewStatus fromWireName(String name) {
        return WireEnums.fromWireName(ReviewStatus.class, name);
    }

    public static ReviewStatus fromValue(int value) {
        return WireEnums.fromValue(ReviewStatus.class, value);
    }
}
