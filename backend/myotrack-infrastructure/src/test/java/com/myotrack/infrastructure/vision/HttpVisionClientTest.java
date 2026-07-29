package com.myotrack.infrastructure.vision;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.client.match.MockRestRequestMatchers.jsonPath;
import static org.springframework.test.web.client.match.MockRestRequestMatchers.method;
import static org.springframework.test.web.client.match.MockRestRequestMatchers.requestTo;
import static org.springframework.test.web.client.response.MockRestResponseCreators.withServerError;
import static org.springframework.test.web.client.response.MockRestResponseCreators.withSuccess;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.myotrack.infrastructure.vision.VisionClient.VisionAnalysis;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.http.HttpMethod;
import org.springframework.http.MediaType;
import org.springframework.test.web.client.MockRestServiceServer;
import org.springframework.web.client.RestClient;

class HttpVisionClientTest {

    private static final ObjectMapper MAPPER = new ObjectMapper();

    private static final VisionProperties PROPERTIES =
            new VisionProperties("http://vision:8000", 600);

    /** Resposta real do `POST /analyze` do serviço, em snake_case. */
    private static final String RESPONSE = """
            {
              "score": 76,
              "rep_count": 8,
              "issues": [
                {
                  "code": "insufficient_depth",
                  "message": "Profundidade insuficiente: desça até o quadril passar da linha do joelho.",
                  "timestamps_sec": [3.2, 11.5]
                }
              ],
              "correct_points": [
                {"code": "excessive_trunk_lean", "message": "Tronco firme na descida."}
              ],
              "metrics": {"knee_angle_deg": 92.4, "duration_sec": 24.3, "pose_coverage": 0.91},
              "not_evaluable_reason": null,
              "overlay_key": "videos/u1/v1-overlay.mp4"
            }
            """;

    private record Fixture(HttpVisionClient client, MockRestServiceServer server) {
    }

    private static Fixture fixture() {
        final RestClient.Builder builder = RestClient.builder();
        final MockRestServiceServer server = MockRestServiceServer.bindTo(builder).build();
        return new Fixture(new HttpVisionClient(PROPERTIES, builder.build()), server);
    }

    @Test
    @DisplayName("manda chaves de objeto, não bytes — o serviço lê e grava no mesmo storage")
    void enviaChaves() {
        final Fixture fixture = fixture();
        fixture.server()
                .expect(requestTo("http://vision:8000/analyze"))
                .andExpect(method(HttpMethod.POST))
                .andExpect(jsonPath("$.media_key").value("videos/u1/v1.mp4"))
                .andExpect(jsonPath("$.exercise").value("squat"))
                .andExpect(jsonPath("$.overlay_key").value("videos/u1/v1-overlay.mp4"))
                .andRespond(withSuccess(RESPONSE, MediaType.APPLICATION_JSON));

        final VisionAnalysis result = fixture.client().analyze("videos/u1/v1.mp4", "squat");

        assertThat(result).isNotNull();
        fixture.server().verify();
    }

    @Test
    @DisplayName("score e repetições saem para colunas próprias")
    void camposComColuna() {
        final Fixture fixture = fixture();
        fixture.server().expect(requestTo("http://vision:8000/analyze"))
                .andRespond(withSuccess(RESPONSE, MediaType.APPLICATION_JSON));

        final VisionAnalysis result = fixture.client().analyze("videos/u1/v1.mp4", "squat");

        assertThat(result.score()).isEqualTo(76);
        assertThat(result.repCount()).isEqualTo(8);
        assertThat(result.overlayVideoKey()).isEqualTo("videos/u1/v1-overlay.mp4");
    }

    @Test
    @DisplayName("o resto vira camelCase — a fronteira de nomenclatura para aqui")
    void converteParaCamelCase() throws Exception {
        final Fixture fixture = fixture();
        fixture.server().expect(requestTo("http://vision:8000/analyze"))
                .andRespond(withSuccess(RESPONSE, MediaType.APPLICATION_JSON));

        final VisionAnalysis result = fixture.client().analyze("videos/u1/v1.mp4", "squat");
        final JsonNode stored = MAPPER.readTree(result.resultJson());

        assertThat(stored.path("issues")).hasSize(1);
        assertThat(stored.path("issues").get(0).path("code").asText())
                .isEqualTo("insufficient_depth");
        // timestamps_sec → timestampsSec: é o nome que a coluna ResultJson documenta.
        assertThat(stored.path("issues").get(0).path("timestampsSec")).hasSize(2);
        assertThat(stored.path("issues").get(0).has("timestamps_sec")).isFalse();
        assertThat(stored.path("correctPoints")).hasSize(1);
        assertThat(stored.path("metrics").path("pose_coverage").asDouble()).isEqualTo(0.91);
    }

    @Test
    @DisplayName("não avaliável: score nulo e o motivo preservado")
    void naoAvaliavel() throws Exception {
        // Zero seria uma nota péssima; nulo diz que não deu para avaliar. A diferença importa
        // porque o usuário mudaria como levanta peso por causa dela.
        final Fixture fixture = fixture();
        fixture.server().expect(requestTo("http://vision:8000/analyze"))
                .andRespond(withSuccess("""
                        {
                          "score": null,
                          "rep_count": 0,
                          "issues": [],
                          "correct_points": [],
                          "metrics": {"pose_coverage": 0.21},
                          "not_evaluable_reason": "Pose detectada em poucos frames.",
                          "overlay_key": null
                        }
                        """, MediaType.APPLICATION_JSON));

        final VisionAnalysis result = fixture.client().analyze("videos/u1/v1.mp4", "squat");

        assertThat(result.score()).isNull();
        assertThat(result.overlayVideoKey()).isNull();
        assertThat(MAPPER.readTree(result.resultJson()).path("notEvaluableReason").asText())
                .isEqualTo("Pose detectada em poucos frames.");
    }

    @Test
    @DisplayName("falha do serviço devolve null, sem lançar")
    void falhaDevolveNull() {
        final Fixture fixture = fixture();
        fixture.server().expect(requestTo("http://vision:8000/analyze"))
                .andRespond(withServerError());

        assertThat(fixture.client().analyze("videos/u1/v1.mp4", "squat")).isNull();
    }

    @Test
    @DisplayName("sem base-url a análise nem é tentada")
    void semConfiguracao() {
        final HttpVisionClient client = new HttpVisionClient(
                new VisionProperties("", 600), RestClient.builder().build());

        assertThat(client.isConfigured()).isFalse();
        assertThat(client.analyze("videos/u1/v1.mp4", "squat")).isNull();
    }

    @Test
    @DisplayName("a chave do overlay fica ao lado do vídeo, para expirar junto")
    void chaveDoOverlay() {
        assertThat(HttpVisionClient.overlayKeyFor("videos/u1/v1.mp4"))
                .isEqualTo("videos/u1/v1-overlay.mp4");
        // MOV entra, MP4 sai: é o que o serviço grava.
        assertThat(HttpVisionClient.overlayKeyFor("videos/u1/v1.mov"))
                .isEqualTo("videos/u1/v1-overlay.mp4");
        assertThat(HttpVisionClient.overlayKeyFor("videos/u1/semextensao"))
                .isEqualTo("videos/u1/semextensao-overlay.mp4");
    }
}
