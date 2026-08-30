package com.myotrack.worker.handlers;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.myotrack.domain.AnalysisJobType;
import com.myotrack.domain.entity.AnalysisJob;
import com.myotrack.domain.entity.FoodItem;
import com.myotrack.domain.entity.MealPhotoAnalysis;
import com.myotrack.domain.service.MealPhotoValidator;
import com.myotrack.domain.service.MealPhotoValidator.AnalyzedMeal;
import com.myotrack.domain.service.MealPhotoValidator.LlmMealPhoto;
import com.myotrack.infrastructure.ai.AiUsageRecorder;
import com.myotrack.infrastructure.ai.GeminiImageClient;
import com.myotrack.infrastructure.ai.GeminiImageClient.GeneratedImage;
import com.myotrack.infrastructure.ai.LlmJsonClient;
import com.myotrack.infrastructure.ai.MealImageAnnotator;
import com.myotrack.infrastructure.ai.MealImageAnnotator.Annotation;
import com.myotrack.infrastructure.ai.LlmJsonClient.LlmJsonResult;
import com.myotrack.infrastructure.repository.FoodItemRepository;
import com.myotrack.infrastructure.repository.MealPhotoAnalysisRepository;
import com.myotrack.infrastructure.storage.MediaStorage;
import com.myotrack.worker.JobHandler;
import java.io.ByteArrayInputStream;
import java.math.RoundingMode;
import java.util.ArrayList;
import java.util.List;
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
 * Estima os macros de uma refeição — a partir da foto, ou da descrição que o usuário escreveu.
 *
 * <p><b>Os dois caminhos são o mesmo tipo de job</b>, {@code MEAL_PHOTO}, e isso é o que faz a
 * cota diária valer para ambos sem uma segunda contabilidade: quem conta é
 * {@code countByUserIdAndType(..., MEAL_PHOTO, hoje)}, e um tipo novo simplesmente não seria
 * visto por ela. O {@code inputJson} traz {@code "mode"} para separar; a ausência dele é o
 * caminho da foto, que é como se parecem todos os jobs gravados antes de a entrada manual
 * existir.
 *
 * <p>O que os dois <b>não</b> compartilham é o desfecho: a foto grava uma linha do diário, a
 * descrição devolve itens para o usuário conferir e não persiste nada. Por isso a estimativa por
 * texto vive no {@link MealTextEstimator}, e aqui só entra o desvio.
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

    /** Valor de {@code inputJson.mode} que desvia para a estimativa por descrição. */
    private static final String TEXT_MODE = "text";

    private final MealPhotoAnalysisRepository analyses;
    private final FoodItemRepository foods;
    private final AiUsageRecorder aiUsage;
    private final MediaStorage storage;
    private final LlmJsonClient llm;
    private final GeminiImageClient imageClient;
    private final MealTextEstimator textEstimator;

    public MealPhotoHandler(
            MealPhotoAnalysisRepository analyses,
            FoodItemRepository foods,
            AiUsageRecorder aiUsage,
            MediaStorage storage,
            LlmJsonClient llm,
            GeminiImageClient imageClient,
            MealTextEstimator textEstimator) {
        this.analyses = analyses;
        this.foods = foods;
        this.aiUsage = aiUsage;
        this.storage = storage;
        this.llm = llm;
        this.imageClient = imageClient;
        this.textEstimator = textEstimator;
    }

    @Override
    public AnalysisJobType type() {
        return AnalysisJobType.MEAL_PHOTO;
    }

    @Override
    @Transactional
    public String handle(AnalysisJob job) {
        // O desvio vem antes de qualquer coisa que pressuponha imagem. Sem "mode", é foto: os
        // jobs gravados antes da entrada manual não têm o campo, e tratá-los como texto os faria
        // falhar em massa numa fila que já existe.
        if (TEXT_MODE.equals(modeOf(job))) {
            return textEstimator.estimate(job);
        }

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

        // A versão ilustrada é melhor-esforço e vem depois de a análise estar pronta:
        // falhar aqui não pode custar os macros, que são o resultado que importa.
        if (illustratedRequested(job)) {
            entity.setIllustratedMediaKey(
                    illustrate(job, mediaKey, image, mediaTypeOf(job), meal));
            analyses.save(entity);
        }

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

    /** Qual dos dois caminhos este job pede. Null/ausente = foto. */
    private static String modeOf(AnalysisJob job) {
        final String input = job.getInputJson();
        if (input == null || input.isBlank()) {
            return null;
        }
        try {
            return MAPPER.readTree(input).path("mode").asText(null);
        } catch (Exception e) {
            // JSON ilegível cai no caminho da foto, que falha adiante com mensagem sobre a foto
            // ausente — dizer "descrição inválida" para um job que talvez seja de foto seria
            // mandar o usuário procurar o problema no lugar errado.
            return null;
        }
    }

    /** O usuário pediu a versão anotada? Vem no {@code inputJson} montado pelo controller. */
    private static boolean illustratedRequested(AnalysisJob job) {
        final String input = job.getInputJson();
        if (input == null || input.isBlank()) {
            return false;
        }
        try {
            return MAPPER.readTree(input).path("illustrated").asBoolean(false);
        } catch (Exception e) {
            return false;
        }
    }

    /**
     * Gera a foto anotada e devolve a chave dela, ou null.
     *
     * <p>Tenta o modelo de imagem do Gemini primeiro e cai no renderizador local. O fallback
     * não é detalhe: o modelo de imagem exige chave com billing e no tier gratuito tem cota
     * zero, então sem ele a funcionalidade quase nunca entregaria alguma coisa.
     */
    private String illustrate(
            AnalysisJob job, String mediaKey, byte[] image, String mediaType, AnalyzedMeal meal) {

        final List<String> labels = new ArrayList<>();
        for (final var item : meal.items()) {
            labels.add("%s \u2014 %s g \u00b7 %s kcal".formatted(
                    item.description(),
                    item.quantityG().setScale(0, RoundingMode.HALF_UP),
                    item.kcal().setScale(0, RoundingMode.HALF_UP)));
        }
        final String totals = "%s kcal \u00b7 P %s g \u00b7 C %s g \u00b7 G %s g".formatted(
                meal.totalKcal(), meal.totalProteinG(), meal.totalCarbsG(), meal.totalFatG());

        byte[] bytes;
        String outputType = "image/jpeg";

        final GeneratedImage generated = imageClient.isConfigured()
                ? imageClient.editImage(image, mediaType, instructionFor(labels, totals))
                : null;

        if (generated != null) {
            bytes = generated.bytes();
            outputType = generated.mediaType();
            recordImageUsage(job.getUserId(), generated);
        } else {
            try {
                final List<Annotation> annotations = new ArrayList<>();
                for (var i = 0; i < meal.items().size(); i++) {
                    final var item = meal.items().get(i);
                    annotations.add(new Annotation(labels.get(i), item.posX(), item.posY()));
                }
                bytes = MealImageAnnotator.render(image, annotations, totals);
            } catch (Exception e) {
                log.warn("Renderização local da análise ilustrada falhou: {}", e.getMessage());
                return null;
            }
        }

        final String key = "%s-ilustrada%s".formatted(
                stripExtension(mediaKey), "image/png".equals(outputType) ? ".png" : ".jpg");
        try {
            storage.upload(key, new ByteArrayInputStream(bytes), bytes.length, outputType);
            return key;
        } catch (Exception e) {
            log.warn("Falha ao guardar a análise ilustrada {}: {}", key, e.getMessage());
            return null;
        }
    }

    private static String instructionFor(List<String> labels, String totals) {
        final StringBuilder lines = new StringBuilder();
        for (final String label : labels) {
            lines.append("- ").append(label).append('\n');
        }
        return """
                Edite esta foto de refeição adicionando anotações visuais elegantes e legíveis
                por cima da imagem, como em um infográfico de nutrição. Mantenha a foto
                original como fundo, sem alterar a comida.
                Para cada item abaixo, desenhe uma etiqueta discreta apontando para o alimento
                correspondente:
                %s
                Adicione também um cartão de resumo em um canto com os totais: %s
                Todos os textos em português.
                """.formatted(lines, totals);
    }

    /** A chave da ilustrada fica ao lado da original, para expirar junto na retenção. */
    private static String stripExtension(String mediaKey) {
        final int dot = mediaKey.lastIndexOf('.');
        return dot < 0 ? mediaKey : mediaKey.substring(0, dot);
    }

    /**
     * A segunda chamada da análise ilustrada, e a mais cara do app por uma ordem de grandeza.
     *
     * <p>Ela grava numa linha separada da extração de propósito: somadas, as duas esconderiam
     * justamente o que precisa ser visto — que a ilustração custa múltiplos da análise que o
     * usuário pediu.
     */
    private void recordImageUsage(UUID userId, GeneratedImage generated) {
        aiUsage.recordImage(userId, AnalysisJobType.MEAL_PHOTO, imageClient, generated);
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
        aiUsage.record(userId, AnalysisJobType.MEAL_PHOTO, llm, result);
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
                Informe também posX e posY: a posição aproximada do centro do alimento na
                imagem, em escala de 0 a 1000 (0,0 = canto superior esquerdo).
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
                          "fatG": { "type": "number" },
                          "posX": { "type": "integer" },
                          "posY": { "type": "integer" }
                        },
                        "required": ["description", "quantityG", "kcal", "proteinG", "carbsG", "fatG", "posX", "posY"]
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
