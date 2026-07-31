import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router.dart';
import '../reports/weekly_report_card.dart';
import 'dashboard_controller.dart';
import 'dashboard_view.dart';

/// Progresso: os gráficos que eram o corpo da home.
///
/// Saíram de lá quando o hub diário assumiu a primeira tela, e viraram destino próprio em vez
/// de sumir. A leitura é outra: a home responde "como está hoje" de relance, e aqui se vem
/// para conferir o eixo — quanto o volume subiu no bloco, se o peso está mesmo caindo.
class ProgressPage extends ConsumerWidget {
  const ProgressPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(dashboardStatsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Progresso')),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(dashboardStatsProvider);
          await ref.read(dashboardStatsProvider.future);
        },
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          children: [
            stats.when(
              loading: () => const SizedBox(
                height: 120,
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (error, _) => _DashboardUnavailable(
                onRetry: () => ref.invalidate(dashboardStatsProvider),
              ),
              data: (data) => data.isEmpty
                  ? const _FirstSteps()
                  : DashboardView(stats: data),
            ),
            // O card do relatório fica acima dos gráficos porque é leitura, não consulta:
            // ele já diz o que a semana foi, e os gráficos existem para quem quer conferir.
            //
            // `canGenerate` diz se vale oferecer a geração quando ainda não há relatório.
            // Quem instalou o app hoje não tem semana fechada, e um botão prometendo um
            // relatório que sairia vazio é pior que botão nenhum.
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: WeeklyReportCard(
                canGenerate: stats.valueOrNull?.isEmpty == false,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Quem ainda não registrou nada não tem gráfico para ver — e um gráfico vazio pareceria
/// defeito. Em vez disso, o próximo passo.
class _FirstSteps extends StatelessWidget {
  const _FirstSteps();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Comece por aqui', style: theme.textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(
              'Registre seu primeiro treino e seu peso. A partir daí esta tela mostra '
              'volume por semana, evolução do peso e seus recordes.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            FilledButton.tonal(
              onPressed: () => context.push(Routes.logSession),
              child: const Text('Registrar treino'),
            ),
          ],
        ),
      ),
    );
  }
}

class _DashboardUnavailable extends StatelessWidget {
  const _DashboardUnavailable({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.cloud_off_outlined, color: theme.colorScheme.outline),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Não foi possível carregar seus números agora.',
                style: theme.textTheme.bodyMedium,
              ),
            ),
            TextButton(onPressed: onRetry, child: const Text('Tentar')),
          ],
        ),
      ),
    );
  }
}
