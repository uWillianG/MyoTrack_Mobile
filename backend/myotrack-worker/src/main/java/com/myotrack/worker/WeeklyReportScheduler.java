package com.myotrack.worker;

import com.myotrack.domain.AnalysisJobType;
import com.myotrack.domain.entity.AnalysisJob;
import com.myotrack.domain.service.TrainingWeek;
import com.myotrack.infrastructure.repository.AnalysisJobRepository;
import com.myotrack.infrastructure.repository.BodyMeasurementRepository;
import com.myotrack.infrastructure.repository.MealPhotoAnalysisRepository;
import com.myotrack.infrastructure.repository.WeeklyReportRepository;
import com.myotrack.infrastructure.repository.WorkoutSessionRepository;
import java.time.LocalDate;
import java.time.OffsetDateTime;
import java.time.ZoneOffset;
import java.util.ArrayList;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Set;
import java.util.UUID;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

/**
 * Enfileira o relatório semanal (segunda a domingo, UTC) de cada usuário que teve atividade na
 * última semana completa e ainda não tem o relatório dela.
 *
 * <p>Idempotente: roda de hora em hora, mas cada usuário/semana gera no máximo um job — é a
 * garantia de "1 chamada de LLM por usuário por semana". Porte de
 * MyoTrack.Worker/WeeklyReportSchedulerService.cs.
 */
@Component
public class WeeklyReportScheduler {

    private static final Logger log = LoggerFactory.getLogger(WeeklyReportScheduler.class);

    private static final long CHECK_INTERVAL_MS = 60 * 60 * 1000L;

    private final WorkoutSessionRepository sessions;
    private final MealPhotoAnalysisRepository meals;
    private final BodyMeasurementRepository measurements;
    private final WeeklyReportRepository reports;
    private final AnalysisJobRepository jobs;

    public WeeklyReportScheduler(
            WorkoutSessionRepository sessions,
            MealPhotoAnalysisRepository meals,
            BodyMeasurementRepository measurements,
            WeeklyReportRepository reports,
            AnalysisJobRepository jobs) {
        this.sessions = sessions;
        this.meals = meals;
        this.measurements = measurements;
        this.reports = reports;
        this.jobs = jobs;
    }

    @Scheduled(fixedDelay = CHECK_INTERVAL_MS, initialDelay = 30_000)
    @Transactional
    public void enqueuePendingReports() {
        try {
            LocalDate lastWeekStart = TrainingWeek.startOf(LocalDate.now(ZoneOffset.UTC)).minusWeeks(1);
            LocalDate lastWeekEnd = lastWeekStart.plusWeeks(1);
            OffsetDateTime startUtc = lastWeekStart.atStartOfDay().atOffset(ZoneOffset.UTC);
            OffsetDateTime endUtc = lastWeekEnd.atStartOfDay().atOffset(ZoneOffset.UTC);

            // Usuários com qualquer atividade na semana: treino, refeição no diário ou medição.
            Set<UUID> active = new LinkedHashSet<>();
            active.addAll(sessions.findUserIdsWithSessionsBetween(lastWeekStart, lastWeekEnd));
            active.addAll(meals.findUserIdsWithDiaryActivity(startUtc, endUtc));
            active.addAll(measurements.findUserIdsWithMeasurementsBetween(lastWeekStart, lastWeekEnd));

            if (active.isEmpty()) {
                return;
            }

            List<UUID> activeList = List.copyOf(active);
            Set<UUID> alreadyCovered = new LinkedHashSet<>();
            alreadyCovered.addAll(reports.findUserIdsWithReportFor(lastWeekStart, activeList));
            alreadyCovered.addAll(jobs.findUsersWithOpenWeeklyReportJob(activeList));

            List<AnalysisJob> pending = new ArrayList<>();
            for (UUID userId : active) {
                if (!alreadyCovered.contains(userId)) {
                    pending.add(newJob(userId, lastWeekStart));
                }
            }

            if (!pending.isEmpty()) {
                jobs.saveAll(pending);
                log.info("Relatórios semanais: {} job(s) enfileirado(s) para a semana de {}.",
                        pending.size(), lastWeekStart);
            }
        } catch (Exception e) {
            log.error("Erro ao agendar relatórios semanais.", e);
        }
    }

    private static AnalysisJob newJob(UUID userId, LocalDate weekStart) {
        AnalysisJob job = new AnalysisJob();
        job.setUserId(userId);
        job.setType(AnalysisJobType.WEEKLY_REPORT);
        job.setInputJson("{\"weekStart\":\"%s\"}".formatted(weekStart));
        return job;
    }
}
