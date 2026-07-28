import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../core/network/api_client.dart';
import '../../core/providers.dart';

part 'progress_controller.freezed.dart';
part 'progress_controller.g.dart';

/// Uma série da última sessão do exercício.
@freezed
abstract class LastSet with _$LastSet {
  const factory LastSet({@Default(0) int reps, @Default(0) num loadKg}) =
      _LastSet;

  factory LastSet.fromJson(Map<String, dynamic> json) =>
      _$LastSetFromJson(json);
}

/// Quanto pôr na barra na próxima sessão — `GET /api/progress/suggestions`.
///
/// Determinístico, calculado pelo `ProgressionCalculator` no servidor. **Não passa por IA**:
/// isto diz a alguém quanto peso levantar, e não pode depender do que um modelo estimou.
@freezed
abstract class ProgressSuggestion with _$ProgressSuggestion {
  const factory ProgressSuggestion({
    String? workoutDayId,
    String? dayLabel,
    int? exerciseId,
    @Default('') String exerciseName,
    @Default(0) int sets,
    @Default(0) int repsMin,
    @Default(0) int repsMax,

    /// Null em quem nunca registrou este exercício.
    String? lastSessionDate,
    @Default([]) List<LastSet> lastSets,

    /// `Start`, `Increase`, `ProgressReps` ou `Consolidate`.
    @Default('Start') String action,

    /// Carga sugerida. Null quando o plano também não trouxe uma.
    num? nextLoadKg,
    @Default(0) int targetReps,
    num? incrementKg,
  }) = _ProgressSuggestion;

  const ProgressSuggestion._();

  factory ProgressSuggestion.fromJson(Map<String, dynamic> json) =>
      _$ProgressSuggestionFromJson(json);

  /// O que fazer, em uma frase.
  ///
  /// O texto explica **por que** e não só o quê: "fechou o topo da faixa" é o que faz a
  /// pessoa confiar no número em vez de achar que o app sorteou.
  String get label => switch (action) {
    'Increase' => 'Suba a carga — você fechou o topo da faixa',
    'ProgressReps' => 'Mantenha a carga e busque $targetReps repetições',
    'Consolidate' => 'Mantenha a carga e consolide a faixa',
    _ => 'Comece pela carga sugerida do plano',
  };

  bool get hasHistory => lastSessionDate != null;
}

/// Volume de uma semana — `GET /api/progress/volume`.
///
/// Só vêm semanas com registro: preencher os buracos com zero depende de quantas semanas o
/// gráfico mostra, e isso quem sabe é a tela.
@freezed
abstract class WeeklyVolume with _$WeeklyVolume {
  const factory WeeklyVolume({
    /// Segunda-feira da semana.
    required DateTime weekStart,
    @Default(0) num volumeKg,

    /// Treinos na semana, contados por sessão — vinte séries num dia são um treino.
    @Default(0) int sessions,
  }) = _WeeklyVolume;

  factory WeeklyVolume.fromJson(Map<String, dynamic> json) =>
      _$WeeklyVolumeFromJson(json);
}

/// Um ponto da curva de peso corporal — `GET /api/progress/weight`.
@freezed
abstract class WeightPoint with _$WeightPoint {
  const factory WeightPoint({
    required DateTime date,
    @Default(0) num weightKg,
  }) = _WeightPoint;

  factory WeightPoint.fromJson(Map<String, dynamic> json) =>
      _$WeightPointFromJson(json);
}

/// Recorde de um exercício — `GET /api/progress/records`.
///
/// Traz a maior carga e o melhor 1RM estimado, que raramente são a mesma série: 5×100
/// estima mais que 1×105.
@freezed
abstract class ExerciseRecord with _$ExerciseRecord {
  const factory ExerciseRecord({
    int? exerciseId,
    @Default('') String name,
    @Default(0) num maxLoadKg,
    DateTime? maxLoadDate,

    /// Repetições daquela série. "120 kg" sozinho não diz se foi uma única ou oito.
    int? maxLoadReps,
    num? bestE1RmKg,
    int? e1RmReps,
    num? e1RmLoadKg,
    DateTime? e1RmDate,
  }) = _ExerciseRecord;

  factory ExerciseRecord.fromJson(Map<String, dynamic> json) =>
      _$ExerciseRecordFromJson(json);
}

class ProgressRepository {
  ProgressRepository(this._api);

  final ApiClient _api;

  Future<List<ProgressSuggestion>> suggestions() async {
    final json = await _api.get<List<dynamic>>('/api/progress/suggestions');
    return json
        .map((e) => ProgressSuggestion.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<WeeklyVolume>> weeklyVolume() async {
    final json = await _api.get<List<dynamic>>('/api/progress/volume');
    return json
        .map((e) => WeeklyVolume.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<WeightPoint>> weight() async {
    final json = await _api.get<List<dynamic>>('/api/progress/weight');
    return json
        .map((e) => WeightPoint.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<ExerciseRecord>> records() async {
    final json = await _api.get<List<dynamic>>('/api/progress/records');
    return json
        .map((e) => ExerciseRecord.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}

final progressRepositoryProvider = Provider<ProgressRepository>(
  (ref) => ProgressRepository(ref.watch(apiClientProvider)),
);

/// Sugestões indexadas por `exerciseId`, que é como a tela de treino as consulta.
///
/// Falha de rede aqui devolve mapa vazio em vez de erro: o plano de treino continua legível
/// sem as sugestões, e derrubar a tela inteira por causa delas seria desproporcional.
final suggestionsByExerciseProvider =
    FutureProvider<Map<int, ProgressSuggestion>>((ref) async {
      try {
        final all = await ref.watch(progressRepositoryProvider).suggestions();
        return {
          for (final s in all)
            if (s.exerciseId != null) s.exerciseId!: s,
        };
      } catch (_) {
        return const {};
      }
    });
