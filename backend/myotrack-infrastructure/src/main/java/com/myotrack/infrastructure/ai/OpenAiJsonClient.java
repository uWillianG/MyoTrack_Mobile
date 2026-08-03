package com.myotrack.infrastructure.ai;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.node.ArrayNode;
import com.fasterxml.jackson.databind.node.ObjectNode;
import java.time.Duration;
import java.util.ArrayList;
import java.util.Base64;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.MediaType;
import org.springframework.stereotype.Component;
import org.springframework.web.client.RestClient;

/**
 * {@link LlmJsonClient} sobre a API da OpenAI (Chat Completions).
 *
 * <p>REST direto, como o {@link GeminiJsonClient} e pelo mesmo motivo: o corpo é pequeno e
 * estável, e um SDK a mais é uma dependência a mais para manter. Structured output via
 * {@code response_format: json_schema} com {@code strict}, que é a garantia equivalente ao
 * {@code responseSchema} do Gemini.
 */
@Component
public class OpenAiJsonClient implements LlmJsonClient {

    private static final Logger log = LoggerFactory.getLogger(OpenAiJsonClient.class);

    static final String URL = "https://api.openai.com/v1/chat/completions";
    static final Duration TIMEOUT = Duration.ofMinutes(5);

    /** O nome é obrigatório no {@code json_schema} e não influencia a saída. */
    static final String SCHEMA_NAME = "resposta";

    private static final ObjectMapper MAPPER = new ObjectMapper();

    private final LlmProperties properties;
    private final RestClient restClient;

    public OpenAiJsonClient(LlmProperties properties, RestClient.Builder restClientBuilder) {
        this.properties = properties;
        this.restClient = restClientBuilder.build();
    }

    @Override
    public boolean isConfigured() {
        return !properties.openaiApiKey().isBlank();
    }

    @Override
    public String model() {
        return properties.openaiModel();
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
     * Ajusta o schema ao modo estrito da OpenAI, que exige duas coisas de <b>todo</b> objeto:
     * {@code additionalProperties: false}, e {@code required} listando <b>todas</b> as
     * propriedades.
     *
     * <p>É o espelho do {@code sanitizeSchema} do Gemini — lá se remove o que o provedor não
     * aceita, aqui se acrescenta o que ele exige. Os schemas deste app já listam tudo em
     * {@code required}, então na prática só o {@code additionalProperties} entra; a linha do
     * {@code required} existe para o dia em que alguém escrever um schema com campo opcional.
     *
     * <p><b>Cuidado ao adicionar campo opcional:</b> o modo estrito não tem "opcional". Um campo
     * que pode faltar precisa virar anulável no próprio tipo ({@code "type": ["string","null"]});
     * deixá-lo fora do {@code required} não é uma opção que a API aceite, e esta função vai
     * obrigá-lo de qualquer forma.
     */
    public static JsonNode strictSchema(JsonNode schema) {
        if (schema == null || !schema.isObject()) {
            return schema;
        }

        ObjectNode result = MAPPER.createObjectNode();
        schema.fields().forEachRemaining(entry -> {
            String name = entry.getKey();
            JsonNode value = entry.getValue();
            switch (name) {
                case "items" -> result.set(name, strictSchema(value));
                case "properties" -> {
                    ObjectNode properties = MAPPER.createObjectNode();
                    value.fields().forEachRemaining(
                            p -> properties.set(p.getKey(), strictSchema(p.getValue())));
                    result.set(name, properties);
                }
                // Recalculado abaixo a partir de "properties": o que vier no schema de origem
                // seria sobrescrito de qualquer jeito, e copiá-lo antes só duplicaria trabalho.
                case "required" -> { }
                default -> result.set(name, value.deepCopy());
            }
        });

        if (result.has("properties")) {
            ArrayNode required = MAPPER.createArrayNode();
            result.get("properties").fieldNames().forEachRemaining(required::add);
            result.set("required", required);
            result.put("additionalProperties", false);
        }

        return result;
    }

    public static JsonNode strictSchema(Map<String, Object> schema) {
        // A variável tipada é necessária: valueToTree() é genérico em <T extends JsonNode> e,
        // sem ela, o compilador não consegue escolher entre as duas sobrecargas.
        JsonNode tree = MAPPER.valueToTree(schema);
        return strictSchema(tree);
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
            List<Object> content = new ArrayList<>();
            // A imagem vem antes do texto, como no cliente anterior e no backend .NET.
            if (imageBytes != null) {
                content.add(Map.of(
                        "type", "image_url",
                        "image_url", Map.of("url", "data:%s;base64,%s".formatted(
                                imageMediaType, Base64.getEncoder().encodeToString(imageBytes)))));
            }
            content.add(Map.of("type", "text", "text", userPrompt));

            Map<String, Object> responseFormat = Map.of(
                    "type", "json_schema",
                    "json_schema", Map.of(
                            "name", SCHEMA_NAME,
                            "strict", true,
                            "schema", strictSchema(jsonSchema)));

            Map<String, Object> body = new LinkedHashMap<>();
            body.put("model", properties.openaiModel());
            body.put("max_completion_tokens", properties.maxTokens());
            body.put("response_format", responseFormat);
            body.put("messages", List.of(
                    Map.of("role", "system", "content", systemPrompt),
                    Map.of("role", "user", "content", content)));

            String payload = restClient.post()
                    .uri(URL)
                    .header("Authorization", "Bearer " + properties.openaiApiKey())
                    .contentType(MediaType.APPLICATION_JSON)
                    .body(body)
                    .retrieve()
                    .body(String.class);

            return parseResponse(payload);
        } catch (Exception e) {
            // Falha de LLM nunca derruba a geração — o chamador cai no motor de regras.
            log.error("Falha na chamada à OpenAI.", e);
            return null;
        }
    }

    private LlmJsonResult parseResponse(String payload) throws Exception {
        JsonNode root = MAPPER.readTree(payload);

        JsonNode choices = root.path("choices");
        if (!choices.isArray() || choices.isEmpty()) {
            log.warn("Resposta da OpenAI sem choices.");
            return null;
        }

        JsonNode choice = choices.get(0);
        String finishReason = choice.path("finish_reason").asText(null);

        // Uma recusa vem em campo próprio, e não como texto: tratá-la como conteúdo faria o
        // parser do chamador falhar com um JSON que nunca existiu.
        JsonNode refusal = choice.path("message").path("refusal");
        if (refusal.isTextual() && !refusal.asText().isBlank()) {
            log.warn("OpenAI recusou a requisição: {}", refusal.asText());
            return null;
        }

        String text = choice.path("message").path("content").asText(null);
        if (text == null || text.isBlank()) {
            // "length" aqui é o teto de max_completion_tokens: nos modelos com raciocínio os
            // tokens de thinking podem consumi-lo antes de sobrar texto.
            log.warn("Resposta da OpenAI sem texto (finish_reason={}).", finishReason);
            return null;
        }

        JsonNode usage = root.path("usage");
        return new LlmJsonResult(
                text,
                usage.path("prompt_tokens").asLong(0),
                usage.path("completion_tokens").asLong(0));
    }
}
