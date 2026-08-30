package com.myotrack.infrastructure.repository;

import com.myotrack.domain.entity.MealPhotoAnalysis;
import java.time.OffsetDateTime;
import java.util.List;
import java.util.Optional;
import java.util.UUID;
import org.springframework.data.domain.Limit;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;

public interface MealPhotoAnalysisRepository extends JpaRepository<MealPhotoAnalysis, UUID> {

    Optional<MealPhotoAnalysis> findByIdAndUserId(UUID id, UUID userId);

    List<MealPhotoAnalysis> findByUserIdOrderByCreatedAtDesc(UUID userId, Limit limit);

    /**
     * Refeições antigas que ainda têm arquivo no storage — o lote da varredura de retenção.
     *
     * <p>O {@code MediaKey is not null} entrou com a refeição manual. Sem ele, a varredura passa
     * a gastar o lote de 100 com linhas que nunca tiveram foto: elas seriam "expiradas" (nada
     * para apagar, só o carimbo), a foto de verdade ficaria para a próxima passagem, e num
     * usuário que registra mais à mão do que por foto a retenção poderia nunca alcançar as
     * imagens — que é justamente a obrigação que ela existe para cumprir.
     */
    List<MealPhotoAnalysis> findByMediaExpiredAtIsNullAndMediaKeyIsNotNullAndCreatedAtBefore(
            OffsetDateTime cutoff, Limit limit);

    /** Usuários que registraram alguma refeição no diário dentro do intervalo. */
    @Query("""
            select distinct a.userId from MealPhotoAnalysis a
            where a.excludedFromDiary = false and a.createdAt >= :start and a.createdAt < :end
            """)
    List<UUID> findUserIdsWithDiaryActivity(OffsetDateTime start, OffsetDateTime end);

    /** Usado na exclusão de conta (LGPD). */
    void deleteByUserId(UUID userId);
}
