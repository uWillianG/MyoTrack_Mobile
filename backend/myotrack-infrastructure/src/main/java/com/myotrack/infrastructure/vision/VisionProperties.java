package com.myotrack.infrastructure.vision;

import java.time.Duration;
import org.springframework.boot.context.properties.ConfigurationProperties;

/**
 * Seção "Vision" do appsettings.json do Worker.
 *
 * <p>O serviço de visão roda fora deste repositório (MediaPipe Pose). O timeout é alto porque
 * analisar um vídeo de série inteira envolve decodificar, estimar pose quadro a quadro e ainda
 * renderizar o overlay — é a operação mais demorada do sistema, e por isso o
 * {@code JobsController} tolera stream de até 15 minutos.
 */
@ConfigurationProperties(prefix = "myotrack.vision")
public record VisionProperties(String baseUrl, int timeoutSeconds) {

    public VisionProperties {
        baseUrl = baseUrl == null ? "" : baseUrl.trim();
        timeoutSeconds = timeoutSeconds <= 0 ? 600 : timeoutSeconds;
    }

    /** Sem base-url o serviço não existe para este ambiente e a análise fica indisponível. */
    public boolean isConfigured() {
        return !baseUrl.isBlank();
    }

    public Duration timeout() {
        return Duration.ofSeconds(timeoutSeconds);
    }
}
