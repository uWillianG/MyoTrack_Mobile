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
        free = free == null ? new PlanLimits(3, 1, 5) : free;
        pro = pro == null ? new PlanLimits(10, 5, 10) : pro;
    }

    public record PlanLimits(
            int maxMealAnalysesPerDay,
            int maxVideoAnalysesPerDay,
            int maxCoachMessagesPerDay) {

        /**
         * Os fallbacks por campo são os do <b>gratuito</b>, e é de propósito: este construtor é
         * compartilhado pelos dois planos, então ele não tem como saber qual está sendo montado.
         * Diante dessa ignorância, o erro barato e o erro caro não são simétricos — cair no
         * gratuito por engano rende uma reclamação de quem paga, e a configuração é corrigida no
         * mesmo dia; cair no Pro por engano libera limite pago a todo mundo, silenciosamente, e a
         * conta do provedor de IA é quem conta a história depois. Por isso uma configuração
         * ausente ou inválida (zero, negativa, chave com nome errado) nunca concede mais do que o
         * plano gratuito.
         */
        public PlanLimits {
            maxMealAnalysesPerDay = maxMealAnalysesPerDay <= 0 ? 3 : maxMealAnalysesPerDay;
            maxVideoAnalysesPerDay = maxVideoAnalysesPerDay <= 0 ? 1 : maxVideoAnalysesPerDay;
            maxCoachMessagesPerDay = maxCoachMessagesPerDay <= 0 ? 5 : maxCoachMessagesPerDay;
        }
    }
}
