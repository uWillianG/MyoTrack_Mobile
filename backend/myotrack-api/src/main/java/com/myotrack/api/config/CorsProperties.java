package com.myotrack.api.config;

import java.util.List;
import org.springframework.boot.context.properties.ConfigurationProperties;

/** Seção "Cors" — origens da SPA. O app Android não passa por CORS. */
@ConfigurationProperties(prefix = "myotrack.cors")
public record CorsProperties(List<String> allowedOrigins) {

    public CorsProperties {
        allowedOrigins = allowedOrigins == null || allowedOrigins.isEmpty()
                ? List.of("http://localhost:5173")
                : allowedOrigins;
    }
}
