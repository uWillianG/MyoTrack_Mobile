package com.myotrack.infrastructure.repository;

import com.myotrack.domain.entity.ProGrant;
import java.time.OffsetDateTime;
import java.util.List;
import java.util.Optional;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;

public interface ProGrantRepository extends JpaRepository<ProGrant, UUID> {

    List<ProGrant> findByUserId(UUID userId);

    /** A pergunta quente: há concessão valendo agora? Roda em toda checagem de limite de IA. */
    boolean existsByUserIdAndExpiresAtAfter(UUID userId, OffsetDateTime moment);

    /**
     * A concessão ativa que dura mais, para a tela de assinatura dizer quando o prêmio acaba.
     *
     * <p>Existe <b>ao lado</b> do exists acima, e não no lugar dele: aquele é a pergunta quente
     * e responder "há alguma?" com uma linha inteira encareceria toda checagem de limite de IA
     * para atender uma tela que quase ninguém abre.
     *
     * <p>A que dura mais, porque podem existir duas — quem fecha as doze semanas já fechou as
     * quatro —, e o prazo que vale é o último a vencer.
     */
    Optional<ProGrant> findFirstByUserIdAndExpiresAtAfterOrderByExpiresAtDesc(
            UUID userId, OffsetDateTime moment);

    boolean existsByUserIdAndMilestone(UUID userId, String milestone);

    /** Usado na exclusão de conta (LGPD). */
    void deleteByUserId(UUID userId);
}
