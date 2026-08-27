package com.myotrack.worker.handlers;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.myotrack.domain.AnalysisJobType;
import com.myotrack.domain.entity.AnalysisJob;
import com.myotrack.infrastructure.ai.AiUsageRecorder;
import com.myotrack.infrastructure.ai.LlmJsonClient;
import com.myotrack.infrastructure.ai.LlmJsonClient.LlmJsonResult;
import java.util.UUID;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.mockito.ArgumentCaptor;

/**
 * A estimativa de macros a partir do que o usuário escreveu.
 *
 * <p>Duas coisas separam este caminho do da foto, e são as duas que estes testes fixam. A
 * primeira é que ele <b>não persiste</b>: o resultado sai no {@code ResultJson} do job para o
 * usuário conferir, e é o {@code POST /manual} que grava depois. A segunda é a classificação do
 * erro — {@link IllegalStateException} encerra o job na primeira tentativa e qualquer outra
 * exceção o devolve para a fila. Trocar as duas é caro nos dois sentidos: erro de negócio
 * reprocessado gasta três chamadas de IA para falhar três vezes igual, e falha passageira tratada
 * como definitiva perde uma estimativa que a próxima tentativa entregaria.
 */
class MealTextEstimatorTest {

    private static final UUID ANA = UUID.fromString("11111111-1111-1111-1111-111111111111");

    private static final ObjectMapper MAPPER = new ObjectMapper();

    /** Uma resposta plausível do modelo para "2 ovos fritos e um pão francês". */
    private static final String RESPOSTA_DO_MODELO = """
            {"items":[
              {"description":"Ovo frito","quantityG":100,"kcal":240,
               "proteinG":15.6,"carbsG":1.2,"fatG":18.6},
              {"description":"Pão francês","quantityG":50,"kcal":150,
               "proteinG":4,"carbsG":29.3,"fatG":1.6}
            ]}
            """;

    private AiUsageRecorder aiUsage;
    private LlmJsonClient llm;
    private MealTextEstimator estimator;

    @BeforeEach
    void setUp() {
        aiUsage = mock(AiUsageRecorder.class);
        llm = mock(LlmJsonClient.class);
        estimator = new MealTextEstimator(aiUsage, llm);

        when(llm.isConfigured()).thenReturn(true);
        when(llm.generateJson(any(), any(), any()))
                .thenReturn(new LlmJsonResult(RESPOSTA_DO_MODELO, 300, 120));
    }

    private static AnalysisJob job(String texto) {
        final AnalysisJob job = new AnalysisJob();
        job.setId(UUID.randomUUID());
        job.setUserId(ANA);
        job.setType(AnalysisJobType.MEAL_PHOTO);
        job.setInputJson(texto == null
                ? null
                : "{\"mode\":\"text\",\"text\":\"%s\"}".formatted(texto));
        return job;
    }

    private JsonNode estimativaDe(String texto) throws Exception {
        return MAPPER.readTree(estimator.estimate(job(texto)));
    }

    @Test
    @DisplayName("devolve os itens e os totais somados pelo validador")
    void devolveItensETotais() throws Exception {
        final JsonNode meal = estimativaDe("2 ovos fritos e um pão francês");

        assertThat(meal.path("items").size()).isEqualTo(2);
        assertThat(meal.path("items").get(0).path("description").asText())
                .isEqualTo("Ovo frito");
        // Os totais são do servidor, como em toda refeição: o modelo nem é convidado a somá-los.
        assertThat(meal.path("totalKcal").decimalValue()).isEqualByComparingTo("390");
        assertThat(meal.path("totalProteinG").decimalValue()).isEqualByComparingTo("19.6");
        assertThat(meal.path("totalCarbsG").decimalValue()).isEqualByComparingTo("30.5");
        assertThat(meal.path("totalFatG").decimalValue()).isEqualByComparingTo("20.2");
    }

    @Test
    @DisplayName("manda o texto do usuário como prompt, sem reescrevê-lo")
    void mandaOTextoDoUsuario() {
        estimator.estimate(job("2 ovos fritos e um pão francês"));

        final ArgumentCaptor<String> userPrompt = ArgumentCaptor.forClass(String.class);
        verify(llm).generateJson(any(), userPrompt.capture(), any());

        assertThat(userPrompt.getValue()).isEqualTo("2 ovos fritos e um pão francês");
    }

    @Test
    @DisplayName("o consumo é registrado como MealPhoto — é o balde que a cota conta")
    void registraConsumoNoBaldeDaRefeicao() {
        estimator.estimate(job("2 ovos fritos"));

        // Uma operação própria aqui separaria o custo no relatório, mas descolaria a
        // contabilidade da cota, que conta jobs MEAL_PHOTO. Um número só, dos dois lados.
        verify(aiUsage).record(eq(ANA), eq(AnalysisJobType.MEAL_PHOTO), eq(llm), any());
    }

    @Test
    @DisplayName("passa pelo saneamento do MealPhotoValidator")
    void saneiaComoAFoto() throws Exception {
        // Quantidade absurda presa à faixa, e caloria reconciliada com os macros: é a mesma
        // aritmética da foto, e é o que garante que "meio quilo de arroz" não vire dois quilos.
        when(llm.generateJson(any(), any(), any())).thenReturn(new LlmJsonResult("""
                {"items":[{"description":"Arroz","quantityG":9000,"kcal":99999,
                           "proteinG":-4,"carbsG":44,"fatG":1}]}
                """, 10, 10));

        final JsonNode item = estimativaDe("muito arroz").path("items").get(0);

        assertThat(item.path("quantityG").decimalValue()).isEqualByComparingTo("2000");
        assertThat(item.path("proteinG").decimalValue()).isEqualByComparingTo("0");
        // 44 g de carboidrato e 1 g de gordura não fazem 99 999 kcal; vence a conta, não o modelo.
        assertThat(item.path("kcal").decimalValue()).isEqualByComparingTo("185");
    }

    @Test
    @DisplayName("sem chave de IA o job falha de vez, em vez de esperar por algo que não vem")
    void semChaveDeIa() {
        when(llm.isConfigured()).thenReturn(false);

        // Ao contrário de treino e dieta, não há motor de regras para cair: nada adivinha quantos
        // gramas cabem em "um pão com manteiga" sem um modelo de linguagem.
        assertThatThrownBy(() -> estimator.estimate(job("2 ovos fritos")))
                .isInstanceOf(IllegalStateException.class)
                .hasMessageContaining("indisponível");
    }

    @Test
    @DisplayName("modelo mudo é falha passageira: o job volta para a fila")
    void modeloMudoEhPassageiro() {
        when(llm.generateJson(any(), any(), any())).thenReturn(null);

        // Não é IllegalStateException de propósito — cota momentânea e instabilidade se resolvem
        // na próxima tentativa, e o poller só reprocessa o que não for erro de negócio.
        assertThatThrownBy(() -> estimator.estimate(job("2 ovos fritos")))
                .isInstanceOf(IllegalArgumentException.class);
    }

    @Test
    @DisplayName("texto sem comida nenhuma não vira refeição de zero caloria")
    void textoSemComida() {
        when(llm.generateJson(any(), any(), any()))
                .thenReturn(new LlmJsonResult("{\"items\":[]}", 10, 5));

        assertThatThrownBy(() -> estimator.estimate(job("asdfgh")))
                .isInstanceOf(IllegalStateException.class)
                .hasMessageContaining("Não entendemos");
    }

    @Test
    @DisplayName("job sem descrição falha de vez: reprocessar não a inventa")
    void jobSemDescricao() {
        assertThatThrownBy(() -> estimator.estimate(job(null)))
                .isInstanceOf(IllegalStateException.class);
    }

    @Test
    @DisplayName("resposta ilegível do modelo não vaza a exceção de parsing")
    void respostaIlegivel() {
        when(llm.generateJson(any(), any(), any()))
                .thenReturn(new LlmJsonResult("isto não é json", 10, 5));

        // Vira a mesma mensagem de "não entendemos", que é o que o usuário precisa ler. Um
        // JsonParseException no lastError do job iria direto para a tela dele.
        assertThatThrownBy(() -> estimator.estimate(job("2 ovos fritos")))
                .isInstanceOf(IllegalStateException.class)
                .hasMessageContaining("Não entendemos");
    }
}
