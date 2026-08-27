package com.myotrack.domain.service;

import java.math.BigDecimal;
import java.math.MathContext;
import java.math.RoundingMode;
import java.util.ArrayList;
import java.util.List;
import java.util.Optional;
import java.util.Set;

/**
 * Valida e corrige a análise de refeição devolvida pelo LLM a partir da foto.
 *
 * <p><b>O modelo é tratado como entrada não confiável</b>, como no {@link LlmDietValidator}, mas o
 * problema aqui é outro. Na dieta o modelo escolhe de um catálogo fechado; na foto ele estima
 * texto livre, e erra de dois jeitos que importam:
 *
 * <ul>
 *   <li><b>Aritmética.</b> É comum devolver macros plausíveis e calorias que não correspondem a
 *       eles. Como o número que o usuário leva para o diário é a caloria, ela é recalculada pelos
 *       fatores de Atwater quando destoa demais dos macros — quem garante a conta é o código.</li>
 *   <li><b>Ids inventados.</b> O {@code foodItemId} liga o item ao catálogo e serve para melhorar
 *       a estimativa depois; um id que não existe é pior que nenhum, então vira null.</li>
 * </ul>
 *
 * <p>Ao contrário da dieta, <b>não há motor de regras para cair</b>: não se adivinha o que havia
 * num prato sem olhar a foto. Proposta inválida devolve vazio e o job falha com mensagem.
 */
public final class MealPhotoValidator {

    private static final MathContext MC = MathContext.DECIMAL128;

    /**
     * Um prato tem alguns itens, não dezenas — acima disso o modelo está fragmentando demais.
     *
     * <p>Público porque a entrada manual precisa <b>recusar</b> a lista longa com uma mensagem,
     * em vez de aceitá-la e cortar em silêncio como se faz com a saída do modelo. A diferença é
     * de quem está do outro lado: o modelo não lê mensagem de erro, o usuário digitou item por
     * item e merece saber que os últimos não entraram.
     */
    public static final int MAX_ITEMS = 20;

    private static final int MAX_DESCRIPTION_LENGTH = 120;

    /** Um item de refeição não pesa menos de 1 g nem mais que 2 kg. */
    private static final BigDecimal MIN_QUANTITY_G = BigDecimal.ONE;
    private static final BigDecimal MAX_QUANTITY_G = BigDecimal.valueOf(2000);

    /** Teto por item: acima disso a estimativa está claramente perdida. */
    private static final BigDecimal MAX_KCAL_PER_ITEM = BigDecimal.valueOf(5000);

    /** Fatores de Atwater: kcal por grama de cada macro. */
    private static final BigDecimal KCAL_PER_PROTEIN_G = BigDecimal.valueOf(4);
    private static final BigDecimal KCAL_PER_CARB_G = BigDecimal.valueOf(4);
    private static final BigDecimal KCAL_PER_FAT_G = BigDecimal.valueOf(9);

    /**
     * Margem tolerada entre a caloria informada e a derivada dos macros.
     *
     * <p>Não é zero porque álcool, fibra e poliois fogem de Atwater, e arredondamento de rótulo
     * também afasta um pouco. Acima disso não é imprecisão, é contradição.
     */
    private static final BigDecimal KCAL_TOLERANCE = new BigDecimal("0.25");

    private MealPhotoValidator() {
    }

    /** Análise proposta pelo LLM, no formato do JSON Schema pedido a ele. */
    public record LlmMealPhoto(List<LlmDetectedItem> items) {
    }

    public record LlmDetectedItem(
            String description,
            Integer foodItemId,
            BigDecimal quantityG,
            BigDecimal kcal,
            BigDecimal proteinG,
            BigDecimal carbsG,
            BigDecimal fatG,
            Integer posX,
            Integer posY) {
    }

    /** Item já validado, no formato que vai para o {@code ItemsJson} e para a tela. */
    /**
     * Item já validado, no formato que vai para o {@code ItemsJson} e para a tela.
     *
     * @param posX centro do alimento na imagem, escala 0–1000; null quando o modelo não
     *     soube dizer. Serve só para desenhar a etiqueta na versão ilustrada — nenhum número
     *     nutricional depende disso.
     */
    public record AnalyzedItem(
            String description,
            Integer foodItemId,
            BigDecimal quantityG,
            BigDecimal kcal,
            BigDecimal proteinG,
            BigDecimal carbsG,
            BigDecimal fatG,
            Integer posX,
            Integer posY) {
    }

    public record AnalyzedMeal(
            List<AnalyzedItem> items,
            BigDecimal totalKcal,
            BigDecimal totalProteinG,
            BigDecimal totalCarbsG,
            BigDecimal totalFatG) {
    }

    /**
     * Devolve a análise saneada, ou vazio quando não sobrou nenhum item aproveitável.
     *
     * @param proposal o que o LLM respondeu
     * @param knownFoodItemIds ids existentes no catálogo; recebe o conjunto e não a lista de
     *     alimentos porque a única pergunta feita aqui é "este id existe?"
     */
    public static Optional<AnalyzedMeal> validate(
            LlmMealPhoto proposal, Set<Integer> knownFoodItemIds) {

        if (proposal == null || proposal.items() == null || proposal.items().isEmpty()) {
            return Optional.empty();
        }

        final List<AnalyzedItem> items = new ArrayList<>();

        for (final LlmDetectedItem raw : proposal.items()) {
            if (items.size() >= MAX_ITEMS) {
                break;
            }
            sanitize(raw, knownFoodItemIds).ifPresent(items::add);
        }

        return items.isEmpty() ? Optional.empty() : Optional.of(totalsOf(items));
    }

    /**
     * Recalcula os totais de uma lista de itens.
     *
     * <p>É o mesmo caminho da correção manual: quando o usuário ajusta uma quantidade, quem soma
     * de novo é o servidor — deixar o total vir do cliente permitiria gravar um dia inteiro de
     * calorias que não corresponde aos itens.
     */
    public static AnalyzedMeal totalsOf(List<AnalyzedItem> items) {
        BigDecimal kcal = BigDecimal.ZERO;
        BigDecimal protein = BigDecimal.ZERO;
        BigDecimal carbs = BigDecimal.ZERO;
        BigDecimal fat = BigDecimal.ZERO;

        for (final AnalyzedItem item : items) {
            kcal = kcal.add(item.kcal());
            protein = protein.add(item.proteinG());
            carbs = carbs.add(item.carbsG());
            fat = fat.add(item.fatG());
        }

        return new AnalyzedMeal(
                List.copyOf(items),
                kcal.setScale(0, RoundingMode.HALF_UP),
                grams(protein),
                grams(carbs),
                grams(fat));
    }

    private static Optional<AnalyzedItem> sanitize(
            LlmDetectedItem raw, Set<Integer> knownFoodItemIds) {

        if (raw == null || raw.description() == null || raw.description().isBlank()) {
            return Optional.empty();
        }

        // Sem peso não dá para corrigir a estimativa depois, e corrigir a quantidade é
        // justamente o que a tela oferece — um item assim seria um número intocável.
        final BigDecimal quantityG = clamp(raw.quantityG(), MIN_QUANTITY_G, MAX_QUANTITY_G);
        if (quantityG == null) {
            return Optional.empty();
        }

        final BigDecimal protein = nonNegative(raw.proteinG());
        final BigDecimal carbs = nonNegative(raw.carbsG());
        final BigDecimal fat = nonNegative(raw.fatG());

        String description = raw.description().trim();
        if (description.length() > MAX_DESCRIPTION_LENGTH) {
            description = description.substring(0, MAX_DESCRIPTION_LENGTH).trim();
        }

        final Integer foodItemId =
                raw.foodItemId() != null && knownFoodItemIds.contains(raw.foodItemId())
                        ? raw.foodItemId()
                        : null;

        return Optional.of(new AnalyzedItem(
                description,
                foodItemId,
                grams(quantityG),
                reconcileKcal(raw.kcal(), protein, carbs, fat),
                grams(protein),
                grams(carbs),
                grams(fat),
                position(raw.posX()),
                position(raw.posY())));
    }

    /**
     * A caloria do item: a informada, quando bate com os macros, e a derivada quando não bate.
     *
     * <p>Com todos os macros zerados não há como derivar nada, e aí a informada é o único dado
     * que existe — é o caso de café preto ou refrigerante zero, onde a resposta correta pode ser
     * mesmo zero.
     */
    private static BigDecimal reconcileKcal(
            BigDecimal reported, BigDecimal protein, BigDecimal carbs, BigDecimal fat) {

        final BigDecimal derived = protein.multiply(KCAL_PER_PROTEIN_G, MC)
                .add(carbs.multiply(KCAL_PER_CARB_G, MC), MC)
                .add(fat.multiply(KCAL_PER_FAT_G, MC), MC);

        final BigDecimal safeReported = capped(nonNegative(reported));

        if (derived.signum() == 0) {
            return safeReported.setScale(0, RoundingMode.HALF_UP);
        }
        if (safeReported.signum() == 0) {
            return capped(derived).setScale(0, RoundingMode.HALF_UP);
        }

        final BigDecimal deviation = safeReported.subtract(derived, MC).abs()
                .divide(derived, MC);

        final BigDecimal chosen = deviation.compareTo(KCAL_TOLERANCE) > 0 ? derived : safeReported;
        return capped(chosen).setScale(0, RoundingMode.HALF_UP);
    }

    /**
     * Coordenada na escala 0–1000, ou null quando fora dela.
     *
     * <p>Posição inválida vira null em vez de ser presa à borda: uma etiqueta encostada no
     * canto da foto engana mais do que uma etiqueta ausente, porque parece apontar para algo.
     */
    private static Integer position(Integer value) {
        return value == null || value < 0 || value > 1000 ? null : value;
    }

    private static BigDecimal capped(BigDecimal value) {
        return value.compareTo(MAX_KCAL_PER_ITEM) > 0 ? MAX_KCAL_PER_ITEM : value;
    }

    private static BigDecimal nonNegative(BigDecimal value) {
        return value == null || value.signum() < 0 ? BigDecimal.ZERO : value;
    }

    /** Null quando o valor não serve; caso contrário, preso à faixa. */
    private static BigDecimal clamp(BigDecimal value, BigDecimal min, BigDecimal max) {
        if (value == null || value.signum() <= 0) {
            return null;
        }
        if (value.compareTo(min) < 0) {
            return min;
        }
        return value.compareTo(max) > 0 ? max : value;
    }

    /** Uma casa decimal: grama com mais precisão que isso é ruído numa estimativa por foto. */
    private static BigDecimal grams(BigDecimal value) {
        return value.setScale(1, RoundingMode.HALF_UP);
    }
}
