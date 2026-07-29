package com.myotrack.api.coach;

import com.myotrack.api.billing.EntitlementService;
import com.myotrack.api.security.CurrentUser;
import com.myotrack.domain.AnalysisJobType;
import com.myotrack.domain.JobStatus;
import com.myotrack.domain.entity.AnalysisJob;
import com.myotrack.domain.entity.CoachMessage;
import com.myotrack.infrastructure.repository.AnalysisJobRepository;
import com.myotrack.infrastructure.repository.CoachMessageRepository;
import java.time.LocalTime;
import java.time.OffsetDateTime;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import org.springframework.data.domain.Limit;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

/**
 * Chat com o coach de IA. Porte de MyoTrack.Api/Controllers/CoachController.cs.
 *
 * <p>A resposta roda como job na fila, e não aqui: <b>a chave da API de IA vive só no
 * Worker</b>. O cliente acompanha por {@code /api/jobs/&#123;id&#125;}, como as demais
 * análises — o mesmo caminho que treino, dieta, refeição e vídeo já usam.
 */
@RestController
@RequestMapping("/api/coach")
public class CoachController {

    /** Teto do que o cliente pode mandar. Acima disso é texto colado, não pergunta. */
    private static final int MAX_CONTENT_LENGTH = 2000;

    /** Quantas mensagens a tela carrega de uma vez. */
    private static final Limit HISTORY = Limit.of(50);

    private final CoachMessageRepository messages;
    private final AnalysisJobRepository jobs;
    private final EntitlementService entitlements;

    public CoachController(
            CoachMessageRepository messages,
            AnalysisJobRepository jobs,
            EntitlementService entitlements) {
        this.messages = messages;
        this.jobs = jobs;
        this.entitlements = entitlements;
    }

    /** A conversa, da mais antiga para a mais recente — que é como a tela desenha. */
    @GetMapping("/messages")
    @Transactional(readOnly = true)
    public List<MessageView> list() {
        final List<CoachMessage> recent =
                new ArrayList<>(messages.findByUserIdOrderByCreatedAtDesc(CurrentUser.id(), HISTORY));

        // Busca decrescente para pegar as 50 ÚLTIMAS, e depois inverte: ordenar crescente na
        // consulta traria as 50 primeiras, que é a conversa de meses atrás.
        recent.sort(Comparator.comparing(CoachMessage::getCreatedAt));

        return recent.stream().map(MessageView::from).toList();
    }

    /** Guarda a pergunta e enfileira a resposta. */
    @PostMapping("/messages")
    @Transactional
    public ResponseEntity<?> send(@RequestBody SendRequest request) {
        final UUID userId = CurrentUser.id();

        final String content = request.content() == null ? "" : request.content().trim();
        if (content.isEmpty()) {
            return ResponseEntity.badRequest()
                    .body(Map.of("error", "Escreva uma mensagem para o coach."));
        }
        if (content.length() > MAX_CONTENT_LENGTH) {
            return ResponseEntity.badRequest().body(Map.of(
                    "error",
                    "Mensagem muito longa (máximo %d caracteres).".formatted(MAX_CONTENT_LENGTH)));
        }

        // Uma pergunta por vez: sem esta trava, mandar três seguidas geraria três jobs que
        // responderiam fora de ordem e ainda gastariam três chamadas de LLM.
        final boolean pending = jobs.findAll().stream().anyMatch(j ->
                j.getUserId().equals(userId)
                        && j.getType() == AnalysisJobType.COACH_CHAT
                        && (j.getStatus() == JobStatus.PENDING
                                || j.getStatus() == JobStatus.PROCESSING));
        if (pending) {
            return ResponseEntity.status(HttpStatus.CONFLICT)
                    .body(Map.of("error", "Aguarde a resposta anterior do coach."));
        }

        final var plan = entitlements.get(userId);
        final long usedToday = messages.countByUserIdAndFromUserTrueAndCreatedAtGreaterThanEqual(
                userId, OffsetDateTime.now().with(LocalTime.MIN));

        if (usedToday >= plan.maxCoachMessagesPerDay()) {
            return ResponseEntity.status(HttpStatus.TOO_MANY_REQUESTS).body(Map.of(
                    "error", plan.limitMessage("mensagens ao coach", plan.maxCoachMessagesPerDay())));
        }

        final CoachMessage question = new CoachMessage();
        question.setUserId(userId);
        question.setFromUser(true);
        question.setContent(content);
        messages.save(question);

        final AnalysisJob job = new AnalysisJob();
        job.setUserId(userId);
        job.setType(AnalysisJobType.COACH_CHAT);

        return ResponseEntity.accepted().body(Map.of("jobId", jobs.save(job).getId()));
    }

    public record SendRequest(String content) {
    }

    public record MessageView(
            UUID id, boolean fromUser, String content, OffsetDateTime createdAt) {

        static MessageView from(CoachMessage message) {
            return new MessageView(
                    message.getId(),
                    message.isFromUser(),
                    message.getContent(),
                    message.getCreatedAt());
        }
    }
}
