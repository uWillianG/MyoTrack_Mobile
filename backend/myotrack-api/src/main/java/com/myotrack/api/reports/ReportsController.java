package com.myotrack.api.reports;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.myotrack.api.security.CurrentUser;
import com.myotrack.domain.entity.WeeklyReport;
import com.myotrack.infrastructure.repository.WeeklyReportRepository;
import java.time.LocalDate;
import java.time.OffsetDateTime;
import java.util.UUID;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.ResponseEntity;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

/**
 * Relatório semanal.
 *
 * <p>Só leitura: quem cria é o {@code WeeklyReportScheduler}, que enfileira um job por usuário
 * ativo por semana. Não há endpoint para pedir a geração de propósito — o limite de "uma
 * chamada de LLM por usuário por semana" mora no agendador, e um botão de gerar aqui o
 * contornaria.
 */
@RestController
@RequestMapping("/api/reports")
public class ReportsController {

    private static final Logger log = LoggerFactory.getLogger(ReportsController.class);

    private static final ObjectMapper MAPPER = new ObjectMapper();

    private final WeeklyReportRepository reports;

    public ReportsController(WeeklyReportRepository reports) {
        this.reports = reports;
    }

    /** O relatório mais recente. 404 enquanto não houver nenhum. */
    @GetMapping("/weekly")
    @Transactional(readOnly = true)
    public ResponseEntity<ReportView> latest() {
        return reports.findFirstByUserIdOrderByWeekStartDesc(CurrentUser.id())
                .map(report -> ResponseEntity.ok(toView(report)))
                .orElseGet(() -> ResponseEntity.notFound().build());
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

    public record ReportView(
            UUID id,
            LocalDate weekStart,
            JsonNode metrics,
            JsonNode narrative,
            OffsetDateTime createdAt) {
    }
}
