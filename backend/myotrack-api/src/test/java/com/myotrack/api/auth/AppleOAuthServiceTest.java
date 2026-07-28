package com.myotrack.api.auth;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import com.nimbusds.jose.JOSEObjectType;
import com.nimbusds.jose.JWSAlgorithm;
import com.nimbusds.jose.JWSHeader;
import com.nimbusds.jose.crypto.RSASSASigner;
import com.nimbusds.jose.jwk.RSAKey;
import com.nimbusds.jose.jwk.gen.RSAKeyGenerator;
import com.nimbusds.jwt.JWTClaimsSet;
import com.nimbusds.jwt.SignedJWT;
import java.time.Instant;
import java.time.temporal.ChronoUnit;
import java.util.Date;
import java.util.Arrays;
import java.util.List;
import org.junit.jupiter.api.BeforeAll;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.security.oauth2.jwt.JwtDecoder;
import org.springframework.security.oauth2.jwt.NimbusJwtDecoder;

/**
 * Testa a validação do identity token da Apple com um par de chaves gerado no próprio teste: os
 * tokens são assinados aqui e verificados pelo mesmo caminho de código que roda em produção,
 * trocando apenas a origem da chave pública (JWKS local em vez do endpoint da Apple).
 */
class AppleOAuthServiceTest {

    private static final String BUNDLE_ID = "com.myotrack.app";
    private static final String OTHER_APP = "com.outroapp.fake";

    private static RSAKey signingKey;
    private static AppleOAuthProperties properties;
    private static AppleOAuthService service;

    @BeforeAll
    static void setUp() throws Exception {
        signingKey = new RSAKeyGenerator(2048).keyID("chave-de-teste").generate();
        properties = new AppleOAuthProperties(List.of(BUNDLE_ID));

        JwtDecoder decoder = NimbusJwtDecoder
                .withPublicKey(signingKey.toRSAPublicKey())
                .signatureAlgorithm(org.springframework.security.oauth2.jose.jws.SignatureAlgorithm.RS256)
                .build();
        ((NimbusJwtDecoder) decoder).setJwtValidator(AppleOAuthService.validators(properties));

        service = new AppleOAuthService(properties, decoder);
    }

    /** Monta um token no formato que a Apple emite. */
    private static String token(
            String audience, String subject, Object emailVerified, String email, Instant expiresAt)
            throws Exception {

        JWTClaimsSet.Builder claims = new JWTClaimsSet.Builder()
                .issuer(AppleOAuthService.ISSUER)
                .audience(audience)
                .subject(subject)
                .issueTime(Date.from(Instant.now().minus(1, ChronoUnit.MINUTES)))
                .expirationTime(Date.from(expiresAt));

        if (email != null) {
            claims.claim("email", email);
        }
        if (emailVerified != null) {
            claims.claim("email_verified", emailVerified);
        }

        SignedJWT jwt = new SignedJWT(
                new JWSHeader.Builder(JWSAlgorithm.RS256)
                        .keyID(signingKey.getKeyID())
                        .type(JOSEObjectType.JWT)
                        .build(),
                claims.build());
        jwt.sign(new RSASSASigner(signingKey));
        return jwt.serialize();
    }

    private static String validToken() throws Exception {
        return token(BUNDLE_ID, "001234.abcdef", true, "willian@exemplo.com",
                Instant.now().plus(10, ChronoUnit.MINUTES));
    }

    @Test
    @DisplayName("Token válido devolve a identidade com provider Apple")
    void acceptsValidToken() throws Exception {
        ExternalIdentity identity = service.verifyIdToken(validToken(), "Willian");

        assertThat(identity.provider()).isEqualTo(AccountService.APPLE_PROVIDER);
        assertThat(identity.subject()).isEqualTo("001234.abcdef");
        assertThat(identity.email()).isEqualTo("willian@exemplo.com");
        assertThat(identity.displayName()).isEqualTo("Willian");
    }

    @Test
    @DisplayName("email_verified como string \"true\" é aceito — a Apple alterna entre os dois formatos")
    void acceptsEmailVerifiedAsString() throws Exception {
        String jwt = token(BUNDLE_ID, "001234.abcdef", "true", "willian@exemplo.com",
                Instant.now().plus(10, ChronoUnit.MINUTES));

        assertThat(service.verifyIdToken(jwt, null).email()).isEqualTo("willian@exemplo.com");
    }

    @Test
    @DisplayName("E-mail de relay da Apple é um endereço válido como qualquer outro")
    void acceptsPrivateRelayEmail() throws Exception {
        String jwt = token(BUNDLE_ID, "001234.abcdef", true,
                "abc123@privaterelay.appleid.com", Instant.now().plus(10, ChronoUnit.MINUTES));

        assertThat(service.verifyIdToken(jwt, null).email())
                .isEqualTo("abc123@privaterelay.appleid.com");
    }

    @Test
    @DisplayName("Nome ausente vira null — a Apple só o envia na primeira autorização")
    void missingDisplayNameBecomesNull() throws Exception {
        assertThat(service.verifyIdToken(validToken(), null).displayName()).isNull();
        assertThat(service.verifyIdToken(validToken(), "   ").displayName()).isNull();
    }

    @Test
    @DisplayName("Token de outro app é recusado — impede reaproveitar token de terceiros")
    void rejectsTokenForAnotherAudience() throws Exception {
        String jwt = token(OTHER_APP, "001234.abcdef", true, "willian@exemplo.com",
                Instant.now().plus(10, ChronoUnit.MINUTES));

        assertThatThrownBy(() -> service.verifyIdToken(jwt, null))
                .isInstanceOf(ExternalAuthException.class);
    }

    @Test
    void rejectsExpiredToken() throws Exception {
        String jwt = token(BUNDLE_ID, "001234.abcdef", true, "willian@exemplo.com",
                Instant.now().minus(10, ChronoUnit.MINUTES));

        assertThatThrownBy(() -> service.verifyIdToken(jwt, null))
                .isInstanceOf(ExternalAuthException.class);
    }

    @Test
    @DisplayName("Token assinado por outra chave é recusado")
    void rejectsTokenSignedByAnotherKey() throws Exception {
        RSAKey intruso = new RSAKeyGenerator(2048).keyID("chave-intrusa").generate();

        SignedJWT jwt = new SignedJWT(
                new JWSHeader.Builder(JWSAlgorithm.RS256).keyID(intruso.getKeyID()).build(),
                new JWTClaimsSet.Builder()
                        .issuer(AppleOAuthService.ISSUER)
                        .audience(BUNDLE_ID)
                        .subject("001234.abcdef")
                        .claim("email", "willian@exemplo.com")
                        .claim("email_verified", true)
                        .expirationTime(Date.from(Instant.now().plus(10, ChronoUnit.MINUTES)))
                        .build());
        jwt.sign(new RSASSASigner(intruso));

        assertThatThrownBy(() -> service.verifyIdToken(jwt.serialize(), null))
                .isInstanceOf(ExternalAuthException.class);
    }

    @Test
    @DisplayName("Token de outro emissor é recusado")
    void rejectsTokenFromAnotherIssuer() throws Exception {
        SignedJWT jwt = new SignedJWT(
                new JWSHeader.Builder(JWSAlgorithm.RS256).keyID(signingKey.getKeyID()).build(),
                new JWTClaimsSet.Builder()
                        .issuer("https://accounts.google.com")
                        .audience(BUNDLE_ID)
                        .subject("001234.abcdef")
                        .claim("email", "willian@exemplo.com")
                        .claim("email_verified", true)
                        .expirationTime(Date.from(Instant.now().plus(10, ChronoUnit.MINUTES)))
                        .build());
        jwt.sign(new RSASSASigner(signingKey));

        assertThatThrownBy(() -> service.verifyIdToken(jwt.serialize(), null))
                .isInstanceOf(ExternalAuthException.class);
    }

    @Test
    @DisplayName("Sem e-mail verificado o login é recusado")
    void rejectsUnverifiedOrMissingEmail() throws Exception {
        String naoVerificado = token(BUNDLE_ID, "001234.abcdef", false, "willian@exemplo.com",
                Instant.now().plus(10, ChronoUnit.MINUTES));
        assertThatThrownBy(() -> service.verifyIdToken(naoVerificado, null))
                .isInstanceOf(ExternalAuthException.class);

        String semEmail = token(BUNDLE_ID, "001234.abcdef", true, null,
                Instant.now().plus(10, ChronoUnit.MINUTES));
        assertThatThrownBy(() -> service.verifyIdToken(semEmail, null))
                .isInstanceOf(ExternalAuthException.class);
    }

    @Test
    @DisplayName("Sem audiences configurados o recurso fica desligado")
    void disabledWithoutAudiences() {
        AppleOAuthService desligado = new AppleOAuthService(
                new AppleOAuthProperties(List.of()), t -> null);

        assertThat(desligado.isEnabled()).isFalse();
        assertThatThrownBy(() -> desligado.verifyIdToken("qualquer.coisa", null))
                .isInstanceOf(ExternalAuthException.class)
                .hasMessageContaining("não está configurado");
    }

    @Test
    @DisplayName("Múltiplos audiences convivem; entradas em branco são descartadas")
    void acceptsAnyConfiguredAudience() {
        // Uma lista vinda de variável de ambiente pode trazer entradas vazias.
        AppleOAuthProperties multi = new AppleOAuthProperties(
                Arrays.asList(BUNDLE_ID, "  com.myotrack.web  ", "", "   "));

        assertThat(multi.audiences()).containsExactly(BUNDLE_ID, "com.myotrack.web");
        assertThat(multi.isEnabled()).isTrue();
    }
}
