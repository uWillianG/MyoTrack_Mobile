package com.myotrack.infrastructure.push;

import org.springframework.boot.context.properties.ConfigurationProperties;

/**
 * Credenciais do FCM. Sem elas o push fica desligado e as mensagens são apenas registradas no log
 * — o mesmo "modo mock" do {@code EmailSender} e dos clientes de LLM, para desenvolver sem
 * configurar nada.
 *
 * <p>O FCM entrega para Android e iOS, mas as duas pontas exigem coisas diferentes fora daqui:
 * o Android precisa do {@code google-services.json} no app, e o iOS precisa de uma chave APNs
 * carregada no console do Firebase — que só existe com conta paga da Apple.
 */
@ConfigurationProperties(prefix = "myotrack.push")
public record PushProperties(String fcmProjectId, String fcmCredentialsJson) {

    public PushProperties {
        fcmProjectId = blankToEmpty(fcmProjectId);
        fcmCredentialsJson = blankToEmpty(fcmCredentialsJson);
    }

    /**
     * Há credenciais para envio real (não só log).
     *
     * <p>Exige as duas: o id do projeto sozinho monta a URL do FCM mas não autentica, e a
     * credencial sozinha não diz para qual projeto enviar. Configurar apenas uma é o engano
     * provável, e sem esta checagem ele apareceria como um 401 do Google no log do Worker,
     * bem longe da causa.
     */
    public boolean isConfigured() {
        return !fcmProjectId.isBlank() && !fcmCredentialsJson.isBlank();
    }

    private static String blankToEmpty(String value) {
        return value == null || value.isBlank() ? "" : value;
    }
}
