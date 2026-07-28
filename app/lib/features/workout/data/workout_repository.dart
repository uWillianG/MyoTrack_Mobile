import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import 'workout_models.dart';

/// Fala com `/api/workout-plans`.
class WorkoutRepository {
  WorkoutRepository(this._api);

  final ApiClient _api;

  /// Plano ativo, ou null quando ainda não há treino gerado.
  ///
  /// O backend responde **404 nesse caso** — não é erro, é o estado inicial de quem acabou
  /// de fazer o onboarding. Vira null aqui para a tela não precisar saber disso.
  Future<WorkoutPlan?> active() async {
    try {
      final json = await _api.get<Map<String, dynamic>>(
        '/api/workout-plans/active',
      );
      return WorkoutPlan.fromJson(json);
    } on ApiException catch (e) {
      if (e.statusCode == 404) {
        return null;
      }
      rethrow;
    }
  }

  Future<List<WorkoutPlanSummary>> history() async {
    final json = await _api.get<List<dynamic>>('/api/workout-plans');
    return json
        .map(
          (item) => WorkoutPlanSummary.fromJson(item as Map<String, dynamic>),
        )
        .toList();
  }

  /// Enfileira a geração e devolve o id do job para acompanhar com o `JobWatcher`.
  Future<String> generate() async {
    final json = await _api.post<Map<String, dynamic>>(
      '/api/workout-plans/generate',
    );
    return json['jobId'] as String;
  }
}
