package com.myotrack.worker;

import com.myotrack.domain.JobStatus;
import com.myotrack.domain.entity.AnalysisJob;
import com.myotrack.infrastructure.push.PushMessage;
import com.myotrack.infrastructure.push.UserPushNotifier;
import java.util.Optional;
import org.springframework.stereotype.Component;

/**
 * Decide se um job que terminou merece uma notificação, e o que ela diz.
 *
 * <p>A regra é uma só: <b>avisa-se quem não está olhando</b>. O app acompanha o job aberto por
 * SSE e já mostra o resultado na tela; mandar push para quem está com o app na mão rende dois
 * avisos do mesmo fato, um deles inútil. Por isso a lista de tipos aqui é curta e por inclusão —
 * um tipo novo não notifica até alguém decidir que deve.
 *
 * <p>Os excluídos, e por quê:
 *
 * <ul>
 *   <li>{@code MEAL_PHOTO} — a análise leva segundos e a pessoa está na tela de câmera esperando.
 *   <li>{@code COACH_CHAT} — é uma conversa; a resposta aparece na própria thread.
 * </ul>
 */
@Component
public class JobCompletionNotifier {

    private final UserPushNotifier push;

    public JobCompletionNotifier(UserPushNotifier push) {
        this.push = push;
    }

    /**
     * Chamado depois de o job ser gravado no estado terminal.
     *
     * <p>Depois, e não antes: uma notificação de "está pronto" que chegasse antes do commit
     * mandaria o app buscar um resultado que o banco ainda não tem.
     */
    public void jobFinished(AnalysisJob job) {
        messageFor(job).ifPresent(message -> push.notifyUser(job.getUserId(), message));
    }

    private static Optional<PushMessage> messageFor(AnalysisJob job) {
        if (job.getType() == null || job.getStatus() == null) {
            return Optional.empty();
        }

        return switch (job.getType()) {
            case WEEKLY_REPORT -> concluido(job)
                    // O caso mais forte de todos: o relatório nasce de um agendador, sem ninguém
                    // ter pedido nada, e sem aviso a pessoa só o encontra por acaso.
                    ? Optional.of(new PushMessage(
                            "Seu relatório da semana está pronto",
                            "Veja como foi sua semana e o que ajustar na próxima.",
                            "/"))
                    // Falha de relatório não se anuncia: ninguém pediu, então não há espera para
                    // encerrar, e o agendador tenta de novo.
                    : Optional.empty();

            case EXERCISE_VIDEO -> concluido(job)
                    ? Optional.of(new PushMessage(
                            "Análise do seu vídeo está pronta",
                            "Confira a pontuação e os pontos de correção.",
                            "/videos"))
                    // Aqui a falha vale aviso: são minutos de espera por algo que a pessoa pediu,
                    // e sem isto ela volta ao app mais tarde para descobrir que não saiu.
                    : Optional.of(new PushMessage(
                            "Não foi possível analisar seu vídeo",
                            "Toque para tentar de novo.",
                            "/videos"));

            case WORKOUT_GENERATION -> concluido(job)
                    ? Optional.of(new PushMessage(
                            "Seu treino está pronto",
                            "Seu plano foi montado. Bom treino.",
                            "/treino"))
                    : Optional.of(new PushMessage(
                            "Não foi possível montar seu treino",
                            "Toque para ver o que faltou.",
                            "/treino"));

            case DIET_GENERATION -> concluido(job)
                    ? Optional.of(new PushMessage(
                            "Sua dieta está pronta",
                            "Seu plano alimentar foi montado.",
                            "/dieta"))
                    : Optional.of(new PushMessage(
                            "Não foi possível montar sua dieta",
                            "Toque para ver o que faltou.",
                            "/dieta"));

            case MEAL_PHOTO, COACH_CHAT -> Optional.empty();
        };
    }

    private static boolean concluido(AnalysisJob job) {
        return job.getStatus() == JobStatus.COMPLETED;
    }
}
