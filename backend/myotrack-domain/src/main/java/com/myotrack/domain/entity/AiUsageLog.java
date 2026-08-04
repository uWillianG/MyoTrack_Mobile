package com.myotrack.domain.entity;

import com.myotrack.domain.AnalysisJobType;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import java.time.OffsetDateTime;
import java.util.UUID;
import lombok.Getter;
import lombok.Setter;

/**
 * Trilha de consumo de IA por usuário — base para limites e controle de custo.
 *
 * <p><b>Provedor e custo existem porque token deixou de ser uma unidade comparável.</b> Enquanto
 * havia um provedor só, somar tokens respondia "quanto se gastou". Com Gemini e OpenAI lado a
 * lado, duas linhas com a mesma contagem podem diferir por uma ordem de grandeza em dinheiro, e a
 * tabela passou a medir uso sem medir gasto — justamente agora, que a IA vai ser liberada de
 * graça e o gasto é o número que decide se isso se sustenta.
 */
@Entity
@Table(name = "AiUsageLogs")
@Getter
@Setter
public class AiUsageLog {

    @Id
    @GeneratedValue
    @Column(name = "Id")
    private UUID id;

    @Column(name = "UserId", nullable = false)
    private UUID userId;

    @Column(name = "Operation", nullable = false)
    private AnalysisJobType operation;

    /** {@code "gemini"} ou {@code "openai"} — quem cobrou. */
    @Column(name = "Provider", nullable = false)
    private String provider;

    @Column(name = "Model", nullable = false)
    private String model;

    @Column(name = "InputTokens", nullable = false)
    private long inputTokens;

    @Column(name = "OutputTokens", nullable = false)
    private long outputTokens;

    /**
     * Custo em nano-dólares, ou null quando o modelo não tinha preço registrado.
     *
     * <p>Null e não zero, e a diferença é o ponto: zero afirmaria que a chamada foi gratuita.
     * Uma soma que ignore essa distinção reporta menos gasto do que houve — o erro que, num
     * controle de custo, custa mais caro. Quem consultar precisa contar as linhas sem preço
     * junto com o total.
     */
    @Column(name = "CostNanoUsd")
    private Long costNanoUsd;

    @Column(name = "CreatedAt", nullable = false)
    private OffsetDateTime createdAt = OffsetDateTime.now();
}
