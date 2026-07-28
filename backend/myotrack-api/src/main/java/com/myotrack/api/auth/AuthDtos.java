package com.myotrack.api.auth;

/**
 * Contratos de entrada e saída de /api/auth. Os nomes dos campos são os mesmos do .NET
 * (camelCase no JSON) — o app e a SPA leem exatamente isto.
 */
public final class AuthDtos {

    private AuthDtos() {
    }

    public record RegisterRequest(String email, String password, String displayName) {
    }

    public record LoginRequest(String email, String password) {
    }

    public record RefreshRequest(String refreshToken) {
    }

    public record AuthResponse(String accessToken, String refreshToken) {
    }

    public record ForgotPasswordRequest(String email) {
    }

    public record ResetPasswordRequest(String userId, String token, String password) {
    }

    public record ExchangeCodeRequest(String code) {
    }

    /** Login nativo do Android: o ID token vindo do Credential Manager. */
    public record GoogleIdTokenRequest(String idToken) {
    }

    /**
     * Sign in with Apple no app.
     *
     * @param displayName nome montado pelo cliente a partir do {@code givenName}/{@code familyName}
     *     que a Apple devolve <b>só na primeira autorização</b> — o identity token nunca traz o
     *     nome, e por isso ele vem em campo separado.
     */
    public record AppleIdTokenRequest(String idToken, String displayName) {
    }

    /** Quais formas de login o cliente deve oferecer nesta instalação. */
    public record ProvidersResponse(boolean google, boolean apple, boolean passwordReset) {
    }
}
