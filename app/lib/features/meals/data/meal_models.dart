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

/// Análise de uma refeição fotografada.
@freezed
abstract class MealAnalysis with _$MealAnalysis {
  const factory MealAnalysis({
    required String id,
    String? analysisJobId,
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
