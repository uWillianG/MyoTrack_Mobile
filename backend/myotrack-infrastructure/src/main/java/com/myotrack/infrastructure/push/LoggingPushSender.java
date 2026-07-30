package com.myotrack.infrastructure.push;

import com.myotrack.domain.entity.DeviceToken;
import java.util.Collection;
import java.util.List;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

/**
 * Escreve a notificação no log em vez de enviá-la.
 *
 * <p>É o que roda em desenvolvimento, onde não há projeto no Firebase: o fluxo inteiro — o job
 * conclui, os tokens do usuário são consultados, a mensagem é montada — acontece de verdade, e só
 * a última etapa vira uma linha de log. É assim que se confere o texto e a rota de uma notificação
 * sem aparelho e sem credencial, do mesmo jeito que o link de redefinição de senha aparece no log
 * da API quando não há SMTP.
 *
 * <p>Nunca devolve token recusado: sem provedor, não há o que recusar.
 */
public class LoggingPushSender implements PushSender {

    private static final Logger log = LoggerFactory.getLogger(LoggingPushSender.class);

    private final String motivo;

    /**
     * @param motivo por que o envio real está desligado, para a linha de log dizer o que
     *     configurar em vez de só constatar que nada foi enviado
     */
    public LoggingPushSender(String motivo) {
        this.motivo = motivo;
    }

    @Override
    public List<String> send(Collection<DeviceToken> targets, PushMessage message) {
        log.info("Push desligado ({}) — não enviado para {} aparelho(s).\nTítulo: {}\nCorpo: {}\nRota: {}",
                motivo, targets.size(), message.title(), message.body(), message.route());
        return List.of();
    }
}
