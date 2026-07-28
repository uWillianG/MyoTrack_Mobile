package com.myotrack.infrastructure.vision;

/**
 * Análise de execução de exercício por vídeo, feita pelo serviço de visão (MediaPipe Pose).
 *
 * <p>É interface porque o serviço vive fora deste repositório: o contrato HTTP dele entra numa
 * implementação só, sem espalhar detalhes de transporte pelo worker. Segue o mesmo padrão do
 * {@link com.myotrack.infrastructure.ai.LlmJsonClient} — {@code isConfigured()} decide se a
 * funcionalidade existe neste ambiente, e a chamada devolve {@code null} em vez de lançar.
 */
public interface VisionClient {

    /** Há serviço de visão configurado neste ambiente? */
    boolean isConfigured();

    /**
     * Analisa o vídeo já guardado no storage.
     *
     * @param mediaKey chave do objeto enviado pelo cliente
     * @param exercise slug do exercício a avaliar (squat, deadlift, overhead_press…)
     * @return o resultado, ou {@code null} quando a chamada falha — cabe ao chamador decidir se
     *     vale reprocessar
     */
    VisionAnalysis analyze(String mediaKey, String exercise);

    /**
     * O que o serviço devolve.
     *
     * @param score 0–100, ou null quando a pose não pôde ser avaliada com confiança
     * @param repCount repetições contadas
     * @param overlayVideoKey chave do vídeo com o esqueleto desenhado, quando gerado
     * @param resultJson {@code {issues: [{code, message, timestampsSec[]}], metrics: {...},
     *     notEvaluableReason?}} — fica como JSON para as heurísticas evoluírem sem migração
     */
    record VisionAnalysis(
            Integer score, int repCount, String overlayVideoKey, String resultJson) {
    }
}
