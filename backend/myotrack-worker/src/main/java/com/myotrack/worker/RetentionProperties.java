package com.myotrack.worker;

import org.springframework.boot.context.properties.ConfigurationProperties;

/** Seção "Retention" do appsettings.json do Worker. */
@ConfigurationProperties(prefix = "myotrack.retention")
public record RetentionProperties(int videoDays, int mealPhotoDays) {

    public RetentionProperties {
        videoDays = videoDays <= 0 ? 30 : videoDays;
        mealPhotoDays = mealPhotoDays <= 0 ? 90 : mealPhotoDays;
    }
}
