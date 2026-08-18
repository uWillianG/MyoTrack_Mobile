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
class DiaryView extends ConsumerStatefulWidget {
  const DiaryView({super.key});

  /// Quantos dias o carrossel cobre, terminando em hoje.
  ///
  /// Sete: é a janela que o próprio backend devolve no gráfico da semana, e é até onde alguém
  /// se lembra do que comeu sem ir procurar a foto.
  static const int days = 7;

  @override
  ConsumerState<DiaryView> createState() => _DiaryViewState();
}

class _DiaryViewState extends ConsumerState<DiaryView> {
  /// A página é a distância até hoje, ao contrário: 0 é o dia mais antigo, o último é hoje.
  late final PageController _pager = PageController(
    initialPage: _indexOf(ref.read(diaryDateProvider)),
  );

  late final DateTime _today = _dateOnly(DateTime.now());

  DateTime _dateAt(int index) =>
      _today.subtract(Duration(days: DiaryView.days - 1 - index));

  int _indexOf(DateTime date) =>
      (DiaryView.days - 1 - _today.difference(_dateOnly(date)).inDays).clamp(
        0,
        DiaryView.days - 1,
      );

  @override
  void dispose() {
    _pager.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    // O provider global segue o carrossel: quem lê o "dia aberto" de fora — a Hoje, o botão de
    // fotografar — precisa ver a mesma data que está na tela.
    ref.read(diaryDateProvider.notifier).state = _dateAt(index);
  }

  @override
  Widget build(BuildContext context) {
    final colors = Blocks.nutrition(Theme.of(context).brightness);

    // Um `listener` do provider e não `watch`: quem manda no carrossel é o gesto, e reagir à
    // própria escrita que ele acabou de fazer devolveria a página ao ponto de partida no meio
    // do arrasto. Só a mudança que veio *de fora* move o carrossel.
    ref.listen<DateTime>(diaryDateProvider, (previous, next) {
      final target = _indexOf(next);
      if (_pager.hasClients && _pager.page?.round() != target) {
        _pager.animateToPage(
          target,
          duration: Motion.slow,
          curve: Motion.enter,
        );
      }
    });

    return Column(
      children: [
        _WeekStrip(
          pager: _pager,
          today: _today,
          colors: colors,
          onPick: (index) => _pager.animateToPage(
            index,
            duration: Motion.slow,
            curve: Motion.enter,
          ),
        ),
        Expanded(
          child: PageView.builder(
            controller: _pager,
            onPageChanged: _onPageChanged,
            itemCount: DiaryView.days,
            itemBuilder: (context, index) =>
                _DayPage(date: _dateAt(index), colors: colors),
          ),
        ),
      ],
    );
  }
}

DateTime _dateOnly(DateTime date) => DateTime(date.year, date.month, date.day);

/// Um dia do carrossel.
///
/// Cada página assiste à **própria** data — ver [diaryDayOfProvider] —, e é isso que faz o dia
/// vizinho já estar desenhado quando o dedo o traz para dentro da tela em vez de aparecer
/// depois, num segundo quadro.
class _DayPage extends ConsumerWidget {
  const _DayPage({required this.date, required this.colors});

  final DateTime date;
  final BlockColors colors;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dayAsync = ref.watch(diaryDayOfProvider(date));

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(diaryDayOfProvider(date));
        await ref.read(diaryDayOfProvider(date).future);
      },
      child: dayAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => EmptyState(
          icon: Icons.cloud_off_outlined,
          title: 'Não foi possível carregar o diário.',
          detail: '$error',
          action: FilledButton.tonal(
            onPressed: () => ref.invalidate(diaryDayOfProvider(date)),
            child: const Text('Tentar de novo'),
          ),
        ),
        data: (day) => _Body(day: day, date: date, colors: colors),
      ),
    );
  }
}

/// A semana em sete alvos, terminando em hoje — e a pastilha que corre com o dedo.
///
/// Substituiu as setas "dia anterior / próximo dia". Com setas, chegar em segunda-feira a
/// partir de domingo custava seis toques e nenhum deles dizia onde a pessoa estava; aqui a
/// semana inteira está à vista, a distância é sempre um toque, **e agora também um arrasto**.
///
/// **A pastilha é solidária ao carrossel, não à página escolhida.** Ela lê a posição contínua
/// do `PageController` — que durante o arrasto é 3,4, 3,7, 3,9 — e não o índice inteiro. É a
/// diferença entre um marcador que *acompanha* o gesto e um que *salta* quando ele termina: o
/// primeiro faz a tira e o conteúdo parecerem a mesma peça, o segundo faz a tira parecer um
/// menu que foi avisado depois.
///
/// Não passa de hoje: o diário registra o que foi comido, e um dia futuro só poderia estar
/// vazio — o usuário acharia que perdeu dados.
class _WeekStrip extends StatelessWidget {
  const _WeekStrip({
    required this.pager,
    required this.today,
    required this.colors,
    required this.onPick,
  });

  final PageController pager;
  final DateTime today;
  final BlockColors colors;
  final ValueChanged<int> onPick;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 66,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(Space.gutter, 4, Space.gutter, 4),
        child: LayoutBuilder(
          builder: (context, constraints) {
            // O passo sai da largura disponível, e não de um chip de tamanho fixo: sete alvos
            // de 44 dp estouram um celular de 360, e a tira que rolava para caber tirava da
            // pastilha a única coisa que ela precisa ter — uma posição que o olho confere.
            final step = constraints.maxWidth / DiaryView.days;

            return Stack(
              children: [
                AnimatedBuilder(
                  animation: pager,
                  builder: (context, _) {
                    final page =
                        pager.hasClients && pager.position.haveDimensions
                        ? pager.page ?? 0
                        : pager.initialPage.toDouble();
                    return Positioned(
                      left: page * step + 2,
                      top: 0,
                      width: step - 4,
                      height: 58,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          // Um véu da família com um contorno dela, e não a cor cheia: sobre
                          // vidro a pastilha é um realce, não um botão.
                          color: colors.ink.withValues(alpha: 0.16),
                          borderRadius: Radii.mdAll,
                          border: Border.all(
                            color: colors.ink.withValues(alpha: 0.35),
                          ),
                        ),
                      ),
                    );
                  },
                ),
                Row(
                  children: [
                    for (var i = 0; i < DiaryView.days; i++)
                      SizedBox(
                        width: step,
                        height: 58,
                        child: _DayChip(
                          date: today.subtract(
                            Duration(days: DiaryView.days - 1 - i),
                          ),
                          onTap: () => onPick(i),
                        ),
                      ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _DayChip extends StatelessWidget {
  const _DayChip({required this.date, required this.onTap});

  final DateTime date;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Semantics(
      button: true,
      // A data por extenso para o leitor de tela: "S 27" não diz nada em voz alta.
      label: DateFormat("EEEE, d 'de' MMMM").format(date),
      excludeSemantics: true,
      child: InkWell(
        borderRadius: Radii.mdAll,
        onTap: onTap,
        // O texto não muda de cor com a seleção: quem marca o dia aberto é a pastilha que
        // corre por trás dele, e trocar a cor da letra no meio de um arrasto contínuo faria a
        // tira piscar de degrau em degrau.
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              DateFormat('E').format(date).substring(0, 1).toUpperCase(),
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 2),
            Text('${date.day}', style: theme.textTheme.titleMedium),
          ],
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
      padding: const EdgeInsets.fromLTRB(
        Space.gutter,
        4,
        Space.gutter,
        24 + Space.fabClearance,
      ),
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
        _MealsSection(entries: day.entries, date: date, colors: colors),
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
                color: colors.onGlass.withValues(alpha: 0.75),
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
  const _MealsSection({
    required this.entries,
    required this.date,
    required this.colors,
  });

  final List<DiaryEntry> entries;
  final DateTime date;
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
                  _EntryRow(entry: entries[i], date: date, colors: colors),
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
  const _EntryRow({
    required this.entry,
    required this.date,
    required this.colors,
  });

  final DiaryEntry entry;

  /// O dia a que esta linha pertence — e o que ela recarrega ao mexer no interruptor.
  ///
  /// Vem de cima em vez de sair de [diaryDateProvider]: no meio do arrasto entre dois dias há
  /// duas páginas vivas, e "o dia aberto" pode já ser o vizinho quando o toque chegar.
  final DateTime date;

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
      ref.refreshDiaryDay(date);
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
          ..clearSnackBars()
          ..showSnackBar(SnackBar(content: Text('$error')));
      }
    }
  }
}
