package com.myotrack.api.privacy;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import com.myotrack.infrastructure.email.EmailSender;
import com.myotrack.infrastructure.identity.ApplicationUser;
import com.myotrack.infrastructure.repository.AiUsageLogRepository;
import com.myotrack.infrastructure.repository.ApplicationUserRepository;
import com.myotrack.infrastructure.repository.BodyMeasurementRepository;
import com.myotrack.infrastructure.repository.CoachMessageRepository;
import com.myotrack.infrastructure.repository.ConsentRecordRepository;
import com.myotrack.infrastructure.repository.DietPlanRepository;
import com.myotrack.infrastructure.repository.ExerciseVideoAnalysisRepository;
import com.myotrack.infrastructure.repository.MealPhotoAnalysisRepository;
import com.myotrack.infrastructure.repository.UserProfileRepository;
import com.myotrack.infrastructure.repository.UserSubscriptionRepository;
import com.myotrack.infrastructure.repository.WeeklyReportRepository;
import com.myotrack.infrastructure.repository.WorkoutPlanRepository;
import com.myotrack.infrastructure.repository.WorkoutSessionRepository;
import com.myotrack.infrastructure.storage.MediaStorage;
import java.time.OffsetDateTime;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.UUID;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.security.oauth2.server.resource.authentication.JwtAuthenticationToken;

/**
 * Os direitos do titular, do lado que a tela de conta consome.
 *
 * <p>O que se testa aqui é <b>a ponte entre a conta e o diálogo de exclusão</b>. A confirmação
 * tem duas formas — senha para quem se cadastrou com uma, e o próprio e-mail para quem entrou
 * com Google ou Apple — e quem decide qual vale é o servidor. Enquanto o app não tinha como
 * perguntar, a tela pedia "senha ou e-mail" e metade das pessoas lia a instrução errada num
 * diálogo irreversível. {@code GET /api/privacy/account} é o que fecha esse buraco, e por isso
 * o que ele responde é testado junto com o que a exclusão aceita: se os dois discordarem, a
 * tela pede uma coisa e o servidor exige outra.
 */
class PrivacyControllerTest {

    private static final UUID ANA = UUID.fromString("11111111-1111-1111-1111-111111111111");

    private static final OffsetDateTime CADASTRO = OffsetDateTime.parse("2026-03-12T09:30:00Z");

    private ApplicationUserRepository users;
    private AccountPurgeService purgeService;
    private PasswordEncoder passwordEncoder;
    private MealPhotoAnalysisRepository mealAnalyses;
    private ExerciseVideoAnalysisRepository videoAnalyses;
    private PrivacyController controller;

    @BeforeEach
    void setUp() {
        users = mock(ApplicationUserRepository.class);
        purgeService = mock(AccountPurgeService.class);
        passwordEncoder = mock(PasswordEncoder.class);
        mealAnalyses = mock(MealPhotoAnalysisRepository.class);
        videoAnalyses = mock(ExerciseVideoAnalysisRepository.class);

        controller = new PrivacyController(
                users,
                mock(UserProfileRepository.class),
                mock(ConsentRecordRepository.class),
                mock(WorkoutPlanRepository.class),
                mock(DietPlanRepository.class),
                mock(WorkoutSessionRepository.class),
                mock(BodyMeasurementRepository.class),
                mealAnalyses,
                videoAnalyses,
                mock(AiUsageLogRepository.class),
                mock(CoachMessageRepository.class),
                mock(WeeklyReportRepository.class),
                mock(UserSubscriptionRepository.class),
                purgeService,
                mock(MediaStorage.class),
                passwordEncoder,
                mock(EmailSender.class));

        signedInAs(ANA);

        // Sem mídia: a coleta de chaves não é o assunto destes testes, e uma lista nula
        // rebentaria antes de chegar à confirmação.
        when(mealAnalyses.findByUserIdOrderByCreatedAtDesc(any(), any())).thenReturn(List.of());
        when(videoAnalyses.findByUserIdOrderByCreatedAtDesc(any(), any())).thenReturn(List.of());
    }

    @AfterEach
    void tearDown() {
        SecurityContextHolder.clearContext();
    }

    private static void signedInAs(UUID userId) {
        Jwt jwt = Jwt.withTokenValue("t")
                .header("alg", "none")
                .subject(userId.toString())
                .build();
        SecurityContextHolder.getContext()
                .setAuthentication(new JwtAuthenticationToken(jwt, List.of()));
    }

    /** Uma conta como o banco a devolveria. {@code passwordHash} nulo é conta de login social. */
    private ApplicationUser conta(String email, String passwordHash) {
        ApplicationUser user = new ApplicationUser();
        user.setId(ANA);
        user.setEmail(email);
        user.setCreatedAt(CADASTRO);
        user.setPasswordHash(passwordHash);
        when(users.findById(ANA)).thenReturn(Optional.of(user));
        return user;
    }

    @SuppressWarnings("unchecked")
    private static String erroDe(ResponseEntity<?> response) {
        return ((Map<String, String>) response.getBody()).get("error");
    }

    @Nested
    @DisplayName("o resumo da conta")
    class Resumo {

        @Test
        @DisplayName("diz que há senha quando a conta tem uma")
        void reportsPassword() {
            conta("ana@exemplo.com", "AQAAAAIAAYag...");

            PrivacyController.AccountSummary summary = controller.account().getBody();

            assertThat(summary).isNotNull();
            // É o que faz o diálogo pedir "Senha" em vez de "Senha ou e-mail".
            assertThat(summary.hasPassword()).isTrue();
            assertThat(summary.email()).isEqualTo("ana@exemplo.com");
            // A data de cadastro é o que permite à tela dizer de que conta se trata sem
            // depender do e-mail sozinho — em aparelho compartilhado, dois e-mails parecidos
            // são a diferença entre apagar a conta certa e a errada.
            assertThat(summary.createdAt()).isEqualTo(CADASTRO);
        }

        @Test
        @DisplayName("conta de login social não tem senha")
        void reportsSocialAccount() {
            conta("ana@exemplo.com", null);

            assertThat(controller.account().getBody().hasPassword()).isFalse();
        }

        @Test
        @DisplayName("hash em branco conta como sem senha")
        void blankHashIsNoPassword() {
            // A tabela veio do ASP.NET Identity e aceita string vazia onde o Java esperaria
            // null. Tratar os dois igual é o que impede a tela de pedir uma senha que não
            // existe — e que ninguém conseguiria digitar.
            conta("ana@exemplo.com", "   ");

            assertThat(controller.account().getBody().hasPassword()).isFalse();
        }

        @Test
        @DisplayName("não devolve credencial nenhuma")
        void neverLeaksTheHash() {
            conta("ana@exemplo.com", "AQAAAAIAAYag...");

            // O registro tem três campos e nenhum deles é o hash: a tela precisa saber que
            // existe uma senha, nunca qual é.
            assertThat(PrivacyController.AccountSummary.class.getRecordComponents())
                    .extracting(java.lang.reflect.RecordComponent::getName)
                    .containsExactly("email", "createdAt", "hasPassword");
        }

        @Test
        @DisplayName("conta que não existe mais responde 404")
        void missingAccountIsNotFound() {
            when(users.findById(ANA)).thenReturn(Optional.empty());

            assertThat(controller.account().getStatusCode()).isEqualTo(HttpStatus.NOT_FOUND);
        }
    }

    @Nested
    @DisplayName("a exclusão")
    class Exclusao {

        @Test
        @DisplayName("aceita a senha de quem tem uma")
        void acceptsThePassword() {
            conta("ana@exemplo.com", "hash");
            when(passwordEncoder.matches("Tr0vao!Verde9", "hash")).thenReturn(true);

            ResponseEntity<?> response = controller.deleteAccount(
                    new PrivacyController.DeleteAccountRequest("Tr0vao!Verde9"));

            assertThat(response.getStatusCode()).isEqualTo(HttpStatus.NO_CONTENT);
            verify(purgeService).purge(ANA);
        }

        @Test
        @DisplayName("senha errada não apaga nada")
        void wrongPasswordPurgesNothing() {
            conta("ana@exemplo.com", "hash");
            when(passwordEncoder.matches(any(), any())).thenReturn(false);

            ResponseEntity<?> response = controller.deleteAccount(
                    new PrivacyController.DeleteAccountRequest("errada"));

            assertThat(response.getStatusCode()).isEqualTo(HttpStatus.BAD_REQUEST);
            assertThat(erroDe(response)).isEqualTo("Senha incorreta.");
            verify(purgeService, never()).purge(any());
        }

        @Test
        @DisplayName("conta social confirma com o próprio e-mail, em qualquer caixa")
        void socialAccountConfirmsWithEmail() {
            // Sem esta alternativa quem entrou com Google ou Apple ficaria sem como exercer o
            // direito de eliminação: a conta não tem senha para digitar.
            conta("Ana@Exemplo.com", null);

            ResponseEntity<?> response = controller.deleteAccount(
                    new PrivacyController.DeleteAccountRequest("ana@exemplo.com"));

            assertThat(response.getStatusCode()).isEqualTo(HttpStatus.NO_CONTENT);
            verify(purgeService).purge(ANA);
        }

        @Test
        @DisplayName("conta social recusa a senha que o app não deveria ter pedido")
        void socialAccountRejectsAnythingElse() {
            conta("ana@exemplo.com", null);

            ResponseEntity<?> response = controller.deleteAccount(
                    new PrivacyController.DeleteAccountRequest("uma senha qualquer"));

            assertThat(response.getStatusCode()).isEqualTo(HttpStatus.BAD_REQUEST);
            // A mensagem é a instrução: é ela que o app mostra quando pediu a coisa errada.
            assertThat(erroDe(response)).contains("digite o e-mail da sua conta");
            verify(purgeService, never()).purge(any());
        }
    }
}
