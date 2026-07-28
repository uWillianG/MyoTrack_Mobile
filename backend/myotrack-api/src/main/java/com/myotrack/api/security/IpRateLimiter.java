package com.myotrack.api.security;

import java.time.Duration;
import java.time.Instant;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.atomic.AtomicInteger;
import org.springframework.stereotype.Component;

/**
 * Janela fixa por IP para os endpoints que disparam e-mail — o alvo mais fácil de abuso
 * (spam para terceiros usando o nosso remetente). Porte do {@code AddRateLimiter} do Program.cs:
 * 10 pedidos a cada 15 minutos.
 *
 * <p>Estado em memória, como no .NET: a instância é única na VPS. Com mais de uma réplica o
 * limite passa a ser por réplica — aceitável para o propósito, que é frear abuso, não contar
 * com precisão.
 *
 * <p>Atrás do Caddy o IP real vem no {@code X-Forwarded-For}; quem resolve isso é o
 * {@code server.forward-headers-strategy=framework} do application.yml.
 */
@Component
public class IpRateLimiter {

    private static final int PERMIT_LIMIT = 10;
    private static final Duration WINDOW = Duration.ofMinutes(15);

    /** Acima disto, uma aquisição aproveita a passagem para limpar as janelas vencidas. */
    private static final int EVICTION_THRESHOLD = 1_000;

    private final Map<String, Window> windows = new ConcurrentHashMap<>();

    /** True quando a requisição cabe na janela; false quando o limite estourou. */
    public boolean tryAcquire(String clientIp) {
        String key = clientIp == null || clientIp.isBlank() ? "desconhecido" : clientIp;
        Instant now = Instant.now();

        if (windows.size() > EVICTION_THRESHOLD) {
            evictExpired(now);
        }

        Window window = windows.compute(key, (ignored, current) ->
                current == null || current.isExpired(now) ? new Window(now) : current);

        return window.count.incrementAndGet() <= PERMIT_LIMIT;
    }

    /** Descarta janelas vencidas — sem isto o mapa cresceria um registro por IP visitante. */
    private void evictExpired(Instant now) {
        windows.entrySet().removeIf(entry -> entry.getValue().isExpired(now));
    }

    private static final class Window {

        private final Instant startedAt;
        private final AtomicInteger count = new AtomicInteger();

        private Window(Instant startedAt) {
            this.startedAt = startedAt;
        }

        private boolean isExpired(Instant now) {
            return startedAt.plus(WINDOW).isBefore(now);
        }
    }
}
