package com.myotrack.api.config;

import org.springframework.boot.context.properties.ConfigurationProperties;

/**
 * URL pública por onde o usuário acessa o sistema. É a base dos links enviados
 * por e-mail e do redirect do OAuth — em desenvolvimento aponta para o Vite
 * (que faz proxy de {@code /api}), em produção para o domínio servido pelo Caddy.
 */
@ConfigurationProperties(prefix = "myotrack.app")
public record AppProperties(String publicBaseUrl) {

    public AppProperties {
        publicBaseUrl = publicBaseUrl == null || publicBaseUrl.isBlank()
                ? "http://localhost:5173"
                : publicBaseUrl.replaceAll("/+$", "");
    }
}
