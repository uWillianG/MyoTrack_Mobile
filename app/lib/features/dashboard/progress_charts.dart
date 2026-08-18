import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/design/blocks.dart';
import '../../core/design/format.dart';
import '../progress/progress_controller.dart';

/// Os dois gráficos do Progresso, sem o cartão em volta.
///
/// **Todo gráfico aqui é de série única, e isso é decisão e não acaso.** As cores do tema
/// reprovam como paleta categórica — entre a primária e a terciária a diferença é ΔE 7,7 na
/// visão normal, contra um piso de 15 —, então duas séries no mesmo gráfico ficariam
/// indistinguíveis. Sem série concorrente também não há tentação de eixo duplo: volume em kg
/// e peso corporal em kg medem coisas diferentes e ficam em gráficos separados.
///
/// Os dois recebem as cores da família de fora, porque cada um pode aparecer como herói (cor
/// cheia) ou como seção (fundo lavado) dependendo do objetivo de quem abriu a tela.

/// Volume levantado por semana.
class VolumeChart extends StatelessWidget {
  const VolumeChart({required this.weeks, required this.colors, super.key});

  final List<WeeklyVolume> weeks;
  final BlockColors colors;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final maxVolume = weeks.fold<double>(
      0,
      (max, w) => w.volumeKg > max ? w.volumeKg.toDouble() : max,
    );
    final ink = colors.ink;
    final muted = theme.colorScheme.onSurfaceVariant;

    if (maxVolume <= 0) {
      return _NoData(
        message: 'Registre um treino para o gráfico aparecer.',
        color: muted,
      );
    }

    return SizedBox(
      height: 150,
      child: BarChart(
        BarChartData(
          maxY: maxVolume * 1.15,
          // Grade recessiva e só na horizontal: linha vertical atrás de barra não ajuda a ler
          // nada e compete com o dado.
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: maxVolume / 2,
            getDrawingHorizontalLine: (_) =>
                FlLine(color: ink.withValues(alpha: 0.15), strokeWidth: 1),
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
                // Um rótulo a cada três semanas: doze datas lado a lado viram um borrão em
                // 360 dp de largura.
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  final step = weeks.length > 6 ? 3 : 1;
                  if (index % step != 0 || index >= weeks.length) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      DateFormat('d/M').format(weeks[index].weekStart),
                      style: theme.textTheme.labelSmall?.copyWith(color: muted),
                    ),
                  );
                },
              ),
            ),
          ),
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipColor: (_) => theme.colorScheme.inverseSurface,
              getTooltipItem: (_, _, rod, index) => BarTooltipItem(
                '${Fmt.kg(weeks[index].volumeKg.toDouble())}\n',
                theme.textTheme.labelMedium!.copyWith(
                  color: theme.colorScheme.onInverseSurface,
                  fontWeight: FontWeight.bold,
                ),
                children: [
                  TextSpan(
                    text: weeks[index].sessions == 1
                        ? '1 treino'
                        : '${weeks[index].sessions} treinos',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onInverseSurface,
                    ),
                  ),
                ],
              ),
            ),
          ),
          barGroups: [
            for (var i = 0; i < weeks.length; i++)
              BarChartGroupData(
                x: i,
                barRods: [
                  BarChartRodData(
                    toY: weeks[i].volumeKg.toDouble(),
                    color: ink,
                    width: weeks.length > 6 ? 10 : 18,
                    // Topo arredondado, base reta: a barra fica ancorada na linha de base em
                    // vez de flutuar.
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(4),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

/// Peso corporal ao longo do tempo.
class WeightChart extends StatelessWidget {
  const WeightChart({required this.points, required this.colors, super.key});

  final List<WeightPoint> points;
  final BlockColors colors;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ink = colors.ink;
    final muted = theme.colorScheme.onSurfaceVariant;

    if (points.length < 2) {
      return _NoData(message: 'Duas pesagens e a linha aparece.', color: muted);
    }

    final weights = points.map((p) => p.weightKg.toDouble()).toList();
    final min = weights.reduce((a, b) => a < b ? a : b);
    final max = weights.reduce((a, b) => a > b ? a : b);
    // Uma folga mínima de 1 kg evita que uma variação de 200 g vire uma montanha — o eixo
    // colado nos extremos exagera ruído de balança e assusta sem motivo.
    final padding = ((max - min) * 0.2).clamp(1.0, double.infinity);

    return SizedBox(
      height: 150,
      child: LineChart(
        LineChartData(
          minY: min - padding,
          maxY: max + padding,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (_) =>
                FlLine(color: ink.withValues(alpha: 0.15), strokeWidth: 1),
          ),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(),
            rightTitles: const AxisTitles(),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 36,
                // **O intervalo é calculado, e a casa decimal segue o intervalo.** Sem isso o
                // eixo saía "84 · 84 · 83 · 83 · 82 · 82": o `fl_chart` escolhe passos menores
                // que um quilo quando a faixa é estreita — que é o caso normal de peso
                // corporal — e arredondar para inteiro fazia dois rótulos diferentes virarem o
                // mesmo texto, um em cima do outro.
                interval: _axisStep(min - padding, max + padding),
                getTitlesWidget: (value, meta) => Text(
                  value.toStringAsFixed(
                    _axisStep(min - padding, max + padding) >= 1 ? 0 : 1,
                  ),
                  style: theme.textTheme.labelSmall?.copyWith(color: muted),
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
                      style: theme.textTheme.labelSmall?.copyWith(color: muted),
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
                  '${Fmt.kg(point.weightKg.toDouble())}\n',
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
                  FlSpot(i.toDouble(), points[i].weightKg.toDouble()),
              ],
              color: ink,
              barWidth: 2.5,
              isCurved: false,
              // Ponto visível só quando há poucos: com trinta pesagens os marcadores encostam
              // uns nos outros e escondem a própria linha.
              dotData: FlDotData(show: points.length <= 12),
              belowBarData: BarAreaData(
                show: true,
                color: ink.withValues(alpha: 0.12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NoData extends StatelessWidget {
  const _NoData({required this.message, required this.color});

  final String message;
  final Color color;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 90,
    child: Center(
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: color),
      ),
    ),
  );
}

/// O passo do eixo de peso: quatro divisões, arredondadas para um valor que se lê.
///
/// Peso corporal varia pouco — uma faixa de 2 kg é o normal —, e deixar o `fl_chart` escolher
/// o passo produz rótulos como 82,35 ou, arredondados para inteiro, o mesmo número duas vezes.
double _axisStep(double min, double max) {
  final raw = (max - min) / 4;
  for (final step in [0.5, 1.0, 2.0, 5.0, 10.0]) {
    if (raw <= step) {
      return step;
    }
  }
  return (raw / 10).ceil() * 10;
}
