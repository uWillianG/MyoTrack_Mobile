package com.myotrack.infrastructure.repository;

import com.myotrack.domain.PlanStatus;
import com.myotrack.domain.entity.DietPlan;
import java.util.List;
import java.util.Optional;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;

public interface DietPlanRepository extends JpaRepository<DietPlan, UUID> {

    Optional<DietPlan> findFirstByUserIdAndStatusOrderByCreatedAtDesc(
            UUID userId, PlanStatus status);

    List<DietPlan> findByUserIdOrderByCreatedAtDesc(UUID userId);

    List<DietPlan> findByStatus(PlanStatus status);

    void deleteByUserId(UUID userId);
}
