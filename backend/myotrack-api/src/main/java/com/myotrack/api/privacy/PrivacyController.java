package com.myotrack.api.privacy;

import com.myotrack.api.security.CurrentUser;
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
import java.time.LocalDate;
import java.time.OffsetDateTime;
import java.time.format.DateTimeFormatter;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.Optional;
import java.util.UUID;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.data.domain.Limit;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

/**
 * Direitos do titular (LGPD): portabilidade (export) e eliminação (exclusão de conta).
 *
 * <p>Porte de MyoTrack.Api/Controllers/PrivacyController.cs.
 */
@RestController
@RequestMapping("/api/privacy")
public class PrivacyController {

    private static final Logger log = LoggerFactory.getLogger(PrivacyController.class);

    private static final Limit ALL = Limit.unlimited();

    private final ApplicationUserRepository users;
    private final UserProfileRepository profiles;
    private final ConsentRecordRepository consents;
    private final WorkoutPlanRepository workoutPlans;
    private final DietPlanRepository dietPlans;
    private final WorkoutSessionRepository sessions;
    private final BodyMeasurementRepository measurements;
    private final MealPhotoAnalysisRepository mealAnalyses;
    private final ExerciseVideoAnalysisRepository videoAnalyses;
    private final AiUsageLogRepository aiUsage;
    private final CoachMessageRepository coachMessages;
    private final WeeklyReportRepository weeklyReports;
    private final UserSubscriptionRepository subscriptions;
    private final AccountPurgeService purgeService;
    private final MediaStorage storage;
    private final PasswordEncoder passwordEncoder;

    public PrivacyController(
            ApplicationUserRepository users,
            UserProfileRepository profiles,
            ConsentRecordRepository consents,
            WorkoutPlanRepository workoutPlans,
            DietPlanRepository dietPlans,
            WorkoutSessionRepository sessions,
            BodyMeasurementRepository measurements,
            MealPhotoAnalysisRepository mealAnalyses,
            ExerciseVideoAnalysisRepository videoAnalyses,
            AiUsageLogRepository aiUsage,
            CoachMessageRepository coachMessages,
            WeeklyReportRepository weeklyReports,
            UserSubscriptionRepository subscriptions,
            AccountPurgeService purgeService,
            MediaStorage storage,
            PasswordEncoder passwordEncoder) {
        this.users = users;
        this.profiles = profiles;
        this.consents = consents;
        this.workoutPlans = workoutPlans;
        this.dietPlans = dietPlans;
        this.sessions = sessions;
        this.measurements = measurements;
        this.mealAnalyses = mealAnalyses;
        this.videoAnalyses = videoAnalyses;
        this.aiUsage = aiUsage;
        this.coachMessages = coachMessages;
        this.weeklyReports = weeklyReports;
        this.subscriptions = subscriptions;
        this.purgeService = purgeService;
        this.storage = storage;
        this.passwordEncoder = passwordEncoder;
    }

    /** Export completo dos dados do titular em JSON (art. 18, LGPD). */
    @GetMapping("/export")
    @Transactional(readOnly = true)
    public ResponseEntity<Map<String, Object>> export() {
        final UUID userId = CurrentUser.id();
        final Optional<ApplicationUser> user = users.findById(userId);

        final Map<String, Object> account = new HashMap<>();
        account.put("email", user.map(ApplicationUser::getEmail).orElse(null));
        account.put("createdAt", user.map(ApplicationUser::getCreatedAt).orElse(null));

        final Map<String, Object> body = new LinkedHashMap<>();
        body.put("exportedAt", OffsetDateTime.now());
        body.put("account", account);
        body.put("profile", profiles.findByUserId(userId).orElse(null));
        body.put("consents", consents.findByUserIdOrderByGrantedAtDesc(userId));
        body.put("workoutPlans", workoutPlans.findByUserIdOrderByCreatedAtDesc(userId));
        body.put("dietPlans", dietPlans.findByUserIdOrderByCreatedAtDesc(userId));
        body.put("workoutSessions", sessions.findByUserIdOrderByDateDesc(userId));
        body.put("bodyMeasurements", measurements.findByUserIdOrderByDateDesc(userId));
        body.put("mealPhotoAnalyses", mealAnalyses.findByUserIdOrderByCreatedAtDesc(userId, ALL));
        body.put("exerciseVideoAnalyses", videoAnalyses.findByUserIdOrderByCreatedAtDesc(userId, ALL));
        body.put("aiUsage", aiUsage.findByUserIdOrderByCreatedAtDesc(userId));
        body.put("coachMessages", coachMessages.findByUserIdOrderByCreatedAtAsc(userId));
        body.put("weeklyReports", weeklyReports.findFirstByUserIdOrderByWeekStartDesc(userId)
                .map(List::of).orElseGet(List::of));
        body.put("subscription", subscriptions.findByUserId(userId).orElse(null));

        final String filename = "myotrack-dados-%s.json".formatted(
                LocalDate.now().format(DateTimeFormatter.ofPattern("yyyyMMdd", Locale.ROOT)));

        return ResponseEntity.ok()
                .contentType(MediaType.APPLICATION_JSON)
                // attachment faz o cliente salvar como arquivo em vez de renderizar.
                .header(HttpHeaders.CONTENT_DISPOSITION,
                        "attachment; filename=\"%s\"".formatted(filename))
                .body(body);
    }

    /**
     * Exclusão definitiva da conta e de todos os dados e mídias do titular.
     *
     * <p>Exige confirmação. Contas criadas pelo Google ou pela Apple não têm senha: nesses
     * casos a confirmação é digitar o próprio e-mail — sem essa alternativa, quem entrou por
     * login social ficaria sem como exercer o direito de eliminação.
     */
    @DeleteMapping("/account")
    public ResponseEntity<?> deleteAccount(@RequestBody DeleteAccountRequest request) {
        final UUID userId = CurrentUser.id();
        final Optional<ApplicationUser> found = users.findById(userId);
        if (found.isEmpty()) {
            return ResponseEntity.notFound().build();
        }
        final ApplicationUser user = found.get();

        final String confirmation = request.password() == null ? "" : request.password().trim();
        final boolean hasPassword =
                user.getPasswordHash() != null && !user.getPasswordHash().isBlank();

        if (hasPassword) {
            if (!passwordEncoder.matches(confirmation, user.getPasswordHash())) {
                return ResponseEntity.badRequest().body(Map.of("error", "Senha incorreta."));
            }
        } else if (!confirmation.equalsIgnoreCase(user.getEmail())) {
            return ResponseEntity.badRequest()
                    .body(Map.of("error", "Para confirmar, digite o e-mail da sua conta."));
        }

        // As chaves de mídia são coletadas ANTES de apagar as linhas — depois do delete não
        // haveria como saber quais arquivos remover do storage.
        final List<String> mediaKeys = collectMediaKeys(userId);

        purgeService.purge(userId);

        // Mídia é melhor-esforço e depois do commit: uma falha aqui não pode ressuscitar a
        // conta. O pior caso é um arquivo órfão, que a política de retenção acaba varrendo.
        mediaKeys.stream().distinct().forEach(key -> {
            try {
                storage.delete(key);
            } catch (Exception e) {
                log.warn("Falha ao apagar mídia {} na exclusão da conta {}: {}",
                        key, userId, e.getMessage());
            }
        });

        log.info("Conta {} excluída a pedido do titular (LGPD).", userId);
        return ResponseEntity.noContent().build();
    }

    /** Mídia ainda no storage — a já expirada pela política de retenção não tem arquivo. */
    private List<String> collectMediaKeys(UUID userId) {
        final List<String> keys = new ArrayList<>();

        mealAnalyses.findByUserIdOrderByCreatedAtDesc(userId, ALL).stream()
                .filter(a -> a.getMediaExpiredAt() == null)
                .forEach(a -> {
                    keys.add(a.getMediaKey());
                    if (a.getIllustratedMediaKey() != null) {
                        keys.add(a.getIllustratedMediaKey());
                    }
                });

        videoAnalyses.findByUserIdOrderByCreatedAtDesc(userId, ALL).stream()
                .filter(a -> a.getMediaExpiredAt() == null)
                .forEach(a -> {
                    keys.add(a.getMediaKey());
                    if (a.getOverlayVideoKey() != null) {
                        keys.add(a.getOverlayVideoKey());
                    }
                });

        return keys;
    }

    public record DeleteAccountRequest(String password) {
    }
}
