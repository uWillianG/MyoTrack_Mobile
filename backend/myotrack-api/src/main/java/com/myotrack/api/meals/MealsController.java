package com.myotrack.api.meals;

import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.myotrack.api.billing.EntitlementService;
import com.myotrack.api.security.CurrentUser;
import com.myotrack.domain.AnalysisJobType;
import com.myotrack.domain.entity.AnalysisJob;
import com.myotrack.domain.entity.MealPhotoAnalysis;
import com.myotrack.domain.service.MealPhotoValidator;
import com.myotrack.domain.service.MealPhotoValidator.AnalyzedItem;
import com.myotrack.domain.service.MealPhotoValidator.AnalyzedMeal;
import com.myotrack.infrastructure.repository.AnalysisJobRepository;
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
import java.util.stream.Collectors;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.data.domain.Limit;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PatchMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RequestPart;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.multipart.MultipartFile;

/**
 * Análise de refeição por foto.
 *
 * <p>A foto sobe <b>multipart pela API</b>, e não direto no storage por URL pré-assinada como o
 * vídeo de exercício: a imagem já chega comprimida pelo app (algumas centenas de KB) e o
 * caminho de uma requisição só evita o estado intermediário de "objeto no bucket que ninguém
 * reclamou" quando o app morre entre o upload e o enfileiramento.
 */
@RestController
@RequestMapping("/api/meals")
public class MealsController {

    private static final Logger log = LoggerFactory.getLogger(MealsController.class);

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

    private final MealPhotoAnalysisRepository analyses;
    private final AnalysisJobRepository jobs;
    private final MediaStorage storage;
    private final EntitlementService entitlements;

    public MealsController(
            MealPhotoAnalysisRepository analyses,
            AnalysisJobRepository jobs,
            MediaStorage storage,
            EntitlementService entitlements) {
        this.analyses = analyses;
        this.jobs = jobs;
        this.storage = storage;
        this.entitlements = entitlements;
    }

    /**
     * Recebe a foto e enfileira a análise; o cliente acompanha por {@code /api/jobs/&#123;id&#125;}.
     */
    @PostMapping("/analyze")
    @Transactional
    public ResponseEntity<?> analyze(@RequestPart("file") MultipartFile file) {
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

        final var plan = entitlements.get(userId);
        final long usedToday = jobs.countByUserIdAndTypeAndCreatedAtGreaterThanEqual(
                userId, AnalysisJobType.MEAL_PHOTO, startOfToday());

        if (usedToday >= plan.maxMealAnalysesPerDay()) {
            // 429 é o que o app reconhece como limite atingido para oferecer o Pro.
            return ResponseEntity.status(HttpStatus.TOO_MANY_REQUESTS).body(Map.of(
                    "error",
                    plan.limitMessage("análises de refeição", plan.maxMealAnalysesPerDay())));
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
        job.setInputJson("{\"contentType\":\"%s\"}".formatted(normalizedType));

        return ResponseEntity.accepted().body(Map.of("jobId", jobs.save(job).getId()));
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
    @PatchMapping("/{id}")
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

    /** Início do dia no fuso do servidor — o mesmo corte que o usuário enxerga no diário. */
    private static OffsetDateTime startOfToday() {
        return OffsetDateTime.now().with(LocalTime.MIN);
    }

    private AnalysisView toView(MealPhotoAnalysis analysis) {
        return new AnalysisView(
                analysis.getId(),
                analysis.getAnalysisJobId(),
                itemsOf(analysis),
                analysis.getTotalKcal(),
                analysis.getTotalProteinG(),
                analysis.getTotalCarbsG(),
                analysis.getTotalFatG(),
                analysis.isUserAdjusted(),
                analysis.isExcludedFromDiary(),
                photoUrl(analysis),
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
    private String photoUrl(MealPhotoAnalysis analysis) {
        if (analysis.getMediaExpiredAt() != null || analysis.getMediaKey() == null) {
            return null;
        }
        try {
            return storage.presignedDownloadUrl(analysis.getMediaKey(), PHOTO_URL_TTL);
        } catch (Exception e) {
            // Storage fora do ar não pode derrubar a listagem: os macros continuam úteis.
            log.warn("Falha ao assinar a URL da foto {}: {}", analysis.getMediaKey(), e.getMessage());
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

    public record AdjustedItem(
            String description,
            Integer foodItemId,
            BigDecimal quantityG,
            BigDecimal kcal,
            BigDecimal proteinG,
            BigDecimal carbsG,
            BigDecimal fatG) {

        MealPhotoValidator.LlmDetectedItem toDetected() {
            return new MealPhotoValidator.LlmDetectedItem(
                    description, foodItemId, quantityG, kcal, proteinG, carbsG, fatG);
        }
    }

    public record AnalysisView(
            UUID id,
            UUID analysisJobId,
            List<AnalyzedItem> items,
            BigDecimal totalKcal,
            BigDecimal totalProteinG,
            BigDecimal totalCarbsG,
            BigDecimal totalFatG,
            boolean userAdjusted,
            boolean excludedFromDiary,
            String photoUrl,
            OffsetDateTime createdAt) {
    }
}
