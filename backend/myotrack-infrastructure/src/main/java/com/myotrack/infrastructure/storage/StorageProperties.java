package com.myotrack.infrastructure.storage;

import org.springframework.boot.context.properties.ConfigurationProperties;

@ConfigurationProperties(prefix = "myotrack.storage")
public record StorageProperties(
        String endpoint,
        String publicEndpoint,
        String accessKey,
        String secretKey,
        String bucket,
        String region) {

    public StorageProperties {
        endpoint = blankToDefault(endpoint, "http://localhost:9000");
        publicEndpoint = publicEndpoint == null ? "" : publicEndpoint;
        accessKey = blankToDefault(accessKey, "myotrack");
        secretKey = blankToDefault(secretKey, "dev-only-password");
        bucket = blankToDefault(bucket, "myotrack-media");
        // Região do MinIO quando não se configura nada. É o mesmo valor que aparece no
        // escopo da credencial das URLs assinadas hoje.
        region = blankToDefault(region, "us-east-1");
    }

    /**
     * Endpoint que o CLIENTE alcança nas URLs pré-assinadas (ex.: https://dominio/media).
     * Vazio = usa o endpoint interno, suficiente em desenvolvimento.
     */
    public String effectivePublicEndpoint() {
        return publicEndpoint.isBlank() ? endpoint : publicEndpoint;
    }

    private static String blankToDefault(String value, String fallback) {
        return value == null || value.isBlank() ? fallback : value;
    }
}
