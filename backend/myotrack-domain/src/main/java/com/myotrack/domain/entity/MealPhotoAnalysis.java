package com.myotrack.domain.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import java.math.BigDecimal;
import java.time.OffsetDateTime;
import java.util.UUID;
import lombok.Getter;
import lombok.Setter;
import org.hibernate.annotations.JdbcTypeCode;
import org.hibernate.type.SqlTypes;

/**
 * Resultado da análise de refeição por foto. Os itens ficam em JSONB
 * para permitir edição manual sem migração de schema.
 */
@Entity
@Table(name = "MealPhotoAnalyses")
@Getter
@Setter
public class MealPhotoAnalysis {

    @Id
    @GeneratedValue
    @Column(name = "Id")
    private UUID id;

    @Column(name = "UserId", nullable = false)
    private UUID userId;

    @Column(name = "AnalysisJobId", nullable = false)
    private UUID analysisJobId;

    @Column(name = "MediaKey", nullable = false)
    private String mediaKey;

    /** Itens detectados: [{description, foodItemId?, quantityG, kcal, proteinG, carbsG, fatG}]. */
    @JdbcTypeCode(SqlTypes.JSON)
    @Column(name = "ItemsJson", nullable = false)
    private String itemsJson = "[]";

    @Column(name = "TotalKcal", nullable = false)
    private BigDecimal totalKcal = BigDecimal.ZERO;

    @Column(name = "TotalProteinG", nullable = false)
    private BigDecimal totalProteinG = BigDecimal.ZERO;

    @Column(name = "TotalCarbsG", nullable = false)
    private BigDecimal totalCarbsG = BigDecimal.ZERO;

    @Column(name = "TotalFatG", nullable = false)
    private BigDecimal totalFatG = BigDecimal.ZERO;

    /** True quando o usuário corrigiu a estimativa (sinal de qualidade para o futuro). */
    @Column(name = "UserAdjusted", nullable = false)
    private boolean userAdjusted;

    /**
     * True quando o usuário tirou esta análise do diário alimentar (ex.: foto
     * repetida ou prato que não foi consumido) — ela deixa de somar no dia.
     */
    @Column(name = "ExcludedFromDiary", nullable = false)
    private boolean excludedFromDiary;

    /**
     * Versão "ilustrada" da foto (IA anota itens e macros na própria imagem),
     * gerada quando o usuário escolhe esse modo. Null = análise padrão ou
     * geração indisponível/falhou (a análise continua válida sem ela).
     */
    @Column(name = "IllustratedMediaKey")
    private String illustratedMediaKey;

    @Column(name = "CreatedAt", nullable = false)
    private OffsetDateTime createdAt = OffsetDateTime.now();

    /** Quando a mídia foi apagada do storage pela política de retenção (LGPD). */
    @Column(name = "MediaExpiredAt")
    private OffsetDateTime mediaExpiredAt;
}
