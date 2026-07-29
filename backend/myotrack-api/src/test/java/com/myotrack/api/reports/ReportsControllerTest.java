package com.myotrack.api.reports;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyList;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import com.myotrack.domain.AnalysisJobType;
import com.myotrack.domain.entity.AnalysisJob;
import com.myotrack.domain.entity.WeeklyReport;
import com.myotrack.infrastructure.repository.AnalysisJobRepository;
import com.myotrack.infrastructure.repository.WeeklyReportRepository;
import java.time.DayOfWeek;
import java.time.LocalDate;
import java.time.ZoneOffset;
import java.time.temporal.TemporalAdjusters;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.UUID;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;
import org.mockito.ArgumentCaptor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.security.oauth2.server.resource.authentication.JwtAuthenticationToken;

/**
 * A geração manual do relatório semanal.
 *
 * <p>O que se testa aqui é o que segura o limite de <b>uma chamada de LLM por usuário por
 * semana</b>. Sem as duas recusas, este endpoint seria um jeito de pedir narrativa quantas
 * vezes quisesse — e é dinheiro por chamada.
 */
class ReportsControllerTest {

    private static final UUID USER_ID = UUID.fromString("11111111-1111-1111-1111-111111111111");

    private WeeklyReportRepository reports;
    private AnalysisJobRepository jobs;
    private ReportsController controller;

    /** Segunda-feira (UTC) da última semana completa — a que o endpoint deve pedir. */
    private static LocalDate lastWeekStart() {
        return LocalDate.now(ZoneOffset.UTC)
                .with(TemporalAdjusters.previousOrSame(DayOfWeek.MONDAY))
                .minusWeeks(1);
    }

    @BeforeEach
    void setUp() {
        reports = mock(WeeklyReportRepository.class);
        jobs = mock(AnalysisJobRepository.class);
        controller = new ReportsController(reports, jobs);

        Jwt jwt = Jwt.withTokenValue("t")
                .header("alg", "none")
                .subject(USER_ID.toString())
                .build();
        SecurityContextHolder.getContext()
                .setAuthentication(new JwtAuthenticationToken(jwt, List.of()));

        // Caminho livre por padrão; cada teste fecha a porta que quer exercitar.
        when(reports.findByUserIdAndWeekStart(any(), any())).thenReturn(Optional.empty());
        when(jobs.findUsersWithOpenWeeklyReportJob(anyList())).thenReturn(List.of());
        // O repositório real atribui o id no save (@GeneratedValue); o mock imita isso,
        // senão a resposta seria testada com um id que a produção nunca devolveria.
        when(jobs.save(any())).thenAnswer(invocation -> {
            AnalysisJob job = invocation.getArgument(0);
            job.setId(UUID.randomUUID());
            return job;
        });
    }

    @AfterEach
    void tearDown() {
        SecurityContextHolder.clearContext();
    }

    @Nested
    @DisplayName("quando não há relatório da semana passada")
    class Livre {

        @Test
        @DisplayName("enfileira o job e responde 202")
        void enqueues() {
            ResponseEntity<?> response = controller.generate();

            // 202 e não 200: quem gera é o worker, e a resposta não espera por ele.
            assertThat(response.getStatusCode()).isEqualTo(HttpStatus.ACCEPTED);

            ArgumentCaptor<AnalysisJob> saved = ArgumentCaptor.forClass(AnalysisJob.class);
            verify(jobs).save(saved.capture());

            assertThat(saved.getValue().getUserId()).isEqualTo(USER_ID);
            assertThat(saved.getValue().getType()).isEqualTo(AnalysisJobType.WEEKLY_REPORT);
            assertThat(response.getBody())
                    .isInstanceOfSatisfying(
                            ReportsController.Enqueued.class,
                            body -> assertThat(body.jobId()).isEqualTo(saved.getValue().getId()));
        }

        @Test
        @DisplayName("pede a última semana completa, não a corrente")
        void asksForTheLastFullWeek() {
            // Uma semana ainda em curso compararia quatro dias contra sete e diria que o
            // volume caiu. O handler lê esta data do inputJson.
            controller.generate();

            ArgumentCaptor<AnalysisJob> saved = ArgumentCaptor.forClass(AnalysisJob.class);
            verify(jobs).save(saved.capture());

            assertThat(saved.getValue().getInputJson())
                    .isEqualTo("{\"weekStart\":\"%s\"}".formatted(lastWeekStart()));
        }
    }

    @Test
    @DisplayName("recusa quando a semana já tem relatório")
    void refusesWhenAlreadyGenerated() {
        when(reports.findByUserIdAndWeekStart(USER_ID, lastWeekStart()))
                .thenReturn(Optional.of(new WeeklyReport()));

        ResponseEntity<?> response = controller.generate();

        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.CONFLICT);
        assertThat(response.getBody())
                .isEqualTo(Map.of("error", "O relatório da última semana já foi gerado."));
        verify(jobs, never()).save(any());
    }

    @Test
    @DisplayName("recusa quando já existe um relatório em geração")
    void refusesWhenJobIsOpen() {
        // Sem esta segunda guarda, tocar o botão duas vezes enfileiraria dois jobs: o primeiro
        // ainda não terminou, então ainda não existe relatório para a checagem anterior ver.
        when(jobs.findUsersWithOpenWeeklyReportJob(List.of(USER_ID)))
                .thenReturn(List.of(USER_ID));

        ResponseEntity<?> response = controller.generate();

        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.CONFLICT);
        assertThat(response.getBody())
                .isEqualTo(Map.of("error", "Já existe um relatório em geração."));
        verify(jobs, never()).save(any());
    }

    @Test
    @DisplayName("a checagem é por usuário, não global")
    void checksThisUserOnly() {
        // Um relatório de outra pessoa na mesma semana não pode impedir o desta.
        controller.generate();

        verify(reports).findByUserIdAndWeekStart(USER_ID, lastWeekStart());
        verify(jobs).findUsersWithOpenWeeklyReportJob(List.of(USER_ID));
    }
}
