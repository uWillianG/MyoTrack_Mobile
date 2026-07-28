package com.myotrack.worker;

import com.myotrack.domain.JobStatus;
import com.myotrack.domain.entity.AnalysisJob;
import com.myotrack.infrastructure.repository.AnalysisJobRepository;
import java.time.OffsetDateTime;
import java.util.Optional;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Propagation;
import org.springframework.transaction.annotation.Transactional;

/**
 * Reserva o próximo job da fila numa transação curta e própria.
 *
 * <p>Está num bean separado do {@link JobPoller} de propósito: {@code @Transactional} só vale
 * quando a chamada passa pelo proxy do Spring, e uma chamada interna do poller para si mesmo não
 * passaria — a transação seria silenciosamente ignorada e o {@code FOR UPDATE SKIP LOCKED}
 * perderia o efeito.
 *
 * <p>A transação precisa ser curta porque o lock da linha tem de ser liberado <b>antes</b> do
 * processamento, que pode levar minutos numa análise de vídeo.
 */
@Component
public class JobClaimer {

    private final AnalysisJobRepository jobs;

    public JobClaimer(AnalysisJobRepository jobs) {
        this.jobs = jobs;
    }

    @Transactional(propagation = Propagation.REQUIRES_NEW)
    public Optional<AnalysisJob> claimNext() {
        return jobs.lockNextPending(JobStatus.PENDING.getValue()).map(job -> {
            job.setStatus(JobStatus.PROCESSING);
            job.setStartedAt(OffsetDateTime.now());
            job.setAttempts(job.getAttempts() + 1);
            return jobs.save(job);
        });
    }
}
