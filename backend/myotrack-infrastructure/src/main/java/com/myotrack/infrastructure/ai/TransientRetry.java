package com.myotrack.infrastructure.ai;

import java.time.Duration;
import java.util.function.Supplier;
import org.slf4j.Logger;
import org.springframework.web.client.HttpClientErrorException;
import org.springframework.web.client.HttpServerErrorException;
import org.springframework.web.client.ResourceAccessException;

/**
 * Repete a chamada ao provedor de IA quando ela falha por motivo passageiro.
 *
 * <p><b>Existe porque a repetição saiu de cima.</b> O {@code JobPoller} não reprocessa job
 * interativo — três tentativas de um job custavam minutos de tela girando para dar a mesma
 * notícia que estava pronta no primeiro erro. Só que o erro mais comum destes provedores não é
 * definitivo: o Gemini devolve {@code 503 "This model is currently experiencing high demand"} e,
 * segundos depois, atende normalmente. Sem nada no lugar, um soluço de dois segundos passou a
 * custar a estimativa inteira.
 *
 * <p>É a mesma decisão do poller vista de perto: repetir <b>aqui</b> custa segundos e é
 * invisível; repetir <b>lá</b> custava um teto de chamada por tentativa, na frente de quem
 * espera.
 *
 * <p>Duas travas, e as duas importam:
 *
 * <ul>
 *   <li>Só motivo passageiro. Um {@code 400} de schema inválido ou um {@code 403} de chave
 *       errada dão o mesmo resultado nas três tentativas — repetir só atrasa a mensagem.
 *   <li>Só enquanto a falha for rápida. Uma chamada que pendurou até o teto já consumiu a
 *       paciência de quem espera; a segunda começaria de um lugar em que a soma não cabe mais.
 * </ul>
 */
final class TransientRetry {

    /** A primeira mais duas repetições. */
    static final int MAX_ATTEMPTS = 3;

    /** Cresce com a tentativa: 1 s, depois 2 s. O provedor sobrecarregado agradece a pausa. */
    static final Duration BACKOFF = Duration.ofSeconds(1);

    /**
     * A partir daqui não se repete mais.
     *
     * <p>Menor que o teto de uma chamada de propósito: o que se quer recuperar é o erro que
     * volta depressa. Uma falha que levou mais do que isto já gastou o tempo que havia, e a
     * repetição entregaria o resultado a alguém que desistiu.
     */
    static final Duration RETRY_WINDOW = Duration.ofSeconds(45);

    private TransientRetry() {
    }

    /**
     * Executa e devolve o resultado; propaga a exceção da última tentativa.
     *
     * <p>Propagar, e não devolver null, é o que mantém o tratamento onde ele já estava: cada
     * cliente tem o seu {@code catch} que registra a falha e devolve null ao chamador.
     */
    static <T> T call(String provider, Logger log, Supplier<T> request) {
        final long started = System.nanoTime();

        for (int attempt = 1; ; attempt++) {
            try {
                return request.get();
            } catch (RuntimeException e) {
                if (attempt >= MAX_ATTEMPTS || !isTransient(e) || !withinWindow(started)) {
                    throw e;
                }
                log.warn(
                        "{} indisponível na tentativa {} de {} ({}). Repetindo.",
                        provider, attempt, MAX_ATTEMPTS, e.getMessage());
                if (!pause(BACKOFF.multipliedBy(attempt))) {
                    throw e;
                }
            }
        }
    }

    /**
     * A falha pode mudar de resultado numa segunda tentativa?
     *
     * <p>{@code 5xx} e {@code 429} são o provedor dizendo "agora não"; {@link
     * ResourceAccessException} é a rede (conexão recusada, timeout de leitura). Todo o resto —
     * schema recusado, chave inválida, modelo inexistente — é determinístico.
     */
    private static boolean isTransient(RuntimeException e) {
        return e instanceof HttpServerErrorException
                || e instanceof ResourceAccessException
                || (e instanceof HttpClientErrorException client
                        && client.getStatusCode().value() == 429);
    }

    private static boolean withinWindow(long startedNanos) {
        return System.nanoTime() - startedNanos < RETRY_WINDOW.toNanos();
    }

    /** False quando a espera foi interrompida — aí o worker está parando e não há o que repetir. */
    private static boolean pause(Duration duration) {
        try {
            Thread.sleep(duration.toMillis());
            return true;
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
            return false;
        }
    }
}
