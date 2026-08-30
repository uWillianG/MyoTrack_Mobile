package com.myotrack.infrastructure.ai;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import java.net.SocketTimeoutException;
import java.util.concurrent.atomic.AtomicInteger;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.HttpStatus;
import org.springframework.web.client.HttpClientErrorException;
import org.springframework.web.client.HttpServerErrorException;
import org.springframework.web.client.ResourceAccessException;
import org.springframework.web.client.RestClientException;

/**
 * A repetição que substituiu o reprocessamento do job interativo.
 *
 * <p>O que se testa é <b>o que merece uma segunda tentativa</b>. Repetir de menos devolve ao
 * usuário o erro de um provedor que teria atendido dois segundos depois — foi o que aconteceu
 * quando o poller parou de reprocessar. Repetir de mais faz uma chave inválida ou um schema
 * recusado gastarem três chamadas para dar a mesma resposta, mais devagar.
 */
class TransientRetryTest {

    private static final Logger LOG = LoggerFactory.getLogger(TransientRetryTest.class);

    @Test
    @DisplayName("não repete quando a primeira tentativa dá certo")
    void succeedsWithoutRetrying() {
        AtomicInteger chamadas = new AtomicInteger();

        String resultado = TransientRetry.call("gemini", LOG, () -> {
            chamadas.incrementAndGet();
            return "ok";
        });

        assertThat(resultado).isEqualTo("ok");
        assertThat(chamadas).hasValue(1);
    }

    @Test
    @DisplayName("repete o 503 do modelo sobrecarregado e entrega a resposta seguinte")
    void retriesServerError() {
        // O caso real: "This model is currently experiencing high demand", com o mesmo modelo
        // respondendo normalmente segundos depois.
        AtomicInteger chamadas = new AtomicInteger();

        String resultado = TransientRetry.call("gemini", LOG, () -> {
            if (chamadas.incrementAndGet() == 1) {
                throw new HttpServerErrorException(HttpStatus.SERVICE_UNAVAILABLE);
            }
            return "ok";
        });

        assertThat(resultado).isEqualTo("ok");
        assertThat(chamadas).hasValue(2);
    }

    @Test
    @DisplayName("repete o 429 e a falha de rede, que também passam")
    void retriesRateLimitAndNetwork() {
        AtomicInteger chamadas = new AtomicInteger();

        String resultado = TransientRetry.call("openai", LOG, () -> {
            int vez = chamadas.incrementAndGet();
            if (vez == 1) {
                throw new HttpClientErrorException(HttpStatus.TOO_MANY_REQUESTS);
            }
            if (vez == 2) {
                throw new ResourceAccessException("Read timed out");
            }
            return "ok";
        });

        assertThat(resultado).isEqualTo("ok");
        assertThat(chamadas).hasValue(TransientRetry.MAX_ATTEMPTS);
    }

    @Test
    @DisplayName("repete a chamada que pendurou, mesmo embrulhada em RestClientException")
    void retriesReadTimeoutWrappedByRestClient() {
        // O caso real de 30/08/2026: o modelo aceitou a requisição e não terminou de responder.
        // O timeout estoura no meio da leitura do corpo e o RestClient o embrulha em
        // "Error while extracting response for type [java.lang.String]" — que não é
        // ResourceAccessException. Olhando só a casca, a avaria mais comum deste provedor
        // passava por definitiva: 104 s de espera, zero repetições no log, e a mesma pergunta
        // respondida em 6,8 s logo depois.
        AtomicInteger chamadas = new AtomicInteger();

        String resultado = TransientRetry.call("gemini", LOG, () -> {
            if (chamadas.incrementAndGet() == 1) {
                throw new RestClientException(
                        "Error while extracting response for type [java.lang.String]",
                        new SocketTimeoutException("Read timed out"));
            }
            return "ok";
        });

        assertThat(resultado).isEqualTo("ok");
        assertThat(chamadas).hasValue(2);
    }

    @Test
    @DisplayName("o teto de uma tentativa cabe dentro da janela de repetição")
    void attemptCeilingFitsInsideTheWindow() {
        // Não é preferência, é condição de existência: com o teto acima da janela, a primeira
        // falha por tempo nasce fora do prazo e a repetição nunca acontece — era o teto de 90 s
        // contra a janela de 45 s. Os dois números só fazem sentido escolhidos juntos, e esta é
        // a asserção que impede que voltem a divergir.
        assertThat(TransientRetry.ATTEMPT_CEILING).isLessThan(TransientRetry.RETRY_WINDOW);
    }

    @Test
    @DisplayName("não repete o que daria o mesmo resultado")
    void doesNotRetryDeterministicFailures() {
        // 400 é schema recusado e 403 é chave errada: a segunda tentativa só atrasa a mensagem.
        AtomicInteger chamadas = new AtomicInteger();

        assertThatThrownBy(() -> TransientRetry.call("gemini", LOG, () -> {
            chamadas.incrementAndGet();
            throw new HttpClientErrorException(HttpStatus.BAD_REQUEST);
        })).isInstanceOf(HttpClientErrorException.class);

        assertThat(chamadas).hasValue(1);
    }

    @Test
    @DisplayName("desiste ao esgotar as tentativas, propagando a última falha")
    void givesUpAtMaxAttempts() {
        // Propagar em vez de devolver null é o que mantém o tratamento no catch de cada cliente,
        // que registra a falha e devolve null ao handler.
        AtomicInteger chamadas = new AtomicInteger();

        assertThatThrownBy(() -> TransientRetry.call("gemini", LOG, () -> {
            chamadas.incrementAndGet();
            throw new HttpServerErrorException(HttpStatus.SERVICE_UNAVAILABLE);
        })).isInstanceOf(HttpServerErrorException.class);

        assertThat(chamadas).hasValue(TransientRetry.MAX_ATTEMPTS);
    }
}
