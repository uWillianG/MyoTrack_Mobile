package com.myotrack.domain.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import java.time.OffsetDateTime;
import java.util.UUID;
import lombok.Getter;
import lombok.Setter;

/**
 * Mensagem do chat com o coach IA. O histórico persiste para dar contexto às
 * próximas respostas e sobreviver ao reload da tela.
 */
@Entity
@Table(name = "CoachMessages")
@Getter
@Setter
public class CoachMessage {

    @Id
    @GeneratedValue
    @Column(name = "Id")
    private UUID id;

    /**
     * O dono da mensagem, repetido aqui e não lido pela conversa.
     *
     * <p>Denormalizado de propósito: o limite diário conta as perguntas do usuário no dia
     * <b>somando todas as conversas</b>, e a exclusão de conta apaga por usuário. As duas
     * teriam que passar por um join para responder o que esta coluna responde direto.
     */
    @Column(name = "UserId", nullable = false)
    private UUID userId;

    /** A qual assunto ela pertence — ver {@link CoachConversation}. */
    @Column(name = "ConversationId", nullable = false)
    private UUID conversationId;

    /** True = mensagem do usuário; false = resposta do coach. */
    @Column(name = "FromUser", nullable = false)
    private boolean fromUser;

    @Column(name = "Content", nullable = false, length = 4000)
    private String content;

    @Column(name = "CreatedAt", nullable = false)
    private OffsetDateTime createdAt = OffsetDateTime.now();
}
