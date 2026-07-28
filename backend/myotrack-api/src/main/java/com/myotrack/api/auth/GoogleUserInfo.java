package com.myotrack.api.auth;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import com.fasterxml.jackson.annotation.JsonProperty;

/** Perfil devolvido pelo endpoint de userinfo do Google (ou extraído do ID token). */
@JsonIgnoreProperties(ignoreUnknown = true)
public record GoogleUserInfo(
        @JsonProperty("sub") String sub,
        @JsonProperty("email") String email,
        @JsonProperty("email_verified") boolean emailVerified,
        @JsonProperty("name") String name,
        @JsonProperty("given_name") String givenName) {

    /** Nome preferido para exibição: o primeiro nome, caindo para o nome completo. */
    public String preferredDisplayName() {
        return givenName == null || givenName.isBlank() ? name : givenName;
    }
}
