package com.myotrack.infrastructure.vision;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.node.ArrayNode;
import com.fasterxml.jackson.databind.node.ObjectNode;
import java.util.LinkedHashMap;
import java.util.Map;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Qualifier;
import org.springframework.http.MediaType;
import org.springframework.stereotype.Component;
import org.springframework.web.client.RestClient;

/**
 * {@link VisionClient} sobre o serviço FastAPI de visão (`vision/app/main.py` do MyoTrack).
 *
 * <p>O serviço lê o vídeo e grava o overlay <b>direto no MinIO</b>, com as mesmas credenciais do
 * backend. Por isso o que trafega aqui são chaves de objeto, não bytes: um vídeo de série ida e
 * volta pela API seria dezenas de MB de tráfego interno sem propósito.
 *
 * <p>A resposta vem em {@code snake_case} (convenção do Python) e é convertida para o
 * {@code camelCase} que a coluna {@code ResultJson} documenta — a fronteira de nomenclatura fica
 * contida aqui em vez de vazar para o banco e daí para o app.
 */
@Component
public class HttpVisionClient implements VisionClient {

    private static final Logger log = LoggerFactory.getLogger(HttpVisionClient.class);

    private static final ObjectMapper MAPPER = new ObjectMapper();

    private final VisionProperties properties;
    private final RestClient restClient;

    /**
     * Recebe o cliente já montado, e não o builder: os timeouts vêm da
     * {@link VisionConfiguration}. Configurá-los aqui dentro sobrescreveria qualquer fábrica de
     * requisição vinda de fora — inclusive a de teste, que é como isto foi descoberto.
     */
    public HttpVisionClient(
            VisionProperties properties,
            @Qualifier(VisionConfiguration.REST_CLIENT) RestClient restClient) {
        this.properties = properties;
        this.restClient = restClient;
    }

    @Override
    public boolean isConfigured() {
        return properties.isConfigured();
    }

    @Override
    public VisionAnalysis analyze(String mediaKey, String exercise) {
        if (!isConfigured()) {
            return null;
        }

        // A chave do overlay é derivada da do vídeo: fica ao lado do original, some junto na
        // retenção e não exige guardar um segundo identificador em lugar nenhum.
        final String overlayKey = overlayKeyFor(mediaKey);

        final Map<String, Object> body = new LinkedHashMap<>();
        body.put("media_key", mediaKey);
        body.put("exercise", exercise);
        body.put("overlay_key", overlayKey);

        try {
            final String payload = restClient.post()
                    .uri("%s/analyze".formatted(properties.baseUrl()))
                    .contentType(MediaType.APPLICATION_JSON)
                    .body(body)
                    .retrieve()
                    .body(String.class);

            return parse(payload);
        } catch (Exception e) {
            // Inclui o 400 de "exercício não suportado" e "vídeo não encontrado". Devolver null
            // deixa a decisão de reprocessar com o handler, que é quem conhece a fila.
            log.error("Falha na análise de vídeo de {} ({}).", mediaKey, exercise, e);
            return null;
        }
    }

    static String overlayKeyFor(String mediaKey) {
        final int dot = mediaKey.lastIndexOf('.');
        final String base = dot < 0 ? mediaKey : mediaKey.substring(0, dot);
        // Sempre .mp4: é o que o serviço grava, independente do formato que entrou.
        return base + "-overlay.mp4";
    }

    private VisionAnalysis parse(String payload) throws Exception {
        final JsonNode root = MAPPER.readTree(payload);

        // score ausente ou nulo significa "não avaliável", e não zero — zero seria uma nota
        // péssima, que é uma afirmação bem diferente de "não deu para avaliar".
        final JsonNode score = root.path("score");
        final Integer parsedScore = score.isNumber() ? score.asInt() : null;

        return new VisionAnalysis(
                parsedScore,
                root.path("rep_count").asInt(0),
                emptyToNull(root.path("overlay_key").asText(null)),
                MAPPER.writeValueAsString(toCamelCase(root)));
    }

    /** O que fica guardado em {@code ResultJson}, sem os campos que têm coluna própria. */
    private static ObjectNode toCamelCase(JsonNode root) {
        final ObjectNode result = MAPPER.createObjectNode();

        final ArrayNode issues = result.putArray("issues");
        for (final JsonNode issue : root.path("issues")) {
            final ObjectNode mapped = issues.addObject();
            mapped.put("code", issue.path("code").asText(""));
            mapped.put("message", issue.path("message").asText(""));
            final ArrayNode timestamps = mapped.putArray("timestampsSec");
            issue.path("timestamps_sec").forEach(timestamps::add);
        }

        // Os acertos existem para o retorno não ser só uma lista de erros: quem grava a série
        // também precisa saber o que já está bom para não "consertar" o que estava certo.
        final ArrayNode correctPoints = result.putArray("correctPoints");
        for (final JsonNode point : root.path("correct_points")) {
            final ObjectNode mapped = correctPoints.addObject();
            mapped.put("code", point.path("code").asText(""));
            mapped.put("message", point.path("message").asText(""));
        }

        result.set("metrics", root.path("metrics").isObject()
                ? root.path("metrics").deepCopy()
                : MAPPER.createObjectNode());

        final String reason = root.path("not_evaluable_reason").asText(null);
        if (reason != null && !reason.isBlank()) {
            result.put("notEvaluableReason", reason);
        }

        return result;
    }

    private static String emptyToNull(String value) {
        return value == null || value.isBlank() ? null : value;
    }
}
