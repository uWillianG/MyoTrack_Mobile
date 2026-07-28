package com.myotrack.api.auth;

import java.util.List;
import org.springframework.boot.context.properties.ConfigurationProperties;

/**
 * Sign in with Apple. Diferente do Google, o app nativo não precisa de client secret: ele obtém
 * um identity token assinado pela Apple e o backend só valida a assinatura contra o JWKS público.
 *
 * <p>{@code audiences} são os identificadores que podem aparecer no claim {@code aud}: o bundle id
 * do app iOS e, se o login com Apple for oferecido na web um dia, o Services ID. Vazio ⇒ o recurso
 * fica desligado e o botão não aparece no app.
 */
@ConfigurationProperties(prefix = "myotrack.auth.apple")
public record AppleOAuthProperties(List<String> audiences) {

    public AppleOAuthProperties {
        audiences = audiences == null
                ? List.of()
                : audiences.stream().map(String::trim).filter(a -> !a.isBlank()).toList();
    }

    public boolean isEnabled() {
        return !audiences.isEmpty();
    }
}
