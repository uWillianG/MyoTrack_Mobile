import 'package:drift/drift.dart' show Value;

import '../../../core/db/local_database.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/sync/sync_queue.dart';
import 'logging_models.dart';

/// Registro manual de treino e de medidas — `/api/sessions`, `/api/measurements`,
/// `/api/exercises`.
///
/// As escritas passam pela [SyncQueue]: sem rede elas ficam guardadas e sobem depois.
class LoggingRepository {
  LoggingRepository(this._api, this._db, this._sync);

  final ApiClient _api;
  final LocalDatabase _db;
  final SyncQueue _sync;

  /// Catálogo de exercícios, do servidor quando dá e do cache quando não dá.
  ///
  /// Sem esta queda para o cache, registrar treino offline seria impossível: o usuário
  /// precisa escolher o exercício, e a lista vem do servidor.
  Future<List<ExerciseOption>> exercises() async {
    try {
      final json = await _api.get<List<dynamic>>('/api/exercises');
      final items = json
          .map((e) => ExerciseOption.fromJson(e as Map<String, dynamic>))
          .toList();

      await _db.replaceExercises(
        items
            .map(
              (e) => CachedExercisesCompanion.insert(
                id: Value(e.id),
                name: e.name,
                muscleGroup: e.muscleGroup,
                equipment: e.equipment,
                isCompound: Value(e.isCompound),
              ),
            )
            .toList(),
      );

      return items;
    } on ApiException catch (e) {
      if (!e.isRetryable) {
        rethrow;
      }
      return _cachedExercises();
    }
  }

  Future<List<ExerciseOption>> _cachedExercises() async {
    final rows = await _db.exercises();
    return rows
        .map(
          (row) => ExerciseOption(
            id: row.id,
            name: row.name,
            muscleGroup: row.muscleGroup,
            equipment: row.equipment,
            isCompound: row.isCompound,
          ),
        )
        .toList();
  }

  /// Registra a sessão. Devolve se subiu na hora ou ficou na fila.
  Future<WriteOutcome> logSession(SessionRequest request) =>
      _sync.submit('/api/sessions', request.toJson());

  Future<WriteOutcome> logMeasurement(MeasurementRequest request) =>
      _sync.submit('/api/measurements', request.toJson());

  /// Medidas corporais, em ordem crescente de data — é assim que o gráfico consome.
  Future<List<MeasurementView>> measurements() async {
    final json = await _api.get<List<dynamic>>('/api/measurements');
    return json
        .map((e) => MeasurementView.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Histórico de sessões, mais recentes primeiro.
  Future<List<WorkoutSessionView>> sessions() async {
    final json = await _api.get<List<dynamic>>('/api/sessions');
    return json
        .map((e) => WorkoutSessionView.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
