import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/api_client.dart';
import '../../core/network/api_exception.dart';
import '../../core/providers.dart';
import 'data/report_models.dart';

/// Lê `/api/reports`.
class ReportRepository {
  ReportRepository(this._api);

  final ApiClient _api;

  /// O relatório mais recente, ou null enquanto o usuário ainda não tem nenhum.
  ///
  /// O 404 é traduzido para null aqui em vez de virar erro na tela: não ter relatório é o
  /// estado de quem acabou de instalar o app, e não uma falha.
  Future<WeeklyReport?> latest() async {
    try {
      final json = await _api.get<Map<String, dynamic>>('/api/reports/weekly');
      return WeeklyReport.fromJson(json);
    } on ApiException catch (e) {
      if (e.statusCode == 404) {
        return null;
      }
      rethrow;
    }
  }

  /// Pede o relatório da última semana completa. Devolve o id do job.
  ///
  /// O servidor recusa com 409 se a semana já tem relatório ou se já há um em geração — é lá
  /// que mora o limite de uma chamada de LLM por usuário por semana, e este método não o
  /// duplica: só repassa a recusa.
  Future<String?> generate() async {
    final json = await _api.post<Map<String, dynamic>>(
      '/api/reports/weekly/generate',
    );
    return json['jobId'] as String?;
  }
}

final reportRepositoryProvider = Provider<ReportRepository>(
  (ref) => ReportRepository(ref.watch(apiClientProvider)),
);

final latestReportProvider = FutureProvider<WeeklyReport?>(
  (ref) => ref.watch(reportRepositoryProvider).latest(),
);
