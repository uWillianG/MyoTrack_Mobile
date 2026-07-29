package com.myotrack.api.security;

import com.myotrack.api.config.CorsProperties;
import com.myotrack.api.config.JwtProperties;
import java.nio.charset.StandardCharsets;
import java.time.Duration;
import java.util.ArrayList;
import java.util.Collection;
import java.util.List;
import javax.crypto.spec.SecretKeySpec;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.http.HttpMethod;
import org.springframework.security.config.Customizer;
import org.springframework.security.config.annotation.method.configuration.EnableMethodSecurity;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.http.SessionCreationPolicy;
import org.springframework.security.core.GrantedAuthority;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.oauth2.core.DelegatingOAuth2TokenValidator;
import org.springframework.security.oauth2.core.OAuth2Error;
import org.springframework.security.oauth2.core.OAuth2TokenValidator;
import org.springframework.security.oauth2.core.OAuth2TokenValidatorResult;
import org.springframework.security.oauth2.jose.jws.MacAlgorithm;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.security.oauth2.jwt.JwtClaimNames;
import org.springframework.security.oauth2.jwt.JwtDecoder;
import org.springframework.security.oauth2.jwt.JwtIssuerValidator;
import org.springframework.security.oauth2.jwt.JwtTimestampValidator;
import org.springframework.security.oauth2.jwt.NimbusJwtDecoder;
import org.springframework.security.oauth2.server.resource.authentication.JwtAuthenticationConverter;
import org.springframework.security.oauth2.server.resource.web.BearerTokenResolver;
import org.springframework.security.web.SecurityFilterChain;
import org.springframework.web.cors.CorsConfiguration;
import org.springframework.web.cors.CorsConfigurationSource;
import org.springframework.web.cors.UrlBasedCorsConfigurationSource;

/** Porte da configuração de autenticação/autorização do MyoTrack.Api/Program.cs. */
@Configuration
@EnableMethodSecurity
public class SecurityConfig {

    /** Mesma tolerância de relógio do .NET (o default do Spring é 60 s). */
    private static final Duration CLOCK_SKEW = Duration.ofSeconds(30);

    private final JwtProperties jwt;
    private final CorsProperties cors;

    public SecurityConfig(JwtProperties jwt, CorsProperties cors) {
        this.jwt = jwt;
        this.cors = cors;
    }

    @Bean
    public SecurityFilterChain filterChain(
            HttpSecurity http, BearerTokenResolver bearerTokenResolver, JwtDecoder jwtDecoder)
            throws Exception {

        http
                // API sem sessão e sem cookie de autenticação: não há o que um token CSRF proteja.
                // O único cookie é o `state` do OAuth, cujo fluxo é GET e é validado à mão.
                .csrf(csrf -> csrf.disable())
                .cors(Customizer.withDefaults())
                .sessionManagement(session -> session.sessionCreationPolicy(SessionCreationPolicy.STATELESS))
                .authorizeHttpRequests(auth -> auth
                        .requestMatchers("/actuator/health", "/actuator/health/**").permitAll()
                        // Cadastro, login, recuperação de senha e todo o vaivém do OAuth.
                        .requestMatchers("/api/auth/**").permitAll()
                        // O Stripe chama sem token; a autenticidade vem da assinatura do webhook.
                        .requestMatchers(HttpMethod.POST, "/api/billing/webhook").permitAll()
                        .requestMatchers("/swagger-ui/**", "/v3/api-docs/**").permitAll()
                        // Verificação de domínio dos deep links. Quem busca é o sistema
                        // operacional, antes de qualquer login — às vezes na instalação do app.
                        .requestMatchers("/.well-known/**").permitAll()
                        .anyRequest().authenticated())
                .oauth2ResourceServer(oauth2 -> oauth2
                        .bearerTokenResolver(bearerTokenResolver)
                        .jwt(jwtConfigurer -> jwtConfigurer
                                .decoder(jwtDecoder)
                                .jwtAuthenticationConverter(jwtAuthenticationConverter())));

        return http.build();
    }

    @Bean
    public JwtDecoder jwtDecoder() {
        SecretKeySpec key = new SecretKeySpec(
                jwt.signingKey().getBytes(StandardCharsets.UTF_8), "HmacSHA256");

        NimbusJwtDecoder decoder = NimbusJwtDecoder.withSecretKey(key)
                .macAlgorithm(MacAlgorithm.HS256)
                .build();

        // Lista montada à mão em vez de JwtValidators.createDefaultWithIssuer: aquele traz um
        // JwtTimestampValidator com o skew padrão de 60 s, e queremos os 30 s do .NET.
        decoder.setJwtValidator(new DelegatingOAuth2TokenValidator<>(
                new JwtTimestampValidator(CLOCK_SKEW),
                new JwtIssuerValidator(jwt.issuer()),
                new AudienceValidator(jwt.audience())));

        return decoder;
    }

    /**
     * Lê os papéis do claim curto {@code role} e do claim longo do .NET — assim tokens emitidos
     * pelo backend antigo continuam válidos durante a transição.
     */
    @Bean
    public JwtAuthenticationConverter jwtAuthenticationConverter() {
        JwtAuthenticationConverter converter = new JwtAuthenticationConverter();
        converter.setJwtGrantedAuthoritiesConverter(SecurityConfig::extractAuthorities);
        converter.setPrincipalClaimName(JwtClaimNames.SUB);
        return converter;
    }

    private static Collection<GrantedAuthority> extractAuthorities(Jwt jwt) {
        List<GrantedAuthority> authorities = new ArrayList<>();
        for (String claim : List.of(TokenService.ROLE_CLAIM, TokenService.DOTNET_ROLE_CLAIM)) {
            for (String role : readStringList(jwt, claim)) {
                GrantedAuthority authority = new SimpleGrantedAuthority("ROLE_" + role);
                if (!authorities.contains(authority)) {
                    authorities.add(authority);
                }
            }
        }
        return authorities;
    }

    /** O claim de papel vem como string quando há um só papel e como lista quando há vários. */
    private static List<String> readStringList(Jwt jwt, String claimName) {
        Object value = jwt.getClaim(claimName);
        if (value instanceof String single) {
            return List.of(single);
        }
        if (value instanceof Collection<?> many) {
            return many.stream().filter(String.class::isInstance).map(String.class::cast).toList();
        }
        return List.of();
    }

    @Bean
    public CorsConfigurationSource corsConfigurationSource() {
        CorsConfiguration configuration = new CorsConfiguration();
        configuration.setAllowedOrigins(cors.allowedOrigins());
        configuration.setAllowedHeaders(List.of("*"));
        configuration.setAllowedMethods(List.of("*"));

        UrlBasedCorsConfigurationSource source = new UrlBasedCorsConfigurationSource();
        source.registerCorsConfiguration("/**", configuration);
        return source;
    }

    /** Recusa tokens emitidos para outro público. */
    record AudienceValidator(String audience) implements OAuth2TokenValidator<Jwt> {

        @Override
        public OAuth2TokenValidatorResult validate(Jwt token) {
            if (token.getAudience() != null && token.getAudience().contains(audience)) {
                return OAuth2TokenValidatorResult.success();
            }
            return OAuth2TokenValidatorResult.failure(
                    new OAuth2Error("invalid_token", "Audience inválido.", null));
        }
    }
}
