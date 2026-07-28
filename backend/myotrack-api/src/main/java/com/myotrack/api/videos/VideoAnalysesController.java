package com.myotrack.api.videos;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.myotrack.api.billing.EntitlementService;
import com.myotrack.api.security.CurrentUser;
import com.myotrack.domain.AnalysisJobType;
import com.myotrack.domain.VideoExercise;
import com.myotrack.domain.entity.AnalysisJob;
import com.myotrack.domain.entity.ExerciseVideoAnalysis;
import com.myotrack.infrastructure.repository.AnalysisJobRepository;
import com.myotrack.infrastructure.repository.ExerciseVideoAnalysisRepository;
import com.myotrack.infrastructure.storage.MediaStorage;
import com.myotrack.infrastructure.storage.StoredObjectInfo;
import com.fasterxml.jackson.databind.JsonNode;
import java.time.Duration;
import java.time.LocalTime;
import java.time.OffsetDateTime;
import java.util.Arrays;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.UUID;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.data.domain.Limit;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

/**
 * Análise de execução de exercício por vídeo.
 *
 * <p>Em dois passos, ao contrário da foto de refeição: o cliente pede uma <b>URL pré-assinada</b>
 * e sobe o arquivo direto no storage, e só depois avisa a API. Vídeo de série passa de dezenas
 * de MB — atravessá-lo pela API ocuparia uma thread do Tomcat por minutos e faria o upload
 * competir com todo o resto do tráfego, além de esbarrar no limite de multipart.
 */
@RestController
@RequestMapping("/api/video-analyses")
public class VideoAnalysesController {

    private static final Logger log = LoggerFactory.getLogger(VideoAnalysesController.class);

    private static final ObjectMapper MAPPER = new ObjectMapper();

    private static final Set<String> ALLOWED_CONTENT_TYPES =
            Set.of("video/mp4", "video/quicktime");

    private static final Map<String, String> EXTENSIONS =
            Map.of("video/mp4", ".mp4", "video/quicktime", ".mov");

    /** Janela para o cliente subir o arquivo. Generosa: vídeo grande em rede móvel demora. */
    private static final Duration UPLOAD_URL_TTL = Duration.ofMinutes(30);

    /** Tempo de vida das URLs de leitura (vídeo original e overlay). */
    private static final Duration PLAYBACK_URL_TTL = Duration.ofMinutes(30);

    private static final long MAX_VIDEO_BYTES = 200L * 1024 * 1024;

    private static final int DEFAULT_LIMIT = 20;
    private static final int MAX_LIMIT = 100;

    private final ExerciseVideoAnalysisRepository analyses;
    private final AnalysisJobRepository jobs;
    private final MediaStorage storage;
    private final EntitlementService entitlements;

    public VideoAnalysesController(
            ExerciseVideoAnalysisRepository analyses,
            AnalysisJobRepository jobs,
            MediaStorage storage,
            EntitlementService entitlements) {
        this.analyses = analyses;
        this.jobs = jobs;
        this.storage = storage;
        this.entitlements = entitlements;
    }

    /**
     * Passo 1: reserva a chave e devolve a URL de upload.
     *
     * <p>O limite diário é conferido aqui e de novo no passo 2. Aqui para não deixar o usuário
     * subir 80 MB antes de descobrir que não pode; e no passo 2 porque é lá que o job nasce, e
     * entre um passo e outro cabe outra análise.
     */
    @PostMapping("/presign")
    public ResponseEntity<?> uploadUrl(@RequestBody UploadUrlRequest request) {
        final UUID userId = CurrentUser.id();

        final String contentType =
                request.contentType() == null ? "" : request.contentType().toLowerCase();
        if (!ALLOWED_CONTENT_TYPES.contains(contentType)) {
            return ResponseEntity.badRequest()
                    .body(Map.of("error", "Envie um vídeo em MP4 ou MOV."));
        }

        final ResponseEntity<?> denied = checkDailyLimit(userId);
        if (denied != null) {
            return denied;
        }

        final String mediaKey = "videos/%s/%s%s".formatted(
                userId, UUID.randomUUID(), EXTENSIONS.get(contentType));

        try {
            return ResponseEntity.ok(new UploadUrlView(
                    mediaKey,
                    storage.presignedUploadUrl(mediaKey, contentType, UPLOAD_URL_TTL),
                    UPLOAD_URL_TTL.toSeconds()));
        } catch (Exception e) {
            log.error("Falha ao assinar o upload de vídeo do usuário {}.", userId, e);
            return ResponseEntity.status(HttpStatus.BAD_GATEWAY)
                    .body(Map.of("error", "Não foi possível preparar o envio. Tente de novo."));
        }
    }

    /** Passo 2: confirma que o arquivo chegou e enfileira a análise. */
    @PostMapping
    @Transactional
    public ResponseEntity<?> analyze(@RequestBody AnalyzeRequest request) {
        final UUID userId = CurrentUser.id();

        final String mediaKey = request.mediaKey() == null ? "" : request.mediaKey();
        // A chave é do cliente, então precisa ser confinada à pasta dele — sem isto, mandar
        // "videos/<outro-usuário>/..." poria o vídeo alheio na fila da própria conta.
        if (!mediaKey.startsWith("videos/%s/".formatted(userId))) {
            return ResponseEntity.badRequest()
                    .body(Map.of("error", "Envio inválido. Comece de novo."));
        }

        // Validar contra a lista fechada aqui, e não deixar o serviço de visão recusar depois,
        // é o que impede o usuário de subir 80 MB para receber "exercício não suportado".
        final VideoExercise exercise = VideoExercise.bySlug(
                request.exercise() == null ? null : request.exercise().trim()).orElse(null);
        if (exercise == null) {
            return ResponseEntity.badRequest()
                    .body(Map.of("error", "Escolha um exercício da lista para analisar."));
        }

        final ResponseEntity<?> denied = checkDailyLimit(userId);
        if (denied != null) {
            return denied;
        }

        // Confirma que o PUT pré-assinado realmente aconteceu. Sem isto, um app que morreu no
        // meio do upload criaria um job que o worker só descobriria vazio minutos depois.
        final StoredObjectInfo info = objectInfo(mediaKey);
        if (info == null) {
            return ResponseEntity.badRequest()
                    .body(Map.of("error", "O vídeo não chegou. Tente enviar de novo."));
        }
        if (info.sizeBytes() > MAX_VIDEO_BYTES) {
            return ResponseEntity.badRequest().body(Map.of(
                    "error", "O vídeo passa de 200 MB. Grave um trecho mais curto."));
        }

        final AnalysisJob job = new AnalysisJob();
        job.setUserId(userId);
        job.setType(AnalysisJobType.EXERCISE_VIDEO);
        job.setMediaKey(mediaKey);
        job.setInputJson("{\"exercise\":\"%s\"}".formatted(exercise.slug()));

        return ResponseEntity.accepted().body(Map.of("jobId", jobs.save(job).getId()));
    }

    /**
     * Exercícios que o serviço de visão sabe avaliar.
     *
     * <p>A tela monta a lista a partir daqui em vez de embutir os slugs no app: um exercício
     * novo no serviço passa a aparecer sem publicar versão nova nas lojas.
     */
    @GetMapping("/supported-exercises")
    public List<ExerciseOption> exercises() {
        return Arrays.stream(VideoExercise.values())
                .map(e -> new ExerciseOption(e.slug(), e.label()))
                .toList();
    }

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

    /** Devolve a resposta de recusa, ou null quando ainda há cota. */
    private ResponseEntity<?> checkDailyLimit(UUID userId) {
        final var plan = entitlements.get(userId);
        final long usedToday = jobs.countByUserIdAndTypeAndCreatedAtGreaterThanEqual(
                userId, AnalysisJobType.EXERCISE_VIDEO, OffsetDateTime.now().with(LocalTime.MIN));

        if (usedToday < plan.maxVideoAnalysesPerDay()) {
            return null;
        }
        return ResponseEntity.status(HttpStatus.TOO_MANY_REQUESTS).body(Map.of(
                "error",
                plan.limitMessage("análises de vídeo", plan.maxVideoAnalysesPerDay())));
    }

    private StoredObjectInfo objectInfo(String mediaKey) {
        try {
            return storage.objectInfo(mediaKey);
        } catch (Exception e) {
            log.warn("Falha ao consultar o vídeo {}: {}", mediaKey, e.getMessage());
            return null;
        }
    }

    private AnalysisView toView(ExerciseVideoAnalysis analysis) {
        final boolean mediaAlive = analysis.getMediaExpiredAt() == null;

        return new AnalysisView(
                analysis.getId(),
                analysis.getAnalysisJobId(),
                analysis.getAnalyzedExercise(),
                analysis.getScore(),
                analysis.getRepCount(),
                readResult(analysis),
                mediaAlive ? playbackUrl(analysis.getMediaKey()) : null,
                mediaAlive ? playbackUrl(analysis.getOverlayVideoKey()) : null,
                analysis.getCreatedAt());
    }

    /**
     * O resultado vai como objeto, não como string de JSON: as heurísticas do serviço de visão
     * evoluem, e repassar a árvore deixa campos novos chegarem ao cliente sem mexer aqui.
     */
    private JsonNode readResult(ExerciseVideoAnalysis analysis) {
        try {
            return MAPPER.readTree(analysis.getResultJson());
        } catch (Exception e) {
            log.warn("ResultJson ilegível na análise {}: {}", analysis.getId(), e.getMessage());
            return MAPPER.createObjectNode();
        }
    }

    private String playbackUrl(String mediaKey) {
        if (mediaKey == null || mediaKey.isBlank()) {
            return null;
        }
        try {
            return storage.presignedDownloadUrl(mediaKey, PLAYBACK_URL_TTL);
        } catch (Exception e) {
            log.warn("Falha ao assinar a URL do vídeo {}: {}", mediaKey, e.getMessage());
            return null;
        }
    }

    public record UploadUrlRequest(String contentType) {
    }

    public record UploadUrlView(String mediaKey, String uploadUrl, long expiresInSeconds) {
    }

    public record AnalyzeRequest(String mediaKey, String exercise) {
    }

    public record ExerciseOption(String slug, String label) {
    }

    public record AnalysisView(
            UUID id,
            UUID analysisJobId,
            String analyzedExercise,
            Integer score,
            int repCount,
            JsonNode result,
            String videoUrl,
            String overlayVideoUrl,
            OffsetDateTime createdAt) {
    }
}
