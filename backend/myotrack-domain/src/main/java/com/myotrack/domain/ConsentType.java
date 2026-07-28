package com.myotrack.domain;

import com.fasterxml.jackson.annotation.JsonCreator;
import com.fasterxml.jackson.annotation.JsonValue;

public enum ConsentType implements WireEnum {

    HEALTH_DATA(1, "HealthData"),
    MEDIA_AI_ANALYSIS(2, "MediaAiAnalysis"),
    TERMS_OF_SERVICE(3, "TermsOfService"),
    PRIVACY_POLICY(4, "PrivacyPolicy");

    private final int value;
    private final String wireName;

    ConsentType(int value, String wireName) {
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
    public static ConsentType fromWireName(String name) {
        return WireEnums.fromWireName(ConsentType.class, name);
    }

    public static ConsentType fromValue(int value) {
        return WireEnums.fromValue(ConsentType.class, value);
    }
}
