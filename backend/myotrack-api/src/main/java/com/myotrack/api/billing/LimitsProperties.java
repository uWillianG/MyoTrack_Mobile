package com.myotrack.api.billing;

import org.springframework.boot.context.properties.ConfigurationProperties;

/**
 * Limites diários de IA por plano. Seção "Limits" dos appsettings.json do .NET.
 *
 * <p>São configuráveis porque o custo de cada chamada muda com o modelo — e porque uma promoção
 * ou um incidente de cota pode exigir apertar o limite sem publicar versão nova.
 */
@ConfigurationProperties(prefix = "myotrack.limits")
public record LimitsProperties(PlanLimits free, PlanLimits pro) {

    public LimitsProperties {
        free = free == null ? new PlanLimits(10, 5, 10) : free;
        pro = pro == null ? new PlanLimits(50, 20, 50) : pro;
    }

    public record PlanLimits(
            int maxMealAnalysesPerDay,
            int maxVideoAnalysesPerDay,
            int maxCoachMessagesPerDay) {

        public PlanLimits {
            maxMealAnalysesPerDay = maxMealAnalysesPerDay <= 0 ? 10 : maxMealAnalysesPerDay;
            maxVideoAnalysesPerDay = maxVideoAnalysesPerDay <= 0 ? 5 : maxVideoAnalysesPerDay;
            maxCoachMessagesPerDay = maxCoachMessagesPerDay <= 0 ? 10 : maxCoachMessagesPerDay;
        }
    }
}
