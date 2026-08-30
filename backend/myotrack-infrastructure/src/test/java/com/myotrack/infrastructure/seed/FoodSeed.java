package com.myotrack.infrastructure.seed;

import com.myotrack.domain.entity.FoodItem;
import java.math.BigDecimal;
import java.util.List;

/**
 * Catálogo de alimentos <b>para testes</b>, valores por 100 g (base TACO 4ª ed., arredondados).
 *
 * <p>Já foi o seed de produção — o {@code DbSeeder} o gravava no primeiro boot com banco vazio.
 * Não é mais: o catálogo passou a ser semeado por migração Flyway ({@code V8__food_catalog_seed}),
 * que é o único jeito de um alimento novo entrar num banco que já tem alimentos. Esta lista
 * sobreviveu porque os testes do motor de dieta precisam de um catálogo pequeno, fixo e legível
 * no próprio arquivo; parear um teste com duas centenas de linhas de SQL tornaria ilegível o que
 * eles verificam.
 *
 * <p><b>Não é uma cópia reduzida do catálogo real</b>, e não deve ser mantida em sincronia com
 * ele: é uma amostra, e o que os testes afirmam vale para qualquer catálogo com estes macros.
 */
public final class FoodSeed {

    private FoodSeed() {
    }

    private static FoodItem f(String name, String kcal, String protein, String carbs, String fat) {
        return f(name, kcal, protein, carbs, fat, null);
    }

    private static FoodItem f(String name, String kcal, String protein, String carbs, String fat, String fiber) {
        FoodItem item = new FoodItem();
        item.setName(name);
        item.setKcalPer100g(new BigDecimal(kcal));
        item.setProteinPer100g(new BigDecimal(protein));
        item.setCarbsPer100g(new BigDecimal(carbs));
        item.setFatPer100g(new BigDecimal(fat));
        item.setFiberPer100g(fiber == null ? null : new BigDecimal(fiber));
        item.setSource("TACO");
        return item;
    }

    public static List<FoodItem> items() {
        return List.of(
                // Cereais e derivados
                f("Arroz branco cozido", "128", "2.5", "28.1", "0.2", "1.6"),
                f("Arroz integral cozido", "124", "2.6", "25.8", "1.0", "2.7"),
                f("Aveia em flocos crua", "394", "13.9", "66.6", "8.5", "9.1"),
                f("Pão francês", "300", "8.0", "58.6", "3.1", "2.3"),
                f("Pão integral de trigo", "253", "9.4", "49.9", "3.7", "6.9"),
                f("Macarrão cozido", "122", "3.9", "24.5", "1.3", "1.5"),
                f("Tapioca (goma hidratada)", "240", "0", "60.0", "0", "0"),
                f("Batata inglesa cozida", "52", "1.2", "11.9", "0", "1.3"),
                f("Batata-doce cozida", "77", "0.6", "18.4", "0.1", "2.2"),
                f("Mandioca cozida", "125", "0.6", "30.1", "0.3", "1.6"),

                // Leguminosas
                f("Feijão carioca cozido", "76", "4.8", "13.6", "0.5", "8.5"),
                f("Feijão preto cozido", "77", "4.5", "14.0", "0.5", "8.4"),
                f("Lentilha cozida", "93", "6.3", "16.3", "0.5", "7.9"),
                f("Grão-de-bico cozido", "164", "8.9", "27.4", "2.6", "7.6"),

                // Carnes e ovos
                f("Peito de frango grelhado (sem pele)", "159", "32.0", "0", "2.5"),
                f("Coxa de frango assada (sem pele)", "167", "26.9", "0", "5.8"),
                f("Carne bovina — patinho grelhado", "219", "35.9", "0", "7.3"),
                f("Carne bovina — acém moído cozido", "212", "26.7", "0", "10.9"),
                f("Carne suína — lombo assado", "210", "35.7", "0", "6.4"),
                f("Tilápia grelhada", "128", "26.0", "0", "2.0"),
                f("Sardinha assada", "164", "32.2", "0", "3.9"),
                f("Atum em conserva (água)", "108", "24.0", "0", "1.0"),
                f("Ovo de galinha cozido", "146", "13.3", "0.6", "9.5"),
                f("Clara de ovo cozida", "59", "13.4", "0", "0.1"),

                // Laticínios
                f("Leite integral", "61", "3.2", "4.6", "3.3"),
                f("Leite desnatado", "35", "3.4", "5.0", "0.2"),
                f("Iogurte natural integral", "51", "4.1", "1.9", "3.0"),
                f("Iogurte natural desnatado", "42", "3.8", "5.8", "0.3"),
                f("Queijo minas frescal", "264", "17.4", "3.2", "20.2"),
                f("Queijo muçarela", "330", "22.6", "3.0", "25.2"),
                f("Requeijão cremoso", "257", "9.6", "2.4", "23.4"),

                // Frutas
                f("Banana prata", "98", "1.3", "26.0", "0.1", "2.0"),
                f("Maçã com casca", "56", "0.3", "15.2", "0", "1.3"),
                f("Laranja pera", "37", "1.0", "8.9", "0.1", "0.8"),
                f("Mamão papaia", "40", "0.5", "10.4", "0.1", "1.0"),
                f("Abacate", "96", "1.2", "6.0", "8.4", "6.3"),
                f("Morango", "30", "0.9", "6.8", "0.3", "1.7"),
                f("Manga palmer", "72", "0.4", "19.4", "0.2", "1.6"),

                // Verduras e legumes
                f("Brócolis cozido", "25", "2.1", "4.4", "0.5", "3.4"),
                f("Cenoura crua", "34", "1.3", "7.7", "0.2", "3.2"),
                f("Tomate cru", "15", "1.1", "3.1", "0.2", "1.2"),
                f("Alface crespa", "11", "1.3", "1.7", "0.2", "1.8"),
                f("Abobrinha cozida", "15", "1.1", "3.0", "0.2", "1.6"),
                f("Couve refogada", "90", "3.1", "8.7", "5.5", "5.7"),

                // Gorduras e oleaginosas
                f("Azeite de oliva", "884", "0", "0", "100"),
                f("Pasta de amendoim integral", "589", "22.5", "21.6", "46.5", "8.0"),
                f("Castanha-de-caju torrada", "570", "18.5", "29.1", "46.3", "3.7"),
                f("Castanha-do-pará", "643", "14.5", "15.1", "63.5", "7.9"),
                f("Amêndoa torrada", "581", "18.6", "29.5", "47.3", "11.6"),

                // Suplementos comuns
                f("Whey protein concentrado (pó)", "400", "80.0", "8.0", "6.0", "0"),
                f("Creatina (pó)", "0", "0", "0", "0"));
    }
}
