package com.myotrack.domain.entity;

import com.myotrack.domain.MealSource;
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
 * Uma refeição do diário alimentar. Os itens ficam em JSONB
 * para permitir edição manual sem migração de schema.
 *
 * <p><b>O nome envelheceu de propósito.</b> A tabela nasceu servindo só à análise por foto e hoje
 * guarda também a refeição digitada à mão, sem foto e sem job. A alternativa era uma segunda
 * tabela, e ela custaria caro no lugar errado: diário, relatório semanal, exportação e exclusão
 * de conta (LGPD) leem <b>esta</b> entidade, e cada um deles precisaria aprender a ler duas
 * fontes e a somá-las na ordem certa. Renomear a tabela, por sua vez, seria uma migração que
 * trava a maior tabela do usuário para ganhar apenas um nome melhor.
 *
 * <p>O que muda com isso é o que pode ser nulo: {@code MediaKey} e {@code AnalysisJobId} valem
 * para a foto e não existem na entrada manual. Quem precisa distinguir olha {@link #source}, e
 * não a nulidade — ver {@link MealSource}.
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

    /** Null na refeição manual: ela não passa pela fila de IA para ser gravada. */
    @Column(name = "AnalysisJobId")
    private UUID analysisJobId;

    /** Null na refeição manual: não há foto nenhuma no storage. */
    @Column(name = "MediaKey")
    private String mediaKey;

    /** Foto ou entrada manual. Ver {@link MealSource} para por que o campo existe. */
    @Column(name = "Source", nullable = false)
    private MealSource source = MealSource.PHOTO;

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
