package com.myotrack.worker;

import com.myotrack.domain.AnalysisJobType;
import com.myotrack.domain.entity.AnalysisJob;

/**
 * Processa um tipo de job da fila. Cada handler é um {@code @Component}; o {@link JobPoller}
 * monta o registro a partir de todos eles no startup — porte do {@code switch} do
 * {@code JobPollerService.HandleAsync}, com o acoplamento invertido para que cada funcionalidade
 * traga o seu handler junto.
 */
public interface JobHandler {

    AnalysisJobType type();

    /**
     * Executa o job e devolve o JSON que vai para {@code AnalysisJob.ResultJson} — é o que o
     * cliente lê ao final do SSE/polling (ex.: {@code {"workoutPlanId":"..."}}).
     *
     * <p>Lançar {@link IllegalStateException} sinaliza erro de negócio (perfil incompleto, catálogo
     * insuficiente); qualquer outra exceção conta como transitória. A distinção decide o
     * reprocessamento <b>do job de fundo</b> — o interativo falha na primeira, porque quem o
     * repetiria é a pessoa que está olhando a tela. Ver {@link AnalysisJobType#isInteractive()}.
     *
     * <p>Consequência para a mensagem: ela é o que o usuário lê, e num job interativo não pode
     * prometer uma segunda tentativa que ninguém vai fazer.
     */
    String handle(AnalysisJob job);
}
