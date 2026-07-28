package com.myotrack.domain.entity;

import com.fasterxml.jackson.annotation.JsonIgnore;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.FetchType;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.Table;
import java.math.BigDecimal;
import java.util.UUID;
import lombok.Getter;
import lombok.Setter;

@Entity
@Table(name = "MealItems")
@Getter
@Setter
public class MealItem {

    @Id
    @GeneratedValue
    @Column(name = "Id")
    private UUID id;

    @JsonIgnore
    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "MealId", nullable = false)
    private Meal meal;

    @ManyToOne(fetch = FetchType.EAGER, optional = false)
    @JoinColumn(name = "FoodItemId", nullable = false)
    private FoodItem foodItem;

    @Column(name = "QuantityG", nullable = false)
    private BigDecimal quantityG;

    public Integer getFoodItemId() {
        return foodItem == null ? null : foodItem.getId();
    }
}
