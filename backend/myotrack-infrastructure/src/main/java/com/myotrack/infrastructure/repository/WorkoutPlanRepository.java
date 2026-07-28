package com.myotrack.infrastructure.repository;

import com.myotrack.domain.PlanStatus;
import com.myotrack.domain.entity.WorkoutPlan;
import java.util.List;
import java.util.Optional;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;

public interface WorkoutPlanRepository extends JpaRepository<WorkoutPlan, UUID> {

    Optional<WorkoutPlan> findFirstByUserIdAndStatusOrderByCreatedAtDesc(
            UUID userId, PlanStatus status);

    List<WorkoutPlan> findByUserIdOrderByCreatedAtDesc(UUID userId);

    List<WorkoutPlan> findByStatus(PlanStatus status);

    void deleteByUserId(UUID userId);
}
