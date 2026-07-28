package com.myotrack.api.privacy;

import com.myotrack.infrastructure.repository.AiUsageLogRepository;
import com.myotrack.infrastructure.repository.AnalysisJobRepository;
import com.myotrack.infrastructure.repository.ApplicationUserRepository;
import com.myotrack.infrastructure.repository.BodyMeasurementRepository;
import com.myotrack.infrastructure.repository.CoachMessageRepository;
import com.myotrack.infrastructure.repository.ConsentRecordRepository;
import com.myotrack.infrastructure.repository.DietPlanRepository;
import com.myotrack.infrastructure.repository.ExerciseVideoAnalysisRepository;
import com.myotrack.infrastructure.repository.LoginCodeRepository;
import com.myotrack.infrastructure.repository.MealPhotoAnalysisRepository;
import com.myotrack.infrastructure.repository.PasswordResetTokenRepository;
import com.myotrack.infrastructure.repository.RefreshTokenRepository;
import com.myotrack.infrastructure.repository.UserProfileRepository;
import com.myotrack.infrastructure.repository.UserSubscriptionRepository;
import com.myotrack.infrastructure.repository.WeeklyReportRepository;
import com.myotrack.infrastructure.repository.WorkoutPlanRepository;
import com.myotrack.infrastructure.repository.WorkoutSessionRepository;
import java.util.UUID;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * Apaga todos os dados de um titular.
 *
 * <p>Está num serviço separado do {@link PrivacyController} de propósito: {@code @Transactional}
 * só vale quando a chamada passa pelo proxy do Spring, e um método chamado de dentro da própria
 * classe não passa. A transação seria silenciosamente ignorada — e numa exclusão de conta isso
 * significaria falhar no meio, deixando a conta pela metade.
 */
@Service
public class AccountPurgeService {

    private final ApplicationUserRepository users;
    private final UserProfileRepository profiles;
    private final ConsentRecordRepository consents;
    private final WorkoutPlanRepository workoutPlans;
    private final DietPlanRepository dietPlans;
    private final WorkoutSessionRepository sessions;
    private final BodyMeasurementRepository measurements;
    private final MealPhotoAnalysisRepository mealAnalyses;
    private final ExerciseVideoAnalysisRepository videoAnalyses;
    private final AnalysisJobRepository jobs;
    private final AiUsageLogRepository aiUsage;
    private final CoachMessageRepository coachMessages;
    private final WeeklyReportRepository weeklyReports;
    private final UserSubscriptionRepository subscriptions;
    private final RefreshTokenRepository refreshTokens;
    private final LoginCodeRepository loginCodes;
    private final PasswordResetTokenRepository resetTokens;

    public AccountPurgeService(
            ApplicationUserRepository users,
            UserProfileRepository profiles,
            ConsentRecordRepository consents,
            WorkoutPlanRepository workoutPlans,
            DietPlanRepository dietPlans,
            WorkoutSessionRepository sessions,
            BodyMeasurementRepository measurements,
            MealPhotoAnalysisRepository mealAnalyses,
            ExerciseVideoAnalysisRepository videoAnalyses,
            AnalysisJobRepository jobs,
            AiUsageLogRepository aiUsage,
            CoachMessageRepository coachMessages,
            WeeklyReportRepository weeklyReports,
            UserSubscriptionRepository subscriptions,
            RefreshTokenRepository refreshTokens,
            LoginCodeRepository loginCodes,
            PasswordResetTokenRepository resetTokens) {
        this.users = users;
        this.profiles = profiles;
        this.consents = consents;
        this.workoutPlans = workoutPlans;
        this.dietPlans = dietPlans;
        this.sessions = sessions;
        this.measurements = measurements;
        this.mealAnalyses = mealAnalyses;
        this.videoAnalyses = videoAnalyses;
        this.jobs = jobs;
        this.aiUsage = aiUsage;
        this.coachMessages = coachMessages;
        this.weeklyReports = weeklyReports;
        this.subscriptions = subscriptions;
        this.refreshTokens = refreshTokens;
        this.loginCodes = loginCodes;
        this.resetTokens = resetTokens;
    }

    /**
     * Ou a conta some inteira, ou nada é removido.
     *
     * <p>A ordem respeita as chaves estrangeiras. {@code SetLogs}, {@code WorkoutDays},
     * {@code Meals} e {@code MealItems} não aparecem porque o schema já os apaga em cascata a
     * partir da sessão e dos planos.
     */
    @Transactional
    public void purge(UUID userId) {
        sessions.deleteByUserId(userId);
        workoutPlans.deleteByUserId(userId);
        dietPlans.deleteByUserId(userId);
        measurements.deleteByUserId(userId);
        mealAnalyses.deleteByUserId(userId);
        videoAnalyses.deleteByUserId(userId);
        jobs.deleteByUserId(userId);
        aiUsage.deleteByUserId(userId);
        coachMessages.deleteByUserId(userId);
        weeklyReports.deleteByUserId(userId);
        subscriptions.deleteByUserId(userId);
        consents.deleteByUserId(userId);
        refreshTokens.deleteByUserId(userId);
        loginCodes.deleteByUserId(userId);
        resetTokens.deleteByUserId(userId);
        profiles.deleteByUserId(userId);

        // Por último o usuário: AspNetUserLogins, UserRoles e UserClaims caem em cascata.
        users.deleteById(userId);
    }
}
