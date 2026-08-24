package com.myotrack.api.billing;

import org.springframework.boot.context.properties.ConfigurationProperties;

/**
 * Credenciais da Google Play Developer API — a conta de serviço com que o servidor pergunta ao
 * Google o estado de uma assinatura.
 *
 * <p>O {@code credentialsJson} é o arquivo inteiro da conta de serviço, com a chave privada
 * dentro. O {@code packageName} identifica o app: a API do Google é por pacote, e um
 * {@code purchaseToken} só existe dentro de um.
 *
 * <p>O {@code notificationsToken} é um segredo combinado que o Pub/Sub devolve na URL de push.
 * Diferente da Apple, cuja notificação vem assinada e se verifica sozinha, uma RTDN é um JSON
 * qualquer — quem garante a origem é a URL secreta. Vazio, o endpoint aceita sem conferir, o que
 * serve para desenvolver e <b>não</b> para produção: o estado real ainda é buscado na API do
 * Google a cada notificação, então o estrago de uma notificação forjada é fazer o servidor
 * reconsultar algo que ele já sabia.
 */
@ConfigurationProperties(prefix = "myotrack.billing.google")
public record PlayStoreProperties(String packageName, String credentialsJson, String notificationsToken) {

    public PlayStoreProperties {
        packageName = blankToEmpty(packageName);
        credentialsJson = blankToEmpty(credentialsJson);
        notificationsToken = blankToEmpty(notificationsToken);
    }

    public boolean isConfigured() {
        return !packageName.isBlank() && !credentialsJson.isBlank();
    }

    private static String blankToEmpty(String value) {
        return value == null || value.isBlank() ? "" : value;
    }
}
