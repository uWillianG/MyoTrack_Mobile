package com.myotrack.api.config;

import org.springframework.boot.context.properties.ConfigurationProperties;

/** Seção "Jwt" dos appsettings.json do .NET. */
@ConfigurationProperties(prefix = "myotrack.jwt")
public record JwtProperties(
        String issuer,
        String audience,
        String signingKey,
        int accessTokenMinutes,
        int refreshTokenDays) {

    public JwtProperties {
        issuer = issuer == null ? "MyoTrack" : issuer;
        audience = audience == null ? "MyoTrack" : audience;
        accessTokenMinutes = accessTokenMinutes <= 0 ? 15 : accessTokenMinutes;
        refreshTokenDays = refreshTokenDays <= 0 ? 30 : refreshTokenDays;
    }
}
