package com.myotrack.worker;

import com.myotrack.domain.AnalysisJobType;
import com.myotrack.domain.JobStatus;
import com.myotrack.domain.entity.AnalysisJob;
import com.myotrack.infrastructure.repository.AnalysisJobRepository;
import java.time.OffsetDateTime;
import java.util.EnumMap;
import java.util.List;
import java.util.Map;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;

/**
 * Consome a fila de jobs de IA persistida no Postgres. Porte de
 * MyoTrack.Worker/JobPollerService.cs.
 *
 * <p>O laço {@code while} + {@code Task.Delay} do {@code BackgroundService} vira um
 * {@code @Scheduled(fixedDelay)}: o Spring só reagenda depois que a execução anterior termina,
 * então nunca há duas varreduras concorrentes na mesma instância.
 */
@Component
public class JobPoller {

    private static final Logger log = LoggerFactory.getLogger(JobPoller.class);

    private static final long POLL_INTERVAL_MS = 2_000;

    /** Teto de tentativas de um job de fundo. O interativo não chega a contar — ver {@link #retryable}. */
    private static final int MAX_ATTEMPTS = 3;

    /** Teto de jobs por varredura: devolve o controle ao scheduler mesmo com a fila cheia. */
    private static final int MAX_JOBS_PER_SWEEP = 20;

    private final AnalysisJobRepository jobs;
    private final JobClaimer claimer;
    private final JobCompletionNotifier notifier;
    private final Map<AnalysisJobType, JobHandler> handlers = new EnumMap<>(AnalysisJobType.class);

    public JobPoller(
            AnalysisJobRepository jobs,
            JobClaimer claimer,
            JobCompletionNotifier notifier,
            List<JobHandler> registeredHandlers) {
        this.jobs = jobs;
        this.claimer = claimer;
        this.notifier = notifier;
        for (JobHandler handler : registeredHandlers) {
            JobHandler previous = handlers.put(handler.type(), handler);
            if (previous != null) {
                throw new IllegalStateException(
                        "Dois handlers registrados para o job '%s'.".formatted(handler.type()));
            }
        }
        log.info("JobPoller iniciado com {} handler(s): {}", handlers.size(), handlers.keySet());
    }

    @Scheduled(fixedDelay = POLL_INTERVAL_MS)
    public void sweep() {
        for (int processed = 0; processed < MAX_JOBS_PER_SWEEP; processed++) {
            try {
                if (!processNextJob()) {
                    return;
                }
            } catch (Exception e) {
                log.error("Erro no laço de polling de jobs.", e);
                return;
            }
        }
    }

    /** True quando havia um job para processar. */
    private boolean processNextJob() {
        AnalysisJob job = claimer.claimNext().orElse(null);
        if (job == null) {
            return false;
        }

        try {
            job.setResultJson(dispatch(job));
            job.setStatus(JobStatus.COMPLETED);
            job.setCompletedAt(OffsetDateTime.now());
        } catch (IllegalStateException e) {
            // Erro de negócio (perfil incompleto, catálogo insuficiente): reprocessar não muda nada.
            log.warn("Job {} falhou por regra de negócio: {}", job.getId(), e.getMessage());
            job.setLastError(e.getMessage());
            job.setStatus(JobStatus.FAILED);
        } catch (Exception e) {
            log.error("Falha ao processar job {} ({}).", job.getId(), job.getType(), e);
            job.setLastError(e.getMessage());
            job.setStatus(retryable(job) ? JobStatus.PENDING : JobStatus.FAILED);
        }

        jobs.save(job);

        // Depois do save, e fora do try acima: a notificação diz "está pronto", e chegar antes de
        // o resultado estar gravado mandaria o app buscar o que o banco ainda não tem. Um job que
        // voltou para PENDING não passa por aqui em estado terminal, então não gera aviso de
        // falha enquanto ainda há tentativa pela frente.
        if (job.getStatus().isTerminal()) {
            notifier.jobFinished(job);
        }

        return true;
    }

    /**
     * Vale devolver este job à fila?
     *
     * <p>Duas condições, e a primeira é sobre quem espera. Reprocessar um job interativo não
     * conserta a falha mais depressa do que o usuário conseguiria tocando no botão de novo — só
     * adia a notícia por mais um teto de chamada de IA, com a tela girando. Ver
     * {@link AnalysisJobType#isInteractive()}.
     *
     * <p>A segunda é o teto do job de fundo: sem ele o job voltaria para PENDING para sempre e a
     * varredura ficaria presa no mesmo, sem alcançar os seguintes.
     */
    private static boolean retryable(AnalysisJob job) {
        return !job.getType().isInteractive() && job.getAttempts() < MAX_ATTEMPTS;
    }

    private String dispatch(AnalysisJob job) {
        JobHandler handler = handlers.get(job.getType());
        if (handler == null) {
            throw new IllegalStateException(
                    "Nenhum handler registrado para o tipo de job '%s'.".formatted(job.getType()));
        }
        return handler.handle(job);
    }
}
