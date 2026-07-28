package com.myotrack.api.security;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import com.myotrack.api.config.CorsProperties;
import com.myotrack.api.config.JwtProperties;
import com.myotrack.api.security.TokenService.TokenPair;
import com.myotrack.infrastructure.identity.ApplicationUser;
import java.time.OffsetDateTime;
import java.util.List;
import java.util.UUID;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.security.oauth2.jwt.JwtDecoder;
import org.springframework.security.oauth2.jwt.JwtException;

class TokenServiceTest {

    private static final JwtProperties PROPERTIES = new JwtProperties(
            "MyoTrack", "MyoTrack", "dev-only-signing-key-change-me-in-production-0123456789", 15, 30);

    private final TokenService tokenService = new TokenService(PROPERTIES);
    private final JwtDecoder decoder = decoderFor(PROPERTIES);

    private static JwtDecoder decoderFor(JwtProperties properties) {
        return new SecurityConfig(properties, new CorsProperties(List.of("http://localhost:5173")))
                .jwtDecoder();
    }

    private static ApplicationUser user() {
        ApplicationUser user = new ApplicationUser();
        user.setId(UUID.fromString("11111111-2222-3333-4444-555555555555"));
        user.setEmail("willian@exemplo.com");
        return user;
    }

    @Test
    @DisplayName("O access token emitido é aceito pelo próprio resource server")
    void accessTokenIsAcceptedByTheDecoder() {
        TokenPair pair = tokenService.createTokenPair(user(), List.of("Student"));

        Jwt jwt = decoder.decode(pair.accessToken());

        assertThat(jwt.getSubject()).isEqualTo("11111111-2222-3333-4444-555555555555");
        assertThat(jwt.getClaimAsString("email")).isEqualTo("willian@exemplo.com");
        // getIssuer() converteria para URL; o issuer aqui é um nome simples, herdado do .NET.
        assertThat(jwt.getClaimAsString("iss")).isEqualTo("MyoTrack");
        assertThat(jwt.getAudience()).containsExactly("MyoTrack");
        assertThat(jwt.getId()).isNotBlank();
    }

    @Test
    @DisplayName("Os papéis saem nos dois claims: o curto e o do .NET")
    void rolesAreEmittedInBothClaims() {
        TokenPair pair = tokenService.createTokenPair(user(), List.of("Trainer", "Admin"));
        Jwt jwt = decoder.decode(pair.accessToken());

        assertThat(jwt.getClaimAsStringList(TokenService.ROLE_CLAIM))
                .containsExactly("Trainer", "Admin");
        assertThat(jwt.getClaimAsStringList(TokenService.DOTNET_ROLE_CLAIM))
                .containsExactly("Trainer", "Admin");
    }

    @Test
    void accessTokenExpiresWithinTheConfiguredWindow() {
        Jwt jwt = decoder.decode(tokenService.createTokenPair(user(), List.of()).accessToken());

        assertThat(jwt.getExpiresAt()).isNotNull();
        assertThat(jwt.getIssuedAt()).isNotNull();
        assertThat(java.time.Duration.between(jwt.getIssuedAt(), jwt.getExpiresAt()).toMinutes())
                .isEqualTo(15);
    }

    @Test
    @DisplayName("Token assinado com outra chave é recusado")
    void rejectsTokenSignedWithAnotherKey() {
        JwtProperties other = new JwtProperties(
                "MyoTrack", "MyoTrack", "uma-outra-chave-completamente-diferente-0123456789", 15, 30);
        String foreign = new TokenService(other).createTokenPair(user(), List.of()).accessToken();

        assertThatThrownBy(() -> decoder.decode(foreign)).isInstanceOf(JwtException.class);
    }

    @Test
    @DisplayName("Token de outro issuer é recusado")
    void rejectsTokenFromAnotherIssuer() {
        JwtProperties other = new JwtProperties(
                "Outro", "MyoTrack", PROPERTIES.signingKey(), 15, 30);
        String foreign = new TokenService(other).createTokenPair(user(), List.of()).accessToken();

        assertThatThrownBy(() -> decoder.decode(foreign)).isInstanceOf(JwtException.class);
    }

    @Test
    @DisplayName("Token para outro audience é recusado")
    void rejectsTokenForAnotherAudience() {
        JwtProperties other = new JwtProperties(
                "MyoTrack", "OutroApp", PROPERTIES.signingKey(), 15, 30);
        String foreign = new TokenService(other).createTokenPair(user(), List.of()).accessToken();

        assertThatThrownBy(() -> decoder.decode(foreign)).isInstanceOf(JwtException.class);
    }

    @Test
    void refreshTokenIsOpaqueRandomAndDated() {
        TokenPair first = tokenService.createTokenPair(user(), List.of());
        TokenPair second = tokenService.createTokenPair(user(), List.of());

        assertThat(first.refreshToken()).isNotEqualTo(second.refreshToken());
        // 64 bytes em Base64 = 88 caracteres com padding.
        assertThat(first.refreshToken()).hasSize(88);
        assertThat(first.refreshTokenExpiresAt()).isAfter(OffsetDateTime.now().plusDays(29));
    }

    @Test
    @DisplayName("O hash do refresh token é SHA-256 em hex MAIÚSCULO, como o Convert.ToHexString do .NET")
    void hashTokenMatchesDotNetFormat() {
        // Vetor conhecido: SHA-256 de "abc".
        assertThat(TokenService.hashToken("abc"))
                .isEqualTo("BA7816BF8F01CFEA414140DE5DAE2223B00361A396177A9CB410FF61F20015AD");
        // Determinístico — é assim que a linha é reencontrada no banco.
        assertThat(TokenService.hashToken("abc")).isEqualTo(TokenService.hashToken("abc"));
    }
}
