package com.myotrack.api.auth;

import com.myotrack.api.security.TokenService;
import com.myotrack.api.security.TokenService.TokenPair;
import com.myotrack.infrastructure.identity.AppRoles;
import com.myotrack.infrastructure.identity.ApplicationRole;
import com.myotrack.infrastructure.identity.ApplicationUser;
import com.myotrack.infrastructure.identity.RefreshToken;
import com.myotrack.infrastructure.identity.UserLogin;
import com.myotrack.infrastructure.identity.UserRole;
import com.myotrack.infrastructure.identity.password.PasswordError;
import com.myotrack.infrastructure.identity.password.PasswordPolicy;
import com.myotrack.infrastructure.repository.ApplicationRoleRepository;
import com.myotrack.infrastructure.repository.ApplicationUserRepository;
import com.myotrack.infrastructure.repository.RefreshTokenRepository;
import com.myotrack.infrastructure.repository.UserLoginRepository;
import com.myotrack.infrastructure.repository.UserRoleRepository;
import java.time.OffsetDateTime;
import java.util.List;
import java.util.Locale;
import java.util.Optional;
import java.util.UUID;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * O que o {@code UserManager<ApplicationUser>} do Identity fazia: criar conta, conferir senha,
 * atribuir papel, vincular login externo e emitir o par de tokens.
 *
 * <p>Normalização de e-mail: o Identity guarda {@code NormalizedEmail}/{@code NormalizedUserName}
 * em maiúsculas e é por eles que busca. Manter isso é o que faz as contas criadas pelo .NET e
 * pelo Java serem encontráveis pelos dois lados.
 */
@Service
public class AccountService {

    /** Valor gravado em {@code AspNetUserLogins.LoginProvider} — o mesmo que o .NET usava. */
    public static final String GOOGLE_PROVIDER = "Google";

    public static final String APPLE_PROVIDER = "Apple";

    private final ApplicationUserRepository users;
    private final ApplicationRoleRepository roles;
    private final UserRoleRepository userRoles;
    private final UserLoginRepository userLogins;
    private final RefreshTokenRepository refreshTokens;
    private final PasswordEncoder passwordEncoder;
    private final PasswordPolicy passwordPolicy;
    private final TokenService tokenService;

    public AccountService(
            ApplicationUserRepository users,
            ApplicationRoleRepository roles,
            UserRoleRepository userRoles,
            UserLoginRepository userLogins,
            RefreshTokenRepository refreshTokens,
            PasswordEncoder passwordEncoder,
            PasswordPolicy passwordPolicy,
            TokenService tokenService) {
        this.users = users;
        this.roles = roles;
        this.userRoles = userRoles;
        this.userLogins = userLogins;
        this.refreshTokens = refreshTokens;
        this.passwordEncoder = passwordEncoder;
        this.passwordPolicy = passwordPolicy;
        this.tokenService = tokenService;
    }

    public static String normalize(String email) {
        return email == null ? null : email.trim().toUpperCase(Locale.ROOT);
    }

    public Optional<ApplicationUser> findByEmail(String email) {
        if (email == null || email.isBlank()) {
            return Optional.empty();
        }
        return users.findByNormalizedEmail(normalize(email));
    }

    public Optional<ApplicationUser> findById(UUID id) {
        return users.findById(id);
    }

    public boolean checkPassword(ApplicationUser user, String rawPassword) {
        return passwordEncoder.matches(rawPassword, user.getPasswordHash());
    }

    /**
     * Cria a conta com senha. Devolve os erros de política em vez de lançar — a tela de cadastro
     * mostra a lista inteira.
     */
    @Transactional
    public CreateResult createWithPassword(String email, String password, String displayName) {
        String trimmedEmail = email == null ? "" : email.trim();

        if (trimmedEmail.isBlank() || !trimmedEmail.contains("@")) {
            return CreateResult.failed(List.of("E-mail inválido."));
        }
        if (users.existsByNormalizedEmail(normalize(trimmedEmail))) {
            return CreateResult.failed(List.of("Já existe uma conta com esse e-mail."));
        }

        List<PasswordError> errors = passwordPolicy.validate(password, trimmedEmail, displayName);
        if (!errors.isEmpty()) {
            return CreateResult.failed(errors.stream().map(PasswordError::description).distinct().toList());
        }

        ApplicationUser user = newUser(trimmedEmail, displayName);
        user.setPasswordHash(passwordEncoder.encode(password));
        // Usar o retorno do save(): é a instância gerenciada, já com o id gerado.
        user = users.save(user);
        addToRole(user, AppRoles.STUDENT);

        return CreateResult.ok(user);
    }

    /**
     * Casa uma identidade externa (Google ou Apple) com uma conta existente — pelo {@code sub} e,
     * na falta dele, pelo e-mail verificado — ou cria uma nova sem senha.
     *
     * <p>Casar por e-mail é o que permite ao usuário que se cadastrou com senha entrar depois pelo
     * Google ou pela Apple sem virar uma conta duplicada. Só é seguro porque os dois provedores
     * entregam o e-mail já verificado (validado antes de chegar aqui).
     */
    @Transactional
    public ApplicationUser findOrCreateExternalUser(ExternalIdentity identity) {
        Optional<UserLogin> login = userLogins.findByIdLoginProviderAndIdProviderKey(
                identity.provider(), identity.subject());
        if (login.isPresent()) {
            return users.findById(login.get().getUserId())
                    .orElseThrow(() -> new IllegalStateException(
                            "Login %s aponta para um usuário que não existe mais."
                                    .formatted(identity.provider())));
        }

        ApplicationUser user = findByEmail(identity.email()).orElse(null);
        if (user == null) {
            user = newUser(identity.email(), identity.displayName());
            user.setEmailConfirmed(true); // o provedor já verificou este endereço
            // Sem senha: a conta só entra pelo provedor externo até o usuário definir uma senha
            // pelo fluxo de "esqueci minha senha".
            user.setPasswordHash(null);
            user = users.save(user);
            addToRole(user, AppRoles.STUDENT);
        } else if (user.getDisplayName() == null && identity.displayName() != null) {
            // Única chance de gravar o nome: a Apple só o envia na primeira autorização.
            user.setDisplayName(identity.displayName());
            user = users.save(user);
        }

        userLogins.save(new UserLogin(
                identity.provider(), identity.subject(), user.getId(), identity.provider()));
        return user;
    }

    /** Adaptador do fluxo do Google, que tem formato próprio de perfil. */
    @Transactional
    public ApplicationUser findOrCreateGoogleUser(GoogleUserInfo info) {
        return findOrCreateExternalUser(new ExternalIdentity(
                GOOGLE_PROVIDER, info.sub(), info.email(), info.preferredDisplayName()));
    }

    /** Emite o par de tokens e persiste o hash do refresh. */
    @Transactional
    public TokenPair issueTokens(ApplicationUser user) {
        List<String> userRoleNames = userRoles.findRoleNamesByUserId(user.getId());
        TokenPair pair = tokenService.createTokenPair(user, userRoleNames);

        RefreshToken token = new RefreshToken();
        token.setUserId(user.getId());
        token.setTokenHash(TokenService.hashToken(pair.refreshToken()));
        token.setExpiresAt(pair.refreshTokenExpiresAt());
        refreshTokens.save(token);

        return pair;
    }

    /** Troca a senha e derruba as sessões abertas — inclusive a de quem roubou a conta. */
    @Transactional
    public List<String> resetPassword(ApplicationUser user, String newPassword) {
        List<PasswordError> errors =
                passwordPolicy.validate(newPassword, user.getEmail(), user.getDisplayName());
        if (!errors.isEmpty()) {
            return errors.stream().map(PasswordError::description).distinct().toList();
        }

        user.setPasswordHash(passwordEncoder.encode(newPassword));
        // O .NET usa o SecurityStamp para invalidar sessões; mantemos o campo girando para
        // não confundir quem ainda lê a conta pelo backend antigo.
        user.setSecurityStamp(UUID.randomUUID().toString());
        users.save(user);

        refreshTokens.revokeAllForUser(user.getId(), OffsetDateTime.now());
        return List.of();
    }

    private ApplicationUser newUser(String email, String displayName) {
        ApplicationUser user = new ApplicationUser();
        // O id NÃO é setado aqui: a coluna é @GeneratedValue e um id preenchido faria o Hibernate
        // tratar a entidade como destacada, emitindo UPDATE numa linha que ainda não existe.
        // UserName e Email guardam o mesmo valor, como no cadastro do .NET.
        user.setUserName(email);
        user.setNormalizedUserName(normalize(email));
        user.setEmail(email);
        user.setNormalizedEmail(normalize(email));
        user.setDisplayName(displayName);
        user.setSecurityStamp(UUID.randomUUID().toString());
        user.setConcurrencyStamp(UUID.randomUUID().toString());
        user.setCreatedAt(OffsetDateTime.now());
        user.setLockoutEnabled(true);
        return user;
    }

    private void addToRole(ApplicationUser user, String roleName) {
        ApplicationRole role = roles.findByNormalizedName(roleName.toUpperCase(Locale.ROOT))
                .orElseThrow(() -> new IllegalStateException(
                        "Papel '%s' não semeado — o DbSeeder não rodou.".formatted(roleName)));
        userRoles.save(new UserRole(user.getId(), role.getId()));
    }

    /** Resultado do cadastro: o usuário criado ou a lista de motivos da recusa. */
    public record CreateResult(ApplicationUser user, List<String> errors) {

        static CreateResult ok(ApplicationUser user) {
            return new CreateResult(user, List.of());
        }

        static CreateResult failed(List<String> errors) {
            return new CreateResult(null, errors);
        }

        public boolean succeeded() {
            return user != null;
        }
    }
}
