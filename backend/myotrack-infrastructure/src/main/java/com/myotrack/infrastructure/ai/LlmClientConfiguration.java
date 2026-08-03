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
 *
 * <p><b>A escolha é do app inteiro.</b> Todo handler recebe o mesmo provedor e o mesmo modelo, o
 * que significa que extrair itens de uma foto contra um schema fixo e gerar um plano de treino
 * pagam a mesma tabela. É a decisão de custo mais cara que este arquivo toma, e mudá-la é trocar
 * este bean único por uma escolha por operação — não foi feito aqui porque é troca de qualidade
 * por preço, e essa é decisão de produto.
 */
@Configuration
public class LlmClientConfiguration {

    private static final Logger log = LoggerFactory.getLogger(LlmClientConfiguration.class);

    @Bean
    @Primary
    public LlmJsonClient llmJsonClient(
            LlmProperties properties, OpenAiJsonClient openai, GeminiJsonClient gemini) {

        final LlmJsonClient chosen =
                "openai".equals(properties.effectiveProvider()) ? openai : gemini;

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
