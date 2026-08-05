import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/design/blocks.dart';
import '../../core/design/format.dart';
import '../../core/design/tokens.dart';
import '../../core/router.dart';
import '../../core/widgets/blocks.dart';
import '../../core/widgets/empty_state.dart';
import '../analysis/analysis_page.dart';
import '../home/home_page.dart';
import 'data/diary_models.dart';
import 'diary_controller.dart';

/// Diário alimentar.
///
/// Rota própria (`/diario`) porque o link do e-mail e a notificação apontam para cá. O conteúdo
/// mora em [DiaryView] para que a aba Nutrição do hub possa mostrá-lo sem uma segunda barra de
/// título por cima da dela.
class DiaryPage extends StatelessWidget {
  const DiaryPage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Diário')),
    body: const DiaryView(),
  );
}

/// O diário sem a barra de título — é o que a aba Nutrição hospeda.
///
/// **Pergunta: o que eu comi neste dia? Ação: fotografar a próxima refeição.**
///
/// A tela é toda esmeralda porque é toda o mesmo assunto. Onde a Hoje usa ladrilhos de cores
/// diferentes — treino, peso, semana são coisas distintas —, aqui calorias, macros, histórico e
/// refeições são o **mesmo** número visto de quatro ângulos, e picotá-los em ladrilhos
/// coloridos sugeriria uma independência que eles não têm. Por isso: um herói e três seções.
///
/// **O número grande é o consumido, e não o que resta.** É a diferença entre esta tela e a
/// Hoje, e ela é deliberada: a Hoje responde "quanto ainda cabe", pergunta que só faz sentido
/// hoje; o diário é navegável para trás, e "restam 624" num sábado que já acabou não significa
/// nada.
class DiaryView extends ConsumerWidget {
  const DiaryView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final date = ref.watch(diaryDateProvider);
    final dayAsync = ref.watch(diaryDayProvider);
    final colors = Blocks.nutrition(Theme.of(context).brightness);

    return Column(
      children: [
        _DayPicker(date: date, colors: colors),
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
              data: (day) => _Body(day: day, date: date, colors: colors),
            ),
          ),
        ),
      ],
    );
  }
}

/// A semana em sete alvos, terminando em hoje.
///
/// Substituiu as setas "dia anterior / próximo dia". Com setas, chegar em segunda-feira a
/// partir de domingo custava seis toques e nenhum deles dizia onde a pessoa estava; aqui a
/// semana inteira está à vista e a distância é sempre um toque.
///
/// Não passa de hoje: o diário registra o que foi comido, e um dia futuro só poderia estar
/// vazio — o usuário acharia que perdeu dados.
class _DayPicker extends ConsumerWidget {
  const _DayPicker({required this.date, required this.colors});

  final DateTime date;
  final BlockColors colors;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    return SizedBox(
      height: 66,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(Space.gutter, 4, Space.gutter, 4),
        children: [
          for (var back = 6; back >= 0; back--) ...[
            if (back < 6) const SizedBox(width: 6),
            () {
              final day = today.subtract(Duration(days: back));
              return _DayChip(
                date: day,
                selected: day == date,
                colors: colors,
                onTap: () => ref.read(diaryDateProvider.notifier).state = day,
              );
            }(),
          ],
        ],
      ),
    );
  }
}

class _DayChip extends StatelessWidget {
  const _DayChip({
    required this.date,
    required this.selected,
    required this.colors,
    required this.onTap,
  });

  final DateTime date;
  final bool selected;
  final BlockColors colors;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final foreground = selected
        ? colors.onTone
        : theme.colorScheme.onSurfaceVariant;

    return Semantics(
      selected: selected,
      button: true,
      // A data por extenso para o leitor de tela: "S 27" não diz nada em voz alta.
      label: DateFormat("EEEE, d 'de' MMMM").format(date),
      excludeSemantics: true,
      child: Material(
        // Cor cheia da família, e não mais o container claro do Material: o dia escolhido é o
        // que comanda a tela inteira abaixo dele, e um chip pálido não sustentava esse papel
        // ao lado de um herói em esmeralda cheio.
        color: selected ? colors.tone : Colors.transparent,
        shape: const StadiumBorder(),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: onTap,
          child: SizedBox(
            width: 44,
            height: 58,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  DateFormat('E').format(date).substring(0, 1).toUpperCase(),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: foreground,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${date.day}',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: foreground,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.day, required this.date, required this.colors});

  final DiaryDay day;
  final DateTime date;
  final BlockColors colors;

  @override
  Widget build(BuildContext context) {
    final targets = day.targets;
    final included = [
      for (final entry in day.entries)
        if (!entry.excludedFromDiary) entry.totalKcal,
    ];

    return ListView(
      padding: const EdgeInsets.fromLTRB(Space.gutter, 4, Space.gutter, 24),
      children: [
        _DayHero(day: day, date: date, colors: colors, mealKcal: included),
        if (targets != null) ...[
          const SizedBox(height: Space.sm),
          BlockSection(
            colors: colors,
            label: 'Macros do dia',
            icon: Icons.pie_chart_outline,
            child: Column(
              children: [
                for (final macro in [
                  ('Proteína', day.consumed.proteinG, targets.proteinG),
                  ('Carboidrato', day.consumed.carbsG, targets.carbsG),
                  ('Gordura', day.consumed.fatG, targets.fatG),
                ]) ...[
                  if (macro.$1 != 'Proteína') const SizedBox(height: Space.sm),
                  BlockMeter(
                    colors: colors,
                    label: macro.$1,
                    value: '${Fmt.integer(macro.$2)} / ${Fmt.grams(macro.$3)}',
                    ratio: macro.$3 <= 0 ? 0 : macro.$2 / macro.$3,
                  ),
                ],
              ],
            ),
          ),
        ],
        if (day.week.any((d) => d.kcal > 0)) ...[
          const SizedBox(height: Space.sm),
          _WeekSection(week: day.week, colors: colors),
        ],
        const SizedBox(height: Space.sm),
        _MealsSection(entries: day.entries, colors: colors),
      ],
    );
  }
}

/// O herói do diário: o total do dia, a barra de refeições e o caminho da próxima.
class _DayHero extends ConsumerWidget {
  const _DayHero({
    required this.day,
    required this.date,
    required this.colors,
    required this.mealKcal,
  });

  final DiaryDay day;
  final DateTime date;
  final BlockColors colors;
  final List<num> mealKcal;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final targets = day.targets;
    final consumed = day.consumed.kcal;
    final left = targets == null
        ? null
        : math.max(0, (targets.kcal - consumed).round());

    return HeroBlock(
      colors: colors,
      label: _dayLabel(date),
      icon: Icons.event_note,
      // O diário é onde a falta aparece — "faltam 62 g de proteína" — e é aqui que dá vontade
      // de registrar o que faltou. Sem este botão o caminho era voltar à barra de navegação e
      // achar a aba Analisar.
      action: HeroAction(
        label: 'Fotografar refeição',
        onPressed: () {
          ref.read(analysisTabProvider.notifier).state = AnalysisTab.meal;
          // Dentro do hub troca de aba; numa `/diario` empilhada não há hub, e aí o jeito de
          // chegar à câmera é a rota.
          if (ref.read(homeTabProvider) == HomeTab.nutrition) {
            ref.read(homeTabProvider.notifier).state = HomeTab.analysis;
          } else {
            context.push(Routes.mealAnalysis);
          }
        },
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          HeroFigure(
            value: Fmt.integer(consumed),
            unit: 'kcal',
            colors: colors,
            detail: targets == null
                // Sem dieta não há meta com que comparar, e inventar uma faria as barras
                // aparecerem estouradas em qualquer refeição.
                ? 'Sem meta ainda: sua dieta não foi gerada.'
                : left == 0
                ? 'Meta de ${Fmt.kcal(targets.kcal)} alcançada'
                : 'de ${Fmt.kcal(targets.kcal)} · faltam ${Fmt.integer(left!)}',
          ),
          if (targets != null && targets.kcal > 0) ...[
            const SizedBox(height: Space.md),
            MealBar(
              slices: MealBar.slicesOf(
                mealKcal: mealKcal,
                consumed: consumed,
                target: targets.kcal,
              ),
              colors: colors,
            ),
            const SizedBox(height: Space.xs),
            Text(
              mealKcal.isEmpty
                  ? 'Nenhuma refeição registrada'
                  : mealKcal.length == 1
                  ? '1 refeição registrada'
                  : '${mealKcal.length} refeições registradas',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colors.onTone.withValues(alpha: 0.75),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// "Hoje", "Ontem", ou a data por extenso.
String _dayLabel(DateTime date) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final days = today
      .difference(DateTime(date.year, date.month, date.day))
      .inDays;

  if (days == 0) {
    return 'Hoje';
  }
  if (days == 1) {
    return 'Ontem';
  }

  return Fmt.weekdayDayMonth(date);
}

/// Calorias dos últimos sete dias.
///
/// Série única, como no dashboard: as cores do tema reprovam como paleta categórica, e aqui
/// também não há segunda série a mostrar.
class _WeekSection extends StatelessWidget {
  const _WeekSection({required this.week, required this.colors});

  final List<DiaryDayTotal> week;
  final BlockColors colors;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final max = week.fold<double>(
      0,
      (m, d) => d.kcal > m ? d.kcal.toDouble() : m,
    );
    final average =
        week.fold<double>(0, (sum, d) => sum + d.kcal) /
        math.max(1, week.where((d) => d.kcal > 0).length);

    return BlockSection(
      colors: colors,
      label: 'Últimos 7 dias',
      icon: Icons.bar_chart,
      trailing: 'média ${Fmt.kcal(average)}',
      child: SizedBox(
        height: 104,
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
                  Fmt.kcal(week[index].kcal),
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
                      // A cor cheia da família sobre o fundo lavado dela. O `primary` do tema
                      // sairia um verde diferente do resto do bloco.
                      color: colors.ink,
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
    );
  }
}

/// As refeições do dia, uma por linha.
///
/// Eram cinco cartões brancos flutuando um sobre o outro. São uma lista: uma caixa só, linhas
/// separadas por um fio. O respiro lateral é zero de propósito — com margem dos dois lados o
/// fio deixa de encostar nas bordas e a lista parece um monte de itens soltos.
class _MealsSection extends StatelessWidget {
  const _MealsSection({required this.entries, required this.colors});

  final List<DiaryEntry> entries;
  final BlockColors colors;

  @override
  Widget build(BuildContext context) {
    final included = entries.where((e) => !e.excludedFromDiary).length;

    return BlockSection(
      colors: colors,
      label: 'Refeições',
      icon: Icons.restaurant,
      trailing: entries.isEmpty ? null : '$included no diário',
      padding: EdgeInsets.zero,
      child: entries.isEmpty
          ? const Padding(
              padding: EdgeInsets.fromLTRB(Space.md, 0, Space.md, Space.lg),
              child: _NoMeals(),
            )
          : Column(
              children: [
                for (var i = 0; i < entries.length; i++) ...[
                  if (i > 0)
                    Divider(
                      height: 1,
                      indent: Space.md,
                      endIndent: Space.md,
                      color: colors.ink.withValues(alpha: 0.14),
                    ),
                  _EntryRow(entry: entries[i], colors: colors),
                ],
              ],
            ),
    );
  }
}

class _NoMeals extends StatelessWidget {
  const _NoMeals();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Nenhuma refeição neste dia.', style: theme.textTheme.titleSmall),
        const SizedBox(height: 2),
        Text(
          'Fotografe o prato e a IA estima calorias e macros.',
          style: theme.textTheme.bodySmall,
        ),
      ],
    );
  }
}

class _EntryRow extends ConsumerWidget {
  const _EntryRow({required this.entry, required this.colors});

  final DiaryEntry entry;
  final BlockColors colors;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final excluded = entry.excludedFromDiary;
    final time = DateTime.tryParse(entry.createdAt ?? '');

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        Space.md,
        Space.sm,
        Space.xs,
        Space.sm,
      ),
      child: Row(
        children: [
          // A hora antes do número: a lista é cronológica, e é por ela que se acha a refeição
          // que se quer mexer.
          SizedBox(
            width: 46,
            child: Text(
              time == null ? '—' : DateFormat('HH:mm').format(time.toLocal()),
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  Fmt.kcal(entry.totalKcal),
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: excluded
                        ? theme.colorScheme.onSurfaceVariant
                        : colors.ink,
                    decoration: excluded ? TextDecoration.lineThrough : null,
                  ),
                ),
                Text(
                  'P ${Fmt.grams(entry.totalProteinG)} · '
                  'C ${Fmt.grams(entry.totalCarbsG)} · '
                  'G ${Fmt.grams(entry.totalFatG)}',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
          // Excluir do diário não apaga a análise: ela continua na lista, riscada. Sumir com
          // ela esconderia do usuário a foto que ele mesmo mandou ignorar.
          Switch(
            value: !excluded,
            onChanged: (included) => _toggle(context, ref, included),
          ),
        ],
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
