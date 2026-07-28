package com.myotrack.api.auth;

import com.myotrack.api.auth.AuthDtos.AppleIdTokenRequest;
import com.myotrack.api.auth.AuthDtos.AuthResponse;
import com.myotrack.api.auth.AuthDtos.ExchangeCodeRequest;
import com.myotrack.api.auth.AuthDtos.ForgotPasswordRequest;
import com.myotrack.api.auth.AuthDtos.GoogleIdTokenRequest;
import com.myotrack.api.auth.AuthDtos.LoginRequest;
import com.myotrack.api.auth.AuthDtos.ProvidersResponse;
import com.myotrack.api.auth.AuthDtos.RefreshRequest;
import com.myotrack.api.auth.AuthDtos.RegisterRequest;
import com.myotrack.api.auth.AuthDtos.ResetPasswordRequest;
import com.myotrack.api.config.AppProperties;
import com.myotrack.api.security.IpRateLimiter;
import com.myotrack.api.security.TokenService;
import com.myotrack.api.security.TokenService.TokenPair;
import com.myotrack.infrastructure.email.EmailContent;
import com.myotrack.infrastructure.email.EmailSender;
import com.myotrack.infrastructure.email.EmailTemplates;
import com.myotrack.infrastructure.identity.ApplicationUser;
import com.myotrack.infrastructure.identity.LoginCode;
import com.myotrack.infrastructure.identity.PasswordResetToken;
import com.myotrack.infrastructure.repository.LoginCodeRepository;
import com.myotrack.infrastructure.repository.PasswordResetTokenRepository;
import com.myotrack.infrastructure.repository.RefreshTokenRepository;
import jakarta.servlet.http.Cookie;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import java.net.URI;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.SecureRandom;
import java.time.OffsetDateTime;
import java.util.Base64;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.UUID;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.core.env.Environment;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.util.UriComponentsBuilder;

/** Porte de MyoTrack.Api/Controllers/AuthController.cs. */
@RestController
@RequestMapping("/api/auth")
public class AuthController {

    private static final Logger log = LoggerFactory.getLogger(AuthController.class);

    /** Validade do link de redefinição — o texto do e-mail promete o mesmo prazo. */
    private static final int PASSWORD_RESET_VALID_HOURS = 24;

    private static final String STATE_COOKIE = "myotrack_oauth_state";
    private static final int STATE_COOKIE_MAX_AGE_SECONDS = 600;
    private static final int LOGIN_CODE_VALID_MINUTES = 2;

    private final AccountService accounts;
    private final GoogleOAuthService google;
    private final AppleOAuthService apple;
    private final EmailSender emailSender;
    private final AppProperties app;
    private final IpRateLimiter rateLimiter;
    private final Environment environment;
    private final RefreshTokenRepository refreshTokens;
    private final LoginCodeRepository loginCodes;
    private final PasswordResetTokenRepository resetTokens;

    private final SecureRandom random = new SecureRandom();

    public AuthController(
            AccountService accounts,
            GoogleOAuthService google,
            AppleOAuthService apple,
            EmailSender emailSender,
            AppProperties app,
            IpRateLimiter rateLimiter,
            Environment environment,
            RefreshTokenRepository refreshTokens,
            LoginCodeRepository loginCodes,
            PasswordResetTokenRepository resetTokens) {
        this.accounts = accounts;
        this.google = google;
        this.apple = apple;
        this.emailSender = emailSender;
        this.app = app;
        this.rateLimiter = rateLimiter;
        this.environment = environment;
        this.refreshTokens = refreshTokens;
        this.loginCodes = loginCodes;
        this.resetTokens = resetTokens;
    }

    @GetMapping("/providers")
    public ProvidersResponse providers() {
        // Sem SMTP o link de redefinição só vai para o log do servidor: em produção a tela
        // esconde a opção para não prometer um e-mail que não chega.
        boolean development = List.of(environment.getActiveProfiles()).contains("dev")
                || environment.matchesProfiles("default");
        return new ProvidersResponse(
                google.isEnabled() || google.isNativeEnabled(),
                apple.isEnabled(),
                emailSender.isConfigured() || development);
    }

    @PostMapping("/register")
    public ResponseEntity<?> register(@RequestBody RegisterRequest request) {
        AccountService.CreateResult result =
                accounts.createWithPassword(request.email(), request.password(), request.displayName());

        if (!result.succeeded()) {
            return ResponseEntity.badRequest().body(Map.of("errors", result.errors()));
        }
        return ResponseEntity.ok(toResponse(accounts.issueTokens(result.user())));
    }

    @PostMapping("/login")
    public ResponseEntity<?> login(@RequestBody LoginRequest request) {
        Optional<ApplicationUser> user = accounts.findByEmail(request.email());

        // Mensagem única para e-mail inexistente e senha errada: distinguir revelaria cadastros.
        if (user.isEmpty() || !accounts.checkPassword(user.get(), request.password())) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED)
                    .body(Map.of("error", "Credenciais inválidas."));
        }
        return ResponseEntity.ok(toResponse(accounts.issueTokens(user.get())));
    }

    @PostMapping("/refresh")
    @Transactional
    public ResponseEntity<?> refresh(@RequestBody RefreshRequest request) {
        if (request.refreshToken() == null || request.refreshToken().isBlank()) {
            return unauthorized("Refresh token inválido ou expirado.");
        }

        var stored = refreshTokens.findByTokenHash(TokenService.hashToken(request.refreshToken()));
        if (stored.isEmpty() || !stored.get().isActive()) {
            return unauthorized("Refresh token inválido ou expirado.");
        }

        Optional<ApplicationUser> user = accounts.findById(stored.get().getUserId());
        if (user.isEmpty()) {
            return unauthorized("Usuário não encontrado.");
        }

        // Rotação: o refresh usado morre aqui, um novo par sai na resposta.
        stored.get().setRevokedAt(OffsetDateTime.now());
        refreshTokens.save(stored.get());

        return ResponseEntity.ok(toResponse(accounts.issueTokens(user.get())));
    }

    /**
     * Envia o link de redefinição. Responde sempre igual, exista ou não a conta:
     * a resposta não pode revelar quem tem cadastro no sistema.
     */
    @PostMapping("/forgot-password")
    @Transactional
    public ResponseEntity<?> forgotPassword(
            @RequestBody ForgotPasswordRequest request, HttpServletRequest httpRequest) {

        if (!rateLimiter.tryAcquire(httpRequest.getRemoteAddr())) {
            return ResponseEntity.status(HttpStatus.TOO_MANY_REQUESTS)
                    .body(Map.of("error", "Muitos pedidos. Tente de novo em alguns minutos."));
        }

        accounts.findByEmail(request.email())
                .filter(user -> user.getEmail() != null)
                .ifPresent(this::sendPasswordResetEmail);

        return ResponseEntity.ok(Map.of(
                "message", "Se houver uma conta com esse e-mail, o link de redefinição foi enviado."));
    }

    private void sendPasswordResetEmail(ApplicationUser user) {
        resetTokens.deleteExpired(OffsetDateTime.now());

        String rawToken = base64Url(randomBytes(32));
        PasswordResetToken token = new PasswordResetToken();
        token.setUserId(user.getId());
        token.setTokenHash(TokenService.hashToken(rawToken));
        token.setExpiresAt(OffsetDateTime.now().plusHours(PASSWORD_RESET_VALID_HOURS));
        resetTokens.save(token);

        String url = UriComponentsBuilder.fromUriString(app.publicBaseUrl() + "/redefinir-senha")
                .queryParam("uid", user.getId())
                .queryParam("token", rawToken)
                .encode()
                .toUriString();

        EmailContent content = EmailTemplates.passwordReset(url, PASSWORD_RESET_VALID_HOURS);
        // O EmailSender já engole falhas de SMTP: um erro aqui revelaria que a conta existe.
        emailSender.send(user.getEmail(), content);
    }

    @PostMapping("/reset-password")
    @Transactional
    public ResponseEntity<?> resetPassword(@RequestBody ResetPasswordRequest request) {
        var stored = request.token() == null || request.token().isBlank()
                ? Optional.<PasswordResetToken>empty()
                : resetTokens.findByTokenHash(TokenService.hashToken(request.token()));

        if (stored.isEmpty() || !stored.get().isUsable() || !matchesUser(stored.get(), request.userId())) {
            return ResponseEntity.badRequest()
                    .body(Map.of("error", "Link inválido ou expirado. Peça um novo."));
        }

        Optional<ApplicationUser> user = accounts.findById(stored.get().getUserId());
        if (user.isEmpty()) {
            return ResponseEntity.badRequest()
                    .body(Map.of("error", "Link inválido ou expirado. Peça um novo."));
        }

        List<String> errors = accounts.resetPassword(user.get(), request.password());
        if (!errors.isEmpty()) {
            // Erros de política de senha ajudam o usuário; os de token são genéricos de propósito.
            return ResponseEntity.badRequest().body(Map.of("error", String.join(" ", errors)));
        }

        stored.get().setUsedAt(OffsetDateTime.now());
        resetTokens.save(stored.get());

        return ResponseEntity.ok(Map.of("message", "Senha redefinida. Entre com a nova senha."));
    }

    /**
     * O {@code uid} do link precisa bater com o dono do token. Sem esta checagem, um token
     * válido de uma conta serviria para redefinir a senha de outra.
     */
    private static boolean matchesUser(PasswordResetToken token, String userId) {
        try {
            return token.getUserId().equals(UUID.fromString(userId));
        } catch (IllegalArgumentException | NullPointerException e) {
            return false;
        }
    }

    // ---------------------------------------------------------------------
    // OAuth do Google — fluxo web (SPA)
    // ---------------------------------------------------------------------

    /** Passo 1: gera o {@code state} anti-CSRF e manda ao Google. */
    @GetMapping("/google/start")
    public ResponseEntity<Void> googleStart(HttpServletRequest request, HttpServletResponse response) {
        if (!google.isEnabled()) {
            return redirectToSpa("erro=google-indisponivel");
        }

        String state = base64Url(randomBytes(32));
        Cookie cookie = new Cookie(STATE_COOKIE, state);
        cookie.setHttpOnly(true);
        cookie.setSecure(request.isSecure());
        cookie.setPath("/api/auth/google");
        cookie.setMaxAge(STATE_COOKIE_MAX_AGE_SECONDS);
        // O retorno do Google é navegação top-level, então Lax basta e Strict quebraria.
        cookie.setAttribute("SameSite", "Lax");
        response.addCookie(cookie);

        return ResponseEntity.status(HttpStatus.FOUND)
                .location(URI.create(google.buildAuthorizationUrl(googleRedirectUri(), state)))
                .build();
    }

    /**
     * Passos 2 e 3: valida o {@code state}, troca o code por token, busca o perfil e devolve o
     * usuário à SPA com um código de uso único (nunca com os tokens na URL).
     */
    @GetMapping("/google/callback")
    @Transactional
    public ResponseEntity<Void> googleCallback(
            @RequestParam(required = false) String code,
            @RequestParam(required = false) String state,
            @RequestParam(required = false) String error,
            HttpServletRequest request,
            HttpServletResponse response) {

        String expectedState = readStateCookie(request);
        clearStateCookie(request, response);

        if (!google.isEnabled()) {
            return redirectToSpa("erro=google-indisponivel");
        }
        if (error != null && !error.isBlank()) {
            return redirectToSpa("erro=google-cancelado");
        }
        if (!isStateValid(state, expectedState)) {
            return redirectToSpa("erro=google-state");
        }
        if (code == null || code.isBlank()) {
            return redirectToSpa("erro=google-falhou");
        }

        GoogleUserInfo info;
        try {
            info = google.fetchUserInfo(google.exchangeCode(code, googleRedirectUri()));
        } catch (ExternalAuthException e) {
            log.warn("Falha no fluxo OAuth do Google.", e);
            return redirectToSpa("erro=google-falhou");
        }

        if (info.email() == null || info.email().isBlank() || !info.emailVerified()) {
            return redirectToSpa("erro=google-email");
        }

        String loginCode = createLoginCode(accounts.findOrCreateGoogleUser(info));
        return redirectToSpa("oauth=" + java.net.URLEncoder.encode(loginCode, StandardCharsets.UTF_8));
    }

    /** Troca o código de uso único pelo par de tokens. */
    @PostMapping("/google/exchange")
    @Transactional
    public ResponseEntity<?> googleExchange(@RequestBody ExchangeCodeRequest request) {
        if (request.code() == null || request.code().isBlank()) {
            return unauthorized("Código de login inválido ou expirado.");
        }

        var stored = loginCodes.findByCodeHash(TokenService.hashToken(request.code()));
        if (stored.isEmpty() || !stored.get().isUsable()) {
            return unauthorized("Código de login inválido ou expirado.");
        }

        Optional<ApplicationUser> user = accounts.findById(stored.get().getUserId());
        if (user.isEmpty()) {
            return unauthorized("Usuário não encontrado.");
        }

        stored.get().setUsedAt(OffsetDateTime.now());
        loginCodes.save(stored.get());

        return ResponseEntity.ok(toResponse(accounts.issueTokens(user.get())));
    }

    // ---------------------------------------------------------------------
    // Login social no app — Google e Apple
    // ---------------------------------------------------------------------

    /**
     * Endpoint que não existia no backend .NET. O app obtém um ID token pelo Credential Manager
     * (Android) e o troca aqui pelo par de tokens do MyoTrack — sem redirect, sem cookie de state
     * e sem client secret no dispositivo, que é o que torna o fluxo web inviável no celular.
     */
    @PostMapping("/google/id-token")
    @Transactional
    public ResponseEntity<?> googleIdToken(@RequestBody GoogleIdTokenRequest request) {
        if (request.idToken() == null || request.idToken().isBlank()) {
            return unauthorized("ID token do Google ausente.");
        }

        GoogleUserInfo info;
        try {
            info = google.verifyIdToken(request.idToken());
        } catch (ExternalAuthException e) {
            log.warn("ID token do Google recusado: {}", e.getMessage());
            return unauthorized("Não foi possível validar sua conta Google.");
        }

        if (info.email() == null || info.email().isBlank() || !info.emailVerified()) {
            return unauthorized("A conta Google precisa ter um e-mail verificado.");
        }

        return ResponseEntity.ok(toResponse(accounts.issueTokens(accounts.findOrCreateGoogleUser(info))));
    }

    /**
     * Sign in with Apple. A App Store (diretriz 4.8) exige esta opção em qualquer app que ofereça
     * login social de terceiros — sem ela, o app é reprovado na revisão.
     *
     * <p>O {@code displayName} vem separado do token de propósito: a Apple entrega o nome apenas
     * na primeira autorização e fora do JWT. Depois disso, não há como recuperá-lo.
     */
    @PostMapping("/apple/id-token")
    @Transactional
    public ResponseEntity<?> appleIdToken(@RequestBody AppleIdTokenRequest request) {
        if (request.idToken() == null || request.idToken().isBlank()) {
            return unauthorized("Identity token da Apple ausente.");
        }

        ExternalIdentity identity;
        try {
            identity = apple.verifyIdToken(request.idToken(), request.displayName());
        } catch (ExternalAuthException e) {
            log.warn("Identity token da Apple recusado: {}", e.getMessage());
            return unauthorized("Não foi possível validar sua conta Apple.");
        }

        return ResponseEntity.ok(
                toResponse(accounts.issueTokens(accounts.findOrCreateExternalUser(identity))));
    }

    // ---------------------------------------------------------------------

    private String createLoginCode(ApplicationUser user) {
        String code = base64Url(randomBytes(32));

        LoginCode entity = new LoginCode();
        entity.setUserId(user.getId());
        entity.setCodeHash(TokenService.hashToken(code));
        entity.setExpiresAt(OffsetDateTime.now().plusMinutes(LOGIN_CODE_VALID_MINUTES));
        loginCodes.save(entity);

        return code;
    }

    /** Deve bater exatamente com o redirect autorizado no Google Cloud Console. */
    private String googleRedirectUri() {
        return app.publicBaseUrl() + "/api/auth/google/callback";
    }

    private ResponseEntity<Void> redirectToSpa(String query) {
        return ResponseEntity.status(HttpStatus.FOUND)
                .location(URI.create(app.publicBaseUrl() + "/login?" + query))
                .build();
    }

    private static ResponseEntity<?> unauthorized(String message) {
        return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body(Map.of("error", message));
    }

    private static AuthResponse toResponse(TokenPair pair) {
        return new AuthResponse(pair.accessToken(), pair.refreshToken());
    }

    /** Comparação em tempo constante — o state é um segredo curto. */
    private static boolean isStateValid(String received, String expected) {
        if (received == null || received.isBlank() || expected == null || expected.isBlank()) {
            return false;
        }
        return MessageDigest.isEqual(
                received.getBytes(StandardCharsets.UTF_8), expected.getBytes(StandardCharsets.UTF_8));
    }

    private static String readStateCookie(HttpServletRequest request) {
        if (request.getCookies() == null) {
            return null;
        }
        for (Cookie cookie : request.getCookies()) {
            if (STATE_COOKIE.equals(cookie.getName())) {
                return cookie.getValue();
            }
        }
        return null;
    }

    private static void clearStateCookie(HttpServletRequest request, HttpServletResponse response) {
        Cookie cookie = new Cookie(STATE_COOKIE, "");
        cookie.setPath("/api/auth/google");
        cookie.setMaxAge(0);
        cookie.setHttpOnly(true);
        cookie.setSecure(request.isSecure());
        response.addCookie(cookie);
    }

    private byte[] randomBytes(int length) {
        byte[] bytes = new byte[length];
        random.nextBytes(bytes);
        return bytes;
    }

    private static String base64Url(byte[] bytes) {
        return Base64.getUrlEncoder().withoutPadding().encodeToString(bytes);
    }
}
