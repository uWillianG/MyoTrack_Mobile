package com.myotrack.infrastructure.ai;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import java.util.Base64;
import java.util.List;
import java.util.Map;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.MediaType;
import org.springframework.stereotype.Component;
import org.springframework.web.client.RestClient;

/**
 * Edição de imagem via Gemini (análise ilustrada): recebe a foto original e uma instrução,
 * devolve a imagem anotada. Falha nunca derruba o chamador — retorna null e a análise segue no
 * modo padrão.
 *
 * <p>Exige chave Gemini com billing habilitado: o tier gratuito tem cota zero para modelos de
 * imagem, e é justamente por isso que o retorno null precisa ser um caminho normal e não um erro.
 *
 * <p>Porte de MyoTrack.Infrastructure/Ai/GeminiImageClient.cs.
 */
@Component
public class GeminiImageClient {

    private static final Logger log = LoggerFactory.getLogger(GeminiImageClient.class);

    private static final ObjectMapper MAPPER = new ObjectMapper();

    private final LlmProperties properties;
    private final RestClient restClient;

    public GeminiImageClient(LlmProperties properties, RestClient.Builder restClientBuilder) {
        this.properties = properties;
        this.restClient = restClientBuilder.build();
    }

    public boolean isConfigured() {
        return !properties.geminiApiKey().isBlank();
    }

    /** Sempre Gemini: não existe caminho de imagem pela OpenAI neste app. */
    public String provider() {
        return "gemini";
    }

    public String model() {
        return properties.geminiImageModel();
    }

    /** A imagem anotada, ou null quando indisponível — nunca lança. */
    public GeneratedImage editImage(byte[] imageBytes, String imageMediaType, String instruction) {
        if (!isConfigured()) {
            return null;
        }

        try {
            Map<String, Object> body = Map.of(
                    "contents", List.of(Map.of(
                            "role", "user",
                            "parts", List.of(
                                    Map.of("inline_data", Map.of(
                                            "mime_type", imageMediaType,
                                            "data", Base64.getEncoder().encodeToString(imageBytes))),
                                    Map.of("text", instruction)))),
                    "generationConfig", Map.of("responseModalities", List.of("TEXT", "IMAGE")));

            String payload = restClient.post()
                    .uri("%s/%s:generateContent".formatted(
                            GeminiJsonClient.BASE_URL, properties.geminiImageModel()))
                    .header(GeminiJsonClient.API_KEY_HEADER, properties.geminiApiKey())
                    .contentType(MediaType.APPLICATION_JSON)
                    .body(body)
                    .retrieve()
                    .body(String.class);

            return parseResponse(payload);
        } catch (Exception e) {
            log.warn("Falha na geração da imagem ilustrada: {}", e.getMessage());
            return null;
        }
    }

    private GeneratedImage parseResponse(String payload) throws Exception {
        JsonNode root = MAPPER.readTree(payload);
        JsonNode candidates = root.path("candidates");

        if (!candidates.isArray() || candidates.isEmpty()) {
            log.warn("Resposta do Gemini (imagem) sem candidates/parts.");
            return null;
        }

        JsonNode usage = root.path("usageMetadata");
        long inputTokens = usage.path("promptTokenCount").asLong(0);
        long outputTokens = usage.path("candidatesTokenCount").asLong(0);

        for (JsonNode part : candidates.get(0).path("content").path("parts")) {
            JsonNode inline = part.path("inlineData");
            String data = inline.path("data").asText(null);
            if (data == null || data.isEmpty()) {
                continue;
            }
            String mediaType = inline.path("mimeType").asText("image/png");
            return new GeneratedImage(
                    Base64.getDecoder().decode(data), mediaType, inputTokens, outputTokens);
        }

        log.warn("Resposta do Gemini (imagem) sem bloco de imagem.");
        return null;
    }

    public record GeneratedImage(byte[] bytes, String mediaType, long inputTokens, long outputTokens) {
    }
}
