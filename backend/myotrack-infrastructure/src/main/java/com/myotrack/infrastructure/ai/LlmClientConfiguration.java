package com.myotrack.infrastructure.ai;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.context.annotation.Primary;

/**
 * Escolhe o provider de LLM. Porte do bloco de composição de MyoTrack.Worker/Program.cs.
 *
 * <p>As duas implementações continuam registradas: quem precisa de uma específica injeta a
 * classe concreta. Quem só quer "o LLM configurado" injeta {@link LlmJsonClient} e recebe este
 * bean. Sem isso o Spring encontra dois candidatos e nem sobe.
 */
@Configuration
public class LlmClientConfiguration {

    private static final Logger log = LoggerFactory.getLogger(LlmClientConfiguration.class);

    @Bean
    @Primary
    public LlmJsonClient llmJsonClient(
            LlmProperties properties, AnthropicJsonClient anthropic, GeminiJsonClient gemini) {

        final LlmJsonClient chosen =
                "gemini".equals(properties.effectiveProvider()) ? gemini : anthropic;

        // Sem chave o cliente devolve null e a geração cai no motor de regras. É um cenário
        // válido em desenvolvimento, mas em produção passa despercebido: registrar no startup
        // é o que diferencia "IA desligada de propósito" de "esqueceram a variável".
        if (chosen.isConfigured()) {
            log.info("LLM: {} ({})", properties.effectiveProvider(), chosen.model());
        } else {
            log.warn(
                    "LLM {} sem chave de API — geração de treino e dieta usará apenas o motor de regras.",
                    properties.effectiveProvider());
        }
        return chosen;
    }
}
