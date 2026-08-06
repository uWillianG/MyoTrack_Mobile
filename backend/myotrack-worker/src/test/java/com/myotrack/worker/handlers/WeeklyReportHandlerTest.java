package com.myotrack.worker.handlers;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.myotrack.domain.AnalysisJobType;
import com.myotrack.domain.entity.AnalysisJob;
import com.myotrack.domain.entity.WeeklyReport;
import com.myotrack.infrastructure.ai.AiUsageRecorder;
import com.myotrack.infrastructure.ai.LlmJsonClient;
import com.myotrack.infrastructure.repository.BodyMeasurementRepository;
import com.myotrack.infrastructure.repository.MealPhotoAnalysisRepository;
import com.myotrack.infrastructure.repository.WeeklyReportRepository;
import com.myotrack.infrastructure.repository.WorkoutSessionRepository;
import java.time.LocalDate;
import java.util.List;
import java.util.Optional;
import java.util.UUID;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.mockito.ArgumentCaptor;
import org.springframework.data.domain.Limit;

/**
 * A gravação do relatório semanal.
 *
 * <p>O que estes testes protegem é a <b>fronteira de serialização</b>. As métricas viram uma
 * coluna JSONB e de lá vão direto para o app, que lê {@code weekStart} como texto — e o
 * {@code ObjectMapper} do Jackson, sem módulo nenhum, nem sabe escrever um {@code LocalDate}:
 * ele lança, o handler transforma em {@code IllegalStateException}, e o job morre na primeira
 * tentativa por ser erro de negócio. Foi assim que todo relatório semanal falhou em silêncio —
 * o usuário não vê job nenhum, só um relatório que nunca aparece.
 */
class WeeklyReportHandlerTest {

    private static final UUID ANA = UUID.fromString("11111111-1111-1111-1111-111111111111");
    private static final LocalDate WEEK_START = LocalDate.of(2026, 8, 3);

    private static final ObjectMapper MAPPER = new ObjectMapper();

    private WorkoutSessionRepository sessions;
    private BodyMeasurementRepository measurements;
    private MealPhotoAnalysisRepository meals;
    private WeeklyReportRepository reports;
    private LlmJsonClient llm;
    private WeeklyReportHandler handler;

    @BeforeEach
    void setUp() {
        sessions = mock(WorkoutSessionRepository.class);
        measurements = mock(BodyMeasurementRepository.class);
        meals = mock(MealPhotoAnalysisRepository.class);
        reports = mock(WeeklyReportRepository.class);
        llm = mock(LlmJsonClient.class);

        when(reports.findByUserIdAndWeekStart(any(), any())).thenReturn(Optional.empty());
        when(sessions.findByUserIdOrderByDateDesc(any())).thenReturn(List.of());
        when(measurements.findByUserIdOrderByDateDesc(any())).thenReturn(List.of());
        when(meals.findByUserIdOrderByCreatedAtDesc(any(), any(Limit.class)))
                .thenReturn(List.of());
        // Sem LLM: a narrativa é opcional e o relatório vale pelos números. O que se mede aqui
        // são os números.
        when(llm.isConfigured()).thenReturn(false);
        when(reports.save(any())).thenAnswer(call -> {
            final WeeklyReport saved = call.getArgument(0);
            saved.setId(UUID.randomUUID());
            return saved;
        });

        handler = new WeeklyReportHandler(
                sessions,
                measurements,
                meals,
                reports,
                mock(AiUsageRecorder.class),
                llm);
    }

    private static AnalysisJob job() {
        final AnalysisJob job = new AnalysisJob();
        job.setId(UUID.randomUUID());
        job.setUserId(ANA);
        job.setType(AnalysisJobType.WEEKLY_REPORT);
        job.setInputJson("{\"weekStart\":\"%s\"}".formatted(WEEK_START));
        return job;
    }

    /**
     * A semana vazia é o caso mais simples que existe — e era o suficiente para quebrar, porque
     * {@code weekStart} sozinho já é um {@code LocalDate}.
     */
    @Test
    void gravaORelatorioDeUmaSemanaSemRegistroNenhum() {
        handler.handle(job());

        final ArgumentCaptor<WeeklyReport> saved = ArgumentCaptor.forClass(WeeklyReport.class);
        verify(reports).save(saved.capture());
        assertThat(saved.getValue().getWeekStart()).isEqualTo(WEEK_START);
    }

    /**
     * A data vai como texto ISO, e não como o vetor {@code [2026,8,3]} que o Jackson escreve por
     * padrão quando só o módulo de datas é registrado. O app declara {@code String? weekStart}:
     * um vetor ali não é um relatório feio, é um relatório que não abre.
     */
    @Test
    void escreveADataDaSemanaComoTextoIso() throws Exception {
        handler.handle(job());

        final ArgumentCaptor<WeeklyReport> saved = ArgumentCaptor.forClass(WeeklyReport.class);
        verify(reports).save(saved.capture());

        final JsonNode metrics = MAPPER.readTree(saved.getValue().getMetricsJson());
        assertThat(metrics.path("weekStart").isTextual()).isTrue();
        assertThat(metrics.path("weekStart").asText()).isEqualTo("2026-08-03");
    }
}
