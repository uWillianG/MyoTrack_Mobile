package com.myotrack.infrastructure.ai;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import java.util.concurrent.atomic.AtomicInteger;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.HttpStatus;
import org.springframework.web.client.HttpClientErrorException;
import org.springframework.web.client.HttpServerErrorException;
import org.springframework.web.client.ResourceAccessException;

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
