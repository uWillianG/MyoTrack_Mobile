import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/design/materials.dart';

import '../../core/network/api_exception.dart';
import 'data/report_models.dart';
import 'report_controller.dart';

/// Card do relatório semanal no dashboard.
///
/// Sem relatório o card some — quem instalou o app hoje não tem semana fechada, e um card
/// dizendo "sem dados" ocuparia o topo da tela sem informar nada. A exceção é [canGenerate]:
/// quem já treinou tem o que relatar, e para essa pessoa o vazio é uma espera sem explicação,
/// porque o agendador roda de hora em hora.
class WeeklyReportCard extends ConsumerWidget {
  const WeeklyReportCard({this.canGenerate = false, super.key});

  /// Se vale oferecer a geração quando ainda não há relatório.
  final bool canGenerate;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final report = ref.watch(latestReportProvider);

    // Em erro o card some. Ele é um complemento do dashboard, não a razão da tela — falhar
    // aqui não pode empurrar os gráficos para baixo com um aviso.
    return report.maybeWhen(
      data: (data) => switch (data) {
        final report? => _Card(report: report),
        _ when canGenerate => const _GeneratePrompt(),
        _ => const SizedBox.shrink(),
      },
      orElse: () => const SizedBox.shrink(),
    );
  }
}

/// Oferece gerar o relatório da última semana, para quem já tem o que relatar.
class _GeneratePrompt extends ConsumerStatefulWidget {
  const _GeneratePrompt();

  @override
  ConsumerState<_GeneratePrompt> createState() => _GeneratePromptState();
}

class _GeneratePromptState extends ConsumerState<_GeneratePrompt> {
  bool _sending = false;
  String? _message;

  Future<void> _generate() async {
    setState(() {
      _sending = true;
      _message = null;
    });

    try {
      await ref.read(reportRepositoryProvider).generate();
      if (mounted) {
        setState(() {
          _sending = false;
          // Quem gera é o worker: a resposta só confirma que entrou na fila. Prometer o
          // relatório "agora" faria a pessoa puxar a tela em vão por alguns minutos.
          _message =
              'Pedido enviado. O relatório aparece aqui assim que ficar pronto.';
        });
      }
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _sending = false;
          // O 409 do servidor já vem escrito para o usuário ("já foi gerado", "já existe um
          // em geração"), e é informação, não falha — mostrar como erro assustaria à toa.
          _message = e.message;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GlassPanel(
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
              ],
            ),
            const SizedBox(height: 8),
            Text(
              _message ??
                  'O relatório da semana passada ainda não foi gerado. '
                      'Você pode pedir agora.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            if (_message == null) ...[
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerLeft,
                child: FilledButton.tonal(
                  onPressed: _sending ? null : _generate,
                  child: _sending
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Gerar relatório'),
                ),
              ),
            ],
          ],
        ),
      ),
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

    return GlassPanel(
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
