import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'data/report_models.dart';
import 'report_controller.dart';

/// Card do relatório semanal no dashboard.
///
/// Só aparece quando existe relatório: quem instalou o app hoje não tem semana fechada, e um
/// card vazio dizendo "sem dados" ocuparia o topo da tela sem informar nada.
class WeeklyReportCard extends ConsumerWidget {
  const WeeklyReportCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final report = ref.watch(latestReportProvider);

    // Sem relatório, e também em erro, o card some. Ele é um complemento do dashboard, não
    // a razão da tela — falhar aqui não pode empurrar os gráficos para baixo com um aviso.
    return report.maybeWhen(
      data: (data) =>
          data == null ? const SizedBox.shrink() : _Card(report: data),
      orElse: () => const SizedBox.shrink(),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.report});

  final WeeklyReport report;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final metrics = report.metrics;
    final narrative = report.narrative;

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.insights_outlined,
                  size: 20,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('Sua semana', style: theme.textTheme.titleMedium),
                ),
                if (report.weekStart != null)
                  Text(
                    _weekLabel(report.weekStart!),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),

            _MetricsLine(metrics: metrics),

            if (narrative != null && narrative.summary.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(narrative.summary, style: theme.textTheme.bodyMedium),
            ],

            for (final highlight in narrative?.highlights ?? const <String>[])
              _Bullet(
                icon: Icons.check_circle_outline,
                color: theme.colorScheme.primary,
                text: highlight,
              ),
            for (final tip in narrative?.recommendations ?? const <String>[])
              _Bullet(
                icon: Icons.arrow_forward,
                color: theme.colorScheme.onSurfaceVariant,
                text: tip,
              ),
          ],
        ),
      ),
    );
  }

  /// `2026-07-20` vira `semana de 20/07`.
  static String _weekLabel(String iso) {
    final date = DateTime.tryParse(iso);
    return date == null ? iso : 'semana de ${DateFormat('d/M').format(date)}';
  }
}

/// Os números da semana em uma linha.
///
/// A variação de volume leva sinal explícito e a palavra "que a semana passada": "+12%"
/// sozinho não diz contra o quê, e cor sozinha não diria se é bom ou ruim para quem não
/// distingue verde de vermelho.
class _MetricsLine extends StatelessWidget {
  const _MetricsLine({required this.metrics});

  final WeeklyMetrics metrics;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final change = metrics.volumeChangePercent;

    final parts = <String>[
      metrics.sessions == 1 ? '1 treino' : '${metrics.sessions} treinos',
      '${NumberFormat('#,##0', 'pt_BR').format(metrics.totalVolumeKg)} kg de volume',
      if (metrics.daysWithMealLogged > 0)
        '${metrics.daysWithMealLogged} '
            '${metrics.daysWithMealLogged == 1 ? 'dia' : 'dias'} com refeição registrada',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          parts.join('  ·  '),
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        if (change != null)
          Text(
            '${change >= 0 ? '+' : '−'}${change.abs().toStringAsFixed(0)}% '
            'de volume que a semana passada',
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        if (metrics.weightChangeKg != null)
          Text(
            '${metrics.weightChangeKg! >= 0 ? '+' : '−'}'
            '${metrics.weightChangeKg!.abs().toStringAsFixed(1)} kg no peso',
            style: theme.textTheme.labelMedium,
          ),
      ],
    );
  }
}

class _Bullet extends StatelessWidget {
  const _Bullet({required this.icon, required this.color, required this.text});

  final IconData icon;
  final Color color;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text, style: Theme.of(context).textTheme.bodySmall),
          ),
        ],
      ),
    );
  }
}
