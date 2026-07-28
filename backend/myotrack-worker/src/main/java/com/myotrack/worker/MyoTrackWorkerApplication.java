package com.myotrack.worker;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.boot.autoconfigure.domain.EntityScan;
import org.springframework.boot.context.properties.ConfigurationPropertiesScan;
import org.springframework.data.jpa.repository.config.EnableJpaRepositories;
import org.springframework.scheduling.annotation.EnableScheduling;

/**
 * Worker da fila de jobs de IA, retenção de mídia e relatório semanal.
 * Porte de MyoTrack.Worker/Program.cs.
 */
@SpringBootApplication(scanBasePackages = { "com.myotrack.worker", "com.myotrack.infrastructure" })
// Cobre as @Entity do domínio, as do Identity (infrastructure) e os @Converter dos enums.
@EntityScan(basePackages = "com.myotrack")
@EnableJpaRepositories(basePackages = "com.myotrack.infrastructure.repository")
@ConfigurationPropertiesScan(basePackages = { "com.myotrack.worker", "com.myotrack.infrastructure" })
@EnableScheduling
public class MyoTrackWorkerApplication {

    public static void main(String[] args) {
        SpringApplication.run(MyoTrackWorkerApplication.class, args);
    }
}
