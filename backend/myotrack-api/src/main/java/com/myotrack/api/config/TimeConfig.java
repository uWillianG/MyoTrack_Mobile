package com.myotrack.api.config;

import java.time.Clock;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

/**
 * O relógio do sistema, como bean.
 *
 * <p>Existe para que regras que dependem de "hoje" sejam testáveis sem esperar o calendário
 * virar. A primeira delas é a concessão de Pro por constância: verificar que quatro semanas
 * seguidas concedem e que a quinta não concede de novo exige empurrar o tempo, e um teste que
 * chama {@code LocalDate.now()} só falharia em quem o rodasse numa segunda-feira.
 *
 * <p>UTC, e não o fuso do servidor: a semana de treino é fechada em datas, e a mesma sessão
 * não pode cair em semanas diferentes conforme onde a aplicação estiver hospedada.
 */
@Configuration
public class TimeConfig {

    @Bean
    public Clock clock() {
        return Clock.systemUTC();
    }
}
