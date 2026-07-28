package com.myotrack.api.config;

import com.myotrack.infrastructure.seed.DbSeeder;
import org.springframework.boot.ApplicationArguments;
import org.springframework.boot.ApplicationRunner;
import org.springframework.stereotype.Component;

/**
 * Semeia papéis e catálogos no startup da API, como o bloco após {@code app.Build()} no
 * Program.cs. As migrations ficam com o Flyway; aqui só entram os dados.
 *
 * <p>Roda apenas na API: se o Worker também semeasse, os dois disputariam a inserção a cada boot.
 */
@Component
public class SeedRunner implements ApplicationRunner {

    private final DbSeeder seeder;

    public SeedRunner(DbSeeder seeder) {
        this.seeder = seeder;
    }

    @Override
    public void run(ApplicationArguments args) {
        seeder.seed();
    }
}
