package com.myotrack.api.coach;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.tuple;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import com.myotrack.api.billing.EntitlementService;
import com.myotrack.api.billing.EntitlementService.Entitlements;
import com.myotrack.domain.AnalysisJobType;
import com.myotrack.domain.SubscriptionPlanType;
import com.myotrack.domain.entity.AnalysisJob;
import com.myotrack.domain.entity.CoachConversation;
import com.myotrack.domain.entity.CoachMessage;
import com.myotrack.infrastructure.repository.AnalysisJobRepository;
import com.myotrack.infrastructure.repository.CoachConversationRepository;
import com.myotrack.infrastructure.repository.CoachMessageRepository;
import java.time.OffsetDateTime;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.UUID;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.mockito.ArgumentCaptor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.security.oauth2.server.resource.authentication.JwtAuthenticationToken;

/**
 * O chat do coach dividido em conversas.
 *
 * <p>O que se testa aqui é o que a divisão trouxe de novo e o que ela quase quebrou: de qual
 * conversa a pergunta é, quem pode abrir e apagar uma, e a cota do dia — que passou a ser
 * contada pelos jobs justamente porque agora existe um botão que apaga mensagens.
 */
class CoachControllerTest {

    private static final UUID USER_ID = UUID.fromString("11111111-1111-1111-1111-111111111111");

    private CoachMessageRepository messages;
    private CoachConversationRepository conversations;
    private AnalysisJobRepository jobs;
    private CoachController controller;

    @BeforeEach
    void setUp() {
        messages = mock(CoachMessageRepository.class);
        conversations = mock(CoachConversationRepository.class);
        jobs = mock(AnalysisJobRepository.class);
        final EntitlementService entitlements = mock(EntitlementService.class);
        controller = new CoachController(messages, conversations, jobs, entitlements);

        final Jwt jwt = Jwt.withTokenValue("t")
                .header("alg", "none")
                .subject(USER_ID.toString())
                .build();
        SecurityContextHolder.getContext()
                .setAuthentication(new JwtAuthenticationToken(jwt, List.of()));

        // Caminho livre por padrão; cada teste fecha a porta que quer exercitar.
        when(entitlements.get(any()))
                .thenReturn(new Entitlements(SubscriptionPlanType.FREE, 3, 1, 5, false));
        when(jobs.findAll()).thenReturn(List.of());
        when(jobs.countByUserIdAndTypeAndCreatedAtGreaterThanEqual(any(), any(), any()))
                .thenReturn(0L);

        // Os repositórios reais atribuem o id no save (@GeneratedValue); os mocks imitam isso,
        // senão o teste veria um id nulo onde a produção devolve um de verdade.
        when(jobs.save(any())).thenAnswer(invocation -> {
            final AnalysisJob job = invocation.getArgument(0);
            job.setId(UUID.randomUUID());
            return job;
        });
        when(conversations.save(any())).thenAnswer(invocation -> {
            final CoachConversation conversation = invocation.getArgument(0);
            if (conversation.getId() == null) {
                conversation.setId(UUID.randomUUID());
            }
            return conversation;
        });
        when(messages.save(any())).thenAnswer(invocation -> {
            final CoachMessage message = invocation.getArgument(0);
            message.setId(UUID.randomUUID());
            return message;
        });
    }

    @AfterEach
    void tearDown() {
        SecurityContextHolder.clearContext();
    }

    @Test
    @DisplayName("pergunta sem id abre uma conversa nova, batizada com a própria pergunta")
    void opensAConversation() {
        final ResponseEntity<?> response = controller.send(
                new CoachController.SendRequest("Posso treinar com dor no ombro?", null));

        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.ACCEPTED);

        final ArgumentCaptor<CoachConversation> saved =
                ArgumentCaptor.forClass(CoachConversation.class);
        verify(conversations).save(saved.capture());
        assertThat(saved.getValue().getUserId()).isEqualTo(USER_ID);
        assertThat(saved.getValue().getTitle()).isEqualTo("Posso treinar com dor no ombro?");

        // A pergunta e o job precisam apontar para a mesma conversa: é o que o Worker lê para
        // saber onde responder, e o que a tela usa para abrir o fio certo.
        final UUID conversationId = saved.getValue().getId();
        final ArgumentCaptor<CoachMessage> question = ArgumentCaptor.forClass(CoachMessage.class);
        verify(messages).save(question.capture());
        assertThat(question.getValue().getConversationId()).isEqualTo(conversationId);
        assertThat(question.getValue().isFromUser()).isTrue();

        final ArgumentCaptor<AnalysisJob> job = ArgumentCaptor.forClass(AnalysisJob.class);
        verify(jobs).save(job.capture());
        assertThat(job.getValue().getType()).isEqualTo(AnalysisJobType.COACH_CHAT);
        assertThat(job.getValue().getInputJson())
                .isEqualTo("{\"conversationId\":\"%s\"}".formatted(conversationId));

        assertThat(response.getBody()).isInstanceOfSatisfying(Map.class, body ->
                assertThat(body.get("conversationId")).isEqualTo(conversationId));
    }

    @Test
    @DisplayName("o título longo é recortado — a lista tem uma linha por conversa")
    void trimsTheTitle() {
        controller.send(new CoachController.SendRequest(
                "Estou com uma dúvida sobre a progressão de carga no agachamento livre "
                        + "depois da lesão do ano passado, o que você acha?",
                null));

        final ArgumentCaptor<CoachConversation> saved =
                ArgumentCaptor.forClass(CoachConversation.class);
        verify(conversations).save(saved.capture());

        assertThat(saved.getValue().getTitle())
                .hasSize(61)
                .endsWith("…")
                .startsWith("Estou com uma dúvida sobre a progressão de carga no");
    }

    @Test
    @DisplayName("pergunta com id continua a conversa, sem criar outra")
    void continuesTheChosenConversation() {
        final CoachConversation existing = conversation("Dor no ombro");
        when(conversations.findByIdAndUserId(existing.getId(), USER_ID))
                .thenReturn(Optional.of(existing));

        final OffsetDateTime before = existing.getUpdatedAt();
        controller.send(new CoachController.SendRequest("E amanhã posso?", existing.getId()));

        final ArgumentCaptor<CoachConversation> saved =
                ArgumentCaptor.forClass(CoachConversation.class);
        verify(conversations).save(saved.capture());

        // A mesma conversa, com o título intocado: quem nomeia é a primeira pergunta.
        assertThat(saved.getValue()).isSameAs(existing);
        assertThat(saved.getValue().getTitle()).isEqualTo("Dor no ombro");
        // E ela sobe para o topo da lista, que ordena por "quando foi retomada".
        assertThat(saved.getValue().getUpdatedAt()).isAfterOrEqualTo(before);

        final ArgumentCaptor<CoachMessage> question = ArgumentCaptor.forClass(CoachMessage.class);
        verify(messages).save(question.capture());
        assertThat(question.getValue().getConversationId()).isEqualTo(existing.getId());
    }

    @Test
    @DisplayName("conversa de outra pessoa não recebe pergunta")
    void refusesSomeoneElsesConversation() {
        final UUID alheia = UUID.randomUUID();
        when(conversations.findByIdAndUserId(alheia, USER_ID)).thenReturn(Optional.empty());

        final ResponseEntity<?> response =
                controller.send(new CoachController.SendRequest("Oi?", alheia));

        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.NOT_FOUND);
        verify(messages, never()).save(any());
        verify(jobs, never()).save(any());
    }

    @Test
    @DisplayName("a cota do dia conta jobs, e não mensagens que podem ser apagadas")
    void countsJobsAndNotMessages() {
        // Cinco perguntas hoje, e o plano Free permite cinco.
        when(jobs.countByUserIdAndTypeAndCreatedAtGreaterThanEqual(
                eq(USER_ID), eq(AnalysisJobType.COACH_CHAT), any()))
                .thenReturn(5L);

        final ResponseEntity<?> response =
                controller.send(new CoachController.SendRequest("Mais uma?", null));

        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.TOO_MANY_REQUESTS);
        verify(jobs, never()).save(any());
        // O ponto do teste: apagar a conversa não pode devolver a cota. Se a contagem voltar a
        // sair das mensagens gravadas, esta verificação cai junto.
        verify(messages, never())
                .countByUserIdAndFromUserTrueAndCreatedAtGreaterThanEqual(any(), any());
    }

    @Test
    @DisplayName("apagar conversa de outra pessoa não apaga nada")
    void refusesToDeleteSomeoneElsesConversation() {
        final UUID alheia = UUID.randomUUID();
        when(conversations.findByIdAndUserId(alheia, USER_ID)).thenReturn(Optional.empty());

        assertThat(controller.delete(alheia).getStatusCode()).isEqualTo(HttpStatus.NOT_FOUND);
        verify(conversations, never()).delete(any());
    }

    @Test
    @DisplayName("a lista traz quantas mensagens cada conversa tem")
    void listsConversationsWithTotals() {
        final CoachConversation comFala = conversation("Dor no ombro");
        final CoachConversation semFala = conversation("Dieta de corte");
        when(conversations.findByUserIdOrderByUpdatedAtDesc(any(), any()))
                .thenReturn(List.of(comFala, semFala));
        when(messages.countByConversation(USER_ID))
                .thenReturn(List.of(new Total(comFala.getId(), 6)));

        final List<CoachController.ConversationView> view = controller.conversations();

        assertThat(view).extracting(
                        CoachController.ConversationView::title,
                        CoachController.ConversationView::messages)
                // Zero e não nulo para a conversa que a contagem não devolveu: a tela escreve
                // esse número, e um nulo ali sairia como "null mensagens".
                .containsExactly(tuple("Dor no ombro", 6L), tuple("Dieta de corte", 0L));
    }

    private static CoachConversation conversation(String title) {
        final CoachConversation conversation = new CoachConversation();
        conversation.setId(UUID.randomUUID());
        conversation.setUserId(USER_ID);
        conversation.setTitle(title);
        conversation.setUpdatedAt(OffsetDateTime.now().minusDays(1));
        return conversation;
    }

    /** A projeção que o {@code group by} do repositório devolve. */
    private record Total(UUID conversationId, long total)
            implements CoachMessageRepository.ConversationTotal {

        @Override
        public UUID getConversationId() {
            return conversationId;
        }

        @Override
        public long getTotal() {
            return total;
        }
    }
}
