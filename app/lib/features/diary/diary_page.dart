import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/widgets/empty_state.dart';
import 'data/diary_models.dart';
import 'diary_controller.dart';

/// Diário alimentar. Porte de `DiaryPage.tsx`.
class DiaryPage extends ConsumerWidget {
  const DiaryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final date = ref.watch(diaryDateProvider);
    final dayAsync = ref.watch(diaryDayProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Diário')),
      body: Column(
        children: [
          _DayPicker(date: date),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(diaryDayProvider);
                await ref.read(diaryDayProvider.future);
              },
              child: dayAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => EmptyState(
                  icon: Icons.cloud_off_outlined,
                  title: 'Não foi possível carregar o diário.',
                  detail: '$error',
                  action: FilledButton.tonal(
                    onPressed: () => ref.invalidate(diaryDayProvider),
                    child: const Text('Tentar de novo'),
                  ),
                ),
                data: (day) => _Body(day: day),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Navegação entre dias.
///
/// Não deixa passar de hoje: o diário registra o que foi comido, e um dia futuro só poderia
/// estar vazio — o usuário acharia que perdeu dados.
class _DayPicker extends ConsumerWidget {
  const _DayPicker({required this.date});

  final DateTime date;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final isToday = date == today;

    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
      child: Row(
        children: [
          IconButton(
            onPressed: () => ref.read(diaryDateProvider.notifier).state = date
                .subtract(const Duration(days: 1)),
            icon: const Icon(Icons.chevron_left),
            tooltip: 'Dia anterior',
          ),
          Expanded(
            child: Text(
              isToday ? 'Hoje' : DateFormat("EEEE, d 'de' MMMM").format(date),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          IconButton(
            onPressed: isToday
                ? null
                : () => ref.read(diaryDateProvider.notifier).state = date.add(
                    const Duration(days: 1),
                  ),
            icon: const Icon(Icons.chevron_right),
            tooltip: 'Próximo dia',
          ),
        ],
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.day});

  final DiaryDay day;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      children: [
        _Totals(day: day),
        const SizedBox(height: 16),
        _WeekChart(week: day.week),
        const SizedBox(height: 16),
        if (day.entries.isEmpty)
          const EmptyState(
            icon: Icons.restaurant_outlined,
            title: 'Nenhuma refeição neste dia.',
            detail: 'Fotografe seu prato na tela de refeições.',
          )
        else
          for (final entry in day.entries) _EntryTile(entry: entry),
      ],
    );
  }
}

class _Totals extends StatelessWidget {
  const _Totals({required this.day});

  final DiaryDay day;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final targets = day.targets;
    final consumed = day.consumed;

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  '${consumed.kcal.round()}',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  targets == null
                      ? 'kcal hoje'
                      : 'de ${targets.kcal.round()} kcal',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            if (targets != null) ...[
              const SizedBox(height: 12),
              _MacroBar(
                label: 'Calorias',
                consumed: consumed.kcal,
                target: targets.kcal,
              ),
              _MacroBar(
                label: 'Proteína',
                consumed: consumed.proteinG,
                target: targets.proteinG,
                unit: 'g',
              ),
              _MacroBar(
                label: 'Carboidrato',
                consumed: consumed.carbsG,
                target: targets.carbsG,
                unit: 'g',
              ),
              _MacroBar(
                label: 'Gordura',
                consumed: consumed.fatG,
                target: targets.fatG,
                unit: 'g',
              ),
            ] else ...[
              const SizedBox(height: 8),
              // Sem dieta não há meta para comparar. Mostrar zero como meta faria as barras
              // aparecerem estouradas em qualquer refeição.
              Text(
                'Gere sua dieta para comparar o consumo com as suas metas.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Barra de consumo contra a meta.
///
/// Passar da meta não é pintado de vermelho: comer acima do alvo num dia não é erro, e o app
/// não deveria repreender. A barra satura em 100% e o número ao lado conta o resto.
class _MacroBar extends StatelessWidget {
  const _MacroBar({
    required this.label,
    required this.consumed,
    required this.target,
    this.unit = '',
  });

  final String label;
  final num consumed;
  final num target;
  final String unit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ratio = target <= 0
        ? 0.0
        : (consumed / target).clamp(0.0, 1.0).toDouble();

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(label, style: theme.textTheme.labelMedium)),
              Text(
                '${consumed.round()}$unit / ${target.round()}$unit',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(value: ratio, minHeight: 6),
          ),
        ],
      ),
    );
  }
}

/// Calorias dos últimos sete dias.
///
/// Série única, como no dashboard: as cores do tema reprovam como paleta categórica, e aqui
/// também não há segunda série a mostrar.
class _WeekChart extends StatelessWidget {
  const _WeekChart({required this.week});

  final List<DiaryDayTotal> week;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final max = week.fold<double>(
      0,
      (m, d) => d.kcal > m ? d.kcal.toDouble() : m,
    );

    if (max <= 0) {
      return const SizedBox.shrink();
    }

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Últimos 7 dias', style: theme.textTheme.titleSmall),
            const SizedBox(height: 12),
            SizedBox(
              height: 110,
              child: BarChart(
                BarChartData(
                  maxY: max * 1.15,
                  gridData: const FlGridData(show: false),
                  borderData: FlBorderData(show: false),
                  titlesData: FlTitlesData(
                    leftTitles: const AxisTitles(),
                    topTitles: const AxisTitles(),
                    rightTitles: const AxisTitles(),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 20,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index < 0 || index >= week.length) {
                            return const SizedBox.shrink();
                          }
                          final date = DateTime.tryParse(week[index].date);
                          return Text(
                            date == null ? '' : DateFormat('E').format(date),
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  barTouchData: BarTouchData(
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipColor: (_) => theme.colorScheme.inverseSurface,
                      getTooltipItem: (_, _, _, index) => BarTooltipItem(
                        '${week[index].kcal.round()} kcal',
                        theme.textTheme.labelSmall!.copyWith(
                          color: theme.colorScheme.onInverseSurface,
                        ),
                      ),
                    ),
                  ),
                  barGroups: [
                    for (var i = 0; i < week.length; i++)
                      BarChartGroupData(
                        x: i,
                        barRods: [
                          BarChartRodData(
                            toY: week[i].kcal.toDouble(),
                            color: theme.colorScheme.primary,
                            width: 14,
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
          ],
        ),
      ),
    );
  }
}

class _EntryTile extends ConsumerWidget {
  const _EntryTile({required this.entry});

  final DiaryEntry entry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final excluded = entry.excludedFromDiary;
    final time = DateTime.tryParse(entry.createdAt ?? '');

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text(
          '${entry.totalKcal.round()} kcal',
          style: theme.textTheme.titleSmall?.copyWith(
            decoration: excluded ? TextDecoration.lineThrough : null,
            color: excluded ? theme.colorScheme.onSurfaceVariant : null,
          ),
        ),
        subtitle: Text(
          '${time == null ? '' : '${DateFormat('HH:mm').format(time.toLocal())}  ·  '}'
          'P ${entry.totalProteinG.round()} g  ·  '
          'C ${entry.totalCarbsG.round()} g  ·  '
          'G ${entry.totalFatG.round()} g',
          style: theme.textTheme.labelSmall,
        ),
        // Excluir do diário não apaga a análise: ela continua na lista, riscada. Sumir com
        // ela esconderia do usuário a foto que ele mesmo mandou ignorar.
        trailing: Switch(
          value: !excluded,
          onChanged: (included) => _toggle(context, ref, included),
        ),
      ),
    );
  }

  Future<void> _toggle(
    BuildContext context,
    WidgetRef ref,
    bool included,
  ) async {
    try {
      await ref.read(diaryRepositoryProvider).setIncluded(entry.id, included);
      ref.invalidate(diaryDayProvider);
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
          ..clearSnackBars()
          ..showSnackBar(SnackBar(content: Text('$error')));
      }
    }
  }
}
