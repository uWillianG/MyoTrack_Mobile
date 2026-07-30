package com.myotrack.infrastructure.push;

import com.myotrack.domain.entity.DeviceToken;
import java.util.Collection;
import java.util.List;

/**
 * Entrega a notificação aos aparelhos de um usuário.
 *
 * <p>É interface pelo mesmo motivo do {@code MediaStorage}: o envio real depende de credencial
 * externa, e teste de unidade não tem provedor para responder.
 */
public interface PushSender {

    /**
     * Envia a mesma mensagem para vários aparelhos.
     *
     * <p><b>Não lança.</b> Quem chama é um handler de job já concluído — deixar uma falha de push
     * derrubar o processamento marcaria como falho um trabalho que ficou pronto, e a próxima
     * tentativa o refaria do zero, pagando outra chamada de LLM por causa de uma notificação.
     *
     * @return os tokens que o provedor recusou <b>definitivamente</b> (app desinstalado, token
     *     rotacionado), para que sejam removidos. Recusa temporária — cota, provedor fora do ar —
     *     não entra nesta lista: apagar o token nesse caso deixaria o aparelho sem push para
     *     sempre, já que o app só registra de novo na próxima abertura.
     */
    List<String> send(Collection<DeviceToken> targets, PushMessage message);
}
