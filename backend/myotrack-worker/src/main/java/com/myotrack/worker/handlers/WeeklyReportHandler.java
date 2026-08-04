package com.myotrack.worker.handlers;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.myotrack.domain.AnalysisJobType;
import com.myotrack.domain.entity.AnalysisJob;
import com.myotrack.domain.entity.BodyMeasurement;
import com.myotrack.domain.entity.MealPhotoAnalysis;
import com.myotrack.domain.entity.SetLog;
import com.myotrack.domain.entity.WeeklyReport;
import com.myotrack.domain.entity.WorkoutSession;
import com.myotrack.domain.service.WeeklyMetrics;
import com.myotrack.domain.service.WeeklyMetrics.MealInput;
import com.myotrack.domain.service.WeeklyMetrics.SessionInput;
import com.myotrack.domain.service.WeeklyMetrics.SetInput;
import com.myotrack.domain.service.WeeklyMetrics.WeightInput;
import com.myotrack.infrastructure.ai.AiUsageRecorder;
import com.myotrack.infrastructure.ai.LlmJsonClient;
import com.myotrack.infrastructure.ai.LlmJsonClient.LlmJsonResult;
import com.myotrack.infrastructure.repository.BodyMeasurementRepository;
import com.myotrack.infrastructure.repository.MealPhotoAnalysisRepository;
import com.myotrack.infrastructure.repository.WeeklyReportRepository;
import com.myotrack.infrastructure.repository.WorkoutSessionRepository;
import com.myotrack.worker.JobHandler;
import java.time.LocalDate;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.data.domain.Limit;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

/**
 * Produz o relatório semanal.
 *
 * <p>Fechava um buraco: o {@code WeeklyReportScheduler} já enfileirava jobs deste tipo de hora
 * em hora, mas não havia handler registrado. O {@code JobPoller} falhava cada um com "nenhum
 * handler registrado", e como o agendador só considera coberto quem tem job PENDING ou
 * PROCESSING, o mesmo usuário voltava para a fila na hora seguinte — indefinidamente.
 *
 * <p>Os números saem do {@link WeeklyMetrics}, em código. O LLM escreve só a narrativa, e sua
 * ausência não impede o relatório: sem chave configurada, ou com resposta inválida, ele fica
 * com {@code narrativeJson} nulo e vale pelos números.
 */
@Component
public class WeeklyReportHandler implements JobHandler {

    private static final Logger log = LoggerFactory.getLogger(WeeklyReportHandler.class);

    private static final ObjectMapper MAPPER = new ObjectMapper();

    /**
     * Teto de refeições lidas por relatório. Uma semana não tem centenas; o limite existe para
     * um usuário com histórico enorme não puxar tudo por causa de sete dias.
     */
    private static final Limit MEAL_LOOKBACK = Limit.of(400);

    private final WorkoutSessionRepository sessions;
    private final BodyMeasurementRepository measurements;
    private final MealPhotoAnalysisRepository meals;
    private final WeeklyReportRepository reports;
    private final AiUsageRecorder aiUsage;
    private final LlmJsonClient llm;

    public WeeklyReportHandler(
            WorkoutSessionRepository sessions,
            BodyMeasurementRepository measurements,
            MealPhotoAnalysisRepository meals,
            WeeklyReportRepository reports,
            AiUsageRecorder aiUsage,
            LlmJsonClient llm) {
        this.sessions = sessions;
        this.measurements = measurements;
        this.meals = meals;
        this.reports = reports;
        this.aiUsage = aiUsage;
        this.llm = llm;
    }

    @Override
    public AnalysisJobType type() {
        return AnalysisJobType.WEEKLY_REPORT;
    }

    @Override
    @Transactional
    public String handle(AnalysisJob job) {
        final UUID userId = job.getUserId();
        final LocalDate weekStart = weekStartOf(job);
        final LocalDate weekEnd = weekStart.plusWeeks(1);

        // Idempotência: o agendador evita duplicar, mas um reprocessamento por falha de rede
        // chegaria aqui de novo, e dois relatórios da mesma semana confundiriam a tela.
        final WeeklyReport existing =
                reports.findByUserIdAndWeekStart(userId, weekStart).orElse(null);
        if (existing != null) {
            return "{\"weeklyReportId\":\"%s\"}".formatted(existing.getId());
        }

        final List<WorkoutSession> all = sessions.findByUserIdOrderByDateDesc(userId);
        final WeeklyMetrics.Result metrics = WeeklyMetrics.compute(
                weekStart,
                sessionsBetween(all, weekStart, weekEnd),
                sessionsBetween(all, weekStart.minusWeeks(1), weekStart),
                weightsBetween(userId, weekStart, weekEnd),
                mealsBetween(userId, weekStart, weekEnd));

        final WeeklyReport report = new WeeklyReport();
        report.setUserId(userId);
        report.setWeekStart(weekStart);
        report.setMetricsJson(toJson(metrics));
        report.setNarrativeJson(narrativeFor(userId, metrics));

        return "{\"weeklyReportId\":\"%s\"}".formatted(reports.save(report).getId());
    }

    /** A semana vem no {@code inputJson} que o agendador montou. */
    private static LocalDate weekStartOf(AnalysisJob job) {
        final String input = job.getInputJson();
        if (input == null || input.isBlank()) {
            throw new IllegalStateException("A semana do relatório não foi informada.");
        }
        try {
            final String value = MAPPER.readTree(input).path("weekStart").asText(null);
            return LocalDate.parse(value);
        } catch (Exception e) {
            throw new IllegalStateException("A semana do relatório não pôde ser lida.", e);
        }
    }

    private static List<SessionInput> sessionsBetween(
            List<WorkoutSession> all, LocalDate start, LocalDate end) {

        return all.stream()
                .filter(s -> s.getDate() != null
                        && !s.getDate().isBefore(start)
                        && s.getDate().isBefore(end))
                .map(s -> new SessionInput(s.getDate(), s.getSets().stream()
                        .map(WeeklyReportHandler::toSetInput)
                        .toList()))
                .toList();
    }

    private static SetInput toSetInput(SetLog set) {
        final String name = set.getExercise() == null ? "" : set.getExercise().getName();
        return new SetInput(name, set.getReps(), set.getLoadKg());
    }

    private List<WeightInput> weightsBetween(UUID userId, LocalDate start, LocalDate end) {
        return measurements.findByUserIdOrderByDateDesc(userId).stream()
                .filter(m -> m.getDate() != null
                        && !m.getDate().isBefore(start)
                        && m.getDate().isBefore(end))
                .map(m -> new WeightInput(m.getDate(), m.getWeightKg()))
                .toList();
    }

    /** Só o que está no diário: refeição excluída pelo usuário não conta na semana dele. */
    private List<MealInput> mealsBetween(UUID userId, LocalDate start, LocalDate end) {
        return meals.findByUserIdOrderByCreatedAtDesc(userId, MEAL_LOOKBACK).stream()
                .filter(m -> !m.isExcludedFromDiary())
                .filter(m -> {
                    final LocalDate date = dateOf(m);
                    return date != null && !date.isBefore(start) && date.isBefore(end);
                })
                .map(m -> new MealInput(dateOf(m), m.getTotalKcal()))
                .toList();
    }

    private static LocalDate dateOf(MealPhotoAnalysis meal) {
        return meal.getCreatedAt() == null ? null : meal.getCreatedAt().toLocalDate();
    }

    /** A narrativa do LLM, ou null quando ela não vem — o relatório vale pelos números. */
    private String narrativeFor(UUID userId, WeeklyMetrics.Result metrics) {
        if (!llm.isConfigured()) {
            return null;
        }

        final LlmJsonResult result =
                llm.generateJson(systemPrompt(), toJson(metrics), narrativeSchema());
        if (result == null) {
            log.warn("Sem narrativa para o relatório de {}: o LLM não respondeu.", userId);
            return null;
        }

        recordUsage(userId, result);

        // Confere que é JSON válido antes de gravar numa coluna JSONB: texto quebrado aqui
        // derrubaria a leitura do relatório inteiro depois.
        try {
            MAPPER.readTree(result.json());
            return result.json();
        } catch (Exception e) {
            log.warn("Narrativa do LLM descartada por ser ilegível: {}", e.getMessage());
            return null;
        }
    }

    private void recordUsage(UUID userId, LlmJsonResult result) {
        aiUsage.record(userId, AnalysisJobType.WEEKLY_REPORT, llm, result);
    }

    private static String systemPrompt() {
        return """
                Você é um personal trainer comentando a semana do aluno.
                Receberá as métricas já calculadas. NÃO recalcule nem invente número algum:
                use apenas os valores recebidos, e ignore os que vierem nulos.
                Escreva em português do Brasil, em segunda pessoa, de forma direta e sem
                bajulação. O resumo tem no máximo três frases. Dê de 1 a 3 destaques e de 1 a 3
                recomendações práticas para a próxima semana.
                Se a semana teve pouco registro, diga isso em vez de elogiar o que não houve.
                """;
    }

    private static Map<String, Object> narrativeSchema() {
        final String schema = """
                {
                  "type": "object",
                  "properties": {
                    "summary": { "type": "string" },
                    "highlights": { "type": "array", "items": { "type": "string" } },
                    "recommendations": { "type": "array", "items": { "type": "string" } }
                  },
                  "required": ["summary", "highlights", "recommendations"]
                }
                """;
        try {
            @SuppressWarnings("unchecked")
            final Map<String, Object> parsed = MAPPER.readValue(schema, Map.class);
            return parsed;
        } catch (Exception e) {
            throw new IllegalStateException("Schema da narrativa inválido.", e);
        }
    }

    private static String toJson(Object value) {
        try {
            return MAPPER.writeValueAsString(value);
        } catch (Exception e) {
            throw new IllegalStateException("Falha ao serializar o relatório.", e);
        }
    }
}
