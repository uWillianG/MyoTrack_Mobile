import 'package:freezed_annotation/freezed_annotation.dart';

part 'report_models.freezed.dart';
part 'report_models.g.dart';

/// Números da semana, calculados pelo servidor em código.
///
/// Nenhum deles vem do LLM: o modelo escreve a narrativa, mas um número estimado por IA num
/// relatório seria pior que relatório nenhum, porque o usuário não teria como desconfiar.
///
/// Os campos anuláveis são estado normal e não erro — "sem semana anterior para comparar",
/// "só uma pesagem", "nenhuma refeição registrada".
@freezed
abstract class WeeklyMetrics with _$WeeklyMetrics {
  const factory WeeklyMetrics({
    String? weekStart,
    @Default(0) int sessions,
    @Default(0) int totalSets,
    @Default(0) num totalVolumeKg,

    /// Variação do volume contra a semana anterior. Null quando não houve treino nela.
    num? volumeChangePercent,
    String? topExercise,
    num? topExerciseVolumeKg,
    num? weightStartKg,
    num? weightEndKg,
    num? weightChangeKg,
    @Default(0) int mealsLogged,
    @Default(0) int daysWithMealLogged,
    num? avgKcalPerLoggedDay,
  }) = _WeeklyMetrics;

  factory WeeklyMetrics.fromJson(Map<String, dynamic> json) =>
      _$WeeklyMetricsFromJson(json);
}

/// O texto que comenta a semana. Null quando a IA está indisponível.
@freezed
abstract class WeeklyNarrative with _$WeeklyNarrative {
  const factory WeeklyNarrative({
    @Default('') String summary,
    @Default([]) List<String> highlights,
    @Default([]) List<String> recommendations,
  }) = _WeeklyNarrative;

  factory WeeklyNarrative.fromJson(Map<String, dynamic> json) =>
      _$WeeklyNarrativeFromJson(json);
}

/// Relatório semanal — `GET /api/reports/weekly`.
@freezed
abstract class WeeklyReport with _$WeeklyReport {
  const factory WeeklyReport({
    required String id,
    String? weekStart,
    @Default(WeeklyMetrics()) WeeklyMetrics metrics,

    /// Null é normal: sem IA configurada o relatório vale pelos números.
    WeeklyNarrative? narrative,
    String? createdAt,
  }) = _WeeklyReport;

  factory WeeklyReport.fromJson(Map<String, dynamic> json) =>
      _$WeeklyReportFromJson(json);
}
