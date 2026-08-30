package com.myotrack.infrastructure.repository;

import com.myotrack.domain.entity.CoachMessage;
import java.time.OffsetDateTime;
import java.util.List;
import java.util.UUID;
import org.springframework.data.domain.Limit;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;

public interface CoachMessageRepository extends JpaRepository<CoachMessage, UUID> {

    List<CoachMessage> findByUserIdOrderByCreatedAtAsc(UUID userId);

    /** A conversa inteira, em ordem de leitura. */
    List<CoachMessage> findByConversationIdOrderByCreatedAtAsc(UUID conversationId);

    /**
     * As últimas mensagens da conversa.
     *
     * <p>Decrescente porque o que se quer é o <b>fim</b> dela — quem lê ordena de volta. Uma
     * consulta crescente com limite traria o começo, que é a conversa de meses atrás.
     */
    List<CoachMessage> findByConversationIdOrderByCreatedAtDesc(UUID conversationId, Limit limit);

    /**
     * Quantas mensagens cada conversa do usuário tem, numa consulta só.
     *
     * <p>Contar dentro do laço que monta a lista seria uma ida ao banco por conversa — o
     * N+1 clássico, e num endpoint que abre uma tela.
     */
    @Query("""
            select m.conversationId as conversationId, count(m) as total
            from CoachMessage m
            where m.userId = :userId
            group by m.conversationId
            """)
    List<ConversationTotal> countByConversation(UUID userId);

    /** Conta as mensagens do usuário no dia — base do limite diário por plano. */
    long countByUserIdAndFromUserTrueAndCreatedAtGreaterThanEqual(
            UUID userId, OffsetDateTime since);

    void deleteByUserId(UUID userId);

    /** Projeção de {@link #countByConversation(UUID)}. */
    interface ConversationTotal {
        UUID getConversationId();

        long getTotal();
    }
}
