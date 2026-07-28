package com.myotrack.domain.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import java.math.BigDecimal;
import lombok.Getter;
import lombok.Setter;

/** Catálogo nutricional (valores por 100 g). Fonte primária: TACO/TBCA. */
@Entity
@Table(name = "FoodItems")
@Getter
@Setter
public class FoodItem {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "Id")
    private Integer id;

    @Column(name = "Name", nullable = false, length = 300)
    private String name;

    @Column(name = "KcalPer100g", nullable = false)
    private BigDecimal kcalPer100g;

    @Column(name = "ProteinPer100g", nullable = false)
    private BigDecimal proteinPer100g;

    @Column(name = "CarbsPer100g", nullable = false)
    private BigDecimal carbsPer100g;

    @Column(name = "FatPer100g", nullable = false)
    private BigDecimal fatPer100g;

    @Column(name = "FiberPer100g")
    private BigDecimal fiberPer100g;

    /** "TACO", "TBCA", "Custom". */
    @Column(name = "Source", nullable = false)
    private String source = "TACO";
}
