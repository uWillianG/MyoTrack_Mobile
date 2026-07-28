package com.myotrack.api.auth;

import org.springframework.boot.context.properties.ConfigurationProperties;

/**
 * Credenciais do OAuth client (tipo "Web application") criado no Google Cloud Console.
 * O redirect autorizado deve ser {@code myotrack.app.public-base-url} +
 * {@code /api/auth/google/callback}. Sem as duas credenciais o recurso fica desligado e o botão
 * "Continuar com Google" não aparece na tela de login.
 *
 * <p>{@code androidClientIds} são os client ids do tipo "Android"/"Web" que o app usa no
 * Credential Manager — o ID token que ele devolve tem um deles no {@code aud}, e é contra essa
 * lista que a validação acontece.
 */
@ConfigurationProperties(prefix = "myotrack.auth.google")
public record GoogleOAuthProperties(
        String clientId,
        String clientSecret,
        java.util.List<String> androidClientIds) {

    public GoogleOAuthProperties {
        clientId = clientId == null ? "" : clientId.trim();
        clientSecret = clientSecret == null ? "" : clientSecret.trim();
        androidClientIds = androidClientIds == null ? java.util.List.of() : androidClientIds;
    }

    /** O fluxo web (start/callback/exchange) exige as duas credenciais. */
    public boolean isEnabled() {
        return !clientId.isBlank() && !clientSecret.isBlank();
    }

    /**
     * O login nativo do Android só precisa saber quais audiences aceitar — não usa o secret.
     * Vale mesmo que só o clientId esteja configurado.
     */
    public java.util.List<String> acceptedAudiences() {
        java.util.List<String> audiences = new java.util.ArrayList<>(androidClientIds);
        if (!clientId.isBlank()) {
            audiences.add(clientId);
        }
        return audiences;
    }
}
