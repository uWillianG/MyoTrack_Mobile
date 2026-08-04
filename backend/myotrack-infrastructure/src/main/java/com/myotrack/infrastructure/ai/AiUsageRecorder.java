package com.myotrack.infrastructure.ai;

import com.myotrack.domain.AnalysisJobType;
import com.myotrack.domain.entity.AiUsageLog;
import com.myotrack.infrastructure.ai.LlmJsonClient.LlmJsonResult;
import com.myotrack.infrastructure.repository.AiUsageLogRepository;
import java.util.UUID;
import org.springframework.stereotype.Component;

/**
 * O único lugar que grava consumo de IA.
 *
 * <p>Antes cada handler montava o {@link AiUsageLog} à mão — seis blocos idênticos de sete linhas,
 * em cinco arquivos. Enquanto o registro era "modelo e tokens" isso era repetição inofensiva;
 * quando passou a incluir provedor e custo, virou seis chances de esquecer um campo, e a linha
 * incompleta não falha nem aparece: ela só some do relatório de gasto.
 *
 * <p><b>Não engole falha de gravação, de propósito.</b> A tentação é proteger o job — a análise é
 * o que o usuário pediu, a contabilidade é para nós. Mas os handlers são {@code @Transactional}:
 * um {@code save} que falhe já marcou a transação para rollback, e capturar a exceção aqui só
 * adiaria o estouro para o commit, onde ele chega como {@code UnexpectedRollbackException} sem
 * dizer de onde veio. O trabalho do handler se perderia do mesmo jeito, com um erro pior de ler.
 */
@Component
public class AiUsageRecorder {

    private final AiUsageLogRepository repository;
    private final LlmPricing pricing;

    public AiUsageRecorder(AiUsageLogRepository repository, LlmPricing pricing) {
        this.repository = repository;
        this.pricing = pricing;
    }

    /** Grava o consumo de uma chamada de texto. */
    public void record(
            UUID userId, AnalysisJobType operation, LlmJsonClient client, LlmJsonResult result) {
        record(
                userId,
                operation,
                client.provider(),
                client.model(),
                result.inputTokens(),
                result.outputTokens());
    }

    /**
     * Grava o consumo de uma geração de imagem.
     *
     * <p>Os tokens de saída de uma imagem não são texto — o Gemini cobra a imagem convertendo-a
     * numa quantidade fixa de tokens de saída. A conta é a mesma, desde que o preço registrado
     * seja o do modelo de imagem, que é onde mora a diferença de ordem de grandeza.
     */
    public void recordImage(
            UUID userId,
            AnalysisJobType operation,
            GeminiImageClient client,
            GeminiImageClient.GeneratedImage image) {
        record(
                userId,
                operation,
                client.provider(),
                client.model(),
                image.inputTokens(),
                image.outputTokens());
    }

    private void record(
            UUID userId,
            AnalysisJobType operation,
            String provider,
            String model,
            long inputTokens,
            long outputTokens) {

        final AiUsageLog usage = new AiUsageLog();
        usage.setUserId(userId);
        usage.setOperation(operation);
        usage.setProvider(provider);
        usage.setModel(model);
        usage.setInputTokens(inputTokens);
        usage.setOutputTokens(outputTokens);
        usage.setCostNanoUsd(pricing.costNanoUsd(model, inputTokens, outputTokens));
        repository.save(usage);
    }
}
