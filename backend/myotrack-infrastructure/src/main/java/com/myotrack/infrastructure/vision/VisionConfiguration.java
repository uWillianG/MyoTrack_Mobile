package com.myotrack.infrastructure.vision;

import java.time.Duration;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.http.client.SimpleClientHttpRequestFactory;
import org.springframework.web.client.RestClient;

/** Cliente HTTP dedicado ao serviço de visão, com os timeouts que ele exige. */
@Configuration
public class VisionConfiguration {

    /** Nome do bean; o {@link HttpVisionClient} o pede por qualificador. */
    public static final String REST_CLIENT = "visionRestClient";

    /** Conectar é instantâneo na rede interna; o que demora é a resposta. */
    private static final Duration CONNECT_TIMEOUT = Duration.ofSeconds(15);

    @Bean(REST_CLIENT)
    public RestClient visionRestClient(
            VisionProperties properties, RestClient.Builder builder) {

        // O timeout de leitura precisa cobrir a análise inteira — estimar pose quadro a quadro
        // e renderizar o overlay leva minutos. Com o padrão do cliente HTTP a chamada morreria
        // muito antes de o serviço terminar, e o job voltaria para a fila em looping.
        final SimpleClientHttpRequestFactory factory = new SimpleClientHttpRequestFactory();
        factory.setConnectTimeout(CONNECT_TIMEOUT);
        factory.setReadTimeout(properties.timeout());

        return builder.requestFactory(factory).build();
    }
}
