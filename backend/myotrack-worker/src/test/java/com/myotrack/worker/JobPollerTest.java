package com.myotrack.worker;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatCode;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.times;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import com.myotrack.domain.AnalysisJobType;
import com.myotrack.domain.JobStatus;
import com.myotrack.domain.entity.AnalysisJob;
import com.myotrack.infrastructure.repository.AnalysisJobRepository;
import java.util.List;
import java.util.Optional;
import java.util.UUID;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;
import org.mockito.ArgumentCaptor;

/**
 * O laço que consome a fila.
 *
 * <p>O que se testa aqui é <b>a diferença entre falha de negócio e falha transitória</b>. Cada
 * tentativa de um job de geração é uma chamada de LLM paga: tratar "perfil incompleto" como
 * transitório faria o mesmo erro determinístico ser pago três vezes, e tratar um timeout de rede
 * como definitivo perderia o trabalho do usuário por uma oscilação de alguns segundos. Os dois
 * enganos são invertidos entre si e nenhum aparece em log de erro — o job simplesmente termina no
 * estado errado.
 */
class JobPollerTest {

    /** Igual ao {@code MAX_ATTEMPTS} do poller: a partir daqui a falha transitória vira definitiva. */
    private static final int MAX_ATTEMPTS = 3;

    /** Igual ao {@code MAX_JOBS_PER_SWEEP} do poller. */
    private static final int MAX_JOBS_PER_SWEEP = 20;

    private AnalysisJobRepository jobs;
    private JobClaimer claimer;
    private JobHandler handler;

    @BeforeEach
    void setUp() {
        jobs = mock(AnalysisJobRepository.class);
        claimer = mock(JobClaimer.class);
        handler = handlerFor(AnalysisJobType.WORKOUT_GENERATION);
    }

    private static JobHandler handlerFor(AnalysisJobType type) {
        JobHandler stub = mock(JobHandler.class);
        when(stub.type()).thenReturn(type);
        return stub;
    }

    private JobPoller pollerWith(JobHandler... handlers) {
        return new JobPoller(jobs, claimer, List.of(handlers));
    }

    /**
     * Um job como o poller o recebe: já reservado pelo {@link JobClaimer}, portanto com
     * {@code attempts} contando esta tentativa.
     */
    private static AnalysisJob claimedJob(AnalysisJobType type, int attempts) {
        AnalysisJob job = new AnalysisJob();
        job.setId(UUID.randomUUID());
        job.setUserId(UUID.randomUUID());
        job.setType(type);
        job.setStatus(JobStatus.PROCESSING);
        job.setAttempts(attempts);
        return job;
    }

    /** Entrega o job uma vez e depois esvazia a fila, para o sweep terminar. */
    private void queueHolds(AnalysisJob job) {
        // Encadeado em vez de thenReturn(a, b): a forma varargs monta um array de Optional
        // genérico e o compilador avisa de unchecked.
        when(claimer.claimNext()).thenReturn(Optional.of(job)).thenReturn(Optional.empty());
    }

    private AnalysisJob saved() {
        ArgumentCaptor<AnalysisJob> captor = ArgumentCaptor.forClass(AnalysisJob.class);
        verify(jobs).save(captor.capture());
        return captor.getValue();
    }

    @Nested
    @DisplayName("quando o handler conclui")
    class Sucesso {

        @Test
        @DisplayName("guarda o resultado e marca como concluído")
        void completes() {
            AnalysisJob job = claimedJob(AnalysisJobType.WORKOUT_GENERATION, 1);
            queueHolds(job);
            when(handler.handle(job)).thenReturn("{\"workoutPlanId\":\"abc\"}");

            pollerWith(handler).sweep();

            AnalysisJob result = saved();
            assertThat(result.getStatus()).isEqualTo(JobStatus.COMPLETED);
            // É o que o app lê ao final do SSE/polling.
            assertThat(result.getResultJson()).isEqualTo("{\"workoutPlanId\":\"abc\"}");
            assertThat(result.getCompletedAt()).isNotNull();
            assertThat(result.getLastError()).isNull();
        }
    }

    @Nested
    @DisplayName("quando o handler falha por regra de negócio")
    class FalhaDeNegocio {

        @Test
        @DisplayName("marca como falho sem reprocessar, ainda na primeira tentativa")
        void failsImmediately() {
            // IllegalStateException é o contrato do JobHandler para "perfil incompleto",
            // "catálogo insuficiente" e afins. Reprocessar não muda o resultado: os dados de
            // entrada são os mesmos, e cada tentativa custa uma chamada de LLM.
            AnalysisJob job = claimedJob(AnalysisJobType.WORKOUT_GENERATION, 1);
            queueHolds(job);
            when(handler.handle(job))
                    .thenThrow(new IllegalStateException("Perfil incompleto: falta peso."));

            pollerWith(handler).sweep();

            AnalysisJob result = saved();
            assertThat(result.getStatus()).isEqualTo(JobStatus.FAILED);
            assertThat(result.getLastError()).isEqualTo("Perfil incompleto: falta peso.");
        }

        @Test
        @DisplayName("tipo sem handler registrado também não volta para a fila")
        void unknownTypeDoesNotRetry() {
            // O dispatch lança IllegalStateException quando não acha handler. Cair no ramo
            // transitório aqui faria o job girar três vezes por uma configuração que nenhuma
            // tentativa consertaria.
            AnalysisJob job = claimedJob(AnalysisJobType.COACH_CHAT, 1);
            queueHolds(job);

            pollerWith(handler).sweep();

            assertThat(saved().getStatus()).isEqualTo(JobStatus.FAILED);
            verify(handler, never()).handle(any());
        }
    }

    @Nested
    @DisplayName("quando o handler falha por erro transitório")
    class FalhaTransitoria {

        @Test
        @DisplayName("devolve à fila enquanto há tentativa sobrando")
        void returnsToQueue() {
            AnalysisJob job = claimedJob(AnalysisJobType.WORKOUT_GENERATION, MAX_ATTEMPTS - 1);
            queueHolds(job);
            when(handler.handle(job)).thenThrow(new RuntimeException("Connection reset"));

            pollerWith(handler).sweep();

            AnalysisJob result = saved();
            assertThat(result.getStatus()).isEqualTo(JobStatus.PENDING);
            // O erro fica registrado mesmo no caminho de retry: é o que explica a demora
            // quando o job acaba concluindo na terceira tentativa.
            assertThat(result.getLastError()).isEqualTo("Connection reset");
        }

        @Test
        @DisplayName("desiste ao esgotar as tentativas")
        void givesUpAtMaxAttempts() {
            // Sem este teto o job voltaria para PENDING indefinidamente e a fila nunca
            // esvaziaria — o worker ficaria preso no mesmo job, sem processar os seguintes.
            AnalysisJob job = claimedJob(AnalysisJobType.WORKOUT_GENERATION, MAX_ATTEMPTS);
            queueHolds(job);
            when(handler.handle(job)).thenThrow(new RuntimeException("Connection reset"));

            pollerWith(handler).sweep();

            assertThat(saved().getStatus()).isEqualTo(JobStatus.FAILED);
        }
    }

    @Nested
    @DisplayName("o registro de handlers")
    class Registro {

        @Test
        @DisplayName("encaminha cada job ao handler do seu tipo")
        void dispatchesByType() {
            JobHandler diet = handlerFor(AnalysisJobType.DIET_GENERATION);
            AnalysisJob job = claimedJob(AnalysisJobType.DIET_GENERATION, 1);
            queueHolds(job);
            when(diet.handle(job)).thenReturn("{}");

            pollerWith(handler, diet).sweep();

            verify(diet).handle(job);
            verify(handler, never()).handle(any());
        }

        @Test
        @DisplayName("recusa dois handlers para o mesmo tipo, na subida")
        void refusesDuplicates() {
            // Sem esta guarda um dos dois venceria por ordem de injeção, que não é estável.
            // Falhar no startup é o único momento em que alguém vê o problema.
            JobHandler outro = handlerFor(AnalysisJobType.WORKOUT_GENERATION);

            assertThatThrownBy(() -> pollerWith(handler, outro))
                    .isInstanceOf(IllegalStateException.class)
                    .hasMessageContaining(AnalysisJobType.WORKOUT_GENERATION.toString());
        }
    }

    @Nested
    @DisplayName("a varredura")
    class Varredura {

        @Test
        @DisplayName("para quando a fila esvazia")
        void stopsOnEmptyQueue() {
            when(claimer.claimNext()).thenReturn(Optional.empty());

            pollerWith(handler).sweep();

            verify(jobs, never()).save(any());
        }

        @Test
        @DisplayName("devolve o controle ao scheduler mesmo com a fila cheia")
        void yieldsAfterCap() {
            // A fila nunca esvazia neste teste. Sem o teto, sweep() não retornaria e o
            // @Scheduled(fixedDelay) nunca reagendaria — nem a retenção de mídia nem o
            // agendador semanal, que dividem o mesmo pool de threads, voltariam a rodar.
            when(claimer.claimNext())
                    .thenAnswer(invocation ->
                            Optional.of(claimedJob(AnalysisJobType.WORKOUT_GENERATION, 1)));
            when(handler.handle(any())).thenReturn("{}");

            pollerWith(handler).sweep();

            verify(handler, times(MAX_JOBS_PER_SWEEP)).handle(any());
        }

        @Test
        @DisplayName("uma falha ao reservar aborta a varredura sem propagar")
        void survivesClaimFailure() {
            // Banco fora do ar, por exemplo. Propagar mataria a execução agendada; insistir no
            // laço faria 20 tentativas contra um banco que já está em apuros.
            when(claimer.claimNext()).thenThrow(new RuntimeException("connection refused"));

            JobPoller poller = pollerWith(handler);

            assertThatCode(poller::sweep).doesNotThrowAnyException();
            verify(claimer, times(1)).claimNext();
        }
    }
}
