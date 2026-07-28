package com.myotrack.domain;

import com.fasterxml.jackson.annotation.JsonCreator;
import com.fasterxml.jackson.annotation.JsonValue;

public enum JobStatus implements WireEnum {

    PENDING(0, "Pending"),
    PROCESSING(1, "Processing"),
    COMPLETED(2, "Completed"),
    FAILED(3, "Failed");

    private final int value;
    private final String wireName;

    JobStatus(int value, String wireName) {
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

    /** True quando o job chegou ao fim — o app para de acompanhar o SSE/polling neste ponto. */
    public boolean isTerminal() {
        return this == COMPLETED || this == FAILED;
    }

    @JsonCreator
    public static JobStatus fromWireName(String name) {
        return WireEnums.fromWireName(JobStatus.class, name);
    }

    public static JobStatus fromValue(int value) {
        return WireEnums.fromValue(JobStatus.class, value);
    }
}
