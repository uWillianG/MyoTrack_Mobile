package com.myotrack.worker;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;

import com.myotrack.domain.AnalysisJobType;
import com.myotrack.domain.JobStatus;
import com.myotrack.domain.entity.AnalysisJob;
import com.myotrack.infrastructure.push.PushMessage;
import com.myotrack.infrastructure.push.UserPushNotifier;
import java.util.UUID;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.CsvSource;
import org.junit.jupiter.params.provider.EnumSource;
import org.mockito.ArgumentCaptor;

/**
 * Quais jobs geram notificação, e o que ela diz.
 *
 * <p>Duas coisas se protegem aqui. A primeira é o <b>silêncio de quem está olhando</b>: o app
 * acompanha o job aberto por SSE, então avisar de uma análise de foto que a pessoa está esperando
 * na tela rende dois avisos do mesmo fato. A segunda é a <b>rota</b> — uma notificação que abre a
 * tela inicial obriga a procurar o que ficou pronto, e aí não valia a pena avisar.
 */
class JobCompletionNotifierTest {

    private static final UUID USER_ID = UUID.fromString("11111111-1111-1111-1111-111111111111");

    private UserPushNotifier push;
    private JobCompletionNotifier notifier;

    @BeforeEach
    void setUp() {
        push = mock(UserPushNotifier.class);
        notifier = new JobCompletionNotifier(push);
    }

    private static AnalysisJob job(AnalysisJobType type, JobStatus status) {
        AnalysisJob job = new AnalysisJob();
        job.setId(UUID.randomUUID());
        job.setUserId(USER_ID);
        job.setType(type);
        job.setStatus(status);
        return job;
    }

    private PushMessage sentMessage() {
        ArgumentCaptor<PushMessage> captor = ArgumentCaptor.forClass(PushMessage.class);
        verify(push).notifyUser(eq(USER_ID), captor.capture());
        return captor.getValue();
    }

    @Nested
    @DisplayName("quem não recebe aviso")
    class Silencio {

        @Test
        @DisplayName("análise de foto de refeição")
        void mealPhotoStaysQuiet() {
            // Leva segundos e a pessoa está na tela da câmera esperando o resultado.
            notifier.jobFinished(job(AnalysisJobType.MEAL_PHOTO, JobStatus.COMPLETED));

            verify(push, never()).notifyUser(any(), any());
        }

        @Test
        @DisplayName("resposta do coach")
        void coachChatStaysQuiet() {
            // É uma conversa: a resposta aparece na própria thread, onde a pessoa está.
            notifier.jobFinished(job(AnalysisJobType.COACH_CHAT, JobStatus.COMPLETED));

            verify(push, never()).notifyUser(any(), any());
        }

        @Test
        @DisplayName("relatório semanal que falhou")
        void failedWeeklyReportStaysQuiet() {
            // Ninguém pediu este relatório — o agendador o criou. Não há espera para encerrar, e
            // o agendador tenta de novo; anunciar a falha seria dar notícia ruim sobre algo que a
            // pessoa não sabia que estava acontecendo.
            notifier.jobFinished(job(AnalysisJobType.WEEKLY_REPORT, JobStatus.FAILED));

            verify(push, never()).notifyUser(any(), any());
        }

        @Test
        @DisplayName("job sem tipo ou sem status não quebra o worker")
        void toleratesIncompleteJob() {
            // Defensivo de propósito: o notificador roda no fim do processamento, e uma
            // NullPointerException aqui viraria "erro no laço de polling" a cada varredura.
            notifier.jobFinished(new AnalysisJob());

            verify(push, never()).notifyUser(any(), any());
        }
    }

    @Nested
    @DisplayName("o relatório semanal pronto")
    class RelatorioSemanal {

        @Test
        @DisplayName("avisa e aponta para a tela inicial")
        void notifiesToHome() {
            notifier.jobFinished(job(AnalysisJobType.WEEKLY_REPORT, JobStatus.COMPLETED));

            PushMessage message = sentMessage();
            assertThat(message.title()).contains("relatório da semana");
            // A tela inicial é onde o card do relatório aparece.
            assertThat(message.route()).isEqualTo("/");
        }
    }

    @Nested
    @DisplayName("as gerações e a análise de vídeo")
    class Pedidos {

        /** Cada rota tem de existir no roteador do app; ver {@code app/lib/core/router.dart}. */
        @ParameterizedTest(name = "{0} pronto aponta para {1}")
        @CsvSource({
            "EXERCISE_VIDEO,     /videos",
            "WORKOUT_GENERATION, /treino",
            "DIET_GENERATION,    /dieta",
        })
        @DisplayName("avisam com a rota da tela do resultado")
        void notifiesWithRoute(AnalysisJobType type, String rotaEsperada) {
            notifier.jobFinished(job(type, JobStatus.COMPLETED));

            assertThat(sentMessage().route()).isEqualTo(rotaEsperada);
        }

        @ParameterizedTest(name = "{0}")
        @EnumSource(
                value = AnalysisJobType.class,
                names = {"EXERCISE_VIDEO", "WORKOUT_GENERATION", "DIET_GENERATION"})
        @DisplayName("avisam também quando falham de vez")
        void notifiesOnFailure(AnalysisJobType type) {
            // Estes três a pessoa pediu e esperou — o de vídeo por minutos. Sem aviso de falha ela
            // volta ao app mais tarde para descobrir que não saiu, que é o pior dos dois avisos.
            notifier.jobFinished(job(type, JobStatus.FAILED));

            assertThat(sentMessage().title()).startsWith("Não foi possível");
        }
    }

}
