package com.myotrack.api.reports;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.myotrack.api.security.CurrentUser;
import com.myotrack.domain.AnalysisJobType;
import com.myotrack.domain.entity.AnalysisJob;
import com.myotrack.domain.entity.WeeklyReport;
import com.myotrack.domain.service.TrainingWeek;
import com.myotrack.infrastructure.repository.AnalysisJobRepository;
import com.myotrack.infrastructure.repository.WeeklyReportRepository;
import java.time.LocalDate;
import java.time.OffsetDateTime;
import java.time.ZoneOffset;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

/**
 * Relatório semanal.
 *
 * <p>Normalmente quem cria é o {@code WeeklyReportScheduler}, que roda de hora em hora e
 * enfileira um job por usuário ativo por semana. O POST daqui existe porque, sem ele, quem
 * acabou de fechar a primeira semana espera até uma hora sem saber por quê — o relatório
 * simplesmente não está lá, e a tela não tem o que dizer.
 *
 * <p>O limite de <b>uma chamada de LLM por usuário por semana</b> continua de pé, e é este
 * controller que o segura: recusa se a semana já tem relatório e recusa se já existe job aberto.
 * Sem essas duas guardas o botão viraria um jeito de pedir narrativa quantas vezes quisesse.
 */
@RestController
@RequestMapping("/api/reports")
public class ReportsController {

    private static final Logger log = LoggerFactory.getLogger(ReportsController.class);

    private static final ObjectMapper MAPPER = new ObjectMapper();

    private final WeeklyReportRepository reports;
    private final AnalysisJobRepository jobs;

    public ReportsController(WeeklyReportRepository reports, AnalysisJobRepository jobs) {
        this.reports = reports;
        this.jobs = jobs;
    }

    /** O relatório mais recente. 404 enquanto não houver nenhum. */
    @GetMapping("/weekly")
    @Transactional(readOnly = true)
    public ResponseEntity<ReportView> latest() {
        return reports.findFirstByUserIdOrderByWeekStartDesc(CurrentUser.id())
                .map(report -> ResponseEntity.ok(toView(report)))
                .orElseGet(() -> ResponseEntity.notFound().build());
    }

    /**
     * Enfileira o relatório da última semana completa.
     *
     * <p>Sempre a semana passada, e não a corrente: um relatório de uma semana ainda em curso
     * compararia quatro dias contra sete e diria que o volume caiu.
     *
     * <p>202 com o id do job — quem gera é o worker, e a resposta não espera por ele.
     */
    @PostMapping("/weekly/generate")
    @Transactional
    public ResponseEntity<?> generate() {
        final UUID userId = CurrentUser.id();
        final LocalDate lastWeek =
                TrainingWeek.startOf(LocalDate.now(ZoneOffset.UTC)).minusWeeks(1);

        if (reports.findByUserIdAndWeekStart(userId, lastWeek).isPresent()) {
            return ResponseEntity.status(HttpStatus.CONFLICT)
                    .body(Map.of("error", "O relatório da última semana já foi gerado."));
        }

        // Sem esta segunda guarda, tocar o botão duas vezes enfileiraria dois jobs: o primeiro
        // ainda não terminou, então ainda não existe relatório para a checagem acima ver.
        if (!jobs.findUsersWithOpenWeeklyReportJob(List.of(userId)).isEmpty()) {
            return ResponseEntity.status(HttpStatus.CONFLICT)
                    .body(Map.of("error", "Já existe um relatório em geração."));
        }

        final AnalysisJob job = new AnalysisJob();
        job.setUserId(userId);
        job.setType(AnalysisJobType.WEEKLY_REPORT);
        job.setInputJson("{\"weekStart\":\"%s\"}".formatted(lastWeek));
        // O id vem da instância devolvida pelo save, e não da que foi passada: com
        // @GeneratedValue quem carrega o id atribuído é a gerenciada.
        final AnalysisJob saved = jobs.save(job);

        // Record e não Map: `Map.of` estoura com valor nulo, e o id vem do banco.
        return ResponseEntity.accepted().body(new Enqueued(saved.getId()));
    }

    private ReportView toView(WeeklyReport report) {
        return new ReportView(
                report.getId(),
                report.getWeekStart(),
                readJson(report.getMetricsJson(), report.getId()),
                // Null é estado normal: sem IA configurada o relatório sai só com os números,
                // e a tela mostra as métricas sem o texto.
                report.getNarrativeJson() == null
                        ? null
                        : readJson(report.getNarrativeJson(), report.getId()),
                report.getCreatedAt());
    }

    /**
     * Devolvidos como objeto, e não como string de JSON.
     *
     * <p>As métricas evoluem — uma nova entra no {@code metricsJson} sem migração —, e repassar
     * a árvore deixa o campo novo chegar ao cliente sem mexer neste arquivo.
     */
    private JsonNode readJson(String raw, UUID reportId) {
        try {
            return MAPPER.readTree(raw == null || raw.isBlank() ? "{}" : raw);
        } catch (Exception e) {
            log.warn("JSON ilegível no relatório {}: {}", reportId, e.getMessage());
            return MAPPER.createObjectNode();
        }
    }

    /** Resposta do 202: o job que o worker vai processar. */
    public record Enqueued(UUID jobId) {
    }

    public record ReportView(
            UUID id,
            LocalDate weekStart,
            JsonNode metrics,
            JsonNode narrative,
            OffsetDateTime createdAt) {
    }
}
