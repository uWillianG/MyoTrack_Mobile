package com.myotrack.infrastructure.push;

/**
 * O que chega no aparelho.
 *
 * <p>{@code route} é um caminho do roteador do app ({@code /treino}, {@code /videos}) e viaja no
 * bloco de dados, não no de notificação. Sem ele o toque na notificação abre a tela inicial e a
 * pessoa tem de procurar o que ficou pronto — o que anula a razão de avisar.
 *
 * @param title  primeira linha, no negrito do sistema
 * @param body   a linha de baixo
 * @param route  destino no app ao tocar
 */
public record PushMessage(String title, String body, String route) {

    public PushMessage {
        if (title == null || title.isBlank()) {
            throw new IllegalArgumentException("Notificação sem título.");
        }
        if (body == null || body.isBlank()) {
            throw new IllegalArgumentException("Notificação sem corpo.");
        }
        // Rota vazia é aceita e vira abertura na tela inicial; rota nula não, porque o campo
        // seguiria para o payload como a string "null" e o roteador tentaria navegar para ela.
        route = route == null ? "" : route;
    }
}
