package com.myotrack.worker.handlers;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.verifyNoInteractions;
import static org.mockito.Mockito.when;

import com.myotrack.domain.AnalysisJobType;
import com.myotrack.domain.entity.AnalysisJob;
import com.myotrack.infrastructure.ai.AiUsageRecorder;
import com.myotrack.infrastructure.ai.GeminiImageClient;
import com.myotrack.infrastructure.ai.LlmJsonClient;
import com.myotrack.infrastructure.repository.FoodItemRepository;
import com.myotrack.infrastructure.repository.MealPhotoAnalysisRepository;
import com.myotrack.infrastructure.storage.MediaStorage;
import java.util.UUID;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

/**
 * O desvio entre os dois caminhos do job de refeição.
 *
 * <p>Foto e descrição compartilham o tipo {@code MEAL_PHOTO} porque é <b>o tipo</b> que a cota
 * diária conta: um tipo novo ficaria invisível para
 * {@code countByUserIdAndType(..., MEAL_PHOTO, hoje)} e a estimativa por texto seria uma chamada
 * de IA de graça, todo dia. O preço dessa escolha é este desvio, e o risco dele é retroativo — a
 * fila pode conter jobs de foto gravados antes de a entrada manual existir, e eles não têm o
 * campo que decide o caminho. Tratá-los como texto os faria falhar em massa.
 */
class MealPhotoHandlerTest {

    private static final UUID ANA = UUID.fromString("11111111-1111-1111-1111-111111111111");

    private MealPhotoAnalysisRepository analyses;
    private MediaStorage storage;
    private MealTextEstimator textEstimator;
    private MealPhotoHandler handler;

    @BeforeEach
    void setUp() {
        analyses = mock(MealPhotoAnalysisRepository.class);
        storage = mock(MediaStorage.class);
        textEstimator = mock(MealTextEstimator.class);

        final LlmJsonClient llm = mock(LlmJsonClient.class);
        when(llm.isConfigured()).thenReturn(true);

        handler = new MealPhotoHandler(
                analyses,
                mock(FoodItemRepository.class),
                mock(AiUsageRecorder.class),
                storage,
                llm,
                mock(GeminiImageClient.class),
                textEstimator);
    }

    private static AnalysisJob job(String inputJson, String mediaKey) {
        final AnalysisJob job = new AnalysisJob();
        job.setId(UUID.randomUUID());
        job.setUserId(ANA);
        job.setType(AnalysisJobType.MEAL_PHOTO);
        job.setInputJson(inputJson);
        job.setMediaKey(mediaKey);
        return job;
    }

    @Test
    @DisplayName("registra-se como MealPhoto: é o tipo que a cota diária conta")
    void tipoDoHandler() {
        assertThat(handler.type()).isEqualTo(AnalysisJobType.MEAL_PHOTO);
    }

    @Test
    @DisplayName("job com mode=text vai para o estimador e não toca no storage")
    void desviaParaOTexto() {
        final AnalysisJob job = job("{\"mode\":\"text\",\"text\":\"2 ovos fritos\"}", null);
        when(textEstimator.estimate(job)).thenReturn("{\"items\":[]}");

        assertThat(handler.handle(job)).isEqualTo("{\"items\":[]}");

        verify(textEstimator).estimate(job);
        // Nada de storage e nada gravado: a estimativa devolve uma proposta para conferência, e
        // não uma linha do diário.
        verifyNoInteractions(storage);
        verify(analyses, never()).save(any());
    }

    @Test
    @DisplayName("job antigo, sem inputJson, continua sendo o caminho da foto")
    void jobAntigoContinuaSendoFoto() {
        // A fila pode ter jobs gravados antes de a entrada manual existir. Se a ausência de
        // "mode" fosse lida como texto, todos eles falhariam de uma vez.
        assertThatThrownBy(() -> handler.handle(job(null, null)))
                .isInstanceOf(IllegalStateException.class)
                .hasMessageContaining("foto");

        verifyNoInteractions(textEstimator);
    }

    @Test
    @DisplayName("job de foto com inputJson próprio não é confundido com texto")
    void jobDeFotoComInput() {
        assertThatThrownBy(() -> handler.handle(
                job("{\"contentType\":\"image/jpeg\",\"illustrated\":false}", null)))
                .isInstanceOf(IllegalStateException.class)
                .hasMessageContaining("foto");

        verifyNoInteractions(textEstimator);
    }

    @Test
    @DisplayName("inputJson corrompido cai no caminho da foto, com a mensagem da foto")
    void inputCorrompido() {
        // Dizer "descrição inválida" para um job que talvez seja de foto mandaria o usuário
        // procurar o problema no lugar errado.
        assertThatThrownBy(() -> handler.handle(job("{isto não é json", "meals/ana/x.jpg")))
                .isInstanceOf(RuntimeException.class);

        verifyNoInteractions(textEstimator);
    }
}
