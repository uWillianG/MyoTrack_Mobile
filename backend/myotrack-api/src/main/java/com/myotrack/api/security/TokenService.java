package com.myotrack.api.security;

import com.myotrack.api.config.JwtProperties;
import com.myotrack.infrastructure.identity.ApplicationUser;
import com.nimbusds.jose.JOSEException;
import com.nimbusds.jose.JWSAlgorithm;
import com.nimbusds.jose.JWSHeader;
import com.nimbusds.jose.crypto.MACSigner;
import com.nimbusds.jwt.JWTClaimsSet;
import com.nimbusds.jwt.SignedJWT;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.security.SecureRandom;
import java.time.Instant;
import java.time.OffsetDateTime;
import java.time.temporal.ChronoUnit;
import java.util.Base64;
import java.util.Collection;
import java.util.Date;
import java.util.HexFormat;
import java.util.List;
import java.util.UUID;
import org.springframework.stereotype.Service;

/**
 * Emite o par access/refresh. Porte de MyoTrack.Api/Services/TokenService.cs.
 *
 * <p>O access token é um JWT HS256 curto (15 min); o refresh é opaco (64 bytes aleatórios) e só
 * o hash vai para o banco. O cliente troca um pelo outro em {@code POST /api/auth/refresh}.
 */
@Service
public class TokenService {

    /** Nome que o .NET usa para o claim de papel. Emitimos os dois por compatibilidade. */
    public static final String DOTNET_ROLE_CLAIM =
            "http://schemas.microsoft.com/ws/2008/06/identity/claims/role";

    public static final String ROLE_CLAIM = "role";

    private final JwtProperties properties;
    private final SecureRandom random = new SecureRandom();

    public TokenService(JwtProperties properties) {
        this.properties = properties;
    }

    public TokenPair createTokenPair(ApplicationUser user, Collection<String> roles) {
        Instant now = Instant.now();
        Instant expiresAt = now.plus(properties.accessTokenMinutes(), ChronoUnit.MINUTES);
        List<String> roleList = List.copyOf(roles);

        JWTClaimsSet claims = new JWTClaimsSet.Builder()
                .issuer(properties.issuer())
                .audience(properties.audience())
                .subject(user.getId().toString())
                .claim("email", user.getEmail() == null ? "" : user.getEmail())
                .jwtID(UUID.randomUUID().toString())
                // O claim curto é o que o app novo lê; o longo mantém a SPA em produção funcionando
                // enquanto os dois backends convivem.
                .claim(ROLE_CLAIM, roleList)
                .claim(DOTNET_ROLE_CLAIM, roleList)
                .issueTime(Date.from(now))
                .notBeforeTime(Date.from(now))
                .expirationTime(Date.from(expiresAt))
                .build();

        String accessToken = sign(claims);
        String refreshToken = newRefreshToken();

        return new TokenPair(
                accessToken,
                refreshToken,
                OffsetDateTime.now().plusDays(properties.refreshTokenDays()));
    }

    private String sign(JWTClaimsSet claims) {
        try {
            SignedJWT jwt = new SignedJWT(new JWSHeader(JWSAlgorithm.HS256), claims);
            jwt.sign(new MACSigner(properties.signingKey().getBytes(StandardCharsets.UTF_8)));
            return jwt.serialize();
        } catch (JOSEException e) {
            // Chave curta demais (< 256 bits) é erro de configuração, não de requisição.
            throw new IllegalStateException("Falha ao assinar o access token.", e);
        }
    }

    private String newRefreshToken() {
        byte[] bytes = new byte[64];
        random.nextBytes(bytes);
        return Base64.getEncoder().encodeToString(bytes);
    }

    /**
     * SHA-256 em hexadecimal MAIÚSCULO — é o formato que o {@code Convert.ToHexString} do .NET
     * gravou nas linhas existentes de RefreshTokens/LoginCodes. Minúsculo não casaria com elas.
     */
    public static String hashToken(String token) {
        try {
            byte[] digest = MessageDigest.getInstance("SHA-256")
                    .digest(token.getBytes(StandardCharsets.UTF_8));
            return HexFormat.of().withUpperCase().formatHex(digest);
        } catch (NoSuchAlgorithmException e) {
            throw new IllegalStateException("SHA-256 indisponível nesta JVM.", e);
        }
    }

    public record TokenPair(String accessToken, String refreshToken, OffsetDateTime refreshTokenExpiresAt) {
    }
}
