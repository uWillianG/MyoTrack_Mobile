package com.myotrack.infrastructure.repository;

import com.myotrack.domain.entity.CoachConversation;
import java.util.List;
import java.util.Optional;
import java.util.UUID;
import org.springframework.data.domain.Limit;
import org.springframework.data.jpa.repository.JpaRepository;

public interface CoachConversationRepository extends JpaRepository<CoachConversation, UUID> {

    /** As conversas do usuário, da retomada mais recente para a mais antiga. */
    List<CoachConversation> findByUserIdOrderByUpdatedAtDesc(UUID userId, Limit limit);

    /** A conversa aberta agora, quando nenhuma foi escolhida. */
    Optional<CoachConversation> findFirstByUserIdOrderByUpdatedAtDesc(UUID userId);

    /**
     * A conversa pelo id, <b>desde que seja do usuário</b>.
     *
     * <p>O filtro por dono vive na assinatura e não em um {@code if} na chamada: o id vem do
     * cliente, e uma conversa é o registro mais íntimo que o app guarda.
     */
    Optional<CoachConversation> findByIdAndUserId(UUID id, UUID userId);

    void deleteByUserId(UUID userId);
}
