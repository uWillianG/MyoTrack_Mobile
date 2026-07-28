import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import 'diet_models.dart';

/// Fala com `/api/diet-plans`.
class DietRepository {
  DietRepository(this._api);

  final ApiClient _api;

  /// Dieta ativa, ou null quando ainda não há plano gerado (o backend responde 404).
  Future<DietPlan?> active() async {
    try {
      final json = await _api.get<Map<String, dynamic>>(
        '/api/diet-plans/active',
      );
      return DietPlan.fromJson(json);
    } on ApiException catch (e) {
      if (e.statusCode == 404) {
        return null;
      }
      rethrow;
    }
  }

  Future<List<DietPlanSummary>> history() async {
    final json = await _api.get<List<dynamic>>('/api/diet-plans');
    return json
        .map((item) => DietPlanSummary.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  /// Enfileira a geração e devolve o id do job para acompanhar com o `JobWatcher`.
  Future<String> generate() async {
    final json = await _api.post<Map<String, dynamic>>(
      '/api/diet-plans/generate',
    );
    return json['jobId'] as String;
  }
}
