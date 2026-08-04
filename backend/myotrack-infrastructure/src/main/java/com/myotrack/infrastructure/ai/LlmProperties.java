package com.myotrack.infrastructure.ai;

import org.springframework.boot.context.properties.ConfigurationProperties;

/**
 * Configuração do LLM. Seção "Llm" do appsettings.json do .NET.
 *
 * <p>Dois provedores: OpenAI e Gemini. <b>A Anthropic saiu</b> — o {@code AnthropicJsonClient} e a
 * dependência do SDK dela foram removidos junto. A troca foi de fornecedor, não de arquitetura: a
 * interface {@link LlmJsonClient} não mudou, e é justamente por ela existir que a substituição não
 * encostou em nenhum handler.
 */
@ConfigurationProperties(prefix = "myotrack.llm")
public record LlmProperties(
        String provider,
        String openaiApiKey,
        String openaiModel,
        String geminiApiKey,
        String geminiModel,
        String geminiImageModel,
        int maxTokens) {

    public LlmProperties {
        provider = provider == null ? "" : provider.trim().toLowerCase(java.util.Locale.ROOT);

        openaiApiKey = openaiApiKey == null ? "" : openaiApiKey.trim();
        openaiModel = blankToDefault(openaiModel, "gpt-5-mini");

        geminiApiKey = geminiApiKey == null ? "" : geminiApiKey.trim();
        geminiModel = blankToDefault(geminiModel, "gemini-3.5-flash");
        geminiImageModel = blankToDefault(geminiImageModel, "gemini-3.1-flash-image");

        // Nos modelos com raciocínio, os tokens de "thinking" contam dentro deste teto —
        // 4096 truncava respostas antes do texto final.
        maxTokens = maxTokens <= 0 ? 8192 : maxTokens;
    }

    /**
     * "openai" ou "gemini". Vazio ⇒ autodetecção pelo provider cuja chave estiver preenchida.
     *
     * <p>Com as duas chaves configuradas o Gemini tem precedência. Isso ocupa o lugar que era da
     * Anthropic e a razão mudou junto: antes era "o provedor que o app já usava", agora é o lado
     * mais barato por token. Quem quiser o outro diz o nome — é uma variável de ambiente.
     */
    public String effectiveProvider() {
        if (!provider.isBlank()) {
            return provider;
        }
        if (!geminiApiKey.isBlank()) {
            return "gemini";
        }
        if (!openaiApiKey.isBlank()) {
            return "openai";
        }
        return "gemini";
    }

    private static String blankToDefault(String value, String fallback) {
        return value == null || value.isBlank() ? fallback : value;
    }
}
