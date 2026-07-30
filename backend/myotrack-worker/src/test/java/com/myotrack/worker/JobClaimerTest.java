package com.myotrack.worker;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyInt;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import com.myotrack.domain.JobStatus;
import com.myotrack.domain.entity.AnalysisJob;
import com.myotrack.infrastructure.repository.AnalysisJobRepository;
import java.time.OffsetDateTime;
import java.util.Optional;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

/**
 * A reserva de um job da fila.
 *
 * <p>O {@code FOR UPDATE SKIP LOCKED} que impede dois workers de pegarem o mesmo job vive na
 * query nativa do repositório e só se verifica contra um Postgres de verdade. O que se testa aqui
 * é o que o claimer faz <b>em cima</b> da linha reservada — em especial o incremento de
 * {@code attempts}, que é o contador de onde o {@link JobPoller} tira o limite de tentativas. Se
 * ele não subisse, um job que falha por rede voltaria para {@code PENDING} para sempre e o worker
 * ficaria preso nele.
 */
class JobClaimerTest {

    private AnalysisJobRepository jobs;
    private JobClaimer claimer;

    @BeforeEach
    void setUp() {
        jobs = mock(AnalysisJobRepository.class);
        claimer = new JobClaimer(jobs);
        when(jobs.save(any())).thenAnswer(invocation -> invocation.getArgument(0));
    }

    private void queueHolds(AnalysisJob job) {
        when(jobs.lockNextPending(anyInt())).thenReturn(Optional.of(job));
    }

    @Test
    @DisplayName("marca como em processamento e conta a tentativa")
    void marksProcessing() {
        AnalysisJob pending = new AnalysisJob();
        queueHolds(pending);

        OffsetDateTime antes = OffsetDateTime.now();
        AnalysisJob claimed = claimer.claimNext().orElseThrow();

        assertThat(claimed.getStatus()).isEqualTo(JobStatus.PROCESSING);
        // Sair de PENDING é o que tira o job do alcance da próxima reserva.
        assertThat(claimed.getAttempts()).isEqualTo(1);
        assertThat(claimed.getStartedAt()).isNotNull().isAfterOrEqualTo(antes);
        verify(jobs).save(claimed);
    }

    @Test
    @DisplayName("soma sobre as tentativas anteriores, não reinicia")
    void accumulatesAttempts() {
        // Um job que já falhou duas vezes por rede voltou para PENDING com attempts=2. Zerar
        // aqui apagaria o histórico e o teto de três tentativas nunca seria alcançado.
        AnalysisJob retried = new AnalysisJob();
        retried.setAttempts(2);
        queueHolds(retried);

        assertThat(claimer.claimNext().orElseThrow().getAttempts()).isEqualTo(3);
    }

    @Test
    @DisplayName("procura pelo status pendente")
    void looksForPending() {
        when(jobs.lockNextPending(anyInt())).thenReturn(Optional.empty());

        claimer.claimNext();

        // A query é nativa e recebe o inteiro da coluna, não o enum: é o valor de banco que o
        // schema do EF Core gravou.
        verify(jobs).lockNextPending(JobStatus.PENDING.getValue());
    }

    @Test
    @DisplayName("fila vazia não grava nada")
    void emptyQueueWritesNothing() {
        when(jobs.lockNextPending(anyInt())).thenReturn(Optional.empty());

        assertThat(claimer.claimNext()).isEmpty();
        verify(jobs, never()).save(any());
    }
}
