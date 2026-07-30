package com.myotrack.worker;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatCode;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyList;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import com.myotrack.domain.AnalysisJobType;
import com.myotrack.domain.entity.AnalysisJob;
import com.myotrack.infrastructure.repository.AnalysisJobRepository;
import com.myotrack.infrastructure.repository.BodyMeasurementRepository;
import com.myotrack.infrastructure.repository.MealPhotoAnalysisRepository;
import com.myotrack.infrastructure.repository.WeeklyReportRepository;
import com.myotrack.infrastructure.repository.WorkoutSessionRepository;
import java.time.DayOfWeek;
import java.time.LocalDate;
import java.time.ZoneOffset;
import java.time.temporal.TemporalAdjusters;
import java.util.List;
import java.util.UUID;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;
import org.mockito.ArgumentCaptor;

/**
 * O enfileiramento automático do relatório semanal.
 *
 * <p>Este agendador roda de hora em hora e cada job que ele cria é uma chamada de LLM paga. A
 * propriedade que sustenta o custo do sistema é a <b>idempotência</b>: 168 execuções ao longo da
 * semana precisam produzir no máximo um job por usuário. Sem as duas guardas — relatório já
 * existente e job já aberto — o mesmo relatório seria pago de hora em hora, e o sintoma não é
 * erro nenhum: é a fatura.
 */
class WeeklyReportSchedulerTest {

    private static final UUID ANA = UUID.fromString("11111111-1111-1111-1111-111111111111");
    private static final UUID BRUNO = UUID.fromString("22222222-2222-2222-2222-222222222222");

    private WorkoutSessionRepository sessions;
    private MealPhotoAnalysisRepository meals;
    private BodyMeasurementRepository measurements;
    private WeeklyReportRepository reports;
    private AnalysisJobRepository jobs;
    private WeeklyReportScheduler scheduler;

    /** Segunda-feira (UTC) da última semana completa — a que o agendador deve cobrir. */
    private static LocalDate lastWeekStart() {
        return LocalDate.now(ZoneOffset.UTC)
                .with(TemporalAdjusters.previousOrSame(DayOfWeek.MONDAY))
                .minusWeeks(1);
    }

    @BeforeEach
    void setUp() {
        sessions = mock(WorkoutSessionRepository.class);
        meals = mock(MealPhotoAnalysisRepository.class);
        measurements = mock(BodyMeasurementRepository.class);
        reports = mock(WeeklyReportRepository.class);
        jobs = mock(AnalysisJobRepository.class);
        scheduler = new WeeklyReportScheduler(sessions, meals, measurements, reports, jobs);

        // Semana sem atividade e sem cobertura; cada teste acende a fonte que exercita.
        when(sessions.findUserIdsWithSessionsBetween(any(), any())).thenReturn(List.of());
        when(meals.findUserIdsWithDiaryActivity(any(), any())).thenReturn(List.of());
        when(measurements.findUserIdsWithMeasurementsBetween(any(), any())).thenReturn(List.of());
        when(reports.findUserIdsWithReportFor(any(), anyList())).thenReturn(List.of());
        when(jobs.findUsersWithOpenWeeklyReportJob(anyList())).thenReturn(List.of());
    }

    private List<AnalysisJob> enqueued() {
        @SuppressWarnings("unchecked")
        ArgumentCaptor<List<AnalysisJob>> captor = ArgumentCaptor.forClass(List.class);
        verify(jobs).saveAll(captor.capture());
        return captor.getValue();
    }

    private List<UUID> enqueuedUserIds() {
        return enqueued().stream().map(AnalysisJob::getUserId).toList();
    }

    @Nested
    @DisplayName("quem entra na lista")
    class Elegiveis {

        @Test
        @DisplayName("treino na semana basta")
        void workoutCounts() {
            when(sessions.findUserIdsWithSessionsBetween(any(), any())).thenReturn(List.of(ANA));

            scheduler.enqueuePendingReports();

            assertThat(enqueuedUserIds()).containsExactly(ANA);
        }

        @Test
        @DisplayName("refeição no diário basta")
        void mealCounts() {
            when(meals.findUserIdsWithDiaryActivity(any(), any())).thenReturn(List.of(ANA));

            scheduler.enqueuePendingReports();

            assertThat(enqueuedUserIds()).containsExactly(ANA);
        }

        @Test
        @DisplayName("medição corporal basta")
        void measurementCounts() {
            // Quem só se pesou na semana ainda tem o que receber: o relatório comenta peso.
            when(measurements.findUserIdsWithMeasurementsBetween(any(), any()))
                    .thenReturn(List.of(ANA));

            scheduler.enqueuePendingReports();

            assertThat(enqueuedUserIds()).containsExactly(ANA);
        }

        @Test
        @DisplayName("as três fontes se unem sem repetir usuário")
        void unionIsDeduplicated() {
            // O caso comum é o usuário ativo aparecer nas três listas. Um job por aparição
            // seriam três relatórios idênticos e três chamadas de LLM para a mesma semana.
            when(sessions.findUserIdsWithSessionsBetween(any(), any())).thenReturn(List.of(ANA, BRUNO));
            when(meals.findUserIdsWithDiaryActivity(any(), any())).thenReturn(List.of(ANA));
            when(measurements.findUserIdsWithMeasurementsBetween(any(), any()))
                    .thenReturn(List.of(ANA, BRUNO));

            scheduler.enqueuePendingReports();

            assertThat(enqueuedUserIds()).containsExactlyInAnyOrder(ANA, BRUNO);
        }

        @Test
        @DisplayName("semana sem atividade nenhuma não grava nada")
        void quietWeekWritesNothing() {
            scheduler.enqueuePendingReports();

            // Nem um saveAll com lista vazia: é o caso de toda hora em que ninguém treinou.
            verify(jobs, never()).saveAll(anyList());
        }
    }

    @Nested
    @DisplayName("a idempotência")
    class Idempotencia {

        @Test
        @DisplayName("salta quem já tem o relatório da semana")
        void skipsUsersAlreadyReported() {
            when(sessions.findUserIdsWithSessionsBetween(any(), any())).thenReturn(List.of(ANA, BRUNO));
            when(reports.findUserIdsWithReportFor(any(), anyList())).thenReturn(List.of(ANA));

            scheduler.enqueuePendingReports();

            assertThat(enqueuedUserIds()).containsExactly(BRUNO);
        }

        @Test
        @DisplayName("salta quem já tem job aberto")
        void skipsUsersWithOpenJob() {
            // A segunda guarda cobre a janela entre enfileirar e concluir: durante ela ainda não
            // existe relatório, então a checagem anterior não veria nada e o job seria refeito a
            // cada hora enquanto o primeiro processa.
            when(sessions.findUserIdsWithSessionsBetween(any(), any())).thenReturn(List.of(ANA, BRUNO));
            when(jobs.findUsersWithOpenWeeklyReportJob(anyList())).thenReturn(List.of(BRUNO));

            scheduler.enqueuePendingReports();

            assertThat(enqueuedUserIds()).containsExactly(ANA);
        }

        @Test
        @DisplayName("todos cobertos não gera job nenhum")
        void allCoveredWritesNothing() {
            when(sessions.findUserIdsWithSessionsBetween(any(), any())).thenReturn(List.of(ANA));
            when(reports.findUserIdsWithReportFor(any(), anyList())).thenReturn(List.of(ANA));

            scheduler.enqueuePendingReports();

            verify(jobs, never()).saveAll(anyList());
        }

        @Test
        @DisplayName("consulta a cobertura só dos usuários ativos")
        void checksCoverageForActiveUsersOnly() {
            // A consulta é filtrada pela lista de ativos, não global: varrer a tabela inteira de
            // relatórios cresceria com a base sem necessidade.
            when(sessions.findUserIdsWithSessionsBetween(any(), any())).thenReturn(List.of(ANA));

            scheduler.enqueuePendingReports();

            verify(reports).findUserIdsWithReportFor(lastWeekStart(), List.of(ANA));
            verify(jobs).findUsersWithOpenWeeklyReportJob(List.of(ANA));
        }
    }

    @Nested
    @DisplayName("a semana pedida")
    class Semana {

        @Test
        @DisplayName("é a última completa, não a corrente")
        void isTheLastFullWeek() {
            // Uma semana em curso compararia quatro dias contra sete e diria que o volume caiu.
            when(sessions.findUserIdsWithSessionsBetween(any(), any())).thenReturn(List.of(ANA));

            scheduler.enqueuePendingReports();

            assertThat(enqueued()).singleElement().satisfies(job -> {
                // O handler lê esta data do inputJson; é o contrato entre os dois.
                assertThat(job.getInputJson())
                        .isEqualTo("{\"weekStart\":\"%s\"}".formatted(lastWeekStart()));
                assertThat(job.getType()).isEqualTo(AnalysisJobType.WEEKLY_REPORT);
            });
        }

        @Test
        @DisplayName("vai de segunda a segunda")
        void spansMondayToMonday() {
            scheduler.enqueuePendingReports();

            // Meia-noite de segunda até meia-noite da segunda seguinte: fim exclusivo, senão o
            // primeiro treino da semana nova entraria no relatório da anterior.
            verify(sessions)
                    .findUserIdsWithSessionsBetween(lastWeekStart(), lastWeekStart().plusWeeks(1));
            assertThat(lastWeekStart().getDayOfWeek()).isEqualTo(DayOfWeek.MONDAY);
        }
    }

    @Test
    @DisplayName("uma falha de banco não propaga para o scheduler")
    void databaseFailureDoesNotPropagate() {
        when(sessions.findUserIdsWithSessionsBetween(any(), any()))
                .thenThrow(new RuntimeException("connection refused"));

        assertThatCode(scheduler::enqueuePendingReports).doesNotThrowAnyException();

        verify(jobs, never()).saveAll(anyList());
    }
}
