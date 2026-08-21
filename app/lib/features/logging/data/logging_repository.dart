import '../../../core/network/api_client.dart';
import '../../../core/sync/sync_queue.dart';
import 'logging_models.dart';

/// Treino e medidas — `/api/sessions`, `/api/measurements`.
///
/// As escritas passam pela [SyncQueue]: sem rede elas ficam guardadas e sobem depois.
class LoggingRepository {
  LoggingRepository(this._api, this._sync);

  final ApiClient _api;
  final SyncQueue _sync;

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
