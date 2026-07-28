import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../logging/data/logging_models.dart';
import '../logging/log_session_controller.dart';
import 'dashboard_stats.dart';

/// Medidas corporais registradas, em ordem crescente de data.
final measurementHistoryProvider = FutureProvider<List<MeasurementView>>(
  (ref) => ref.watch(loggingRepositoryProvider).measurements(),
);

/// Os números do dashboard.
///
/// Combina as duas fontes que já existiam — sessões e medidas — em vez de pedir um endpoint
/// de resumo ao backend: o volume de dados de um usuário cabe folgado na memória, e um
/// endpoint novo seria mais uma coisa a manter em sincronia.
final dashboardStatsProvider = FutureProvider<DashboardStats>((ref) async {
  final sessions = await ref.watch(sessionHistoryProvider.future);
  final measurements = await ref.watch(measurementHistoryProvider.future);

  return DashboardStats.from(sessions: sessions, measurements: measurements);
});
