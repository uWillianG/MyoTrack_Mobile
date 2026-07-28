package com.myotrack.infrastructure.ai;

import org.springframework.boot.context.properties.ConfigurationProperties;

/** Seção "Llm" do appsettings.json do Worker. */
@ConfigurationProperties(prefix = "myotrack.llm")
public record LlmProperties(
        String provider,
        String anthropicApiKey,
        String model,
        String geminiApiKey,
        String geminiModel,
        String geminiImageModel,
        int maxTokens) {

    public LlmProperties {
        provider = provider == null ? "" : provider.trim().toLowerCase(java.util.Locale.ROOT);
        anthropicApiKey = anthropicApiKey == null ? "" : anthropicApiKey.trim();
        model = blankToDefault(model, "claude-opus-4-8");
        geminiApiKey = geminiApiKey == null ? "" : geminiApiKey.trim();
        geminiModel = blankToDefault(geminiModel, "gemini-3.5-flash");
        geminiImageModel = blankToDefault(geminiImageModel, "gemini-3.1-flash-image");
        // Nos modelos com raciocínio, os tokens de "thinking" contam dentro deste teto —
        // 4096 truncava respostas antes do texto final.
        maxTokens = maxTokens <= 0 ? 8192 : maxTokens;
    }

    /**
     * "anthropic" ou "gemini". Vazio ⇒ autodetecção: usa o provider cuja chave de API estiver
     * preenchida (Anthropic tem precedência se ambas).
     */
    public String effectiveProvider() {
        if (!provider.isBlank()) {
            return provider;
        }
        if (!anthropicApiKey.isBlank()) {
            return "anthropic";
        }
        if (!geminiApiKey.isBlank()) {
            return "gemini";
        }
        return "anthropic";
    }

    private static String blankToDefault(String value, String fallback) {
        return value == null || value.isBlank() ? fallback : value;
    }
}
