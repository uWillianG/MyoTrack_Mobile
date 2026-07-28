package com.myotrack.api.auth;

/**
 * Falha em um fluxo de login externo (Google ou Apple).
 *
 * <p>A mensagem é de diagnóstico e vai para o log — nunca para o cliente. O que o usuário recebe é
 * sempre genérico, para não revelar quais contas existem.
 */
public class ExternalAuthException extends RuntimeException {

    public ExternalAuthException(String message) {
        super(message);
    }

    public ExternalAuthException(String message, Throwable cause) {
        super(message, cause);
    }
}
