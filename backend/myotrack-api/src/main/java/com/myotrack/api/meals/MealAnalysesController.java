package com.myotrack.api.meals;

import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.myotrack.api.billing.EntitlementService;
import com.myotrack.api.security.CurrentUser;
import com.myotrack.domain.AnalysisJobType;
import com.myotrack.domain.MealSource;
import com.myotrack.domain.entity.AnalysisJob;
import com.myotrack.domain.entity.FoodItem;
import com.myotrack.domain.entity.MealPhotoAnalysis;
import com.myotrack.domain.service.FoodPortion;
import com.myotrack.domain.service.MealPhotoValidator;
import com.myotrack.domain.service.MealPhotoValidator.AnalyzedItem;
import com.myotrack.domain.service.MealPhotoValidator.AnalyzedMeal;
import com.myotrack.infrastructure.repository.AnalysisJobRepository;
import com.myotrack.infrastructure.repository.FoodItemRepository;
import com.myotrack.infrastructure.repository.MealPhotoAnalysisRepository;
import com.myotrack.infrastructure.storage.MediaStorage;
import java.io.IOException;
import java.math.BigDecimal;
import java.time.Duration;
import java.time.LocalTime;
import java.time.OffsetDateTime;
import java.util.List;
import java.util.Map;
import java.util.Objects;
import java.util.Set;
import java.util.UUID;
import java.util.function.Function;
import java.util.stream.Collectors;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.data.domain.Limit;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RequestPart;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.multipart.MultipartFile;

/**
 * Registro de refeição no diário alimentar, pelos quatro caminhos que o produto oferece.
 *
 * <p>A foto sobe <b>multipart pela API</b>, e não direto no storage por URL pré-assinada como o
 * vídeo de exercício: a imagem já chega comprimida pelo app (algumas centenas de KB) e o
 * caminho de uma requisição só evita o estado intermediário de "objeto no bucket que ninguém
 * reclamou" quando o app morre entre o upload e o enfileiramento.
 *
 * <p>Os outros três dispensam foto e convergem para o mesmo {@code POST /manual}: digitar tudo à
 * mão, aceitar o que a IA estimou do texto livre ({@code POST /estimate}) ou escolher no catálogo
 * ({@code GET /api/foods}). <b>Nenhum deles grava sozinho</b> — a estimativa por texto devolve
 * itens para conferência e não toca no diário, porque o valor dela está em ser editável antes de
 * virar caloria contada. Quem grava é sempre o {@code /manual}, com os totais somados aqui.
 */
@RestController
@RequestMapping("/api/meal-analyses")
public class MealAnalysesController {

    private static final Logger log = LoggerFactory.getLogger(MealAnalysesController.class);

    private static final ObjectMapper MAPPER = new ObjectMapper();

    /** Casado com o {@code spring.servlet.multipart.max-file-size} do application.yml. */
    private static final long MAX_PHOTO_BYTES = 10L * 1024 * 1024;

    /** HEIC entra porque é o padrão da câmera do iPhone. */
    private static final Set<String> ALLOWED_CONTENT_TYPES =
            Set.of("image/jpeg", "image/png", "image/webp", "image/heic", "image/heif");

    private static final Map<String, String> EXTENSIONS = Map.of(
            "image/jpeg", ".jpg",
            "image/png", ".png",
            "image/webp", ".webp",
            "image/heic", ".heic",
            "image/heif", ".heif");

    /** Tempo de vida da URL de leitura da foto: o suficiente para a tela abrir e rolar. */
    private static final Duration PHOTO_URL_TTL = Duration.ofMinutes(30);

    private static final int DEFAULT_LIMIT = 30;
    private static final int MAX_LIMIT = 100;

    /**
     * Teto do texto livre mandado à estimativa. Uma refeição descrita cabe folgadamente aqui;
     * acima disso é texto colado, e o mesmo teto do coach vale pelo mesmo motivo — cada caractere
     * a mais é token pago numa chamada que já consome a cota do dia.
     */
    private static final int MAX_TEXT_LENGTH = 500;

    /**
     * Até quando se pode registrar uma refeição para trás.
     *
     * <p>Existe porque a entrada manual nasce do esquecimento: quem digita à mão quase sempre está
     * lançando o almoço às nove da noite, e o diário é por dia — sem data escolhida, esse almoço
     * cairia no jantar. O limite de 30 dias é o que separa "corrigir o registro" de "reescrever o
     * histórico": a semana já fechada em relatório não deveria mudar de valor depois de lida.
     */
    private static final int MAX_BACKDATE_DAYS = 30;

    /** Folga para o relógio do aparelho adiantado. Refeição no futuro não existe. */
    private static final Duration FUTURE_TOLERANCE = Duration.ofMinutes(5);

    private final MealPhotoAnalysisRepository analyses;
    private final AnalysisJobRepository jobs;
    private final FoodItemRepository foods;
    private final MediaStorage storage;
    private final EntitlementService entitlements;

    public MealAnalysesController(
            MealPhotoAnalysisRepository analyses,
            AnalysisJobRepository jobs,
            FoodItemRepository foods,
            MediaStorage storage,
            EntitlementService entitlements) {
        this.analyses = analyses;
        this.jobs = jobs;
        this.foods = foods;
        this.storage = storage;
        this.entitlements = entitlements;
    }

    /**
     * Recebe a foto e enfileira a análise; o cliente acompanha por {@code /api/jobs/&#123;id&#125;}.
     */
    @PostMapping
    @Transactional
    public ResponseEntity<?> analyze(
            @RequestPart("photo") MultipartFile file,
            // Vem do multipart como texto; ausente = análise padrão.
            @RequestParam(name = "illustrated", defaultValue = "false") boolean illustrated) {
        final UUID userId = CurrentUser.id();

        final String contentType = file.getContentType();
        if (file.isEmpty() || contentType == null
                || !ALLOWED_CONTENT_TYPES.contains(contentType.toLowerCase())) {
            return ResponseEntity.badRequest()
                    .body(Map.of("error", "Envie uma foto em JPEG, PNG, WEBP ou HEIC."));
        }
        if (file.getSize() > MAX_PHOTO_BYTES) {
            return ResponseEntity.badRequest()
                    .body(Map.of("error", "A foto passa de 10 MB. Tire outra com menos resolução."));
        }

        final String quotaError = mealQuotaError(userId);
        if (quotaError != null) {
            // 429 é o que o app reconhece como limite atingido para oferecer o Pro.
            return ResponseEntity.status(HttpStatus.TOO_MANY_REQUESTS)
                    .body(Map.of("error", quotaError));
        }

        final String normalizedType = contentType.toLowerCase();
        final String mediaKey = "meals/%s/%s%s".formatted(
                userId, UUID.randomUUID(), EXTENSIONS.getOrDefault(normalizedType, ".jpg"));

        try (var stream = file.getInputStream()) {
            storage.upload(mediaKey, stream, file.getSize(), normalizedType);
        } catch (IOException e) {
            log.error("Falha ao guardar a foto de refeição do usuário {}.", userId, e);
            return ResponseEntity.status(HttpStatus.BAD_GATEWAY)
                    .body(Map.of("error", "Não foi possível guardar a foto. Tente de novo."));
        }

        final AnalysisJob job = new AnalysisJob();
        job.setUserId(userId);
        job.setType(AnalysisJobType.MEAL_PHOTO);
        job.setMediaKey(mediaKey);
        // O worker precisa do tipo real para mandar ao modelo o mime certo.
        job.setInputJson(
                "{\"contentType\":\"%s\",\"illustrated\":%s}"
                        .formatted(normalizedType, illustrated));

        return ResponseEntity.accepted().body(Map.of("jobId", jobs.save(job).getId()));
    }

    /**
     * Estima os itens de uma refeição a partir de texto livre — <b>sem gravar nada</b>.
     *
     * <p>Vai para a fila em vez de responder na hora, e a razão não é a latência: a chave da API
     * de IA vive só no Worker, como no chat do coach. Fazer a chamada aqui exigiria a chave também
     * no processo que atende a internet, o que é uma troca ruim por alguns segundos de espera num
     * caminho que o app já sabe acompanhar por SSE. De quebra, o job é o que faz a cota funcionar:
     * ele é gravado como {@code MEAL_PHOTO}, então a contagem diária o enxerga sem que exista uma
     * segunda contabilidade — uma chamada de IA é uma chamada de IA.
     *
     * <p>O resultado sai no {@code resultJson} do job, no mesmo formato dos itens de uma análise,
     * e o cliente o manda de volta pelo {@code POST /manual} depois de o usuário conferir. Nada
     * entra no diário antes disso, de propósito: o valor da estimativa está em ser editável, e uma
     * linha gravada que a pessoa ainda vai corrigir já contou calorias erradas no caminho.
     */
    @PostMapping("/estimate")
    @Transactional
    public ResponseEntity<?> estimate(@RequestBody EstimateRequest request) {
        final UUID userId = CurrentUser.id();

        final String text = request.text() == null ? "" : request.text().trim();
        if (text.isEmpty()) {
            return ResponseEntity.badRequest()
                    .body(Map.of("error", "Descreva o que você comeu."));
        }
        if (text.length() > MAX_TEXT_LENGTH) {
            return ResponseEntity.badRequest().body(Map.of(
                    "error",
                    "Descrição muito longa (máximo %d caracteres).".formatted(MAX_TEXT_LENGTH)));
        }

        final String quotaError = mealQuotaError(userId);
        if (quotaError != null) {
            return ResponseEntity.status(HttpStatus.TOO_MANY_REQUESTS)
                    .body(Map.of("error", quotaError));
        }

        final AnalysisJob job = new AnalysisJob();
        job.setUserId(userId);
        job.setType(AnalysisJobType.MEAL_PHOTO);
        // O "mode" é o que separa os dois caminhos dentro do mesmo tipo de job. Serializado pelo
        // Jackson, e não por concatenação como o caminho da foto: aqui entra texto do usuário, e
        // uma aspa digitada no meio da frase quebraria o JSON da coluna.
        job.setInputJson(toJson(Map.of("mode", "text", "text", text)));

        return ResponseEntity.accepted().body(Map.of("jobId", jobs.save(job).getId()));
    }

    /**
     * Grava uma refeição montada pelo usuário — digitada, estimada por texto ou vinda do catálogo.
     *
     * <p>Os três caminhos chegam aqui porque produzem a mesma coisa: uma lista de itens que a
     * pessoa <b>já conferiu</b>. Separá-los em três endpoints criaria três lugares para somar
     * totais e três para errar a soma.
     *
     * <p>O cliente nunca manda total, pela mesma razão do {@code PUT} de ajuste: é o total que o
     * diário soma, e aceitá-lo pronto permitiria gravar um dia de calorias que não corresponde a
     * nada do que está na tela. E quando o item traz {@code foodItemId}, os macros também são
     * recalculados aqui a partir do catálogo — senão o vínculo com o alimento seria decorativo, e
     * "150 g de arroz" poderia valer zero caloria.
     */
    @PostMapping("/manual")
    @Transactional
    public ResponseEntity<?> manual(@RequestBody ManualRequest request) {
        final UUID userId = CurrentUser.id();

        final List<ManualItem> items = request.items() == null ? List.of() : request.items();
        if (items.isEmpty()) {
            return ResponseEntity.badRequest()
                    .body(Map.of("error", "Uma refeição precisa de pelo menos um item."));
        }
        if (items.size() > MealPhotoValidator.MAX_ITEMS) {
            // Recusa em vez de cortar: o validador descarta o excedente em silêncio, o que é a
            // resposta certa para um modelo que fragmentou demais e a errada para alguém que
            // digitou item por item e não veria os últimos entrarem.
            return ResponseEntity.badRequest().body(Map.of(
                    "error",
                    "Uma refeição aceita no máximo %d itens.".formatted(MealPhotoValidator.MAX_ITEMS)));
        }

        final OffsetDateTime createdAt =
                request.createdAt() == null ? OffsetDateTime.now() : request.createdAt();
        if (!isWithinRegistrationWindow(createdAt)) {
            return ResponseEntity.badRequest().body(Map.of(
                    "error",
                    "A refeição precisa ter sido consumida nos últimos %d dias."
                            .formatted(MAX_BACKDATE_DAYS)));
        }

        final Set<Integer> requestedFoodIds = items.stream()
                .map(ManualItem::foodItemId)
                .filter(Objects::nonNull)
                .collect(Collectors.toSet());

        final Map<Integer, FoodItem> catalog = foods.findAllById(requestedFoodIds).stream()
                .collect(Collectors.toMap(FoodItem::getId, Function.identity()));

        // Id desconhecido é erro, e não vínculo ignorado como no PUT de ajuste. A diferença é o
        // que aconteceria depois: lá o item já tem macros próprios e perder o vínculo não muda
        // número nenhum; aqui o cliente pode estar contando que o servidor calcule a partir do
        // catálogo, e ignorar o id gravaria a porção com os zeros que ele mandou no lugar.
        if (catalog.size() != requestedFoodIds.size()) {
            return ResponseEntity.badRequest().body(Map.of(
                    "error", "Um dos alimentos escolhidos não está mais no catálogo."));
        }

        // Mesmo saneamento da saída da IA: o cliente também é entrada não confiável, e é ele que
        // garante que kcal e macros continuem coerentes entre si.
        final AnalyzedMeal meal = MealPhotoValidator
                .validate(new MealPhotoValidator.LlmMealPhoto(items.stream()
                        .map(item -> item.toDetected(catalog))
                        .toList()), catalog.keySet())
                .orElse(null);

        if (meal == null) {
            return ResponseEntity.badRequest()
                    .body(Map.of("error", "Os itens enviados não são válidos."));
        }

        final MealPhotoAnalysis analysis = new MealPhotoAnalysis();
        analysis.setUserId(userId);
        analysis.setSource(MealSource.MANUAL);
        // Sem MediaKey e sem AnalysisJobId: não houve foto nem fila. A estimativa por texto passa
        // por um job, mas o job dela não produz esta linha — ele devolve itens para conferência, e
        // amarrá-lo aqui diria que este registro é o resultado de uma análise que ninguém aprovou.
        analysis.setCreatedAt(createdAt);
        analysis.setItemsJson(toJson(meal.items()));
        analysis.setTotalKcal(meal.totalKcal());
        analysis.setTotalProteinG(meal.totalProteinG());
        analysis.setTotalCarbsG(meal.totalCarbsG());
        analysis.setTotalFatG(meal.totalFatG());
        // userAdjusted continua false: ele mede "a estimativa da IA precisou de correção", e é
        // sinal de qualidade do modelo. Uma refeição que nunca foi estimada marcaria um erro que
        // não houve.

        return ResponseEntity.status(HttpStatus.CREATED).body(toView(analyses.save(analysis)));
    }

    /** Análises mais recentes, para o diário alimentar. */
    @GetMapping
    @Transactional(readOnly = true)
    public List<AnalysisView> list(@RequestParam(required = false) Integer limit) {
        final int size = limit == null ? DEFAULT_LIMIT : Math.clamp(limit, 1, MAX_LIMIT);

        return analyses.findByUserIdOrderByCreatedAtDesc(CurrentUser.id(), Limit.of(size)).stream()
                .map(this::toView)
                .toList();
    }

    @GetMapping("/{id}")
    @Transactional(readOnly = true)
    public ResponseEntity<AnalysisView> get(@PathVariable UUID id) {
        return analyses.findByIdAndUserId(id, CurrentUser.id())
                .map(analysis -> ResponseEntity.ok(toView(analysis)))
                .orElseGet(() -> ResponseEntity.notFound().build());
    }

    /**
     * Correção manual da estimativa.
     *
     * <p>Os totais são sempre recalculados no servidor a partir dos itens: aceitar o total do
     * cliente permitiria gravar um dia de calorias que não corresponde a nada do que está na
     * tela, e é justamente o total que o diário soma.
     */
    @PutMapping("/{id}")
    @Transactional
    public ResponseEntity<?> adjust(@PathVariable UUID id, @RequestBody AdjustRequest request) {
        final MealPhotoAnalysis analysis =
                analyses.findByIdAndUserId(id, CurrentUser.id()).orElse(null);
        if (analysis == null) {
            return ResponseEntity.notFound().build();
        }

        if (request.excludedFromDiary() != null) {
            analysis.setExcludedFromDiary(request.excludedFromDiary());
        }

        if (request.items() != null) {
            if (request.items().isEmpty()) {
                return ResponseEntity.badRequest().body(Map.of(
                        "error",
                        "Uma refeição precisa de pelo menos um item. "
                                + "Para descartá-la, tire-a do diário."));
            }

            // Passa pelo mesmo saneamento da resposta da IA: o cliente também é entrada não
            // confiável, e é o mesmo lugar que garante que kcal e macros continuem coerentes.
            final AnalyzedMeal recalculated = MealPhotoValidator
                    .validate(new MealPhotoValidator.LlmMealPhoto(request.items().stream()
                            .map(AdjustedItem::toDetected)
                            .toList()), knownFoodItemIds(analysis))
                    .orElse(null);

            if (recalculated == null) {
                return ResponseEntity.badRequest()
                        .body(Map.of("error", "Os itens enviados não são válidos."));
            }

            analysis.setItemsJson(toJson(recalculated.items()));
            analysis.setTotalKcal(recalculated.totalKcal());
            analysis.setTotalProteinG(recalculated.totalProteinG());
            analysis.setTotalCarbsG(recalculated.totalCarbsG());
            analysis.setTotalFatG(recalculated.totalFatG());
            // Sinal de qualidade: onde a estimativa erra é o que diz onde melhorá-la.
            analysis.setUserAdjusted(true);
        }

        return ResponseEntity.ok(toView(analyses.save(analysis)));
    }

    /**
     * Ids de catálogo que já constavam na análise.
     *
     * <p>A correção pode manter a ligação que a análise trouxe, mas não criar uma nova: aceitar
     * qualquer id do cliente deixaria a origem do vínculo indistinguível.
     */
    private Set<Integer> knownFoodItemIds(MealPhotoAnalysis analysis) {
        return itemsOf(analysis).stream()
                .map(AnalyzedItem::foodItemId)
                .filter(Objects::nonNull)
                .collect(Collectors.toSet());
    }

    /**
     * Mensagem de limite diário atingido, ou null quando ainda cabe uma chamada de IA hoje.
     *
     * <p>Uma conta só para a foto e para a estimativa por texto, e é decisão de produto: as duas
     * são uma chamada de IA paga por chamada. A contagem sai da própria fila —
     * {@code AnalysisJobs} do tipo {@code MEAL_PHOTO} criados hoje —, o que significa que
     * qualquer caminho novo passa a contar só por gravar o job com esse tipo, sem tabela de uso
     * paralela para manter em sincronia.
     */
    private String mealQuotaError(UUID userId) {
        final var plan = entitlements.get(userId);
        final long usedToday = jobs.countByUserIdAndTypeAndCreatedAtGreaterThanEqual(
                userId, AnalysisJobType.MEAL_PHOTO, startOfToday());

        return usedToday >= plan.maxMealAnalysesPerDay()
                ? plan.limitMessage("análises de refeição", plan.maxMealAnalysesPerDay())
                : null;
    }

    /** A refeição não está no futuro nem além do retroativo permitido. */
    private static boolean isWithinRegistrationWindow(OffsetDateTime when) {
        final OffsetDateTime now = OffsetDateTime.now();
        return !when.isAfter(now.plus(FUTURE_TOLERANCE))
                && !when.isBefore(now.minusDays(MAX_BACKDATE_DAYS));
    }

    /** Início do dia no fuso do servidor — o mesmo corte que o usuário enxerga no diário. */
    private static OffsetDateTime startOfToday() {
        return OffsetDateTime.now().with(LocalTime.MIN);
    }

    private AnalysisView toView(MealPhotoAnalysis analysis) {
        return new AnalysisView(
                analysis.getId(),
                analysis.getAnalysisJobId(),
                analysis.getSource(),
                itemsOf(analysis),
                analysis.getTotalKcal(),
                analysis.getTotalProteinG(),
                analysis.getTotalCarbsG(),
                analysis.getTotalFatG(),
                analysis.isUserAdjusted(),
                analysis.isExcludedFromDiary(),
                photoUrl(analysis.getMediaKey(), analysis),
                photoUrl(analysis.getIllustratedMediaKey(), analysis),
                analysis.getCreatedAt());
    }

    private List<AnalyzedItem> itemsOf(MealPhotoAnalysis analysis) {
        try {
            return MAPPER.readValue(analysis.getItemsJson(), new TypeReference<>() {
            });
        } catch (Exception e) {
            log.warn("ItemsJson ilegível na análise {}: {}", analysis.getId(), e.getMessage());
            return List.of();
        }
    }

    /**
     * URL temporária da foto, ou null quando a retenção já apagou o arquivo — o resultado da
     * análise é preservado mesmo depois de a imagem sumir.
     */
    private String photoUrl(String mediaKey, MealPhotoAnalysis analysis) {
        if (analysis.getMediaExpiredAt() != null || mediaKey == null || mediaKey.isBlank()) {
            return null;
        }
        try {
            return storage.presignedDownloadUrl(mediaKey, PHOTO_URL_TTL);
        } catch (Exception e) {
            // Storage fora do ar não pode derrubar a listagem: os macros continuam úteis.
            log.warn("Falha ao assinar a URL da foto {}: {}", mediaKey, e.getMessage());
            return null;
        }
    }

    private static String toJson(Object value) {
        try {
            return MAPPER.writeValueAsString(value);
        } catch (Exception e) {
            throw new IllegalStateException("Falha ao serializar os itens da refeição.", e);
        }
    }

    public record AdjustRequest(List<AdjustedItem> items, Boolean excludedFromDiary) {
    }

    public record EstimateRequest(String text) {
    }

    /**
     * @param createdAt quando a refeição foi consumida; ausente = agora. Ver
     *     {@link #MAX_BACKDATE_DAYS} para por que o campo existe e até onde ele vai
     */
    public record ManualRequest(List<ManualItem> items, OffsetDateTime createdAt) {
    }

    /**
     * Um item montado pelo usuário.
     *
     * <p>Com {@code foodItemId}, os macros vêm do catálogo e o que o cliente mandou neles é
     * ignorado — inclusive a descrição, que cai para o nome do alimento quando vem em branco.
     * Sem ele, os números do cliente são tudo o que existe, e é assim que o texto digitado à mão
     * e a estimativa por IA entram.
     */
    public record ManualItem(
            String description,
            Integer foodItemId,
            BigDecimal quantityG,
            BigDecimal kcal,
            BigDecimal proteinG,
            BigDecimal carbsG,
            BigDecimal fatG) {

        MealPhotoValidator.LlmDetectedItem toDetected(Map<Integer, FoodItem> catalog) {
            final FoodItem food = foodItemId == null ? null : catalog.get(foodItemId);
            if (food == null) {
                // posX/posY ficam nulos: são a posição do alimento na foto, e aqui não há foto.
                return new MealPhotoValidator.LlmDetectedItem(
                        description, null, quantityG, kcal, proteinG, carbsG, fatG, null, null);
            }

            final FoodPortion portion = FoodPortion.of(food, quantityG);
            return new MealPhotoValidator.LlmDetectedItem(
                    description == null || description.isBlank() ? food.getName() : description,
                    food.getId(),
                    quantityG,
                    portion.kcal(),
                    portion.proteinG(),
                    portion.carbsG(),
                    portion.fatG(),
                    null,
                    null);
        }
    }

    public record AdjustedItem(
            String description,
            Integer foodItemId,
            BigDecimal quantityG,
            BigDecimal kcal,
            BigDecimal proteinG,
            BigDecimal carbsG,
            BigDecimal fatG,
            Integer posX,
            Integer posY) {

        MealPhotoValidator.LlmDetectedItem toDetected() {
            return new MealPhotoValidator.LlmDetectedItem(
                    description, foodItemId, quantityG, kcal, proteinG, carbsG, fatG, posX, posY);
        }
    }

    /**
     * @param analysisJobId null na refeição manual — ela não passou pela fila de IA
     * @param source "Photo" ou "Manual". A tela usa isto para saber se cabe oferecer a foto; a
     *     ausência de {@code photoUrl} não responde a mesma pergunta, porque a retenção de mídia
     *     apaga a imagem de análises antigas e elas continuam sendo análises por foto
     */
    public record AnalysisView(
            UUID id,
            UUID analysisJobId,
            MealSource source,
            List<AnalyzedItem> items,
            BigDecimal totalKcal,
            BigDecimal totalProteinG,
            BigDecimal totalCarbsG,
            BigDecimal totalFatG,
            boolean userAdjusted,
            boolean excludedFromDiary,
            String photoUrl,
            /** Versão anotada pela IA. Null quando não foi pedida ou não pôde ser gerada. */
            String illustratedPhotoUrl,
            OffsetDateTime createdAt) {
    }
}
