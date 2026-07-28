package com.myotrack.api.auth;

import java.time.Duration;
import java.util.List;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.oauth2.core.DelegatingOAuth2TokenValidator;
import org.springframework.security.oauth2.core.OAuth2Error;
import org.springframework.security.oauth2.core.OAuth2TokenValidator;
import org.springframework.security.oauth2.core.OAuth2TokenValidatorResult;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.security.oauth2.jwt.JwtDecoder;
import org.springframework.security.oauth2.jwt.JwtException;
import org.springframework.security.oauth2.jwt.JwtIssuerValidator;
import org.springframework.security.oauth2.jwt.JwtTimestampValidator;
import org.springframework.security.oauth2.jwt.NimbusJwtDecoder;
import org.springframework.stereotype.Service;

/**
 * Valida o identity token do Sign in with Apple.
 *
 * <p>O fluxo nativo é bem mais simples que o OAuth do Google: o app já recebe da Apple um JWT
 * assinado, e ao backend cabe apenas conferir assinatura, emissor, audience e validade. Não há
 * redirect, client secret nem troca de código.
 *
 * <p>A verificação de assinatura usa o {@link NimbusJwtDecoder} do Spring Security apontado para o
 * JWKS público da Apple — ele já cuida de buscar, cachear e rotacionar as chaves.
 */
@Service
public class AppleOAuthService {

    static final String ISSUER = "https://appleid.apple.com";
    static final String JWK_SET_URI = "https://appleid.apple.com/auth/keys";

    private static final Duration CLOCK_SKEW = Duration.ofSeconds(30);

    private final AppleOAuthProperties properties;
    private final JwtDecoder decoder;

    // @Autowired explícito: com dois construtores, o Spring não escolhe sozinho e
    // acaba procurando um construtor padrão que não existe.
    @Autowired
    public AppleOAuthService(AppleOAuthProperties properties) {
        this(properties, defaultDecoder(properties));
    }

    /** Construtor para testes, que injetam um decoder com chave conhecida. */
    AppleOAuthService(AppleOAuthProperties properties, JwtDecoder decoder) {
        this.properties = properties;
        this.decoder = decoder;
    }

    private static JwtDecoder defaultDecoder(AppleOAuthProperties properties) {
        NimbusJwtDecoder decoder = NimbusJwtDecoder.withJwkSetUri(JWK_SET_URI).build();
        decoder.setJwtValidator(validators(properties));
        return decoder;
    }

    static OAuth2TokenValidator<Jwt> validators(AppleOAuthProperties properties) {
        return new DelegatingOAuth2TokenValidator<>(
                new JwtTimestampValidator(CLOCK_SKEW),
                new JwtIssuerValidator(ISSUER),
                new AppleAudienceValidator(properties.audiences()));
    }

    public boolean isEnabled() {
        return properties.isEnabled();
    }

    /**
     * Valida o token e devolve a identidade.
     *
     * @param displayName nome enviado pelo app. A Apple entrega nome e sobrenome <b>apenas na
     *     primeira autorização</b> e nunca dentro do token — vem à parte, na resposta da
     *     autorização. Se não for gravado agora, some para sempre (recuperá-lo exigiria o usuário
     *     revogar o app nos ajustes do iPhone).
     */
    public ExternalIdentity verifyIdToken(String idToken, String displayName) {
        if (!isEnabled()) {
            throw new ExternalAuthException("Login com Apple não está configurado nesta instalação.");
        }

        Jwt jwt;
        try {
            jwt = decoder.decode(idToken);
        } catch (JwtException e) {
            throw new ExternalAuthException("Identity token da Apple inválido ou expirado.", e);
        }

        String email = jwt.getClaimAsString("email");
        if (email == null || email.isBlank() || !isEmailVerified(jwt)) {
            throw new ExternalAuthException("A conta Apple precisa ter um e-mail verificado.");
        }

        return new ExternalIdentity(
                AccountService.APPLE_PROVIDER,
                jwt.getSubject(),
                email,
                displayName == null || displayName.isBlank() ? null : displayName.trim());
    }

    /**
     * A Apple envia {@code email_verified} ora como boolean, ora como a string "true" — depende do
     * fluxo e já mudou entre versões. Ler só como boolean rejeitaria logins válidos.
     */
    private static boolean isEmailVerified(Jwt jwt) {
        Object claim = jwt.getClaim("email_verified");
        if (claim instanceof Boolean verified) {
            return verified;
        }
        return claim != null && Boolean.parseBoolean(claim.toString());
    }

    /** Aceita qualquer um dos identificadores configurados (bundle id do app, Services ID da web). */
    record AppleAudienceValidator(List<String> audiences) implements OAuth2TokenValidator<Jwt> {

        @Override
        public OAuth2TokenValidatorResult validate(Jwt token) {
            List<String> received = token.getAudience();
            if (received != null && received.stream().anyMatch(audiences::contains)) {
                return OAuth2TokenValidatorResult.success();
            }
            return OAuth2TokenValidatorResult.failure(
                    new OAuth2Error("invalid_token", "Audience não corresponde a este app.", null));
        }
    }
}
