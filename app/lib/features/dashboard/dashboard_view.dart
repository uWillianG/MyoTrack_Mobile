import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'dashboard_stats.dart';

/// Corpo do dashboard: números do momento, evolução e recordes.
///
/// **Todo gráfico aqui é de série única, e isso é decisão e não acaso.** As cores do tema
/// reprovam como paleta categórica — entre a primária e a terciária a diferença é ΔE 7,7 na
/// visão normal, contra um piso de 15 —, então duas séries no mesmo gráfico ficariam
/// indistinguíveis. Sem série concorrente também não há tentação de eixo duplo: volume em kg
/// e peso corporal em kg medem coisas diferentes e ficam em gráficos separados.
class DashboardView extends StatelessWidget {
  const DashboardView({required this.stats, super.key});

  final DashboardStats stats;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _StatTiles(stats: stats),
        const SizedBox(height: 16),
        _VolumeChart(weeks: stats.weeklyVolume),
        if (stats.weightSeries.length >= 2) ...[
          const SizedBox(height: 16),
          _WeightChart(points: stats.weightSeries),
        ],
        if (stats.records.isNotEmpty) ...[
          const SizedBox(height: 16),
          _Records(records: stats.records),
        ],
      ],
    );
  }
}

/// Números que não precisam de gráfico.
///
/// Um valor único vira número grande, não uma barra sozinha: a barra gastaria a altura de um
/// gráfico para comunicar o que o número comunica numa linha.
class _StatTiles extends StatelessWidget {
  const _StatTiles({required this.stats});

  final DashboardStats stats;

  @override
  Widget build(BuildContext context) {
    final delta = stats.weightDeltaKg;

    return Row(
      children: [
        Expanded(
          child: _Tile(
            label: 'Treinos na semana',
            value: '${stats.sessionsThisWeek}',
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _Tile(
            label: 'Volume da semana',
            value: formatKg(stats.volumeThisWeek),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _Tile(
            label: 'Peso atual',
            value: stats.currentWeightKg == null
                ? '—'
                : formatKg(stats.currentWeightKg!),
            // O sinal vai explícito: "+2 kg" e "−2 kg" contam histórias opostas, e cor
            // sozinha não diria qual é qual para quem não distingue verde de vermelho.
            detail: delta == null
                ? null
                : '${delta >= 0 ? '+' : '−'}${formatKg(delta.abs())} no período',
          ),
        ),
      ],
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({required this.label, required this.value, this.detail});

  final String label;
  final String value;
  final String? detail;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Três cartões lado a lado deixam ~105 dp para cada um. Sem teto de linhas, um
            // usuário com a fonte do sistema ampliada quebraria o rótulo em cinco linhas e
            // esticaria os três cartões junto — acessibilidade virando defeito de layout.
            Text(
              label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 4),
            // O número encolhe em vez de quebrar: "1.250 kg" partido em duas linhas perde a
            // leitura de relance, que é a única função deste cartão.
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                value,
                maxLines: 1,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            if (detail != null)
              Text(
                detail!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _VolumeChart extends StatelessWidget {
  const _VolumeChart({required this.weeks});

  final List<WeeklyVolume> weeks;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final maxVolume = weeks.fold<double>(
      0,
      (max, w) => w.volumeKg > max ? w.volumeKg : max,
    );

    return _ChartCard(
      title: 'Volume por semana',
      subtitle:
          'Últimas ${DashboardStats.volumeWeeks} semanas, em kg levantados',
      child: maxVolume <= 0
          ? _NoData(message: 'Registre um treino para o gráfico aparecer.')
          : SizedBox(
              height: 180,
              child: BarChart(
                BarChartData(
                  maxY: maxVolume * 1.15,
                  // Grade recessiva e só na horizontal: linha vertical atrás de barra não
                  // ajuda a ler nada e compete com o dado.
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: maxVolume / 2,
                    getDrawingHorizontalLine: (_) => FlLine(
                      color: theme.colorScheme.outlineVariant,
                      strokeWidth: 1,
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  titlesData: FlTitlesData(
                    leftTitles: const AxisTitles(),
                    topTitles: const AxisTitles(),
                    rightTitles: const AxisTitles(),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 22,
                        // Um rótulo a cada três semanas: doze datas lado a lado viram um
                        // borrão em 360 dp de largura.
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index % 3 != 0 || index >= weeks.length) {
                            return const SizedBox.shrink();
                          }
                          return Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              DateFormat('d/M').format(weeks[index].weekStart),
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  barTouchData: BarTouchData(
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipColor: (_) => theme.colorScheme.inverseSurface,
                      getTooltipItem: (_, _, rod, index) {
                        final week = weeks[index];
                        return BarTooltipItem(
                          '${formatKg(week.volumeKg)}\n',
                          theme.textTheme.labelMedium!.copyWith(
                            color: theme.colorScheme.onInverseSurface,
                            fontWeight: FontWeight.bold,
                          ),
                          children: [
                            TextSpan(
                              text: week.sessions == 1
                                  ? '1 treino'
                                  : '${week.sessions} treinos',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.onInverseSurface,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                  barGroups: [
                    for (var i = 0; i < weeks.length; i++)
                      BarChartGroupData(
                        x: i,
                        barRods: [
                          BarChartRodData(
                            toY: weeks[i].volumeKg,
                            color: theme.colorScheme.primary,
                            width: 10,
                            // Topo arredondado, base reta: a barra fica ancorada na linha de
                            // base em vez de flutuar.
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(4),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
    );
  }
}

class _WeightChart extends StatelessWidget {
  const _WeightChart({required this.points});

  final List<WeightPoint> points;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final weights = points.map((p) => p.weightKg).toList();
    final min = weights.reduce((a, b) => a < b ? a : b);
    final max = weights.reduce((a, b) => a > b ? a : b);
    // Uma folga mínima de 1 kg evita que uma variação de 200 g vire uma montanha — o eixo
    // colado nos extremos exagera ruído de balança e assusta sem motivo.
    final padding = ((max - min) * 0.2).clamp(1.0, double.infinity);

    return _ChartCard(
      title: 'Peso corporal',
      subtitle: '${points.length} registros',
      child: SizedBox(
        height: 180,
        child: LineChart(
          LineChartData(
            minY: min - padding,
            maxY: max + padding,
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              getDrawingHorizontalLine: (_) => FlLine(
                color: theme.colorScheme.outlineVariant,
                strokeWidth: 1,
              ),
            ),
            borderData: FlBorderData(show: false),
            titlesData: FlTitlesData(
              topTitles: const AxisTitles(),
              rightTitles: const AxisTitles(),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 36,
                  getTitlesWidget: (value, meta) => Text(
                    value.toStringAsFixed(0),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 22,
                  interval: (points.length / 3).ceilToDouble(),
                  getTitlesWidget: (value, meta) {
                    final index = value.toInt();
                    if (index < 0 || index >= points.length) {
                      return const SizedBox.shrink();
                    }
                    return Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        DateFormat('d/M').format(points[index].date),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            lineTouchData: LineTouchData(
              touchTooltipData: LineTouchTooltipData(
                getTooltipColor: (_) => theme.colorScheme.inverseSurface,
                getTooltipItems: (spots) => spots.map((spot) {
                  final point = points[spot.x.toInt()];
                  return LineTooltipItem(
                    '${formatKg(point.weightKg)}\n',
                    theme.textTheme.labelMedium!.copyWith(
                      color: theme.colorScheme.onInverseSurface,
                      fontWeight: FontWeight.bold,
                    ),
                    children: [
                      TextSpan(
                        text: DateFormat('d/M/y').format(point.date),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onInverseSurface,
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
            lineBarsData: [
              LineChartBarData(
                spots: [
                  for (var i = 0; i < points.length; i++)
                    FlSpot(i.toDouble(), points[i].weightKg),
                ],
                color: theme.colorScheme.primary,
                barWidth: 2,
                isCurved: false,
                // Ponto visível só quando há poucos: com trinta pesagens os marcadores
                // encostam uns nos outros e escondem a própria linha.
                dotData: FlDotData(show: points.length <= 12),
                belowBarData: BarAreaData(
                  show: true,
                  color: theme.colorScheme.primary.withValues(alpha: 0.08),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Recordes de carga. Lista e não gráfico: são pares nome+número, e o nome do exercício é
/// tão importante quanto o valor — numa barra ele viraria rótulo cortado.
class _Records extends StatelessWidget {
  const _Records({required this.records});

  final List<PersonalRecord> records;

  /// Os dez maiores. Mais que isso vira inventário do catálogo, não destaque.
  static const int _maxShown = 10;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final shown = records.take(_maxShown).toList();

    return _ChartCard(
      title: 'Seus recordes',
      subtitle: 'Maior carga registrada em cada exercício',
      child: Column(
        children: [
          for (final record in shown)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      record.exerciseName,
                      style: theme.textTheme.bodyMedium,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    formatKg(record.loadKg),
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 92,
                    child: Text(
                      '${record.reps} reps · ${DateFormat('d/M/y').format(record.date)}',
                      textAlign: TextAlign.end,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _ChartCard extends StatelessWidget {
  const _ChartCard({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget child;

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
            // O título nomeia a série; com uma só, uma legenda seria uma caixa repetindo o
            // que o título já disse.
            Text(title, style: theme.textTheme.titleMedium),
            Text(
              subtitle,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }
}

class _NoData extends StatelessWidget {
  const _NoData({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 90,
      child: Center(
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

/// Peso em pt-BR, sem casa decimal desnecessária: "1.250 kg", "82,4 kg".
String formatKg(double value) {
  final pattern = value == value.roundToDouble() ? '#,##0' : '#,##0.0';
  return '${NumberFormat(pattern, 'pt_BR').format(value)} kg';
}
