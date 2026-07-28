package com.myotrack.domain.entity;

import com.fasterxml.jackson.annotation.JsonIgnore;
import jakarta.persistence.CascadeType;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.FetchType;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.OneToMany;
import jakarta.persistence.Table;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;
import lombok.Getter;
import lombok.Setter;

@Entity
@Table(name = "Meals")
@Getter
@Setter
public class Meal {

    @Id
    @GeneratedValue
    @Column(name = "Id")
    private UUID id;

    @JsonIgnore
    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "DietPlanId", nullable = false)
    private DietPlan dietPlan;

    @Column(name = "Order", nullable = false)
    private int order;

    /** Ex.: "Café da manhã", "Almoço". */
    @Column(name = "Name", nullable = false)
    private String name;

    @OneToMany(mappedBy = "meal", cascade = CascadeType.ALL, orphanRemoval = true)
    private List<MealItem> items = new ArrayList<>();

    public void addItem(MealItem item) {
        item.setMeal(this);
        items.add(item);
    }
}
