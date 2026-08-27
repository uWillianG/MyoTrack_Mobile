package com.myotrack.api.meals;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.myotrack.api.billing.EntitlementService;
import com.myotrack.api.meals.MealAnalysesController.AnalysisView;
import com.myotrack.api.meals.MealAnalysesController.EstimateRequest;
import com.myotrack.api.meals.MealAnalysesController.ManualItem;
import com.myotrack.api.meals.MealAnalysesController.ManualRequest;
import com.myotrack.domain.AnalysisJobType;
import com.myotrack.domain.MealSource;
import com.myotrack.domain.SubscriptionPlanType;
import com.myotrack.domain.entity.AnalysisJob;
import com.myotrack.domain.entity.FoodItem;
import com.myotrack.domain.entity.MealPhotoAnalysis;
import com.myotrack.infrastructure.repository.AnalysisJobRepository;
import com.myotrack.infrastructure.repository.FoodItemRepository;
import com.myotrack.infrastructure.repository.MealPhotoAnalysisRepository;
import com.myotrack.infrastructure.storage.MediaStorage;
import java.math.BigDecimal;
import java.time.OffsetDateTime;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import java.util.stream.IntStream;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;
import org.mockito.ArgumentCaptor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.security.oauth2.server.resource.authentication.JwtAuthenticationToken;

/**
 * A entrada de refeição sem foto.
 *
 * <p>Três coisas se protegem aqui, e todas as três têm o mesmo sintoma quando quebram — um diário
 * que fecha o dia com um número que não corresponde ao que a pessoa comeu, sem erro nenhum no
 * caminho:
 *
 * <ul>
 *   <li><b>O total é do servidor.</b> O cliente manda itens, nunca somas. É o total que o diário
 *       soma e que a meta compara.</li>
 *   <li><b>O catálogo vence o cliente.</b> Item com {@code foodItemId} tem os macros recalculados
 *       a partir da tabela; aceitar os números que vieram junto tornaria o vínculo decorativo, e
 *       "150 g de arroz" poderia valer zero caloria.</li>
 *   <li><b>A estimativa por texto não grava.</b> Ela existe para ser conferida e editada antes de
 *       virar caloria contada; uma linha gravada antes disso já contou errado no caminho.</li>
 * </ul>
 */
class MealAnalysesControllerTest {

    private static final UUID ANA = UUID.fromString("11111111-1111-1111-1111-111111111111");

    private static final ObjectMapper MAPPER = new ObjectMapper();

    /** Arroz branco cozido, por 100 g — os mesmos números do catálogo semeado. */
    private static final FoodItem ARROZ = food(1, "Arroz branco cozido", "128", "2.5", "28.1", "0.2");

    private MealPhotoAnalysisRepository analyses;
    private AnalysisJobRepository jobs;
    private FoodItemRepository foods;
    private EntitlementService entitlements;
    private MealAnalysesController controller;

    @BeforeEach
    void setUp() {
        analyses = mock(MealPhotoAnalysisRepository.class);
        jobs = mock(AnalysisJobRepository.class);
        foods = mock(FoodItemRepository.class);
        final MediaStorage storage = mock(MediaStorage.class);
        entitlements = mock(EntitlementService.class);

        controller = new MealAnalysesController(analyses, jobs, foods, storage, entitlements);

        signedInAs(ANA);
        planoComLimite(10);
        usadasHoje(0);

        when(foods.findAllById(any())).thenReturn(List.of());
        when(analyses.save(any())).thenAnswer(invocation -> {
            final MealPhotoAnalysis saved = invocation.getArgument(0);
            if (saved.getId() == null) {
                saved.setId(UUID.randomUUID());
            }
            return saved;
        });
        when(jobs.save(any())).thenAnswer(invocation -> {
            final AnalysisJob saved = invocation.getArgument(0);
            if (saved.getId() == null) {
                saved.setId(UUID.randomUUID());
            }
            return saved;
        });
    }

    @AfterEach
    void tearDown() {
        SecurityContextHolder.clearContext();
    }

    private static void signedInAs(UUID userId) {
        final Jwt jwt = Jwt.withTokenValue("t")
                .header("alg", "none")
                .subject(userId.toString())
                .build();
        SecurityContextHolder.getContext()
                .setAuthentication(new JwtAuthenticationToken(jwt, List.of()));
    }

    private void planoComLimite(int maxMealAnalysesPerDay) {
        when(entitlements.get(any())).thenReturn(new EntitlementService.Entitlements(
                SubscriptionPlanType.FREE, maxMealAnalysesPerDay, 5, 10, false));
    }

    private void usadasHoje(long count) {
        when(jobs.countByUserIdAndTypeAndCreatedAtGreaterThanEqual(any(), any(), any()))
                .thenReturn(count);
    }

    private static FoodItem food(
            int id, String name, String kcal, String protein, String carbs, String fat) {
        final FoodItem item = new FoodItem();
        item.setId(id);
        item.setName(name);
        item.setKcalPer100g(new BigDecimal(kcal));
        item.setProteinPer100g(new BigDecimal(protein));
        item.setCarbsPer100g(new BigDecimal(carbs));
        item.setFatPer100g(new BigDecimal(fat));
        return item;
    }

    /** Item digitado à mão: sem vínculo com o catálogo, todos os números vêm do cliente. */
    private static ManualItem digitado(
            String description, String quantityG,
            String kcal, String protein, String carbs, String fat) {
        return new ManualItem(
                description,
                null,
                new BigDecimal(quantityG),
                new BigDecimal(kcal),
                new BigDecimal(protein),
                new BigDecimal(carbs),
                new BigDecimal(fat));
    }

    private MealPhotoAnalysis gravada() {
        final ArgumentCaptor<MealPhotoAnalysis> captor =
                ArgumentCaptor.forClass(MealPhotoAnalysis.class);
        verify(analyses).save(captor.capture());
        return captor.getValue();
    }

    private AnalysisJob enfileirado() {
        final ArgumentCaptor<AnalysisJob> captor = ArgumentCaptor.forClass(AnalysisJob.class);
        verify(jobs).save(captor.capture());
        return captor.getValue();
    }

    @SuppressWarnings("unchecked")
    private static String erroDe(ResponseEntity<?> response) {
        return ((Map<String, String>) response.getBody()).get("error");
    }

    @Nested
    @DisplayName("na refeição manual")
    class Manual {

        @Test
        @DisplayName("soma os totais no servidor a partir dos itens")
        void somaOsTotais() {
            final ResponseEntity<?> response = controller.manual(new ManualRequest(List.of(
                    digitado("Ovo frito", "100", "240", "15.6", "1.2", "18.6"),
                    digitado("Pão francês", "50", "150", "4", "29.3", "1.6")), null));

            assertThat(response.getStatusCode()).isEqualTo(HttpStatus.CREATED);

            final MealPhotoAnalysis meal = gravada();
            assertThat(meal.getTotalKcal()).isEqualByComparingTo("390");
            assertThat(meal.getTotalProteinG()).isEqualByComparingTo("19.6");
            assertThat(meal.getTotalCarbsG()).isEqualByComparingTo("30.5");
            assertThat(meal.getTotalFatG()).isEqualByComparingTo("20.2");
        }

        @Test
        @DisplayName("grava como Manual, sem foto e sem job")
        void gravaComoManual() {
            controller.manual(new ManualRequest(
                    List.of(digitado("Ovo frito", "100", "240", "15.6", "1.2", "18.6")), null));

            final MealPhotoAnalysis meal = gravada();
            assertThat(meal.getSource()).isEqualTo(MealSource.MANUAL);
            assertThat(meal.getMediaKey()).isNull();
            assertThat(meal.getAnalysisJobId()).isNull();
            // userAdjusted mede "a estimativa da IA precisou de correção". Uma refeição que nunca
            // foi estimada marcaria um erro do modelo que não houve.
            assertThat(meal.isUserAdjusted()).isFalse();
            assertThat(meal.isExcludedFromDiary()).isFalse();
        }

        @Test
        @DisplayName("item do catálogo tem os macros calculados aqui, não pelo cliente")
        void catalogoVenceOCliente() {
            // O cliente manda zeros de propósito: se eles fossem aceitos, o vínculo com o
            // alimento seria decorativo e 150 g de arroz entrariam no diário valendo nada.
            when(foods.findAllById(any())).thenReturn(List.of(ARROZ));

            controller.manual(new ManualRequest(List.of(new ManualItem(
                    null, 1, new BigDecimal("150"),
                    BigDecimal.ZERO, BigDecimal.ZERO, BigDecimal.ZERO, BigDecimal.ZERO)), null));

            final MealPhotoAnalysis meal = gravada();
            assertThat(meal.getTotalKcal()).isEqualByComparingTo("192");
            assertThat(meal.getTotalProteinG()).isEqualByComparingTo("3.8");
            assertThat(meal.getTotalCarbsG()).isEqualByComparingTo("42.2");
            // Descrição em branco cai para o nome do catálogo: um item sem rótulo na tela é um
            // número que o usuário não consegue conferir.
            assertThat(meal.getItemsJson()).contains("Arroz branco cozido");
        }

        @Test
        @DisplayName("alimento que não está no catálogo é recusado, e não ignorado")
        void alimentoDesconhecido() {
            // Diferente do PUT de ajuste, onde o id inválido só perde o vínculo: aqui o cliente
            // pode estar contando que o servidor calcule a porção, e ignorar o id gravaria os
            // zeros que ele mandou no lugar dos macros.
            when(foods.findAllById(any())).thenReturn(List.of());

            final ResponseEntity<?> response = controller.manual(new ManualRequest(List.of(
                    new ManualItem(null, 999, new BigDecimal("150"),
                            BigDecimal.ZERO, BigDecimal.ZERO, BigDecimal.ZERO, BigDecimal.ZERO)),
                    null));

            assertThat(response.getStatusCode()).isEqualTo(HttpStatus.BAD_REQUEST);
            assertThat(erroDe(response)).contains("catálogo");
            verify(analyses, never()).save(any());
        }

        @Test
        @DisplayName("passa pelo mesmo saneamento da saída da IA")
        void saneiaComoAResposta_daIa() {
            // O cliente também é entrada não confiável. Macro negativo vira zero, e a caloria é
            // reconciliada com os macros — o mesmo caminho que a foto percorre.
            final ResponseEntity<?> response = controller.manual(new ManualRequest(
                    List.of(digitado("Salada", "100", "20", "-5", "4", "0")), null));

            assertThat(response.getStatusCode()).isEqualTo(HttpStatus.CREATED);
            assertThat(gravada().getTotalProteinG()).isEqualByComparingTo("0");
        }

        @Test
        @DisplayName("lista vazia não vira refeição de zero caloria")
        void listaVazia() {
            assertThat(controller.manual(new ManualRequest(List.of(), null)).getStatusCode())
                    .isEqualTo(HttpStatus.BAD_REQUEST);
            assertThat(controller.manual(new ManualRequest(null, null)).getStatusCode())
                    .isEqualTo(HttpStatus.BAD_REQUEST);
            verify(analyses, never()).save(any());
        }

        @Test
        @DisplayName("nenhum item aproveitável é recusado em vez de gravar refeição vazia")
        void nenhumItemAproveitavel() {
            final ResponseEntity<?> response = controller.manual(new ManualRequest(
                    List.of(digitado("   ", "0", "0", "0", "0", "0")), null));

            assertThat(response.getStatusCode()).isEqualTo(HttpStatus.BAD_REQUEST);
            verify(analyses, never()).save(any());
        }

        @Test
        @DisplayName("lista longa é recusada, e não cortada em silêncio")
        void listaLonga() {
            // O validador corta o excedente, que é a resposta certa para um modelo que
            // fragmentou demais e a errada para quem digitou item por item: os últimos sumiriam
            // da tela sem explicação.
            final List<ManualItem> muitos = IntStream.rangeClosed(1, 25)
                    .mapToObj(i -> digitado("Item " + i, "10", "10", "1", "1", "0"))
                    .toList();

            final ResponseEntity<?> response =
                    controller.manual(new ManualRequest(muitos, null));

            assertThat(response.getStatusCode()).isEqualTo(HttpStatus.BAD_REQUEST);
            assertThat(erroDe(response)).contains("20");
            verify(analyses, never()).save(any());
        }

        @Test
        @DisplayName("aceita registrar o almoço à noite, preservando a hora informada")
        void aceitaRetroativoRecente() {
            // É o caso que faz o campo existir: quem digita à mão quase sempre está lançando uma
            // refeição de horas atrás, e o diário é por dia.
            final OffsetDateTime almoco = OffsetDateTime.now().minusHours(9);

            controller.manual(new ManualRequest(
                    List.of(digitado("Arroz", "150", "192", "3.8", "42.2", "0.3")), almoco));

            assertThat(gravada().getCreatedAt()).isEqualTo(almoco);
        }

        @Test
        @DisplayName("recusa refeição no futuro e refeição velha demais")
        void recusaDataForaDaJanela() {
            final List<ManualItem> item =
                    List.of(digitado("Arroz", "150", "192", "3.8", "42.2", "0.3"));

            assertThat(controller.manual(
                    new ManualRequest(item, OffsetDateTime.now().plusDays(1))).getStatusCode())
                    .isEqualTo(HttpStatus.BAD_REQUEST);
            // Mais de 30 dias: a semana já fechada em relatório não deveria mudar de valor.
            assertThat(controller.manual(
                    new ManualRequest(item, OffsetDateTime.now().minusDays(45))).getStatusCode())
                    .isEqualTo(HttpStatus.BAD_REQUEST);

            verify(analyses, never()).save(any());
        }

        @Test
        @DisplayName("não consome a cota de IA: não houve chamada de IA")
        void naoConsomeCota() {
            planoComLimite(10);
            usadasHoje(10);

            final ResponseEntity<?> response = controller.manual(new ManualRequest(
                    List.of(digitado("Arroz", "150", "192", "3.8", "42.2", "0.3")), null));

            assertThat(response.getStatusCode()).isEqualTo(HttpStatus.CREATED);
        }

        @Test
        @DisplayName("devolve a refeição já no formato que a listagem usa")
        void devolveAView() {
            final ResponseEntity<?> response = controller.manual(new ManualRequest(
                    List.of(digitado("Arroz", "150", "192", "3.8", "42.2", "0.3")), null));

            final AnalysisView view = (AnalysisView) response.getBody();
            assertThat(view).isNotNull();
            assertThat(view.source()).isEqualTo(MealSource.MANUAL);
            assertThat(view.analysisJobId()).isNull();
            assertThat(view.photoUrl()).isNull();
            assertThat(view.items()).hasSize(1);
            assertThat(view.totalKcal()).isEqualByComparingTo("192");
        }
    }

    @Nested
    @DisplayName("na estimativa por texto")
    class Estimativa {

        @Test
        @DisplayName("enfileira como MealPhoto — é o tipo que a cota diária conta")
        void enfileiraComoMealPhoto() {
            final ResponseEntity<?> response =
                    controller.estimate(new EstimateRequest("2 ovos fritos e um pão francês"));

            assertThat(response.getStatusCode()).isEqualTo(HttpStatus.ACCEPTED);

            final AnalysisJob job = enfileirado();
            // Um tipo próprio ficaria invisível para countByUserIdAndType(..., MEAL_PHOTO, hoje),
            // e a estimativa por texto seria uma chamada de IA de graça, todo dia, sem limite.
            assertThat(job.getType()).isEqualTo(AnalysisJobType.MEAL_PHOTO);
            assertThat(job.getUserId()).isEqualTo(ANA);
            assertThat(job.getMediaKey()).isNull();
        }

        @Test
        @DisplayName("não grava nada no diário")
        void naoGravaNada() {
            controller.estimate(new EstimateRequest("2 ovos fritos"));

            // O valor da estimativa está em ser conferida e editada antes de virar caloria
            // contada. Gravar aqui já teria contado errado no caminho.
            verify(analyses, never()).save(any());
        }

        @Test
        @DisplayName("o texto do usuário sobrevive a aspas no inputJson")
        void textoComAspas() throws Exception {
            // O caminho da foto monta o inputJson por concatenação, e pode: só entram valores que
            // o servidor escolheu. Aqui entra texto digitado, e uma aspa no meio da frase
            // quebraria o JSON de uma coluna jsonb — a inserção falharia inteira.
            final String texto = "pão com \"requeijão\" e café";

            controller.estimate(new EstimateRequest(texto));

            final var input = MAPPER.readTree(enfileirado().getInputJson());
            assertThat(input.path("mode").asText()).isEqualTo("text");
            assertThat(input.path("text").asText()).isEqualTo(texto);
        }

        @Test
        @DisplayName("texto em branco não gasta uma chamada de IA")
        void textoEmBranco() {
            assertThat(controller.estimate(new EstimateRequest("   ")).getStatusCode())
                    .isEqualTo(HttpStatus.BAD_REQUEST);
            assertThat(controller.estimate(new EstimateRequest(null)).getStatusCode())
                    .isEqualTo(HttpStatus.BAD_REQUEST);
            verify(jobs, never()).save(any());
        }

        @Test
        @DisplayName("texto colado é recusado: cada caractere é token pago")
        void textoLongo() {
            final String longo = "arroz ".repeat(200);

            final ResponseEntity<?> response = controller.estimate(new EstimateRequest(longo));

            assertThat(response.getStatusCode()).isEqualTo(HttpStatus.BAD_REQUEST);
            verify(jobs, never()).save(any());
        }

        @Test
        @DisplayName("gasta o mesmo balde da análise por foto")
        void compartilhaACotaDaFoto() {
            planoComLimite(10);
            usadasHoje(10);

            final ResponseEntity<?> response =
                    controller.estimate(new EstimateRequest("2 ovos fritos"));

            // 429 é o que o app reconhece como limite atingido para oferecer o Pro.
            assertThat(response.getStatusCode()).isEqualTo(HttpStatus.TOO_MANY_REQUESTS);
            assertThat(erroDe(response)).contains("Assine o Pro");
            verify(jobs, never()).save(any());
        }

        @Test
        @DisplayName("a contagem olha os jobs de refeição do dia, e não outra tabela")
        void contagemVemDaFila() {
            controller.estimate(new EstimateRequest("2 ovos fritos"));

            final ArgumentCaptor<AnalysisJobType> tipo =
                    ArgumentCaptor.forClass(AnalysisJobType.class);
            verify(jobs).countByUserIdAndTypeAndCreatedAtGreaterThanEqual(
                    any(), tipo.capture(), any());

            assertThat(tipo.getValue()).isEqualTo(AnalysisJobType.MEAL_PHOTO);
        }
    }
}
