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
 * Um assunto conversado com o coach, do jeito que qualquer chatbot organiza: começo, título e
 * um lugar na lista para voltar depois.
 *
 * <p>Existe porque o fio único não escala com o uso. Perfil, plano e sessões o coach lê do
 * banco a cada resposta; o que ele só tem pela transcrição é <b>o que já foi dito</b> — e numa
 * linha do tempo só, as últimas vinte mensagens que vão para o modelo podem ser inteiramente
 * sobre outro assunto. Separar a conversa é o que faz a pergunta de hoje ser respondida com o
 * contexto de hoje.
 */
@Entity
@Table(name = "CoachConversations")
@Getter
@Setter
public class CoachConversation {

    @Id
    @GeneratedValue
    @Column(name = "Id")
    private UUID id;

    @Column(name = "UserId", nullable = false)
    private UUID userId;

    /**
     * O nome do assunto na lista.
     *
     * <p>Nasce da primeira pergunta, recortada pela API no momento em que a conversa é criada,
     * e o Worker o reescreve na primeira resposta com o título que o modelo deu ao assunto.
     * Ele nunca fica vazio nesse meio-tempo de propósito: a lista é escrita antes de a resposta
     * chegar, e "Nova conversa" repetido três vezes não distingue nada.
     */
    @Column(name = "Title", nullable = false, length = 120)
    private String title;

    @Column(name = "CreatedAt", nullable = false)
    private OffsetDateTime createdAt = OffsetDateTime.now();

    /** A hora da última mensagem — é por ela que a lista ordena. */
    @Column(name = "UpdatedAt", nullable = false)
    private OffsetDateTime updatedAt = OffsetDateTime.now();
}
