package com.myotrack.api.coach;

import com.myotrack.api.billing.EntitlementService;
import com.myotrack.api.security.CurrentUser;
import com.myotrack.domain.AnalysisJobType;
import com.myotrack.domain.JobStatus;
import com.myotrack.domain.entity.AnalysisJob;
import com.myotrack.domain.entity.CoachConversation;
import com.myotrack.domain.entity.CoachMessage;
import com.myotrack.infrastructure.repository.AnalysisJobRepository;
import com.myotrack.infrastructure.repository.CoachConversationRepository;
import com.myotrack.infrastructure.repository.CoachMessageRepository;
import java.time.LocalTime;
import java.time.OffsetDateTime;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.UUID;
import org.springframework.data.domain.Limit;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
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
 *
 * <p><b>A conversa é a unidade, e não a mensagem.</b> Cada pergunta entra numa
 * {@link CoachConversation}, que é o que a tela lista, abre e apaga — a organização de
 * qualquer chatbot, e a única que sobrevive ao segundo mês de uso.
 */
@RestController
@RequestMapping("/api/coach")
public class CoachController {

    /** Teto do que o cliente pode mandar. Acima disso é texto colado, não pergunta. */
    private static final int MAX_CONTENT_LENGTH = 2000;

    /** Quantas conversas a lista carrega. Além disso é rolagem que ninguém faz. */
    private static final Limit CONVERSATIONS = Limit.of(50);

    /**
     * Teto de mensagens de uma conversa aberta.
     *
     * <p>Conversa é um assunto, e assunto acaba — o teto existe para o caso patológico de
     * alguém tratar um fio como diário, não para cortar uso normal. Vem alto de propósito:
     * cortar por baixo faria a tela perder o começo do assunto, que é justamente o que a
     * separação por conversa veio consertar.
     */
    private static final Limit MESSAGES = Limit.of(200);

    /** Quanto do título cabe numa linha da lista sem virar parágrafo. */
    private static final int TITLE_LENGTH = 60;

    private final CoachMessageRepository messages;
    private final CoachConversationRepository conversations;
    private final AnalysisJobRepository jobs;
    private final EntitlementService entitlements;

    public CoachController(
            CoachMessageRepository messages,
            CoachConversationRepository conversations,
            AnalysisJobRepository jobs,
            EntitlementService entitlements) {
        this.messages = messages;
        this.conversations = conversations;
        this.jobs = jobs;
        this.entitlements = entitlements;
    }

    /** O histórico: as conversas do usuário, da mais recente para a mais antiga. */
    @GetMapping("/conversations")
    @Transactional(readOnly = true)
    public List<ConversationView> conversations() {
        final UUID userId = CurrentUser.id();

        final Map<UUID, Long> totals = new HashMap<>();
        messages.countByConversation(userId)
                .forEach(total -> totals.put(total.getConversationId(), total.getTotal()));

        return conversations.findByUserIdOrderByUpdatedAtDesc(userId, CONVERSATIONS).stream()
                .map(conversation -> ConversationView.from(
                        conversation, totals.getOrDefault(conversation.getId(), 0L)))
                .toList();
    }

    /**
     * A conversa aberta, da mais antiga para a mais recente — que é como a tela desenha.
     *
     * <p>Responde 404 tanto para conversa inexistente quanto para conversa de outro usuário:
     * a mesma resposta para os dois casos, para o id não virar um jeito de descobrir que
     * alguém existe.
     */
    @GetMapping("/conversations/{id}/messages")
    @Transactional(readOnly = true)
    public ResponseEntity<List<MessageView>> messages(@PathVariable UUID id) {
        return conversations.findByIdAndUserId(id, CurrentUser.id())
                .map(conversation -> ResponseEntity.ok(messagesOf(conversation.getId())))
                .orElseGet(() -> ResponseEntity.notFound().build());
    }

    /**
     * A conversa corrente — a última que teve movimento.
     *
     * <p>Continua existindo para as versões do app anteriores às conversas separadas: elas
     * pedem esta rota e não sabem passar id. Para elas o mundo segue como era, um fio só, que
     * agora é o fio mais recente.
     */
    @GetMapping("/messages")
    @Transactional(readOnly = true)
    public List<MessageView> list() {
        return conversations.findFirstByUserIdOrderByUpdatedAtDesc(CurrentUser.id())
                .map(conversation -> messagesOf(conversation.getId()))
                .orElseGet(List::of);
    }

    /** Apaga a conversa e, por cascata no banco, o que foi dito nela. */
    @DeleteMapping("/conversations/{id}")
    @Transactional
    public ResponseEntity<Void> delete(@PathVariable UUID id) {
        final Optional<CoachConversation> found =
                conversations.findByIdAndUserId(id, CurrentUser.id());
        if (found.isEmpty()) {
            return ResponseEntity.notFound().build();
        }

        conversations.delete(found.get());
        return ResponseEntity.noContent().build();
    }

    /**
     * Guarda a pergunta e enfileira a resposta.
     *
     * <p>Sem {@code conversationId} a pergunta abre uma conversa nova. É o que faz o botão de
     * nova conversa não precisar de rota própria: conversa vazia nunca é criada, e por isso
     * não existe linha sem nada dentro na lista de ninguém.
     */
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

        // Uma pergunta por vez, e vale para o usuário e não para a conversa: sem esta trava,
        // abrir três conversas e perguntar em todas geraria três jobs que responderiam fora de
        // ordem e ainda gastariam três chamadas de LLM.
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
        // O gasto do dia sai dos JOBS, e não das mensagens gravadas. Desde que a tela apaga
        // conversas, contar mensagens devolveria a cota a quem apagasse o que perguntou — e a
        // chamada ao modelo, essa, já foi paga.
        final long usedToday = jobs.countByUserIdAndTypeAndCreatedAtGreaterThanEqual(
                userId, AnalysisJobType.COACH_CHAT, OffsetDateTime.now().with(LocalTime.MIN));

        if (usedToday >= plan.maxCoachMessagesPerDay()) {
            return ResponseEntity.status(HttpStatus.TOO_MANY_REQUESTS).body(Map.of(
                    "error", plan.limitMessage("mensagens ao coach", plan.maxCoachMessagesPerDay())));
        }

        final Optional<CoachConversation> chosen = request.conversationId() == null
                ? Optional.empty()
                : conversations.findByIdAndUserId(request.conversationId(), userId);
        if (request.conversationId() != null && chosen.isEmpty()) {
            return ResponseEntity.notFound().build();
        }

        final CoachConversation conversation =
                chosen.orElseGet(() -> newConversation(userId, content));
        conversation.setUpdatedAt(OffsetDateTime.now());
        conversations.save(conversation);

        final CoachMessage question = new CoachMessage();
        question.setUserId(userId);
        question.setConversationId(conversation.getId());
        question.setFromUser(true);
        question.setContent(content);
        messages.save(question);

        final AnalysisJob job = new AnalysisJob();
        job.setUserId(userId);
        job.setType(AnalysisJobType.COACH_CHAT);
        // Em qual conversa responder. Sem isto o Worker teria que deduzir pela mensagem mais
        // recente do usuário, e deduziria errado no dia em que duas perguntas se cruzassem.
        job.setInputJson("{\"conversationId\":\"%s\"}".formatted(conversation.getId()));

        return ResponseEntity.accepted().body(Map.of(
                "jobId", jobs.save(job).getId(),
                "conversationId", conversation.getId()));
    }

    private List<MessageView> messagesOf(UUID conversationId) {
        final List<CoachMessage> recent = new ArrayList<>(
                messages.findByConversationIdOrderByCreatedAtDesc(conversationId, MESSAGES));

        // Busca decrescente para pegar as ÚLTIMAS, e depois inverte: ordenar crescente na
        // consulta traria as primeiras, que é o começo da conversa e não o fim dela.
        recent.sort(Comparator.comparing(CoachMessage::getCreatedAt));

        return recent.stream().map(MessageView::from).toList();
    }

    private CoachConversation newConversation(UUID userId, String firstQuestion) {
        final CoachConversation conversation = new CoachConversation();
        conversation.setUserId(userId);
        conversation.setTitle(titleFrom(firstQuestion));
        return conversation;
    }

    /**
     * O título provisório: a própria pergunta, numa linha e recortada.
     *
     * <p>O Worker o troca pelo assunto que o modelo entendeu assim que a primeira resposta
     * fica pronta. Até lá a lista precisa de um nome de verdade — "Nova conversa" repetido
     * três vezes seria o mesmo que não ter lista.
     */
    private static String titleFrom(String question) {
        final String line = question.replaceAll("\\s+", " ").trim();
        return line.length() <= TITLE_LENGTH
                ? line
                : line.substring(0, TITLE_LENGTH).trim() + "…";
    }

    public record SendRequest(String content, UUID conversationId) {
    }

    public record ConversationView(
            UUID id, String title, OffsetDateTime updatedAt, long messages) {

        static ConversationView from(CoachConversation conversation, long messages) {
            return new ConversationView(
                    conversation.getId(),
                    conversation.getTitle(),
                    conversation.getUpdatedAt(),
                    messages);
        }
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
