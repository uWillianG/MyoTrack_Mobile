package com.myotrack.infrastructure.ai;

import com.anthropic.client.AnthropicClient;
import com.anthropic.client.okhttp.AnthropicOkHttpClient;
import com.anthropic.core.JsonValue;
import com.anthropic.models.messages.Base64ImageSource;
import com.anthropic.models.messages.ContentBlockParam;
import com.anthropic.models.messages.ImageBlockParam;
import com.anthropic.models.messages.JsonOutputFormat;
import com.anthropic.models.messages.Message;
import com.anthropic.models.messages.MessageCreateParams;
import com.anthropic.models.messages.OutputConfig;
import com.anthropic.models.messages.TextBlockParam;
import java.util.ArrayList;
import java.util.Base64;
import java.util.List;
import java.util.Map;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Component;

/**
 * Cliente do Claude com structured output. Porte de
 * MyoTrack.Infrastructure/Ai/AnthropicJsonClient.cs.
 *
 * <p>O modelo vem da configuração (o mesmo do backend .NET) — este é um porte, não uma migração
 * de modelo: trocar o modelo aqui mudaria o comportamento da IA em produção.
 */
@Component
public class AnthropicJsonClient implements LlmJsonClient {

    private static final Logger log = LoggerFactory.getLogger(AnthropicJsonClient.class);

    private final LlmProperties properties;
    private final AnthropicClient client;

    public AnthropicJsonClient(LlmProperties properties) {
        this.properties = properties;
        this.client = properties.anthropicApiKey().isBlank()
                ? null
                : AnthropicOkHttpClient.builder().apiKey(properties.anthropicApiKey()).build();
    }

    @Override
    public boolean isConfigured() {
        return client != null;
    }

    @Override
    public String model() {
        return properties.model();
    }

    @Override
    public LlmJsonResult generateJson(
            String systemPrompt, String userPrompt, Map<String, Object> jsonSchema) {
        return create(systemPrompt, userPrompt, jsonSchema, null);
    }

    @Override
    public LlmJsonResult generateJsonFromImage(
            String systemPrompt,
            String userPrompt,
            byte[] imageBytes,
            String imageMediaType,
            Map<String, Object> jsonSchema) {

        ImageBlockParam image = ImageBlockParam.builder()
                .source(Base64ImageSource.builder()
                        .data(Base64.getEncoder().encodeToString(imageBytes))
                        .mediaType(Base64ImageSource.MediaType.of(imageMediaType))
                        .build())
                .build();

        return create(systemPrompt, userPrompt, jsonSchema, image);
    }

    private LlmJsonResult create(
            String systemPrompt, String userPrompt, Map<String, Object> jsonSchema, ImageBlockParam image) {

        if (client == null) {
            return null;
        }

        try {
            List<ContentBlockParam> content = new ArrayList<>();
            // A imagem vem antes do texto: é a ordem recomendada e a que o backend .NET usa.
            if (image != null) {
                content.add(ContentBlockParam.ofImage(image));
            }
            content.add(ContentBlockParam.ofText(TextBlockParam.builder().text(userPrompt).build()));

            MessageCreateParams params = MessageCreateParams.builder()
                    .model(properties.model())
                    .maxTokens(properties.maxTokens())
                    .system(systemPrompt)
                    .outputConfig(OutputConfig.builder()
                            .format(JsonOutputFormat.builder()
                                    .schema(JsonValue.from(jsonSchema))
                                    .build())
                            .build())
                    .addUserMessageOfBlockParams(content)
                    .build();

            Message response = client.messages().create(params);

            String json = response.content().stream()
                    .flatMap(block -> block.text().stream())
                    .map(text -> text.text())
                    .findFirst()
                    .orElse(null);

            if (json == null) {
                log.warn("Resposta do LLM sem bloco de texto (stop_reason={}).", response.stopReason());
                return null;
            }

            return new LlmJsonResult(json, response.usage().inputTokens(), response.usage().outputTokens());
        } catch (Exception e) {
            // Falha de LLM nunca derruba a geração — o chamador cai no motor de regras.
            log.error("Falha na chamada ao LLM.", e);
            return null;
        }
    }
}
