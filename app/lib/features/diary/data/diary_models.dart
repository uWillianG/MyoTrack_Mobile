import 'package:freezed_annotation/freezed_annotation.dart';

part 'diary_models.freezed.dart';
part 'diary_models.g.dart';

/// Calorias e macros — serve tanto para a meta quanto para o consumido.
@freezed
abstract class DiaryMacros with _$DiaryMacros {
  const factory DiaryMacros({
    @Default(0) num kcal,
    @Default(0) num proteinG,
    @Default(0) num carbsG,
    @Default(0) num fatG,
  }) = _DiaryMacros;

  factory DiaryMacros.fromJson(Map<String, dynamic> json) =>
      _$DiaryMacrosFromJson(json);
}

/// Uma refeição analisada que aparece no dia.
@freezed
abstract class DiaryEntry with _$DiaryEntry {
  const factory DiaryEntry({
    required String id,
    String? createdAt,
    @Default(0) num totalKcal,
    @Default(0) num totalProteinG,
    @Default(0) num totalCarbsG,
    @Default(0) num totalFatG,
    @Default(false) bool userAdjusted,

    /// Fora do diário: continua na lista, riscada, mas não soma no dia.
    @Default(false) bool excludedFromDiary,
  }) = _DiaryEntry;

  factory DiaryEntry.fromJson(Map<String, dynamic> json) =>
      _$DiaryEntryFromJson(json);
}

/// Total de um dia no gráfico da semana.
@freezed
abstract class DiaryDayTotal with _$DiaryDayTotal {
  const factory DiaryDayTotal({required String date, @Default(0) num kcal}) =
      _DiaryDayTotal;

  factory DiaryDayTotal.fromJson(Map<String, dynamic> json) =>
      _$DiaryDayTotalFromJson(json);
}

/// Um dia do diário — `GET /api/diary`.
@freezed
abstract class DiaryDay with _$DiaryDay {
  const factory DiaryDay({
    required String date,

    /// Metas da dieta ativa. **Null quando ainda não há dieta gerada** — e null não é zero:
    /// zero seria uma meta de jejum.
    DiaryMacros? targets,
    @Default(DiaryMacros()) DiaryMacros consumed,
    @Default([]) List<DiaryEntry> entries,

    /// Sete dias terminando no dia pedido.
    @Default([]) List<DiaryDayTotal> week,
  }) = _DiaryDay;

  factory DiaryDay.fromJson(Map<String, dynamic> json) =>
      _$DiaryDayFromJson(json);
}
