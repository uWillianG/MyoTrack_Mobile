package com.myotrack.worker.handlers;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.myotrack.domain.AnalysisJobType;
import com.myotrack.domain.entity.AiUsageLog;
import com.myotrack.domain.entity.AnalysisJob;
import com.myotrack.domain.entity.FoodItem;
import com.myotrack.domain.entity.MealPhotoAnalysis;
import com.myotrack.domain.service.MealPhotoValidator;
import com.myotrack.domain.service.MealPhotoValidator.AnalyzedMeal;
import com.myotrack.domain.service.MealPhotoValidator.LlmMealPhoto;
import com.myotrack.infrastructure.ai.LlmJsonClient;
import com.myotrack.infrastructure.ai.LlmJsonClient.LlmJsonResult;
import com.myotrack.infrastructure.repository.AiUsageLogRepository;
import com.myotrack.infrastructure.repository.FoodItemRepository;
import com.myotrack.infrastructure.repository.MealPhotoAnalysisRepository;
import com.myotrack.infrastructure.storage.MediaStorage;
import com.myotrack.worker.JobHandler;
import java.util.Map;
import java.util.Optional;
import java.util.Set;
import java.util.UUID;
import java.util.stream.Collectors;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

/**
 * Estima os macros de uma refeição a partir da foto.
 *
 * <p>Diferente das gerações de treino e dieta em um ponto que muda o desenho: <b>não há motor de
 * regras para cair quando a IA falha</b>. Treino e dieta são derivados do perfil, que o backend
 * tem; o que havia num prato só existe na imagem. Sem resposta utilizável, o job falha com
 * mensagem em vez de gravar uma estimativa inventada — número errado no diário alimentar é pior
 * que número nenhum, porque o usuário não tem como desconfiar dele.
 *
 * <p>A aritmética e os limites ficam no {@link MealPhotoValidator}; aqui só entra o que depende
 * de infraestrutura (storage, LLM, persistência).
 */
@Component
public class MealPhotoHandler implements JobHandler {

    private static final Logger log = LoggerFactory.getLogger(MealPhotoHandler.class);

    private static final ObjectMapper MAPPER = new ObjectMapper();

    private static final String DEFAULT_MEDIA_TYPE = "image/jpeg";

    private final MealPhotoAnalysisRepository analyses;
    private final FoodItemRepository foods;
    private final AiUsageLogRepository aiUsage;
    private final MediaStorage storage;
    private final LlmJsonClient llm;

    public MealPhotoHandler(
            MealPhotoAnalysisRepository analyses,
            FoodItemRepository foods,
            AiUsageLogRepository aiUsage,
            MediaStorage storage,
            LlmJsonClient llm) {
        this.analyses = analyses;
        this.foods = foods;
        this.aiUsage = aiUsage;
        this.storage = storage;
        this.llm = llm;
    }

    @Override
    public AnalysisJobType type() {
        return AnalysisJobType.MEAL_PHOTO;
    }

    @Override
    @Transactional
    public String handle(AnalysisJob job) {
        final UUID userId = job.getUserId();

        final String mediaKey = job.getMediaKey();
        if (mediaKey == null || mediaKey.isBlank()) {
            throw new IllegalStateException("A foto da refeição não foi encontrada.");
        }

        // Sem chave de IA não existe caminho alternativo — melhor dizer isso do que deixar o
        // usuário esperando por uma análise que nunca vem.
        if (!llm.isConfigured()) {
            throw new IllegalStateException(
                    "A análise de refeição está indisponível no momento.");
        }

        final byte[] image = download(mediaKey);
        final LlmJsonResult result = llm.generateJsonFromImage(
                systemPrompt(), userPrompt(), image, mediaTypeOf(job), mealPhotoSchema());

        if (result == null) {
            // Null aqui é falha de chamada ou resposta vazia — pode ser passageiro (cota,
            // instabilidade), então NÃO é IllegalStateException: vale reprocessar.
            throw new IllegalArgumentException(
                    "A IA não respondeu a análise da foto. Tentaremos de novo.");
        }

        recordUsage(userId, result);

        final AnalyzedMeal meal = parseAndValidate(result.json()).orElseThrow(
                () -> new IllegalStateException(
                        "Não identificamos alimentos nessa foto. "
                                + "Tente enquadrar o prato inteiro, com boa luz."));

        final MealPhotoAnalysis entity = persist(userId, job, mediaKey, meal);
        return "{\"mealAnalysisId\":\"%s\"}".formatted(entity.getId());
    }

    private byte[] download(String mediaKey) {
        final byte[] image = storage.download(mediaKey);
        if (image == null || image.length == 0) {
            // A retenção de mídia (LGPD) apaga fotos antigas; um job represado por dias pode
            // acordar depois disso, e reprocessar não traria o arquivo de volta.
            throw new IllegalStateException("A foto da refeição não está mais disponível.");
        }
        return image;
    }

    /** O tipo real da imagem, gravado pelo controller no {@code inputJson} do job. */
    private static String mediaTypeOf(AnalysisJob job) {
        final String input = job.getInputJson();
        if (input == null || input.isBlank()) {
            return DEFAULT_MEDIA_TYPE;
        }
        try {
            final String contentType = MAPPER.readTree(input).path("contentType").asText(null);
            return contentType == null || contentType.isBlank() ? DEFAULT_MEDIA_TYPE : contentType;
        } catch (Exception e) {
            return DEFAULT_MEDIA_TYPE;
        }
    }

    private Optional<AnalyzedMeal> parseAndValidate(String json) {
        try {
            final LlmMealPhoto proposal = MAPPER.readValue(json, LlmMealPhoto.class);
            return MealPhotoValidator.validate(proposal, knownFoodItemIds());
        } catch (Exception e) {
            log.warn("Resposta do LLM para a foto não pôde ser lida: {}", e.getMessage());
            return Optional.empty();
        }
    }

    private Set<Integer> knownFoodItemIds() {
        return foods.findAll().stream().map(FoodItem::getId).collect(Collectors.toSet());
    }

    private MealPhotoAnalysis persist(
            UUID userId, AnalysisJob job, String mediaKey, AnalyzedMeal meal) {

        final MealPhotoAnalysis entity = new MealPhotoAnalysis();
        entity.setUserId(userId);
        entity.setAnalysisJobId(job.getId());
        entity.setMediaKey(mediaKey);
        entity.setItemsJson(toJson(meal.items()));
        entity.setTotalKcal(meal.totalKcal());
        entity.setTotalProteinG(meal.totalProteinG());
        entity.setTotalCarbsG(meal.totalCarbsG());
        entity.setTotalFatG(meal.totalFatG());

        return analyses.save(entity);
    }

    private void recordUsage(UUID userId, LlmJsonResult result) {
        final AiUsageLog usage = new AiUsageLog();
        usage.setUserId(userId);
        usage.setOperation(AnalysisJobType.MEAL_PHOTO);
        usage.setModel(llm.model());
        usage.setInputTokens(result.inputTokens());
        usage.setOutputTokens(result.outputTokens());
        aiUsage.save(usage);
    }

    private static String systemPrompt() {
        return """
                Você é um nutricionista analisando a foto de uma refeição.
                Liste os alimentos visíveis, um item por alimento, estimando a porção em gramas e
                os macronutrientes de CADA item (não do prato inteiro).
                Descreva cada item em português, de forma curta (ex.: "Arroz branco cozido").
                Estime a porção pelo tamanho aparente comparado a talheres, pratos e copos na
                imagem. Se não houver comida na foto, devolva a lista vazia.
                Não invente itens que não estejam visíveis.
                """;
    }

    private static String userPrompt() {
        return "Analise esta refeição e devolva os itens com quantidade e macros.";
    }

    /**
     * JSON Schema da resposta. O {@code foodItemId} não é pedido: ligar ao catálogo exigiria
     * mandar a lista inteira de alimentos junto da imagem, e o campo continua no modelo para
     * quando essa ligação for feita por busca textual no servidor.
     */
    private static Map<String, Object> mealPhotoSchema() {
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
            throw new IllegalStateException("Schema da análise de refeição inválido.", e);
        }
    }

    private static String toJson(Object value) {
        try {
            return MAPPER.writeValueAsString(value);
        } catch (Exception e) {
            throw new IllegalStateException("Falha ao serializar os itens da refeição.", e);
        }
    }
}
