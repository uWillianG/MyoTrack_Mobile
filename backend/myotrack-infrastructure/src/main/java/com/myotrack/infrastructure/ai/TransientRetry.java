package com.myotrack.infrastructure.ai;

import java.net.ConnectException;
import java.net.SocketTimeoutException;
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
 *   <li>Só enquanto ainda couber. Passada a {@link #RETRY_WINDOW}, quem espera já esperou o
 *       que tinha para esperar, e a tentativa seguinte entregaria o resultado a quem desistiu.
 * </ul>
 *
 * <p><b>O teto de uma tentativa mora aqui, e não em cada cliente</b>, porque ele e a janela são
 * um par: se uma tentativa puder demorar mais do que a janela inteira, a primeira falha já
 * nasce fora do prazo e <b>a repetição nunca acontece</b>. Foi o que houve — teto de 90 s
 * contra janela de 45 s. O erro mais comum deste provedor não é o 503 rápido, é a chamada que
 * pendura: em 30/08/2026 uma estimativa por descrição gastou 104 s para falhar com "a IA não
 * respondeu", sem uma única repetição no log, enquanto a mesma pergunta ao mesmo modelo era
 * respondida em 6,8 s. Os dois números agora são escolhidos juntos, e há teste sobre a relação
 * entre eles.
 */
final class TransientRetry {

    /** A primeira mais duas repetições. */
    static final int MAX_ATTEMPTS = 3;

    /** Cresce com a tentativa: 1 s, depois 2 s. O provedor sobrecarregado agradece a pausa. */
    static final Duration BACKOFF = Duration.ofSeconds(1);

    /**
     * Teto de <b>uma</b> tentativa: é o read timeout que os clientes põem na fábrica de
     * requisições.
     *
     * <p>Dimensionado pelo que uma chamada boa custa, e não pelo pior caso imaginável: as
     * respostas medidas ficam entre 7 e 30 s, contando o trabalho do handler em volta. Acima
     * disso não se está esperando uma resposta lenta, se está esperando uma que não vem — e o
     * conserto dela é começar outra, não esticar esta.
     */
    static final Duration ATTEMPT_CEILING = Duration.ofSeconds(45);

    /**
     * Até quando ainda vale <b>começar</b> outra tentativa.
     *
     * <p>Maior que {@link #ATTEMPT_CEILING} por obrigação: a chamada pendurada é justamente o
     * caso que precisa de segunda chance, e uma janela menor que o teto a excluiria por
     * construção. Maior o bastante para caber a repetição, e curta o bastante para o pior caso
     * — duas tentativas no teto — ainda caber na espera de quem está na tela, que desiste em
     * três minutos (`JobWatcher.maxWait`).
     */
    static final Duration RETRY_WINDOW = Duration.ofSeconds(60);

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
     * <p>{@code 5xx} e {@code 429} são o provedor dizendo "agora não"; a rede — conexão
     * recusada, timeout de leitura — é o mesmo "agora não" dito por omissão. Todo o resto —
     * schema recusado, chave inválida, modelo inexistente — é determinístico.
     *
     * <p><b>O tipo da exceção não basta para reconhecer a rede.</b> O timeout de leitura chega
     * como {@link ResourceAccessException} quando estoura antes da resposta começar, mas como
     * um {@code RestClientException} cru — "Error while extracting response for type
     * [java.lang.String]" — quando estoura no meio da leitura do corpo, que é o caso comum de
     * um modelo que aceitou a requisição e não terminou de responder. São a mesma avaria com
     * dois embrulhos, e olhar só o de fora deixava a segunda passar por definitiva. Por isso a
     * pergunta é feita à causa, e não à casca.
     */
    private static boolean isTransient(RuntimeException e) {
        if (e instanceof HttpServerErrorException
                || e instanceof ResourceAccessException
                || (e instanceof HttpClientErrorException client
                        && client.getStatusCode().value() == 429)) {
            return true;
        }
        return hasNetworkCause(e);
    }

    /** Alguma camada desta exceção é a rede desistindo? */
    private static boolean hasNetworkCause(Throwable e) {
        for (Throwable cause = e; cause != null; cause = cause.getCause()) {
            if (cause instanceof SocketTimeoutException || cause instanceof ConnectException) {
                return true;
            }
            if (cause.getCause() == cause) {
                break;
            }
        }
        return false;
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
