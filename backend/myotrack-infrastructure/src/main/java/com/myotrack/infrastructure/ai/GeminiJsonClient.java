package com.myotrack.infrastructure.ai;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.node.ObjectNode;
import java.time.Duration;
import java.util.ArrayList;
import java.util.Base64;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Set;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.MediaType;
import org.springframework.stereotype.Component;
import org.springframework.web.client.RestClient;

/**
 * {@link LlmJsonClient} sobre a API do Google Gemini (Generative Language API, chave do AI
 * Studio). Usa REST direto — o corpo é pequeno e estável, e evita depender do SDK do Google.
 * Structured output via {@code responseSchema}.
 *
 * <p>Porte de MyoTrack.Infrastructure/Ai/GeminiJsonClient.cs.
 */
@Component
public class GeminiJsonClient implements LlmJsonClient {

    private static final Logger log = LoggerFactory.getLogger(GeminiJsonClient.class);

    static final String BASE_URL = "https://generativelanguage.googleapis.com/v1beta/models";
    static final String API_KEY_HEADER = "x-goog-api-key";
    static final Duration TIMEOUT = Duration.ofMinutes(5);

    /**
     * O {@code responseSchema} do Gemini é um subconjunto do OpenAPI 3.0: palavras-chave como
     * {@code additionalProperties} e {@code $schema} causam 400.
     */
    private static final Set<String> ALLOWED_SCHEMA_KEYS = Set.of(
            "type", "format", "description", "nullable", "enum", "items",
            "properties", "required", "minimum", "maximum", "minItems", "maxItems");

    private static final ObjectMapper MAPPER = new ObjectMapper();

    private final LlmProperties properties;
    private final RestClient restClient;

    public GeminiJsonClient(LlmProperties properties, RestClient.Builder restClientBuilder) {
        this.properties = properties;
        this.restClient = restClientBuilder.build();
    }

    @Override
    public boolean isConfigured() {
        return !properties.geminiApiKey().isBlank();
    }

    @Override
    public String model() {
        return properties.geminiModel();
    }

    @Override
    public LlmJsonResult generateJson(
            String systemPrompt, String userPrompt, Map<String, Object> jsonSchema) {
        return create(systemPrompt, userPrompt, jsonSchema, null, null);
    }

    @Override
    public LlmJsonResult generateJsonFromImage(
            String systemPrompt,
            String userPrompt,
            byte[] imageBytes,
            String imageMediaType,
            Map<String, Object> jsonSchema) {
        return create(systemPrompt, userPrompt, jsonSchema, imageBytes, imageMediaType);
    }

    /**
     * Remove o que o Gemini não suporta, preservando a estrutura — a validação forte continua
     * no backend.
     */
    public static JsonNode sanitizeSchema(JsonNode schema) {
        if (schema == null || !schema.isObject()) {
            return schema;
        }

        ObjectNode result = MAPPER.createObjectNode();
        schema.fields().forEachRemaining(entry -> {
            String name = entry.getKey();
            if (!ALLOWED_SCHEMA_KEYS.contains(name)) {
                return;
            }
            switch (name) {
                case "items" -> result.set(name, sanitizeSchema(entry.getValue()));
                case "properties" -> {
                    ObjectNode properties = MAPPER.createObjectNode();
                    entry.getValue().fields().forEachRemaining(
                            p -> properties.set(p.getKey(), sanitizeSchema(p.getValue())));
                    result.set(name, properties);
                }
                default -> result.set(name, entry.getValue().deepCopy());
            }
        });
        return result;
    }

    public static JsonNode sanitizeSchema(Map<String, Object> schema) {
        // A variável tipada é necessária: valueToTree() é genérico em <T extends JsonNode> e,
        // sem ela, o compilador não consegue escolher entre as duas sobrecargas.
        JsonNode tree = MAPPER.valueToTree(schema);
        return sanitizeSchema(tree);
    }

    private LlmJsonResult create(
            String systemPrompt,
            String userPrompt,
            Map<String, Object> jsonSchema,
            byte[] imageBytes,
            String imageMediaType) {

        if (!isConfigured()) {
            return null;
        }

        try {
            List<Object> parts = new ArrayList<>();
            if (imageBytes != null) {
                parts.add(Map.of("inline_data", Map.of(
                        "mime_type", imageMediaType,
                        "data", Base64.getEncoder().encodeToString(imageBytes))));
            }
            parts.add(Map.of("text", userPrompt));

            Map<String, Object> generationConfig = new LinkedHashMap<>();
            generationConfig.put("maxOutputTokens", properties.maxTokens());
            generationConfig.put("responseMimeType", "application/json");
            generationConfig.put("responseSchema", sanitizeSchema(jsonSchema));

            Map<String, Object> body = Map.of(
                    "system_instruction", Map.of("parts", List.of(Map.of("text", systemPrompt))),
                    "contents", List.of(Map.of("role", "user", "parts", parts)),
                    "generationConfig", generationConfig);

            String payload = restClient.post()
                    .uri("%s/%s:generateContent".formatted(BASE_URL, properties.geminiModel()))
                    .header(API_KEY_HEADER, properties.geminiApiKey())
                    .contentType(MediaType.APPLICATION_JSON)
                    .body(body)
                    .retrieve()
                    .body(String.class);

            return parseResponse(payload);
        } catch (Exception e) {
            // Falha de LLM nunca derruba a geração — o chamador cai no motor de regras.
            log.error("Falha na chamada ao Gemini.", e);
            return null;
        }
    }

    private LlmJsonResult parseResponse(String payload) throws Exception {
        JsonNode root = MAPPER.readTree(payload);

        String text = null;
        String finishReason = null;

        JsonNode candidates = root.path("candidates");
        if (candidates.isArray() && !candidates.isEmpty()) {
            JsonNode candidate = candidates.get(0);
            finishReason = candidate.path("finishReason").asText(null);
            // MAX_TOKENS pode devolver candidate sem content/parts (os tokens de raciocínio do
            // modelo consomem o maxOutputTokens antes do texto).
            for (JsonNode part : candidate.path("content").path("parts")) {
                if (part.hasNonNull("text")) {
                    text = part.get("text").asText();
                    break;
                }
            }
        }

        if (text == null || text.isBlank()) {
            log.warn("Resposta do Gemini sem texto (finishReason={}).", finishReason);
            return null;
        }

        JsonNode usage = root.path("usageMetadata");
        return new LlmJsonResult(
                text,
                usage.path("promptTokenCount").asLong(0),
                usage.path("candidatesTokenCount").asLong(0));
    }
}
