package com.myotrack.infrastructure.repository;

import com.myotrack.domain.entity.Exercise;
import java.util.Optional;
import org.springframework.data.jpa.repository.JpaRepository;

public interface ExerciseRepository extends JpaRepository<Exercise, Integer> {

    Optional<Exercise> findByNameIgnoreCase(String name);
}
