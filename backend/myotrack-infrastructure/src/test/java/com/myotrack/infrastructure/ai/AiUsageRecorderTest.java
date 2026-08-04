package com.myotrack.infrastructure.ai;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import com.myotrack.domain.AnalysisJobType;
import com.myotrack.domain.entity.AiUsageLog;
import com.myotrack.infrastructure.ai.LlmJsonClient.LlmJsonResult;
import com.myotrack.infrastructure.ai.LlmPricing.ModelPrice;
import com.myotrack.infrastructure.repository.AiUsageLogRepository;
import java.math.BigDecimal;
import java.util.Map;
import java.util.UUID;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.mockito.ArgumentCaptor;
import org.springframework.web.client.RestClient;

/**
 * O que a trilha de consumo passa a saber.
 *
 * <p>O provedor vem do cliente que fez a chamada, e não de adivinhar pelo nome do modelo — a
 * adivinhação erraria em silêncio no dia em que um provedor lançasse um nome parecido com o do
 * outro, e o erro apareceria como custo somado à conta errada, nunca como exceção.
 */
class AiUsageRecorderTest {

    private static final UUID USER = UUID.randomUUID();

    private static LlmPricing pricing(String model) {
        return new LlmPricing(Map.of(
                model, new ModelPrice(new BigDecimal("0.30"), new BigDecimal("2.50"))));
    }

    private static AiUsageLog capture(AiUsageLogRepository repository) {
        final ArgumentCaptor<AiUsageLog> captor = ArgumentCaptor.forClass(AiUsageLog.class);
        verify(repository).save(captor.capture());
        return captor.getValue();
    }

    @Test
    @DisplayName("o Gemini grava provedor gemini e o custo calculado")
    void recordsGeminiWithCost() {
        final AiUsageLogRepository repository = mock(AiUsageLogRepository.class);
        when(repository.save(any(AiUsageLog.class))).thenAnswer(i -> i.getArgument(0));

        final LlmProperties properties =
                new LlmProperties("gemini", null, null, "chave-g", "gemini-3.5-flash", null, 0);
        final GeminiJsonClient client = new GeminiJsonClient(properties, RestClient.builder());

        new AiUsageRecorder(repository, pricing("gemini-3.5-flash"))
                .record(
                        USER,
                        AnalysisJobType.MEAL_PHOTO,
                        client,
                        new LlmJsonResult("{}", 1500, 400));

        final AiUsageLog saved = capture(repository);
        assertThat(saved.getProvider()).isEqualTo("gemini");
        assertThat(saved.getModel()).isEqualTo("gemini-3.5-flash");
        assertThat(saved.getOperation()).isEqualTo(AnalysisJobType.MEAL_PHOTO);
        assertThat(saved.getInputTokens()).isEqualTo(1500);
        assertThat(saved.getCostNanoUsd()).isEqualTo(1_450_000L);
    }

    @Test
    @DisplayName("a OpenAI grava provedor openai — é o que torna as linhas comparáveis")
    void recordsOpenAiProvider() {
        final AiUsageLogRepository repository = mock(AiUsageLogRepository.class);
        when(repository.save(any(AiUsageLog.class))).thenAnswer(i -> i.getArgument(0));

        final LlmProperties properties =
                new LlmProperties("openai", "chave-o", "gpt-5-mini", null, null, null, 0);
        final OpenAiJsonClient client = new OpenAiJsonClient(properties, RestClient.builder());

        new AiUsageRecorder(repository, pricing("gpt-5-mini"))
                .record(
                        USER,
                        AnalysisJobType.COACH_CHAT,
                        client,
                        new LlmJsonResult("{}", 1500, 400));

        final AiUsageLog saved = capture(repository);
        assertThat(saved.getProvider()).isEqualTo("openai");
        assertThat(saved.getModel()).isEqualTo("gpt-5-mini");
    }

    @Test
    @DisplayName("sem preço registrado grava a linha assim mesmo, com custo nulo")
    void recordsWithoutPrice() {
        final AiUsageLogRepository repository = mock(AiUsageLogRepository.class);
        when(repository.save(any(AiUsageLog.class))).thenAnswer(i -> i.getArgument(0));

        final LlmProperties properties =
                new LlmProperties("gemini", null, null, "chave-g", "modelo-novo", null, 0);
        final GeminiJsonClient client = new GeminiJsonClient(properties, RestClient.builder());

        // Preço é configuração e o app é entregue sem tabela: sem esta garantia, trocar de
        // modelo apagaria a trilha de consumo inteira em vez de só o custo dela.
        new AiUsageRecorder(repository, new LlmPricing(Map.of()))
                .record(
                        USER,
                        AnalysisJobType.WORKOUT_GENERATION,
                        client,
                        new LlmJsonResult("{}", 900, 300));

        final AiUsageLog saved = capture(repository);
        assertThat(saved.getModel()).isEqualTo("modelo-novo");
        assertThat(saved.getOutputTokens()).isEqualTo(300);
        assertThat(saved.getCostNanoUsd()).isNull();
    }

    @Test
    @DisplayName("a imagem é uma linha própria, com o preço do modelo de imagem")
    void recordsImageSeparately() {
        final AiUsageLogRepository repository = mock(AiUsageLogRepository.class);
        when(repository.save(any(AiUsageLog.class))).thenAnswer(i -> i.getArgument(0));

        final LlmProperties properties = new LlmProperties(
                "gemini", null, null, "chave-g", null, "gemini-3.1-flash-image", 0);
        final GeminiImageClient client = new GeminiImageClient(properties, RestClient.builder());

        // Somar a ilustração com a extração esconderia justamente o que precisa ser visto: que
        // ela custa múltiplos da análise que o usuário pediu.
        new AiUsageRecorder(repository, pricing("gemini-3.1-flash-image"))
                .recordImage(
                        USER,
                        AnalysisJobType.MEAL_PHOTO,
                        client,
                        new GeminiImageClient.GeneratedImage(
                                new byte[] {1}, "image/png", 1500, 400));

        final AiUsageLog saved = capture(repository);
        assertThat(saved.getProvider()).isEqualTo("gemini");
        assertThat(saved.getModel()).isEqualTo("gemini-3.1-flash-image");
        assertThat(saved.getCostNanoUsd()).isEqualTo(1_450_000L);
    }
}
