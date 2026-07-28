package com.myotrack.infrastructure.repository;

import com.myotrack.domain.entity.FoodItem;
import org.springframework.data.jpa.repository.JpaRepository;

public interface FoodItemRepository extends JpaRepository<FoodItem, Integer> {

    java.util.List<FoodItem> findByNameContainingIgnoreCase(String fragment);
}
