import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:go_router/go_router.dart';

import '../../core/design/tokens.dart';
import '../../core/design/format.dart';
import '../../core/design/typography.dart';
import '../../core/router.dart';
import '../../core/widgets/empty_state.dart';
import '../analysis/analysis_page.dart';
import '../home/home_page.dart';
import 'data/diary_models.dart';
import 'diary_controller.dart';

/// Diário alimentar. Porte de `DiaryPage.tsx`.
///
/// Rota própria (`/diario`) porque o link do e-mail e a notificação apontam para cá. O
/// conteúdo mora em [DiaryView] para que a aba Nutrição do hub diário possa mostrá-lo sem
/// uma segunda barra de título por cima da dela.
class DiaryPage extends StatelessWidget {
  const DiaryPage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Diário')),
    body: const DiaryView(),
  );
}

/// O diário sem a barra de título — é o que a aba Nutrição hospeda.
class DiaryView extends ConsumerWidget {
  const DiaryView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final date = ref.watch(diaryDateProvider);
    final dayAsync = ref.watch(diaryDayProvider);

    return Column(
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
  const _DayPicker({required this.date});

  final DateTime date;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    return SizedBox(
      height: 68,
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
    required this.onTap,
  });

  final DateTime date;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final foreground = selected
        ? theme.colorScheme.onPrimaryContainer
        : theme.colorScheme.onSurfaceVariant;

    return Semantics(
      selected: selected,
      button: true,
      // A data por extenso para o leitor de tela: "S 27" não diz nada em voz alta.
      label: DateFormat("EEEE, d 'de' MMMM").format(date),
      excludeSemantics: true,
      child: Material(
        // `primaryContainer`, o mesmo da aba selecionada na barra inferior. Com o esmeralda
        // cheio, o dia escolhido virava a coisa mais berrante da tela — mais que o botão de
        // fotografar a refeição, que é a ação que a tela quer. Cor cheia fica para ação.
        color: selected
            ? theme.colorScheme.primaryContainer
            : Colors.transparent,
        shape: const StadiumBorder(),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: onTap,
          child: SizedBox(
            width: 44,
            height: 60,
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
  const _Body({required this.day});

  final DiaryDay day;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(Space.gutter, 8, Space.gutter, 16),
      children: [
        _Totals(day: day),
        const SizedBox(height: 16),
        _WeekChart(week: day.week),
        const SizedBox(height: 16),
        if (day.entries.isEmpty)
          // `inline` porque isto já está dentro de uma `ListView`: a versão comum do
          // `EmptyState` é outra, e uma dentro da outra quebra o layout do dia sem refeição.
          const EmptyState.inline(
            icon: Icons.restaurant_outlined,
            title: 'Nenhuma refeição neste dia.',
            detail: 'Fotografe seu prato na tela de refeições.',
          )
        else
          for (final entry in day.entries) _EntryTile(entry: entry),
        // O diário é onde a falta aparece — "faltam 62 g de proteína" —, e é aqui que dá
        // vontade de registrar o que faltou. Sem este botão o caminho era voltar à barra de
        // navegação e achar a aba Analisar.
        const SizedBox(height: 8),
        const _AddMealButton(),
      ],
    );
  }
}

class _AddMealButton extends ConsumerWidget {
  const _AddMealButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return OutlinedButton.icon(
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
      icon: const Icon(Icons.photo_camera_outlined),
      label: const Text('Adicionar refeição por foto'),
      style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
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
                  Fmt.integer(consumed.kcal),
                  style: AppTypography.numeric(
                    size: 30,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(width: Space.xxs + 2),
                // `Flexible` porque a meta é um número que vem do servidor: com quatro
                // dígitos de cada lado e a fonte do sistema ampliada, a linha estoura a
                // largura do cartão num celular de 360 dp.
                Flexible(
                  child: Text(
                    targets == null
                        ? 'kcal hoje'
                        : 'de ${Fmt.kcal(targets.kcal)}',
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
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
                grams: true,
              ),
              _MacroBar(
                label: 'Carboidrato',
                consumed: consumed.carbsG,
                target: targets.carbsG,
                grams: true,
              ),
              _MacroBar(
                label: 'Gordura',
                consumed: consumed.fatG,
                target: targets.fatG,
                grams: true,
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
    this.grams = false,
  });

  final String label;
  final num consumed;
  final num target;

  /// Calorias não levam unidade nesta linha — o cabeçalho do cartão já disse "kcal".
  final bool grams;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ratio = target <= 0
        ? 0.0
        : (consumed / target).clamp(0.0, 1.0).toDouble();
    final unit = grams ? Fmt.grams : Fmt.integer;

    return Padding(
      padding: const EdgeInsets.only(bottom: Space.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(label, style: theme.textTheme.labelMedium)),
              Text(
                '${Fmt.integer(consumed)} / ${unit(target)}',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: Space.xxs),
          // O raio e a altura vêm do tema (`progressIndicatorTheme`), que é onde a barra do
          // app inteiro é definida — aqui só a altura menor, porque esta é uma barra de
          // apoio e não a de progresso de uma tela.
          LinearProgressIndicator(value: ratio, minHeight: 6),
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
          Fmt.kcal(entry.totalKcal),
          style: theme.textTheme.titleSmall?.copyWith(
            decoration: excluded ? TextDecoration.lineThrough : null,
            color: excluded ? theme.colorScheme.onSurfaceVariant : null,
          ),
        ),
        subtitle: Text(
          '${time == null ? '' : '${DateFormat('HH:mm').format(time.toLocal())}  ·  '}'
          'P ${Fmt.grams(entry.totalProteinG)}  ·  '
          'C ${Fmt.grams(entry.totalCarbsG)}  ·  '
          'G ${Fmt.grams(entry.totalFatG)}',
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
