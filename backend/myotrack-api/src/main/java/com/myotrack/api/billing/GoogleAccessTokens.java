package com.myotrack.api.billing;

import com.fasterxml.jackson.databind.JsonNode;
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
import org.springframework.http.MediaType;
import org.springframework.stereotype.Component;
import org.springframework.util.LinkedMultiValueMap;
import org.springframework.util.MultiValueMap;
import org.springframework.web.client.RestClient;
import org.springframework.web.client.RestClientException;

/**
 * Troca a conta de serviço do Google por um access token da Play Developer API.
 *
 * <p>É o fluxo JWT bearer, feito à mão como o resto das integrações deste repositório: monta-se
 * um JWT assinado com a chave privada da conta de serviço e o Google devolve um token de uma
 * hora. A alternativa era a biblioteca de autenticação do Google — mais uma dependência, com
 * transitivas próprias, para gerar um JWT de três campos.
 *
 * <p>O token é guardado e reusado até perto de vencer: pedir um novo a cada consulta de recibo
 * dobraria as chamadas externas de toda compra e de toda notificação.
 */
@Component
public class GoogleAccessTokens {

    static final String SCOPE = "https://www.googleapis.com/auth/androidpublisher";
    static final String DEFAULT_TOKEN_URL = "https://oauth2.googleapis.com/token";
    static final String GRANT_TYPE = "urn:ietf:params:oauth:grant-type:jwt-bearer";

    private static final Duration LIFETIME = Duration.ofHours(1);
    private static final Duration EARLY_RENEWAL = Duration.ofMinutes(2);

    private static final ObjectMapper MAPPER = new ObjectMapper();

    private final PlayStoreProperties properties;
    private final Clock clock;
    private final RestClient restClient;

    private volatile Token current;

    public GoogleAccessTokens(
            PlayStoreProperties properties, Clock clock, RestClient.Builder restClientBuilder) {
        this.properties = properties;
        this.clock = clock;
        this.restClient = restClientBuilder.build();
    }

    /** Token válido para a Play Developer API, renovado quando falta pouco. */
    public String bearer() {
        final Instant now = clock.instant();
        final Token cached = current;

        if (cached != null && now.isBefore(cached.expiresAt().minus(EARLY_RENEWAL))) {
            return cached.value();
        }

        final JsonNode credentials = credentials();
        final String tokenUrl = credentials.path("token_uri").asText(DEFAULT_TOKEN_URL);
        final String assertion = assertion(credentials, tokenUrl, now);

        final MultiValueMap<String, String> form = new LinkedMultiValueMap<>();
        form.add("grant_type", GRANT_TYPE);
        form.add("assertion", assertion);

        final JsonNode response;
        try {
            response = restClient.post()
                    .uri(tokenUrl)
                    .contentType(MediaType.APPLICATION_FORM_URLENCODED)
                    .body(form)
                    .retrieve()
                    .body(JsonNode.class);
        } catch (RestClientException e) {
            throw new IllegalStateException("Google recusou a conta de serviço.", e);
        }

        final String accessToken = response == null ? null : response.path("access_token").asText(null);
        if (accessToken == null || accessToken.isBlank()) {
            throw new IllegalStateException("Google não devolveu access token.");
        }

        // O expires_in do Google costuma ser 3599; usar o que ele mandou evita depender de um
        // valor que só é constante hoje.
        final long expiresIn = response.path("expires_in").asLong(LIFETIME.toSeconds());
        final Token token = new Token(accessToken, now.plusSeconds(expiresIn));
        current = token;
        return token.value();
    }

    private String assertion(JsonNode credentials, String tokenUrl, Instant now) {
        final ObjectNode header = MAPPER.createObjectNode();
        header.put("alg", "RS256");
        header.put("typ", "JWT");

        final ObjectNode claims = MAPPER.createObjectNode();
        claims.put("iss", credentials.path("client_email").asText());
        claims.put("scope", SCOPE);
        claims.put("aud", tokenUrl);
        claims.put("iat", now.getEpochSecond());
        claims.put("exp", now.plus(LIFETIME).getEpochSecond());

        final String signingInput = encode(header.toString()) + "." + encode(claims.toString());

        try {
            final Signature signature = Signature.getInstance("SHA256withRSA");
            signature.initSign(privateKey(credentials));
            signature.update(signingInput.getBytes(StandardCharsets.US_ASCII));

            return signingInput + "." + Base64.getUrlEncoder().withoutPadding()
                    .encodeToString(signature.sign());
        } catch (Exception e) {
            throw new IllegalStateException("Não foi possível assinar o JWT da conta de serviço.", e);
        }
    }

    private JsonNode credentials() {
        try {
            return MAPPER.readTree(properties.credentialsJson());
        } catch (Exception e) {
            throw new IllegalStateException("JSON da conta de serviço do Google ilegível.", e);
        }
    }

    private static PrivateKey privateKey(JsonNode credentials) throws Exception {
        // O JSON traz a chave com "\n" já como quebra de linha real; quando ele passa por
        // variável de ambiente, às vezes não. Os dois casos chegam aqui.
        final String pem = credentials.path("private_key").asText()
                .replace("\\n", "\n")
                .replace("-----BEGIN PRIVATE KEY-----", "")
                .replace("-----END PRIVATE KEY-----", "")
                .replaceAll("\\s", "");

        return KeyFactory.getInstance("RSA")
                .generatePrivate(new PKCS8EncodedKeySpec(Base64.getDecoder().decode(pem)));
    }

    private static String encode(String json) {
        return Base64.getUrlEncoder().withoutPadding()
                .encodeToString(json.getBytes(StandardCharsets.UTF_8));
    }

    private record Token(String value, Instant expiresAt) {
    }
}
