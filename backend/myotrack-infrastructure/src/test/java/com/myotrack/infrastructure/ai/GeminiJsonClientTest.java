package com.myotrack.infrastructure.ai;

import static org.assertj.core.api.Assertions.assertThat;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.CsvSource;

/** Porte de MyoTrack.Tests/GeminiJsonClientTests.cs. */
class GeminiJsonClientTest {

    private static final ObjectMapper MAPPER = new ObjectMapper();

    @Test
    @DisplayName("sanitizeSchema remove palavras-chave não suportadas e preserva a estrutura")
    void sanitizeSchemaRemovesUnsupportedKeywordsKeepsStructure() throws Exception {
        String schema = """
                {
                  "type": "object",
                  "$schema": "http://json-schema.org/draft-07/schema#",
                  "additionalProperties": false,
                  "properties": {
                    "days": {
                      "type": "array",
                      "items": {
                        "type": "object",
                        "additionalProperties": false,
                        "properties": {
                          "order": { "type": "integer" },
                          "label": { "type": "string" }
                        },
                        "required": ["order", "label"]
                      }
                    }
                  },
                  "required": ["days"]
                }
                """;

        JsonNode sanitized = GeminiJsonClient.sanitizeSchema(MAPPER.readTree(schema));
        String text = sanitized.toString();

        // Estas duas causam 400 no responseSchema do Gemini.
        assertThat(text).doesNotContain("additionalProperties");
        assertThat(text).doesNotContain("$schema");

        // Estrutura preservada, inclusive dentro de items aninhados.
        assertThat(sanitized.path("properties").path("days")
                .path("items").path("properties").path("order").path("type").asText())
                .isEqualTo("integer");
        assertThat(sanitized.path("properties").path("days").path("items").path("required"))
                .hasSize(2);
    }

    @Test
    @DisplayName("sanitizeSchema aceita um Map, que é como os serviços montam o schema")
    void sanitizeSchemaAcceptsMap() {
        JsonNode sanitized = GeminiJsonClient.sanitizeSchema(java.util.Map.of(
                "type", "object",
                "additionalProperties", false,
                "properties", java.util.Map.of("nome", java.util.Map.of("type", "string"))));

        assertThat(sanitized.has("additionalProperties")).isFalse();
        assertThat(sanitized.path("properties").path("nome").path("type").asText()).isEqualTo("string");
    }

    @ParameterizedTest
    @CsvSource(nullValues = "null", value = {
        // explícito vence a autodetecção
        "gemini,    chave-a, chave-g, gemini",
        // explícito, sem depender de caixa
        "Anthropic, null,    chave-g, anthropic",
        // autodetecção pela chave preenchida
        "null,      chave-a, null,    anthropic",
        "null,      null,    chave-g, gemini",
        // ambas preenchidas ⇒ Anthropic tem precedência
        "null,      chave-a, chave-g, anthropic",
        // nenhuma ⇒ padrão (o cliente fica "não configurado" e a geração cai nas regras)
        "null,      null,    null,    anthropic"
    })
    void effectiveProviderSelectsByConfigOrKeys(
            String provider, String anthropicKey, String geminiKey, String expected) {

        LlmProperties properties = new LlmProperties(
                provider, anthropicKey, null, geminiKey, null, null, 0);

        assertThat(properties.effectiveProvider()).isEqualTo(expected);
    }

    @Test
    @DisplayName("Sem chave, o cliente se declara não configurado em vez de falhar")
    void notConfiguredWithoutApiKey() {
        LlmProperties properties = new LlmProperties(null, null, null, null, null, null, 0);
        GeminiJsonClient client = new GeminiJsonClient(
                properties, org.springframework.web.client.RestClient.builder());

        assertThat(client.isConfigured()).isFalse();
        // E a chamada devolve null — é esse contrato que faz o chamador cair no motor de regras.
        assertThat(client.generateJson("sistema", "usuário", java.util.Map.of())).isNull();
    }

    @Test
    @DisplayName("Os defaults dos modelos batem com os do appsettings.json do .NET")
    void defaultsMatchDotNetConfiguration() {
        LlmProperties properties = new LlmProperties(null, null, null, null, null, null, 0);

        assertThat(properties.model()).isEqualTo("claude-opus-4-8");
        assertThat(properties.geminiModel()).isEqualTo("gemini-3.5-flash");
        assertThat(properties.geminiImageModel()).isEqualTo("gemini-3.1-flash-image");
        assertThat(properties.maxTokens()).isEqualTo(8192);
    }
}
