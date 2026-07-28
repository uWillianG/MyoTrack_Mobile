package com.myotrack.api.jobs;

import com.myotrack.api.security.CurrentUser;
import com.myotrack.domain.entity.AnalysisJob;
import com.myotrack.infrastructure.repository.AnalysisJobRepository;
import java.io.IOException;
import java.time.Duration;
import java.time.OffsetDateTime;
import java.util.Objects;
import java.util.Optional;
import java.util.UUID;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.servlet.mvc.method.annotation.SseEmitter;

/**
 * Estado dos jobs de IA. Porte de MyoTrack.Api/Controllers/JobsController.cs.
 *
 * <p>Seis funcionalidades dependem daqui — geração de treino e de dieta, análise de refeição e
 * de vídeo, coach e relatório semanal. O cliente acompanha por SSE e cai para polling em
 * {@code GET /api/jobs/&#123;id&#125;} se o stream não estiver disponível.
 */
@RestController
@RequestMapping("/api/jobs")
public class JobsController {

    private static final Logger log = LoggerFactory.getLogger(JobsController.class);

    /** Intervalo entre consultas ao banco enquanto o job não termina. */
    private static final Duration POLL_INTERVAL = Duration.ofSeconds(1);

    /**
     * Teto do stream. Análise de vídeo leva minutos; o cliente reconecta se estourar, e o
     * {@code JobWatcher} do app já sabe cair para polling nesse caso.
     */
    private static final Duration STREAM_DEADLINE = Duration.ofMinutes(15);

    /**
     * Cada stream ocupa uma thread enquanto espera. Virtual threads deixam isso barato: com
     * threads de plataforma, algumas dezenas de usuários aguardando análise esgotariam o pool
     * do Tomcat e a API pararia de responder.
     */
    private final ExecutorService streamExecutor =
            Executors.newVirtualThreadPerTaskExecutor();

    private final AnalysisJobRepository jobs;

    public JobsController(AnalysisJobRepository jobs) {
        this.jobs = jobs;
    }

    @GetMapping("/{id}")
    public ResponseEntity<JobView> get(@PathVariable UUID id) {
        return findForCurrentUser(id, CurrentUser.id())
                .map(ResponseEntity::ok)
                .orElseGet(() -> ResponseEntity.notFound().build());
    }

    /**
     * Estado do job via Server-Sent Events: um evento por mudança, encerrando quando o job
     * termina.
     *
     * <p>A autenticação vem pelo parâmetro {@code access_token} — nem o {@code EventSource} do
     * browser nem os clientes SSE mandam header. O {@code JobStreamBearerTokenResolver} só
     * aceita isso neste caminho.
     */
    @GetMapping(value = "/{id}/stream", produces = MediaType.TEXT_EVENT_STREAM_VALUE)
    public SseEmitter stream(@PathVariable UUID id) {
        // O id do usuário é lido AQUI, na thread da requisição: dentro do executor o
        // SecurityContext já não está disponível.
        final UUID userId = CurrentUser.id();

        final SseEmitter emitter = new SseEmitter(STREAM_DEADLINE.toMillis());
        streamExecutor.execute(() -> pump(emitter, id, userId));
        return emitter;
    }

    private void pump(SseEmitter emitter, UUID jobId, UUID userId) {
        final OffsetDateTime deadline = OffsetDateTime.now().plus(STREAM_DEADLINE);
        JobView previous = null;

        try {
            while (OffsetDateTime.now().isBefore(deadline)) {
                final Optional<JobView> found = findForCurrentUser(jobId, userId);

                if (found.isEmpty()) {
                    // Job inexistente ou de outro usuário — a mesma resposta para os dois
                    // casos, para não revelar a existência de jobs alheios.
                    emitter.send(SseEmitter.event().data(new JobError("not_found")));
                    emitter.complete();
                    return;
                }

                final JobView job = found.get();
                // Só emite quando algo muda — evita inundar o cliente a cada segundo.
                if (!Objects.equals(previous, job)) {
                    emitter.send(SseEmitter.event().data(job));
                    previous = job;
                }

                if (job.isTerminal()) {
                    emitter.complete();
                    return;
                }

                Thread.sleep(POLL_INTERVAL.toMillis());
            }
            // Estourou o teto sem terminar: fecha limpo e o cliente reconecta.
            emitter.complete();
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
            emitter.complete();
        } catch (IOException | IllegalStateException e) {
            // Cliente desconectou (fechou o app, perdeu a rede). Não é erro.
            emitter.complete();
        } catch (Exception e) {
            log.warn("Falha no stream do job {}: {}", jobId, e.getMessage());
            emitter.completeWithError(e);
        }
    }

    private Optional<JobView> findForCurrentUser(UUID jobId, UUID userId) {
        return jobs.findById(jobId)
                .filter(job -> job.getUserId().equals(userId))
                .map(JobView::from);
    }

    /**
     * O que o cliente vê de um job.
     *
     * <p>É um record para que a comparação por igualdade decida se houve mudança — e não
     * expõe {@code inputJson}, que pode conter dados do prompt.
     */
    public record JobView(
            UUID id,
            String type,
            String status,
            String resultJson,
            String lastError,
            OffsetDateTime createdAt,
            OffsetDateTime completedAt) {

        static JobView from(AnalysisJob job) {
            return new JobView(
                    job.getId(),
                    job.getType().getWireName(),
                    job.getStatus().getWireName(),
                    job.getResultJson(),
                    job.getLastError(),
                    job.getCreatedAt(),
                    job.getCompletedAt());
        }

        boolean isTerminal() {
            return "Completed".equals(status) || "Failed".equals(status);
        }
    }

    /** Enviado quando o job não existe — o cliente encerra em vez de esperar para sempre. */
    public record JobError(String error) {
    }
}
