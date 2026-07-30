package com.myotrack.infrastructure.repository;

import com.myotrack.domain.entity.DeviceToken;
import java.util.Collection;
import java.util.List;
import java.util.Optional;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;

public interface DeviceTokenRepository extends JpaRepository<DeviceToken, UUID> {

    /**
     * Busca pelo token, sem filtrar por usuário de propósito: é assim que o registro descobre que
     * o aparelho trocou de dono e reatribui a linha em vez de inserir uma segunda.
     */
    Optional<DeviceToken> findByToken(String token);

    /** Para onde notificar este usuário. Vazio é normal — nem todo mundo autoriza push. */
    List<DeviceToken> findByUserId(UUID userId);

    void deleteByToken(String token);

    /** Remoção dos tokens que o provedor recusou definitivamente. */
    void deleteByTokenIn(Collection<String> tokens);

    /** Usada no purge de conta (LGPD): o aparelho não deve receber push de uma conta apagada. */
    void deleteByUserId(UUID userId);
}
