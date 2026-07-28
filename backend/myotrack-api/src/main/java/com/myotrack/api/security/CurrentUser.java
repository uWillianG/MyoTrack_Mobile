package com.myotrack.api.security;

import java.util.UUID;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.security.oauth2.server.resource.authentication.JwtAuthenticationToken;

/**
 * Identidade da requisição atual. Equivale ao {@code ApiControllerBase.CurrentUserId} do .NET —
 * ali era uma propriedade da classe base; aqui é estático porque os controllers não herdam nada.
 */
public final class CurrentUser {

    private CurrentUser() {
    }

    public static UUID id() {
        return requireJwt().map(jwt -> UUID.fromString(jwt.getSubject()))
                .orElseThrow(() -> new IllegalStateException("Token sem identificador de usuário."));
    }

    public static String email() {
        return requireJwt().map(jwt -> jwt.getClaimAsString("email")).orElse(null);
    }

    public static boolean hasRole(String role) {
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        return authentication != null && authentication.getAuthorities().stream()
                .anyMatch(granted -> granted.getAuthority().equals("ROLE_" + role));
    }

    private static java.util.Optional<Jwt> requireJwt() {
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        if (authentication instanceof JwtAuthenticationToken token) {
            return java.util.Optional.of(token.getToken());
        }
        return java.util.Optional.empty();
    }
}
