package com.myotrack.infrastructure.email;

import org.springframework.boot.context.properties.ConfigurationProperties;

/**
 * SMTP de saída. Sem {@code user}/{@code password} o envio fica desligado e as mensagens são
 * apenas registradas no log — o mesmo "modo mock" dos demais serviços externos, para desenvolver
 * sem credenciais.
 */
@ConfigurationProperties(prefix = "myotrack.email")
public record EmailProperties(
        String host,
        int port,
        boolean useStartTls,
        String user,
        String password,
        String from,
        String fromName) {

    public EmailProperties {
        host = blankToDefault(host, "smtp.gmail.com");
        port = port <= 0 ? 587 : port;
        user = blankToDefault(user, "");
        password = blankToDefault(password, "");
        from = blankToDefault(from, "");
        fromName = blankToDefault(fromName, "MyoTrack");
    }

    /** Remetente exibido. Vazio = usa o próprio usuário SMTP. */
    public String effectiveFrom() {
        return from.isBlank() ? user : from;
    }

    public boolean isConfigured() {
        return !user.isBlank() && !password.isBlank();
    }

    private static String blankToDefault(String value, String fallback) {
        return value == null || value.isBlank() ? fallback : value;
    }
}
