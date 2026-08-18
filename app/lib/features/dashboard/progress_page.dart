import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/design/blocks.dart';
import '../../core/design/materials.dart';
import '../../core/design/format.dart';
import '../../core/design/tokens.dart';
import '../../core/router.dart';
import '../../core/widgets/blocks.dart';
import '../achievements/achievements_section.dart';
import '../achievements/data/rewards_repository.dart';
import '../profile/onboarding_controller.dart';
import '../progress/progress_controller.dart';
import '../reports/weekly_report_card.dart';
import 'dashboard_controller.dart';
import 'dashboard_stats.dart';
import 'progress_charts.dart';

/// Progresso: estou evoluindo?
///
/// **A manchete muda conforme o objetivo do perfil**, e é o que faz a tela responder a
/// pergunta que *esta* pessoa faz. Quem quer emagrecer abre para ver o peso; quem quer
/// hipertrofia abre para ver o volume; quem quer condicionamento abre para ver se está
/// aparecendo. Antes os três viam a mesma pilha de gráficos e dois deles tinham de rolar até
/// achar o seu.
///
/// **Absorveu as conquistas.** Eram tela própria e respondiam a mesma pergunta, obrigando a
/// pessoa a escolher entre conferir o número e ver o que ele rendeu. `/conquistas` agora
/// redireciona para cá, e a novidade fica acima da dobra — marcar como visto algo que exigiria
/// rolagem seria enganar quem veio comemorar.
///
/// **O relatório semanal subiu.** Um comentário nesta tela afirmava que ele ficava acima dos
/// gráficos "porque é leitura, não consulta", e o código o punha depois de tudo. Agora ele é a
/// primeira coisa abaixo da manchete: é o único bloco que já vem interpretado.
class ProgressPage extends ConsumerWidget {
  const ProgressPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Progresso')),
      body: const ProgressView(),
    );
  }
}

/// O corpo do Progresso, sem a barra de título.
class ProgressView extends ConsumerWidget {
  const ProgressView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(dashboardStatsProvider);

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(dashboardStatsProvider);
        await ref.read(dashboardStatsProvider.future);
      },
      child: async.when(
        loading: () => const _Skeleton(),
        error: (error, _) =>
            _Unavailable(onRetry: () => ref.invalidate(dashboardStatsProvider)),
        data: (stats) =>
            stats.isEmpty ? const _FirstSteps() : _Body(stats: stats),
      ),
    );
  }
}

// ---------------------------------------------------------------------------------------
// Quem é a manchete
// ---------------------------------------------------------------------------------------

/// Os três assuntos que podem abrir o Progresso.
enum ProgressFocus {
  /// Emagrecimento: o número que muda todo dia é o da balança.
  weight,

  /// Hipertrofia e estética: o trabalho feito, em quilos levantados.
  volume,

  /// Condicionamento: aparecer é o que se está medindo.
  consistency,
}

/// **A manchete sai do objetivo do perfil**, e não de uma preferência que ninguém configuraria.
///
/// Função pura e no topo do arquivo pelo mesmo motivo do `pickHero` da Hoje: é a única decisão
/// de produto desta tela, e decisão enterrada dentro de um `build` é decisão que ninguém
/// revisa. Recebe o objetivo em vez de ler o provider para que a tabela inteira caiba num
/// teste.
///
/// Sem perfil, [ProgressFocus.volume]: é o número que o app calcula sozinho a partir do que
/// foi registrado, enquanto o peso depende de a pessoa subir na balança.
ProgressFocus pickProgressFocus(String? goal) => switch (goal) {
  'WeightLoss' => ProgressFocus.weight,
  'Conditioning' => ProgressFocus.consistency,
  'Hypertrophy' || 'Aesthetics' => ProgressFocus.volume,
  _ => ProgressFocus.volume,
};

// ---------------------------------------------------------------------------------------
// O período
// ---------------------------------------------------------------------------------------

/// O recorte de tempo dos dois gráficos.
enum ProgressPeriod {
  // "1 mês" e não "4 semanas": os três rótulos por extenso estouravam o segmentado em 360 dp,
  // e é assim que se fala de um bloco de treino. O recorte exato em semanas fica no rótulo de
  // cada bloco, que é onde ele precisa ser preciso.
  fourWeeks('1 mês', 4),
  twelveWeeks('3 meses', 12),
  all('Tudo', null);

  const ProgressPeriod(this.label, this.weeks);

  final String label;

  /// Quantas semanas mostrar, ou null para todas as que houver.
  final int? weeks;
}

/// O período escolhido.
///
/// Mora num provider e não no `State` da tela porque o Progresso é montado de dois lugares — a
/// rota própria e a gaveta —, e a escolha da pessoa não pode se perder na ida e volta.
final progressPeriodProvider = StateProvider<ProgressPeriod>(
  (ref) => ProgressPeriod.twelveWeeks,
);

// ---------------------------------------------------------------------------------------
// O corpo
// ---------------------------------------------------------------------------------------

class _Body extends ConsumerWidget {
  const _Body({required this.stats});

  final DashboardStats stats;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final brightness = Theme.of(context).brightness;
    final period = ref.watch(progressPeriodProvider);
    final focus = pickProgressFocus(
      ref.watch(userProfileProvider).valueOrNull?.goal,
    );

    // **O volume satura em doze semanas** porque é o que o app guarda por semana; "Tudo" e
    // "12 semanas" mostram a mesma coisa nele, e a legenda de cada bloco diz o recorte real
    // para o rótulo do segmentado não prometer o que não existe.
    final weeks = period.weeks == null
        ? stats.weeklyVolume
        : stats.weeklyVolume.length <= period.weeks!
        ? stats.weeklyVolume
        : stats.weeklyVolume.sublist(stats.weeklyVolume.length - period.weeks!);

    final points = period.weeks == null
        ? stats.weightSeries
        : _weightWithin(stats.weightSeries, period.weeks!);

    return ListView(
      padding: const EdgeInsets.fromLTRB(Space.gutter, 4, Space.gutter, 32),
      children: [
        const _PeriodPicker(),
        const SizedBox(height: Space.sm),
        _Headline(
          focus: focus,
          stats: stats,
          weeks: weeks,
          points: points,
          period: period,
        ),
        // A comemoração vem antes de tudo, e acima da dobra: abrir esta tela marca as
        // conquistas como vistas, e quem veio só olhar o peso não pode gastar a comemoração
        // sem ver nada.
        const SizedBox(height: Space.sm),
        const AchievementsHighlight(),
        // O relatório é o único bloco que já vem interpretado: ele diz o que a semana foi, e
        // os gráficos existem para quem quer conferir.
        const SizedBox(height: Space.sm),
        const WeeklyReportCard(canGenerate: true),
        // As duas séries que não viraram manchete descem para seção, sem sumir.
        if (focus != ProgressFocus.volume) ...[
          const SizedBox(height: Space.sm),
          BlockSection(
            colors: Blocks.progress(brightness),
            label: 'Volume por semana',
            icon: Icons.bar_chart,
            trailing: _weeksLabel(weeks.length),
            child: VolumeChart(
              weeks: weeks,
              colors: Blocks.progress(brightness),
            ),
          ),
        ],
        if (focus != ProgressFocus.weight) ...[
          const SizedBox(height: Space.sm),
          BlockSection(
            colors: Blocks.progress(brightness),
            label: 'Peso corporal',
            icon: Icons.monitor_weight_outlined,
            trailing: points.length == 1
                ? '1 registro'
                : '${points.length} registros',
            child: WeightChart(
              points: points,
              colors: Blocks.progress(brightness),
            ),
          ),
        ],
        if (focus != ProgressFocus.consistency) ...[
          const SizedBox(height: Space.sm),
          _ConsistencySection(stats: stats, weeks: weeks),
        ],
        if (stats.records.isNotEmpty) ...[
          const SizedBox(height: Space.sm),
          _Records(records: stats.records),
        ],
        const SizedBox(height: Space.sm),
        const AchievementsSection(),
      ],
    );
  }

  /// As pesagens dentro da janela de semanas pedida.
  static List<WeightPoint> _weightWithin(List<WeightPoint> points, int weeks) {
    if (points.isEmpty) {
      return points;
    }
    final cutoff = DateTime.now().subtract(Duration(days: 7 * weeks));
    final within = [
      for (final point in points)
        if (!point.date.isBefore(cutoff)) point,
    ];
    // Menos de duas pesagens na janela não desenha linha nenhuma. Nesse caso a janela é
    // ignorada: um gráfico vazio porque a pessoa não se pesou este mês lê como defeito, e o
    // histórico dela continua sendo verdade.
    return within.length >= 2 ? within : points;
  }

  static String _weeksLabel(int count) =>
      count == 1 ? '1 semana' : '$count semanas';
}

class _PeriodPicker extends ConsumerWidget {
  const _PeriodPicker();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final period = ref.watch(progressPeriodProvider);

    return SegmentedButton<ProgressPeriod>(
      segments: [
        for (final option in ProgressPeriod.values)
          ButtonSegment(value: option, label: Text(option.label)),
      ],
      selected: {period},
      showSelectedIcon: false,
      onSelectionChanged: (selection) =>
          ref.read(progressPeriodProvider.notifier).state = selection.first,
    );
  }
}

// ---------------------------------------------------------------------------------------
// A manchete
// ---------------------------------------------------------------------------------------

class _Headline extends StatelessWidget {
  const _Headline({
    required this.focus,
    required this.stats,
    required this.weeks,
    required this.points,
    required this.period,
  });

  final ProgressFocus focus;
  final DashboardStats stats;
  final List<WeeklyVolume> weeks;
  final List<WeightPoint> points;
  final ProgressPeriod period;

  @override
  Widget build(BuildContext context) {
    final colors = Blocks.progress(Theme.of(context).brightness);

    return switch (focus) {
      ProgressFocus.weight => _WeightHeadline(
        stats: stats,
        points: points,
        colors: colors,
      ),
      ProgressFocus.volume => _VolumeHeadline(
        stats: stats,
        weeks: weeks,
        colors: colors,
      ),
      ProgressFocus.consistency => _ConsistencyHeadline(
        weeks: weeks,
        colors: colors,
      ),
    };
  }
}

class _WeightHeadline extends StatelessWidget {
  const _WeightHeadline({
    required this.stats,
    required this.points,
    required this.colors,
  });

  final DashboardStats stats;
  final List<WeightPoint> points;
  final BlockColors colors;

  @override
  Widget build(BuildContext context) {
    final current = stats.currentWeightKg;
    final delta = _deltaOf(points);

    return HeroBlock(
      colors: colors,
      label: 'Peso corporal',
      icon: Icons.monitor_weight_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          HeroFigure(
            value: current == null
                ? '—'
                : Fmt.kg(current).replaceAll(' kg', ''),
            unit: 'kg',
            colors: colors,
            // O sinal vai explícito: "+2 kg" e "−2 kg" contam histórias opostas, e cor
            // sozinha não diria qual é qual para quem não distingue verde de vermelho.
            detail: delta == null
                ? 'Uma segunda pesagem e a variação aparece'
                : '${Fmt.delta(delta, Fmt.kg)} no período',
          ),
          const SizedBox(height: Space.md),
          WeightChart(points: points, colors: colors),
        ],
      ),
    );
  }

  static double? _deltaOf(List<WeightPoint> points) => points.length < 2
      ? null
      : points.last.weightKg.toDouble() - points.first.weightKg.toDouble();
}

class _VolumeHeadline extends StatelessWidget {
  const _VolumeHeadline({
    required this.stats,
    required this.weeks,
    required this.colors,
  });

  final DashboardStats stats;
  final List<WeeklyVolume> weeks;
  final BlockColors colors;

  @override
  Widget build(BuildContext context) {
    final change = _changePercent(weeks);

    return HeroBlock(
      colors: colors,
      label: 'Volume da semana',
      icon: Icons.bar_chart,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          HeroFigure(
            value: _tons(stats.volumeThisWeek),
            unit: stats.volumeThisWeek < 1000 ? 'kg' : 't',
            colors: colors,
            detail: change == null
                ? 'Levantados nesta semana'
                : '${change >= 0 ? '+' : '−'}${change.abs().round()}% '
                      'que a semana passada',
          ),
          const SizedBox(height: Space.md),
          VolumeChart(weeks: weeks, colors: colors),
        ],
      ),
    );
  }

  /// Quanto o volume mudou da semana anterior para esta.
  ///
  /// Null quando não há semana anterior com volume: dividir por zero daria infinito, e "+∞%"
  /// não é elogio nenhum para quem voltou a treinar depois de uma pausa.
  static double? _changePercent(List<WeeklyVolume> weeks) {
    if (weeks.length < 2) {
      return null;
    }
    final previous = weeks[weeks.length - 2].volumeKg.toDouble();
    if (previous <= 0) {
      return null;
    }
    final current = weeks.last.volumeKg.toDouble();
    return (current - previous) / previous * 100;
  }

  /// Volume em toneladas a partir de mil quilos: "8,4" contra "8.400" é a diferença entre um
  /// número que se lê de relance e um que se soletra.
  static String _tons(double kg) => kg < 1000
      ? Fmt.integer(kg)
      : NumberFormat('#,##0.0', 'pt_BR').format(kg / 1000);
}

class _ConsistencyHeadline extends ConsumerWidget {
  const _ConsistencyHeadline({required this.weeks, required this.colors});

  final List<WeeklyVolume> weeks;
  final BlockColors colors;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trained = weeks.where((w) => w.sessions > 0).length;
    final streak = ref.watch(rewardStatusProvider).valueOrNull?.streakWeeks;

    return HeroBlock(
      colors: colors,
      label: 'Constância',
      icon: Icons.local_fire_department,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          HeroFigure(
            value: '$trained',
            unit: 'de ${weeks.length} semanas',
            colors: colors,
            detail: streak == null || streak < 2
                ? 'Com pelo menos um treino'
                : 'Sequência atual de $streak semanas seguidas',
          ),
          const SizedBox(height: Space.md),
          _WeekBars(weeks: weeks, colors: colors),
        ],
      ),
    );
  }
}

/// A constância como seção, para quem não a tem como manchete.
class _ConsistencySection extends StatelessWidget {
  const _ConsistencySection({required this.stats, required this.weeks});

  final DashboardStats stats;
  final List<WeeklyVolume> weeks;

  @override
  Widget build(BuildContext context) {
    final colors = Blocks.progress(Theme.of(context).brightness);
    final trained = weeks.where((w) => w.sessions > 0).length;

    return BlockSection(
      colors: colors,
      label: 'Constância',
      icon: Icons.local_fire_department,
      trailing: '$trained de ${weeks.length} semanas',
      child: _WeekBars(weeks: weeks, colors: colors),
    );
  }
}

/// Uma barrinha por semana: cheia se houve treino, vazada se não.
///
/// Não é um gráfico — é um calendário. O número de sessões não entra na altura de propósito:
/// a pergunta da constância é "apareci?", e uma barra proporcional faria a semana de dois
/// treinos parecer meio ausente.
class _WeekBars extends StatelessWidget {
  const _WeekBars({required this.weeks, required this.colors});

  final List<WeeklyVolume> weeks;
  final BlockColors colors;

  @override
  Widget build(BuildContext context) {
    final ink = colors.ink;

    return Semantics(
      label:
          '${weeks.where((w) => w.sessions > 0).length} de ${weeks.length} '
          'semanas com treino',
      excludeSemantics: true,
      child: SizedBox(
        height: 34,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            for (var i = 0; i < weeks.length; i++) ...[
              if (i > 0) const SizedBox(width: 4),
              Expanded(
                child: Container(
                  height: weeks[i].sessions > 0 ? 34 : 12,
                  decoration: BoxDecoration(
                    color: ink.withValues(
                      alpha: weeks[i].sessions > 0 ? 1 : 0.25,
                    ),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------------------
// Recordes
// ---------------------------------------------------------------------------------------

/// Os três maiores, e a lista inteira a um toque.
///
/// Eram dez linhas no meio de uma tela de gráficos — inventário que a pessoa aprende a rolar
/// por cima. Três cabem sem disputar, e quem quer o histórico de força inteiro tem onde vê-lo.
class _Records extends StatelessWidget {
  const _Records({required this.records});

  static const int _shown = 3;

  final List<ExerciseRecord> records;

  @override
  Widget build(BuildContext context) {
    final colors = Blocks.progress(Theme.of(context).brightness);
    final extra = records.length - _shown;

    return BlockSection(
      colors: colors,
      label: 'Recordes',
      icon: Icons.military_tech_outlined,
      trailing: 'por exercício',
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          for (final record in records.take(_shown))
            _RecordRow(record: record, colors: colors),
          if (extra > 0)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                Space.xs,
                0,
                Space.md,
                Space.xs,
              ),
              child: Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  onPressed: () => _showAll(context, records, colors),
                  child: Text(
                    extra == 1
                        ? 'Ver mais 1 exercício'
                        : 'Ver mais $extra exercícios',
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  static Future<void> _showAll(
    BuildContext context,
    List<ExerciseRecord> records,
    BlockColors colors,
  ) {
    return showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      // Altura de teto e rolagem própria, em vez de um `DraggableScrollableSheet`: a folha só
      // precisa caber e rolar, e o arrasto para redimensionar acrescenta um gesto que compete
      // com o de rolar a própria lista.
      builder: (context) => SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * 0.75,
          ),
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.fromLTRB(0, 0, 0, Space.lg),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  Space.gutter,
                  0,
                  Space.gutter,
                  Space.md,
                ),
                child: Text(
                  'Seus recordes',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              for (final record in records)
                _RecordRow(record: record, colors: colors),
            ],
          ),
        ),
      ),
    );
  }
}

class _RecordRow extends StatelessWidget {
  const _RecordRow({required this.record, required this.colors});

  final ExerciseRecord record;
  final BlockColors colors;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        Space.md,
        Space.xs,
        Space.md,
        Space.xs,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  record.name,
                  style: theme.textTheme.titleSmall,
                  overflow: TextOverflow.ellipsis,
                ),
                if (_detailOf(record) case final detail when detail.isNotEmpty)
                  Text(detail, style: theme.textTheme.bodySmall),
              ],
            ),
          ),
          const SizedBox(width: Space.sm),
          Text(
            Fmt.kg(record.maxLoadKg.toDouble()),
            style: theme.textTheme.titleSmall?.copyWith(color: colors.ink),
          ),
        ],
      ),
    );
  }

  /// Repetições e data da série mais pesada, no que houver delas.
  ///
  /// Os dois campos são opcionais no contrato: um recorde sem data ou sem repetições ainda é
  /// uma carga válida para mostrar, e sumir com a linha inteira por causa disso seria pior.
  static String _detailOf(ExerciseRecord record) => [
    if (record.maxLoadReps != null) '${record.maxLoadReps} reps',
    if (record.maxLoadDate != null)
      DateFormat('d/M/y').format(record.maxLoadDate!),
  ].join(' · ');
}

// ---------------------------------------------------------------------------------------
// Estados
// ---------------------------------------------------------------------------------------

/// Quem ainda não registrou nada não tem gráfico para ver — e um gráfico vazio pareceria
/// defeito. Em vez disso, o próximo passo.
class _FirstSteps extends StatelessWidget {
  const _FirstSteps();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = Blocks.progress(theme.brightness);

    return ListView(
      padding: const EdgeInsets.fromLTRB(Space.gutter, 4, Space.gutter, 32),
      children: [
        HeroBlock(
          colors: colors,
          label: 'Progresso',
          icon: Icons.insights,
          action: HeroAction(
            label: 'Registrar treino',
            onPressed: () => context.push(Routes.logSession),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Ainda não há\no que comparar.',
                style: theme.textTheme.displaySmall?.copyWith(
                  color: colors.onGlass,
                ),
              ),
              const SizedBox(height: Space.sm),
              Text(
                'Registre seu primeiro treino e seu peso. A partir daí esta tela mostra '
                'volume por semana, evolução do peso e seus recordes.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colors.onGlass.withValues(alpha: 0.85),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Skeleton extends StatelessWidget {
  const _Skeleton();

  @override
  Widget build(BuildContext context) {
    // O mesmo vidro dos blocos de verdade: a espera é o cartão ainda sem conteúdo, e a chegada
    // do dado não troca a superfície debaixo dele.
    return ListView(
      padding: const EdgeInsets.fromLTRB(Space.gutter, 4, Space.gutter, 32),
      children: [
        for (final height in [48.0, 260.0, 170.0, 170.0])
          Padding(
            padding: const EdgeInsets.only(bottom: Space.sm),
            child: GlassPanel(child: SizedBox(height: height)),
          ),
      ],
    );
  }
}

class _Unavailable extends StatelessWidget {
  const _Unavailable({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.fromLTRB(Space.gutter, 4, Space.gutter, 32),
      children: [
        Container(
          height: 220,
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHigh,
            borderRadius: Radii.lgAll,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.cloud_off_outlined,
                size: 32,
                color: theme.colorScheme.outline,
              ),
              const SizedBox(height: Space.md),
              Text(
                'Não foi possível carregar seus números.',
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: Space.xs),
              TextButton(
                onPressed: onRetry,
                child: const Text('Tentar de novo'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
