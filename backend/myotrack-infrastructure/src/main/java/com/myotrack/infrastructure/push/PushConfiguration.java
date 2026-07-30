package com.myotrack.infrastructure.push;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

/**
 * Escolhe o remetente de push conforme a configuração — mesmo desenho de
 * {@code LlmClientConfiguration}, que cai no motor de regras quando não há chave de LLM.
 *
 * <p>A escolha é feita na subida e registrada no log. É deliberado: um sistema que "não notifica"
 * tem duas causas indistinguíveis pelo sintoma — credencial ausente ou token não registrado — e
 * saber qual das duas é, sem depender de aparelho na mão, economiza a tarde inteira.
 */
@Configuration
public class PushConfiguration {

    private static final Logger log = LoggerFactory.getLogger(PushConfiguration.class);

    @Bean
    public PushSender pushSender(PushProperties properties) {
        if (!properties.isConfigured()) {
            final String motivo = motivoDaAusencia(properties);
            log.info("Push em modo log: {}. As notificações aparecem aqui e não vão para os aparelhos.",
                    motivo);
            return new LoggingPushSender(motivo);
        }

        // Aqui entra o FcmPushSender. Enquanto ele não existe, o modo log vale para todo mundo:
        // devolver um remetente que estoura na primeira notificação deixaria o Worker
        // aparentemente saudável até o primeiro job concluir.
        log.warn("MYOTRACK_FCM_* está configurado, mas o envio via FCM ainda não foi implementado — "
                + "seguindo em modo log.");
        return new LoggingPushSender("envio via FCM não implementado");
    }

    private static String motivoDaAusencia(PushProperties properties) {
        final boolean semProjeto = properties.fcmProjectId().isBlank();
        final boolean semCredencial = properties.fcmCredentialsJson().isBlank();

        if (semProjeto && semCredencial) {
            return "MYOTRACK_FCM_PROJECT_ID e MYOTRACK_FCM_CREDENTIALS_JSON não configurados";
        }
        // Metade configurada é o engano provável, e é o que merece a mensagem mais específica.
        return semProjeto
                ? "falta MYOTRACK_FCM_PROJECT_ID"
                : "falta MYOTRACK_FCM_CREDENTIALS_JSON";
    }
}
