package com.myotrack.infrastructure.ai;

import static org.assertj.core.api.Assertions.assertThat;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import java.util.List;
import java.util.Map;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.web.client.RestClient;

/**
 * O modo estrito da OpenAI é onde a substituição de provedor pode quebrar em silêncio: um schema
 * que a Anthropic e o Gemini aceitavam é recusado com 400 se faltar {@code additionalProperties}
 * ou se o {@code required} não listar tudo. O que se fixa aqui é a adaptação — e o fato de ela ser
 * o espelho exato do {@code sanitizeSchema} do Gemini, que <b>remove</b> o que aquele provedor não
 * aceita.
 */
class OpenAiJsonClientTest {

    private static final ObjectMapper MAPPER = new ObjectMapper();

    @Test
    @DisplayName("strictSchema fecha todo objeto, inclusive dentro de items aninhados")
    void strictSchemaClosesEveryObject() throws Exception {
        // O schema real da análise de refeição, encurtado: objeto com array de objetos.
        String schema = """
                {
                  "type": "object",
                  "properties": {
                    "items": {
                      "type": "array",
                      "items": {
                        "type": "object",
                        "properties": {
                          "description": { "type": "string" },
                          "quantityG": { "type": "number" }
                        },
                        "required": ["description", "quantityG"]
                      }
                    }
                  },
                  "required": ["items"]
                }
                """;

        JsonNode strict = OpenAiJsonClient.strictSchema(MAPPER.readTree(schema));

        // A raiz e o objeto de dentro do array precisam dos dois.
        assertThat(strict.path("additionalProperties").asBoolean()).isFalse();
        JsonNode item = strict.path("properties").path("items").path("items");
        assertThat(item.path("additionalProperties").asBoolean()).isFalse();
        assertThat(item.path("required")).hasSize(2);

        // Estrutura preservada.
        assertThat(item.path("properties").path("quantityG").path("type").asText())
                .isEqualTo("number");
    }

    @Test
    @DisplayName("um array de tipos primitivos não ganha additionalProperties")
    void primitiveArrayIsLeftAlone() throws Exception {
        // O schema do relatório semanal tem arrays de string. Fechar um item que não é objeto
        // produziria um schema que a API recusa.
        String schema = """
                {
                  "type": "object",
                  "properties": {
                    "highlights": { "type": "array", "items": { "type": "string" } }
                  },
                  "required": ["highlights"]
                }
                """;

        JsonNode strict = OpenAiJsonClient.strictSchema(MAPPER.readTree(schema));
        JsonNode item = strict.path("properties").path("highlights").path("items");

        assertThat(item.has("additionalProperties")).isFalse();
        assertThat(item.has("required")).isFalse();
        assertThat(item.path("type").asText()).isEqualTo("string");
    }

    @Test
    @DisplayName("campo fora do required é obrigado — o modo estrito não tem opcional")
    void optionalFieldBecomesRequired() {
        // Consequência deliberada e documentada: quem precisar de campo que pode faltar tem de
        // torná-lo anulável no tipo. Deixá-lo fora do required não é opção que a API aceite, e
        // este teste existe para que a descoberta seja aqui e não num 400 em produção.
        JsonNode strict = OpenAiJsonClient.strictSchema(Map.of(
                "type", "object",
                "properties", Map.of("nome", Map.of("type", "string")),
                "required", List.of()));

        assertThat(strict.path("required")).hasSize(1);
        assertThat(strict.path("required").get(0).asText()).isEqualTo("nome");
    }

    @Test
    @DisplayName("strictSchema é idempotente sobre um schema já fechado")
    void strictSchemaIsIdempotent() throws Exception {
        String schema = """
                {
                  "type": "object",
                  "additionalProperties": false,
                  "properties": { "nome": { "type": "string" } },
                  "required": ["nome"]
                }
                """;

        JsonNode once = OpenAiJsonClient.strictSchema(MAPPER.readTree(schema));
        JsonNode twice = OpenAiJsonClient.strictSchema(once);

        assertThat(twice).isEqualTo(once);
    }

    @Test
    @DisplayName("Sem chave, o cliente se declara não configurado em vez de falhar")
    void notConfiguredWithoutApiKey() {
        LlmProperties properties = new LlmProperties(null, null, null, null, null, null, 0);
        OpenAiJsonClient client = new OpenAiJsonClient(properties, RestClient.builder());

        assertThat(client.isConfigured()).isFalse();
        // E a chamada devolve null — é esse contrato que faz o chamador cair no motor de regras.
        assertThat(client.generateJson("sistema", "usuário", Map.of())).isNull();
        assertThat(client.generateJsonFromImage("sistema", "usuário", new byte[] {1}, "image/jpeg", Map.of()))
                .isNull();
    }

    @Test
    @DisplayName("Com chave, o cliente se declara configurado e anuncia o modelo")
    void configuredWithApiKey() {
        LlmProperties properties =
                new LlmProperties(null, "chave-o", "gpt-5-nano", null, null, null, 0);
        OpenAiJsonClient client = new OpenAiJsonClient(properties, RestClient.builder());

        assertThat(client.isConfigured()).isTrue();
        assertThat(client.model()).isEqualTo("gpt-5-nano");
    }
}
