import 'package:freezed_annotation/freezed_annotation.dart';

part 'meal_models.freezed.dart';
part 'meal_models.g.dart';

/// Um alimento identificado na foto — `GET /api/meal-analyses`.
///
/// Os números chegam como `num` porque o backend os serializa como `BigDecimal`: dependendo
/// do valor o JSON traz `195` ou `195.0`, e tipar como `double` faria o primeiro caso
/// explodir na desserialização.
@freezed
abstract class MealAnalysisItem with _$MealAnalysisItem {
  const factory MealAnalysisItem({
    required String description,

    /// Ligação com o catálogo de alimentos, quando o backend conseguiu fazê-la.
    int? foodItemId,
    @Default(0) num quantityG,
    @Default(0) num kcal,
    @Default(0) num proteinG,
    @Default(0) num carbsG,
    @Default(0) num fatG,

    /// Centro do alimento na foto, escala 0–1000. Só serve para desenhar a etiqueta na
    /// versão ilustrada — nenhum número nutricional depende disso.
    int? posX,
    int? posY,
  }) = _MealAnalysisItem;

  factory MealAnalysisItem.fromJson(Map<String, dynamic> json) =>
      _$MealAnalysisItemFromJson(json);
}

/// Uma refeição do diário: fotografada e estimada pela IA, ou montada à mão.
@freezed
abstract class MealAnalysis with _$MealAnalysis {
  const MealAnalysis._();

  const factory MealAnalysis({
    required String id,

    /// Null na refeição manual: ela não passou pela fila de IA para ser gravada.
    String? analysisJobId,

    /// `"Photo"` ou `"Manual"` — a origem da refeição.
    ///
    /// **Não dá para deduzir isto de [photoUrl] nula**, e é por isso que o campo existe: a
    /// retenção de mídia (LGPD) apaga a foto de análises antigas e deixa o resultado para
    /// trás, então "nunca teve foto" e "a foto expirou" chegam aqui idênticas. String crua
    /// como `calorieGoal` e `reviewStatus`: um enum do lado do app quebraria na primeira vez
    /// que o servidor emitisse um valor novo, e o que se faz com ele aqui é decidir se cabe
    /// oferecer a foto.
    String? source,
    @Default([]) List<MealAnalysisItem> items,
    @Default(0) num totalKcal,
    @Default(0) num totalProteinG,
    @Default(0) num totalCarbsG,
    @Default(0) num totalFatG,

    /// O usuário corrigiu a estimativa da IA.
    @Default(false) bool userAdjusted,

    /// Fora do diário: continua no histórico, mas não soma no dia.
    @Default(false) bool excludedFromDiary,

    /// URL temporária da foto. Null quando a retenção (LGPD) já apagou o arquivo — o
    /// resultado da análise sobrevive à imagem.
    String? photoUrl,

    /// Foto anotada pela IA. Null quando o modo ilustrado não foi pedido, ou quando a
    /// geração não pôde ser feita — a análise vale igual sem ela.
    String? illustratedPhotoUrl,
    String? createdAt,
  }) = _MealAnalysis;

  factory MealAnalysis.fromJson(Map<String, dynamic> json) =>
      _$MealAnalysisFromJson(json);

  /// Foi digitada, e não fotografada.
  ///
  /// Falso também quando o servidor não mandou origem nenhuma — é o que uma versão anterior
  /// da API responde, e nela toda refeição era de foto.
  bool get isManual => source == 'Manual';
}

/// Um alimento do catálogo nutricional — `GET /api/foods`.
///
/// **Os valores são por 100 g, e o nome de cada campo diz isso.** Sem o sufixo, o `kcal` de um
/// alimento se confundiria com o `kcal` de um [MealAnalysisItem], que já é a porção inteira —
/// e a diferença entre os dois é a regra de três que separa 128 kcal de 192.
@freezed
abstract class FoodItem with _$FoodItem {
  const factory FoodItem({
    required int id,
    required String name,
    @Default(0) num kcalPer100g,
    @Default(0) num proteinPer100g,
    @Default(0) num carbsPer100g,
    @Default(0) num fatPer100g,
    num? fiberPer100g,

    /// "TACO", "TBCA" ou "Custom" — de onde vieram os números.
    String? source,
  }) = _FoodItem;

  factory FoodItem.fromJson(Map<String, dynamic> json) =>
      _$FoodItemFromJson(json);
}

/// Um item do corpo de `POST /api/meal-analyses/manual`.
///
/// Separado de [MealAnalysisItem] porque **não é a mesma coisa**: aquele é o que o servidor
/// devolve, com a posição do alimento na foto; este é o que se manda, e posição num prato que
/// não foi fotografado não existe.
///
/// Com [foodItemId], os macros são recalculados pelo servidor a partir do catálogo e o que
/// for mandado neles é ignorado — mandá-los mesmo assim é de propósito, para a lista da tela e
/// o corpo da requisição serem a mesma coisa.
@freezed
abstract class MealManualItem with _$MealManualItem {
  const factory MealManualItem({
    required String description,
    int? foodItemId,
    @Default(0) num quantityG,
    @Default(0) num kcal,
    @Default(0) num proteinG,
    @Default(0) num carbsG,
    @Default(0) num fatG,
  }) = _MealManualItem;

  factory MealManualItem.fromJson(Map<String, dynamic> json) =>
      _$MealManualItemFromJson(json);
}

/// Corpo de `POST /api/meal-analyses/manual`.
///
/// Os totais não vão aqui, pela mesma razão do [MealAdjustRequest]: quem soma é o servidor, a
/// partir dos itens. É o total que o diário soma, e mandá-lo pronto permitiria gravar um dia
/// de calorias que não corresponde a nada do que está na tela.
@freezed
abstract class MealManualRequest with _$MealManualRequest {
  const factory MealManualRequest({
    required List<MealManualItem> items,

    /// Quando a refeição foi consumida. Null = agora, no relógio do servidor.
    String? createdAt,
  }) = _MealManualRequest;

  factory MealManualRequest.fromJson(Map<String, dynamic> json) =>
      _$MealManualRequestFromJson(json);
}

/// O que a IA estimou a partir do texto livre — o `resultJson` do job.
///
/// **Não está gravado em lugar nenhum.** É uma proposta: o usuário confere, corrige e só então
/// manda pelo `POST /manual`. Os totais vêm junto para a tela poder mostrar a soma sem
/// recalcular, mas quem soma o que vai para o diário continua sendo o servidor.
@freezed
abstract class MealEstimate with _$MealEstimate {
  const factory MealEstimate({
    @Default([]) List<MealAnalysisItem> items,
    @Default(0) num totalKcal,
    @Default(0) num totalProteinG,
    @Default(0) num totalCarbsG,
    @Default(0) num totalFatG,
  }) = _MealEstimate;

  factory MealEstimate.fromJson(Map<String, dynamic> json) =>
      _$MealEstimateFromJson(json);
}

/// Correção manual — corpo de `PUT /api/meal-analyses/{id}`.
///
/// Os totais não vão aqui: quem soma é o servidor, a partir dos itens.
@freezed
abstract class MealAdjustRequest with _$MealAdjustRequest {
  const factory MealAdjustRequest({
    List<MealAnalysisItem>? items,
    bool? excludedFromDiary,
  }) = _MealAdjustRequest;

  factory MealAdjustRequest.fromJson(Map<String, dynamic> json) =>
      _$MealAdjustRequestFromJson(json);
}
