package com.myotrack.infrastructure.push;

import com.myotrack.domain.entity.DeviceToken;
import com.myotrack.infrastructure.repository.DeviceTokenRepository;
import java.util.List;
import java.util.UUID;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * Notifica todos os aparelhos de um usuário.
 *
 * <p>Existe para que quem avisa não precise saber de token, de provedor nem de limpeza: o handler
 * de job diz "avise esta pessoa disto" e pronto.
 *
 * <p><b>Nada aqui lança.</b> Quem chama já terminou um trabalho que custou tempo e dinheiro; uma
 * exceção subindo daqui marcaria como falho um job que ficou pronto, e a nova tentativa refaria a
 * geração inteira por causa de uma notificação.
 */
@Service
public class UserPushNotifier {

    private static final Logger log = LoggerFactory.getLogger(UserPushNotifier.class);

    private final DeviceTokenRepository tokens;
    private final PushSender sender;

    public UserPushNotifier(DeviceTokenRepository tokens, PushSender sender) {
        this.tokens = tokens;
        this.sender = sender;
    }

    @Transactional
    public void notifyUser(UUID userId, PushMessage message) {
        try {
            final List<DeviceToken> targets = tokens.findByUserId(userId);
            if (targets.isEmpty()) {
                // Estado normal, não erro: ninguém é obrigado a autorizar notificação, e no iOS
                // a recusa é a resposta padrão do sistema.
                log.debug("Usuário {} não tem aparelho registrado; nada a notificar.", userId);
                return;
            }

            final List<String> rejeitados = sender.send(targets, message);

            if (!rejeitados.isEmpty()) {
                // Sem esta limpeza os tokens mortos ficam para sempre, e cada notificação passa a
                // gastar uma chamada por aparelho que já não existe. É a única oportunidade de
                // descobri-los: o provedor só os denuncia na tentativa de envio.
                log.info("Removendo {} token(s) recusado(s) pelo provedor.", rejeitados.size());
                tokens.deleteByTokenIn(rejeitados);
            }
        } catch (Exception e) {
            log.error("Falha ao notificar o usuário {}: {}", userId, e.getMessage(), e);
        }
    }
}
