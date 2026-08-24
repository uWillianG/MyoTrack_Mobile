package com.myotrack.api.billing;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.node.ObjectNode;
import java.nio.charset.StandardCharsets;
import java.security.KeyFactory;
import java.security.PrivateKey;
import java.security.Signature;
import java.security.spec.PKCS8EncodedKeySpec;
import java.time.Clock;
import java.time.Duration;
import java.time.Instant;
import java.util.Base64;
import org.springframework.stereotype.Component;

/**
 * Emite o token com que o servidor se identifica na App Store Server API.
 *
 * <p>A Apple não usa chave fixa: cada requisição leva um JWT ES256 assinado com a chave privada
 * baixada do App Store Connect, e ele vale por pouco tempo. Aqui ele é reaproveitado enquanto
 * está válido — assinar um por chamada é barato, mas gerar um token novo a cada consulta em uma
 * hora de pico é desperdício sem contrapartida.
 *
 * <p>A validade é de meia hora, e não da máxima de uma: a diferença não custa nada e evita a
 * classe de bug em que o token expira entre montar a requisição e a Apple recebê-la.
 */
@Component
public class AppStoreServerTokens {

    /** Audience fixa da App Store Server API. */
    static final String AUDIENCE = "appstoreconnect-v1";

    private static final Duration LIFETIME = Duration.ofMinutes(30);

    /** Margem para não entregar um token que expira no caminho. */
    private static final Duration EARLY_RENEWAL = Duration.ofMinutes(2);

    private static final ObjectMapper MAPPER = new ObjectMapper();

    private final AppStoreProperties properties;
    private final Clock clock;

    private volatile Token current;

    public AppStoreServerTokens(AppStoreProperties properties, Clock clock) {
        this.properties = properties;
        this.clock = clock;
    }

    /** O token atual, emitido de novo se o anterior estiver perto de vencer. */
    public String bearer() {
        final Instant now = clock.instant();
        final Token cached = current;

        if (cached != null && now.isBefore(cached.expiresAt().minus(EARLY_RENEWAL))) {
            return cached.value();
        }

        final Instant expiresAt = now.plus(LIFETIME);
        final Token token = new Token(sign(now, expiresAt), expiresAt);
        current = token;
        return token.value();
    }

    private String sign(Instant issuedAt, Instant expiresAt) {
        final ObjectNode header = MAPPER.createObjectNode();
        header.put("alg", "ES256");
        header.put("kid", properties.keyId());
        header.put("typ", "JWT");

        final ObjectNode payload = MAPPER.createObjectNode();
        payload.put("iss", properties.issuerId());
        payload.put("iat", issuedAt.getEpochSecond());
        payload.put("exp", expiresAt.getEpochSecond());
        payload.put("aud", AUDIENCE);
        // O bundle id no token é o que amarra a chave a este app: a mesma chave do App Store
        // Connect serve para vários, e sem isto uma configuração trocada consultaria o app errado
        // e devolveria "assinatura não encontrada" sem dizer por quê.
        payload.put("bid", properties.bundleId());

        final String signingInput = encode(header.toString()) + "." + encode(payload.toString());

        try {
            final Signature signature = Signature.getInstance("SHA256withECDSAinP1363Format");
            signature.initSign(privateKey());
            signature.update(signingInput.getBytes(StandardCharsets.US_ASCII));

            return signingInput + "." + Base64.getUrlEncoder().withoutPadding()
                    .encodeToString(signature.sign());
        } catch (Exception e) {
            throw new IllegalStateException("Não foi possível assinar o token da App Store.", e);
        }
    }

    /** A .p8 do App Store Connect é uma chave EC em PKCS#8 — o formato que o JDK lê direto. */
    private PrivateKey privateKey() throws Exception {
        final String pem = properties.privateKey()
                .replace("-----BEGIN PRIVATE KEY-----", "")
                .replace("-----END PRIVATE KEY-----", "")
                .replaceAll("\\s", "");

        return KeyFactory.getInstance("EC")
                .generatePrivate(new PKCS8EncodedKeySpec(Base64.getDecoder().decode(pem)));
    }

    private static String encode(String json) {
        return Base64.getUrlEncoder().withoutPadding()
                .encodeToString(json.getBytes(StandardCharsets.UTF_8));
    }

    private record Token(String value, Instant expiresAt) {
    }
}
