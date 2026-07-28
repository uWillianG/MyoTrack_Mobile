package com.myotrack.api.auth;

import com.google.api.client.googleapis.auth.oauth2.GoogleIdToken;
import com.google.api.client.googleapis.auth.oauth2.GoogleIdTokenVerifier;
import com.google.api.client.http.javanet.NetHttpTransport;
import com.google.api.client.json.gson.GsonFactory;
import java.time.Duration;
import java.util.Map;
import org.springframework.http.MediaType;
import org.springframework.stereotype.Service;
import org.springframework.util.LinkedMultiValueMap;
import org.springframework.util.MultiValueMap;
import org.springframework.web.client.RestClient;
import org.springframework.web.client.RestClientException;
import org.springframework.web.util.UriComponentsBuilder;

/**
 * Login social com Google. Dois caminhos, para dois tipos de cliente:
 *
 * <ol>
 *   <li><b>Web (authorization-code flow)</b> — usado pela SPA: redireciona ao Google com um
 *       {@code state} anti-CSRF, troca o {@code code} por um access token servidor-a-servidor
 *       (o client secret nunca vai ao browser) e busca o perfil.</li>
 *   <li><b>Android (ID token)</b> — o Credential Manager já devolve um ID token assinado pelo
 *       Google; aqui só se valida assinatura, emissor, validade e audience. Não há redirect nem
 *       secret envolvido, que é o que torna o fluxo web inadequado no celular.</li>
 * </ol>
 *
 * <p>Porte de MyoTrack.Api/Services/GoogleOAuthService.cs, mais o caminho novo do ID token.
 */
@Service
public class GoogleOAuthService {

    private static final String AUTH_ENDPOINT = "https://accounts.google.com/o/oauth2/v2/auth";
    private static final String TOKEN_ENDPOINT = "https://oauth2.googleapis.com/token";
    private static final String USER_INFO_ENDPOINT = "https://openidconnect.googleapis.com/v1/userinfo";
    private static final String SCOPE = "openid email profile";
    private static final Duration TIMEOUT = Duration.ofSeconds(10);

    private final GoogleOAuthProperties properties;
    private final RestClient restClient;
    private final GoogleIdTokenVerifier idTokenVerifier;

    public GoogleOAuthService(GoogleOAuthProperties properties, RestClient.Builder restClientBuilder) {
        this.properties = properties;
        this.restClient = restClientBuilder.build();
        this.idTokenVerifier = new GoogleIdTokenVerifier.Builder(
                new NetHttpTransport(), GsonFactory.getDefaultInstance())
                .setAudience(properties.acceptedAudiences())
                .build();
    }

    public boolean isEnabled() {
        return properties.isEnabled();
    }

    /** O login nativo do Android não usa o client secret — basta haver audience configurado. */
    public boolean isNativeEnabled() {
        return !properties.acceptedAudiences().isEmpty();
    }

    public String buildAuthorizationUrl(String redirectUri, String state) {
        return UriComponentsBuilder.fromUriString(AUTH_ENDPOINT)
                .queryParam("client_id", properties.clientId())
                .queryParam("redirect_uri", redirectUri)
                .queryParam("response_type", "code")
                .queryParam("scope", SCOPE)
                .queryParam("state", state)
                .queryParam("access_type", "online")
                .queryParam("prompt", "select_account")
                .encode()
                .toUriString();
    }

    public String exchangeCode(String code, String redirectUri) {
        MultiValueMap<String, String> form = new LinkedMultiValueMap<>();
        form.add("code", code);
        form.add("client_id", properties.clientId());
        form.add("client_secret", properties.clientSecret());
        form.add("redirect_uri", redirectUri);
        form.add("grant_type", "authorization_code");

        Map<String, Object> payload;
        try {
            payload = restClient.post()
                    .uri(TOKEN_ENDPOINT)
                    .contentType(MediaType.APPLICATION_FORM_URLENCODED)
                    .body(form)
                    .retrieve()
                    .body(new org.springframework.core.ParameterizedTypeReference<>() { });
        } catch (RestClientException e) {
            throw new ExternalAuthException("Falha ao trocar o code no token endpoint do Google.", e);
        }

        Object accessToken = payload == null ? null : payload.get("access_token");
        if (accessToken == null || accessToken.toString().isBlank()) {
            throw new ExternalAuthException("Token endpoint não devolveu access_token.");
        }
        return accessToken.toString();
    }

    public GoogleUserInfo fetchUserInfo(String accessToken) {
        try {
            GoogleUserInfo info = restClient.get()
                    .uri(USER_INFO_ENDPOINT)
                    .header("Authorization", "Bearer " + accessToken)
                    .retrieve()
                    .body(GoogleUserInfo.class);
            if (info == null) {
                throw new ExternalAuthException("Userinfo endpoint devolveu resposta vazia.");
            }
            return info;
        } catch (RestClientException e) {
            throw new ExternalAuthException("Falha ao buscar o perfil no userinfo endpoint.", e);
        }
    }

    /**
     * Valida o ID token vindo do Credential Manager do Android.
     *
     * <p>A biblioteca do Google confere assinatura (contra as chaves públicas do Google, com
     * cache), emissor, expiração e audience. O que sobra para nós é a mesma checagem do fluxo
     * web: o e-mail precisa existir e estar verificado.
     */
    public GoogleUserInfo verifyIdToken(String idTokenString) {
        if (!isNativeEnabled()) {
            throw new ExternalAuthException("Login com Google não está configurado nesta instalação.");
        }

        GoogleIdToken idToken;
        try {
            idToken = idTokenVerifier.verify(idTokenString);
        } catch (Exception e) {
            throw new ExternalAuthException("Falha ao validar o ID token do Google.", e);
        }
        if (idToken == null) {
            throw new ExternalAuthException("ID token do Google inválido ou expirado.");
        }

        GoogleIdToken.Payload payload = idToken.getPayload();
        return new GoogleUserInfo(
                payload.getSubject(),
                payload.getEmail(),
                Boolean.TRUE.equals(payload.getEmailVerified()),
                asString(payload, "name"),
                asString(payload, "given_name"));
    }

    private static String asString(GoogleIdToken.Payload payload, String key) {
        Object value = payload.get(key);
        return value == null ? null : value.toString();
    }
}
