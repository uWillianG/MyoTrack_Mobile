package com.myotrack.worker.handlers;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.myotrack.domain.AnalysisJobType;
import com.myotrack.domain.entity.AnalysisJob;
import com.myotrack.domain.service.MealPhotoValidator;
import com.myotrack.domain.service.MealPhotoValidator.AnalyzedMeal;
import com.myotrack.domain.service.MealPhotoValidator.LlmMealPhoto;
import com.myotrack.infrastructure.ai.AiUsageRecorder;
import com.myotrack.infrastructure.ai.LlmJsonClient;
import com.myotrack.infrastructure.ai.LlmJsonClient.LlmJsonResult;
import java.util.Map;
import java.util.Optional;
import java.util.Set;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Component;

/**
 * Estima os itens de uma refeição a partir do que o usuário escreveu ("2 ovos fritos e um pão
 * francês com manteiga").
 *
 * <p><b>Não persiste nada.</b> É a diferença que justifica esta classe existir ao lado do
 * {@link MealPhotoHandler}, e não dentro dele: o caminho da foto grava uma linha do diário ao
 * terminar, e este devolve uma proposta para o usuário conferir e editar antes de decidir se ela
 * vira caloria contada. O resultado sai no {@code ResultJson} do job e o app o reenvia pelo
 * {@code POST /api/meal-analyses/manual}.
 *
 * <p>Roda como job pelo mesmo motivo que o chat do coach: a chave da API de IA vive só no Worker.
 * O tipo do job continua sendo {@code MEAL_PHOTO} — é ele que a cota diária conta, e uma chamada
 * de IA é uma chamada de IA, venha de foto ou de texto.
 *
 * <p>A aritmética e os limites são os mesmos da foto, no {@link MealPhotoValidator}. Uma segunda
 * validação aqui seria uma segunda definição de "porção plausível" e de "kcal que bate com os
 * macros", livres para divergir — e divergiriam no lugar onde ninguém olha, que é o item que a
 * pessoa aceitou sem conferir.
 */
@Component
public class MealTextEstimator {

    private static final Logger log = LoggerFactory.getLogger(MealTextEstimator.class);

    private static final ObjectMapper MAPPER = new ObjectMapper();

    private final AiUsageRecorder aiUsage;
    private final LlmJsonClient llm;

    public MealTextEstimator(AiUsageRecorder aiUsage, LlmJsonClient llm) {
        this.aiUsage = aiUsage;
        this.llm = llm;
    }

    /** Devolve o JSON de {@link AnalyzedMeal} que vai para o {@code ResultJson} do job. */
    public String estimate(AnalysisJob job) {
        final String text = textOf(job);
        if (text.isBlank()) {
            // O controller já recusa texto vazio; chegar aqui significa job montado à mão ou
            // corrompido, e reprocessar não conserta nenhum dos dois.
            throw new IllegalStateException("A descrição da refeição não foi encontrada.");
        }

        if (!llm.isConfigured()) {
            // Sem chave não há caminho alternativo: ao contrário de treino e dieta, não existe
            // motor de regras capaz de adivinhar quantos gramas cabem em "um pão com manteiga".
            throw new IllegalStateException(
                    "A estimativa por descrição está indisponível no momento.");
        }

        final LlmJsonResult result =
                llm.generateJson(systemPrompt(), text, mealTextSchema());

        if (result == null) {
            // Falha de chamada ou resposta vazia — pode ser passageiro (cota, instabilidade), e
            // por isso NÃO é IllegalStateException: vale reprocessar.
            throw new IllegalArgumentException(
                    "A IA não respondeu a estimativa. Tentaremos de novo.");
        }

        aiUsage.record(job.getUserId(), AnalysisJobType.MEAL_PHOTO, llm, result);

        final AnalyzedMeal meal = parseAndValidate(result.json()).orElseThrow(
                () -> new IllegalStateException(
                        "Não entendemos os alimentos nessa descrição. "
                                + "Tente algo como \"2 ovos fritos e 1 pão francês\"."));

        return toJson(meal);
    }

    /** O texto livre, gravado pelo controller no {@code inputJson} do job. */
    private static String textOf(AnalysisJob job) {
        final String input = job.getInputJson();
        if (input == null || input.isBlank()) {
            return "";
        }
        try {
            return MAPPER.readTree(input).path("text").asText("");
        } catch (Exception e) {
            log.warn("InputJson ilegível no job {}: {}", job.getId(), e.getMessage());
            return "";
        }
    }

    private Optional<AnalyzedMeal> parseAndValidate(String json) {
        try {
            final LlmMealPhoto proposal = MAPPER.readValue(json, LlmMealPhoto.class);
            // Conjunto vazio de ids conhecidos: o schema não pede foodItemId, então não há
            // vínculo com o catálogo a preservar. Quem quiser o vínculo escolhe o alimento na
            // busca — e aí é o servidor que calcula os macros, não o modelo.
            return MealPhotoValidator.validate(proposal, Set.of());
        } catch (Exception e) {
            log.warn("Resposta do LLM para a descrição não pôde ser lida: {}", e.getMessage());
            return Optional.empty();
        }
    }

    private static String systemPrompt() {
        return """
                Você é um nutricionista convertendo a descrição de uma refeição em números.
                O usuário escreve em português, informalmente, e usa medidas caseiras
                ("2 ovos", "um pão francês", "uma colher de arroz", "meio prato").
                Devolva um item por alimento citado, com a porção em gramas e os macronutrientes
                de CADA item (não da refeição inteira).
                Converta as medidas caseiras para gramas usando porções brasileiras usuais
                (ovo ≈ 50 g, pão francês ≈ 50 g, colher de sopa de arroz ≈ 25 g,
                concha de feijão ≈ 80 g, fatia de queijo ≈ 20 g, copo de leite ≈ 200 ml).
                Quando a quantidade não for dita, assuma uma porção individual comum e não uma
                porção mínima — quem escreve "arroz e feijão" comeu um prato, não uma colher.
                Descreva cada item em português, de forma curta ("Arroz branco cozido").
                Inclua o modo de preparo citado no cálculo: frito leva o óleo absorvido, e um
                pão "com manteiga" é dois itens, o pão e a manteiga.
                Se o texto não descrever comida nenhuma, devolva a lista vazia.
                Não invente alimentos que o usuário não citou.
                """;
    }

    /**
     * JSON Schema da resposta.
     *
     * <p>Sem {@code posX}/{@code posY}, ao contrário do schema da foto: eles marcam onde o
     * alimento está na imagem, e aqui não há imagem. Pedi-los renderia coordenadas inventadas
     * para um desenho que ninguém vai fazer.
     */
    private static Map<String, Object> mealTextSchema() {
        final String schema = """
                {
                  "type": "object",
                  "properties": {
                    "items": {
                      "type": "array",
                      "items": {
                        "type": "object",
                        "properties": {
                          "description": { "type": "string" },
                          "quantityG": { "type": "number" },
                          "kcal": { "type": "number" },
                          "proteinG": { "type": "number" },
                          "carbsG": { "type": "number" },
                          "fatG": { "type": "number" }
                        },
                        "required": ["description", "quantityG", "kcal", "proteinG", "carbsG", "fatG"]
                      }
                    }
                  },
                  "required": ["items"]
                }
                """;
        try {
            @SuppressWarnings("unchecked")
            final Map<String, Object> parsed = MAPPER.readValue(schema, Map.class);
            return parsed;
        } catch (Exception e) {
            throw new IllegalStateException("Schema da estimativa por descrição inválido.", e);
        }
    }

    private static String toJson(Object value) {
        try {
            return MAPPER.writeValueAsString(value);
        } catch (Exception e) {
            throw new IllegalStateException("Falha ao serializar a estimativa da refeição.", e);
        }
    }
}
