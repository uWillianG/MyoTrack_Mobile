package com.myotrack.infrastructure.ai;

import java.util.Map;

/**
 * Chamada de LLM com structured output (JSON Schema).
 *
 * <p>Devolve {@code null} quando não há chave configurada ou quando a chamada falha — nunca
 * lança. É esse contrato que faz a geração de treino e dieta cair no motor de regras em vez de
 * quebrar quando a IA está indisponível.
 *
 * <p>Porte de MyoTrack.Infrastructure/Ai/ILlmJsonClient.cs.
 */
public interface LlmJsonClient {

    boolean isConfigured();

    /**
     * Quem cobrou pela chamada: {@code "gemini"} ou {@code "openai"}.
     *
     * <p>Vem do cliente, e não de deduzir pelo nome do modelo, porque a dedução erraria em
     * silêncio no dia em que um provedor lançar um nome parecido com o do outro — e o erro
     * apareceria como custo atribuído à conta errada, não como exceção.
     */
    String provider();

    String model();

    LlmJsonResult generateJson(String systemPrompt, String userPrompt, Map<String, Object> jsonSchema);

    LlmJsonResult generateJsonFromImage(
            String systemPrompt,
            String userPrompt,
            byte[] imageBytes,
            String imageMediaType,
            Map<String, Object> jsonSchema);

    /** O JSON devolvido pelo modelo mais o consumo de tokens, que alimenta o AiUsageLog. */
    record LlmJsonResult(String json, long inputTokens, long outputTokens) {
    }
}
