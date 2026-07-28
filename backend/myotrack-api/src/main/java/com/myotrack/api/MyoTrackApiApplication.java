package com.myotrack.api;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.boot.autoconfigure.domain.EntityScan;
import org.springframework.boot.context.properties.ConfigurationPropertiesScan;
import org.springframework.data.jpa.repository.config.EnableJpaRepositories;

/**
 * API REST do MyoTrack. Porte de MyoTrack.Api/Program.cs.
 *
 * <p>Entidades e repositórios moram nos módulos domain/infrastructure, fora do pacote
 * desta classe — daí o escaneamento explícito.
 */
@SpringBootApplication(scanBasePackages = { "com.myotrack.api", "com.myotrack.infrastructure" })
// Cobre as @Entity do domínio, as do Identity (infrastructure) e os @Converter dos enums.
@EntityScan(basePackages = "com.myotrack")
@EnableJpaRepositories(basePackages = "com.myotrack.infrastructure.repository")
@ConfigurationPropertiesScan(basePackages = { "com.myotrack.api", "com.myotrack.infrastructure" })
public class MyoTrackApiApplication {

    public static void main(String[] args) {
        SpringApplication.run(MyoTrackApiApplication.class, args);
    }
}
