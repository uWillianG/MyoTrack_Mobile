import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../progress/progress_controller.dart';
import 'dashboard_stats.dart';

/// Os números do dashboard.
///
/// Três agregados de `/api/progress/*` em vez do histórico inteiro de sessões. Além de não
/// duplicar as contas, muda o que trafega: quem treina há um ano tem centenas de sessões com
/// todas as séries dentro, e a tela usava isso só para somar por semana.
final dashboardStatsProvider = FutureProvider<DashboardStats>((ref) async {
  final repo = ref.watch(progressRepositoryProvider);

  // Em paralelo: são três chamadas independentes, e em série a tela esperaria a soma dos
  // três tempos de rede.
  final results = await Future.wait([
    repo.weeklyVolume(),
    repo.weight(),
    repo.records(),
  ]);

  return DashboardStats.from(
    volume: results[0] as List<WeeklyVolume>,
    weight: results[1] as List<WeightPoint>,
    records: results[2] as List<ExerciseRecord>,
  );
});
