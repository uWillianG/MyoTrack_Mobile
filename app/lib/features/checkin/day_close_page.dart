import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/design/tokens.dart';
import '../../core/design/format.dart';
import '../../core/design/typography.dart';
import '../../core/sync/sync_queue.dart';
import '../../core/widgets/review_badge.dart';
import '../dashboard/dashboard_controller.dart';
import '../dashboard/dashboard_stats.dart';
import '../diary/data/diary_models.dart';
import '../diary/diary_controller.dart';
import '../diet/diet_plan_controller.dart';
import '../home/today_controller.dart';
import 'day_close_controller.dart';
import 'weigh_in.dart';

/// Fechar o dia: três perguntas e o que elas mudam.
///
/// Uma pergunta por tela, com opções grandes, porque isto é respondido no sofá às onze da
/// noite e não merece um formulário. As três em sequência também servem a outra coisa: a
/// pesagem, que é o único dado com destino certo, vem no meio de perguntas fáceis em vez de
/// sozinha — pedir só o peso todo dia soa cobrança.
class DayClosePage extends ConsumerStatefulWidget {
  const DayClosePage({super.key});

  @override
  ConsumerState<DayClosePage> createState() => _DayClosePageState();
}

class _DayClosePageState extends ConsumerState<DayClosePage> {
  /// 0, 1 e 2 são as perguntas; 3 é o resumo.
  int _step = 0;

  @override
  void initState() {
    super.initState();
    // Fechar o dia duas vezes começa do zero na segunda: as respostas de ontem não podem
    // aparecer já marcadas hoje.
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => ref.read(dayCloseProvider.notifier).restart(),
    );
  }

  void _advance() => setState(() => _step = _step + 1);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Fechar o dia')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            Space.gutter,
            Space.sm,
            Space.gutter,
            Space.xl,
          ),
          children: [
            // Fina de propósito: é um indicador de onde a pessoa está nas quatro etapas, e
            // não o assunto da tela. A barra padrão de 8 dp do tema competiria com o
            // enunciado da pergunta logo abaixo. O raio vem do tema.
            LinearProgressIndicator(value: (_step + 1) / 4, minHeight: 4),
            const SizedBox(height: Space.xl),
            switch (_step) {
              0 => _EffortStep(onAnswered: _advance),
              1 => _WeightStep(onAnswered: _advance),
              2 => _EnergyStep(onAnswered: _advance),
              _ => const _Summary(),
            },
          ],
        ),
      ),
    );
  }
}

class _EffortStep extends ConsumerWidget {
  const _EffortStep({required this.onAnswered});

  final VoidCallback onAnswered;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chosen = ref.watch(dayCloseProvider).effort;

    return _Question(
      title: 'Como foi o dia?',
      help: 'É o que diz se amanhã pede carga ou descanso.',
      children: [
        for (final effort in DayEffort.values)
          _Option(
            icon: switch (effort) {
              DayEffort.easy => Icons.sentiment_satisfied_outlined,
              DayEffort.normal => Icons.sentiment_neutral_outlined,
              DayEffort.hard => Icons.sentiment_dissatisfied_outlined,
            },
            label: effort.label,
            detail: effort.detail,
            selected: chosen == effort,
            onTap: () {
              ref.read(dayCloseProvider.notifier).setEffort(effort);
              onAnswered();
            },
          ),
      ],
    );
  }
}

class _EnergyStep extends ConsumerWidget {
  const _EnergyStep({required this.onAnswered});

  final VoidCallback onAnswered;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chosen = ref.watch(dayCloseProvider).energy;

    return _Question(
      title: 'Como está sua energia?',
      help:
          'Três dias seguidos em baixa é sinal de que o volume passou do ponto.',
      children: [
        for (final energy in DayEnergy.values)
          _Option(
            icon: switch (energy) {
              DayEnergy.high => Icons.battery_full,
              DayEnergy.medium => Icons.battery_5_bar,
              DayEnergy.low => Icons.battery_2_bar,
            },
            label: energy.label,
            detail: energy.detail,
            selected: chosen == energy,
            onTap: () {
              ref.read(dayCloseProvider.notifier).setEnergy(energy);
              onAnswered();
            },
          ),
      ],
    );
  }
}

/// A pesagem. É a única resposta do fechamento que chega ao servidor.
///
/// A primeira opção repete a última pesagem porque é a resposta certa na maioria dos dias —
/// peso corporal não muda meio quilo de um dia para o outro, e obrigar a digitar o mesmo
/// número faz a pessoa parar de responder na terceira noite.
class _WeightStep extends ConsumerWidget {
  const _WeightStep({required this.onAnswered});

  final VoidCallback onAnswered;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final last = ref.watch(dashboardStatsProvider).valueOrNull?.currentWeightKg;
    final chosen = ref.watch(dayCloseProvider).weightKg;

    return _Question(
      title: 'Seu peso de hoje',
      help: 'Uma pesagem por dia basta. Pela manhã é o ideal.',
      children: [
        if (last != null)
          _Option(
            icon: Icons.monitor_weight_outlined,
            label: Fmt.kg(last),
            detail: 'Igual à última pesagem',
            selected: chosen == last,
            onTap: () => _save(context, ref, last),
          ),
        _Option(
          icon: Icons.edit_outlined,
          label: last == null ? 'Informar peso' : 'Outro valor',
          detail: 'Digitar o que a balança mostrou',
          selected: chosen != null && chosen != last,
          onTap: () => _typeIn(context, ref),
        ),
        _Option(
          icon: Icons.remove_circle_outline,
          label: 'Não pesei hoje',
          detail: 'Segue sem registrar peso',
          selected: false,
          onTap: () {
            ref.read(dayCloseProvider.notifier).setWeight(null);
            onAnswered();
          },
        ),
      ],
    );
  }

  Future<void> _typeIn(BuildContext context, WidgetRef ref) async {
    final typed = await askWeightKg(context, title: 'Seu peso de hoje');

    if (typed != null && context.mounted) {
      await _save(context, ref, typed);
    }
  }

  Future<void> _save(
    BuildContext context,
    WidgetRef ref,
    double weightKg,
  ) async {
    // O que precisa sobreviver ao `await` é lido agora, enquanto este widget existe: a tela
    // avança na linha seguinte, e a pergunta do peso sai da árvore antes de o POST voltar.
    // O container é o do `ProviderScope` e o messenger é o do `MaterialApp` — os dois duram
    // mais que a tela.
    final container = containerOf(context);
    final messenger = ScaffoldMessenger.of(context);

    ref.read(dayCloseProvider.notifier).setWeight(weightKg);
    // Avança antes de a rede responder: a pergunta já foi respondida, e prender a tela
    // esperando um POST faria o fechamento parecer travado no Wi-Fi ruim.
    onAnswered();

    final outcome = await saveWeighIn(container, weightKg);
    if (outcome == WriteOutcome.sent) {
      return;
    }
    messenger
      ..clearSnackBars()
      ..showSnackBar(
        const SnackBar(
          content: Text('Peso guardado no aparelho. Sobe quando houver rede.'),
        ),
      );
  }
}

/// O resumo: o dia em três números, e o que já está marcado para amanhã.
///
/// **Não inventa ajuste.** O protótipo prometia "o plano de amanhã se ajusta ao que o dia
/// foi", e isso depende de um endpoint de check-in que o backend ainda não tem. O que a tela
/// mostra é o que existe: o consumo contra a meta, a pesagem, o próximo treino do plano e o
/// estado de revisão dele.
class _Summary extends ConsumerWidget {
  const _Summary();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final day = ref.watch(diaryDayProvider).valueOrNull;
    final stats = ref.watch(dashboardStatsProvider).valueOrNull;
    final answers = ref.watch(dayCloseProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Dia fechado', style: theme.textTheme.headlineSmall),
        const SizedBox(height: 6),
        Text(
          'É isto que ele deixou registrado.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 20),
        _Tiles(day: day, stats: stats),
        const SizedBox(height: 16),
        const _TomorrowCard(),
        const SizedBox(height: 12),
        _AnswersNote(answers: answers),
        const SizedBox(height: 20),
        FilledButton(
          onPressed: () {
            ref.invalidate(diaryDayProvider);
            Navigator.of(context).pop();
          },
          child: const Text('Concluir'),
        ),
      ],
    );
  }
}

class _Tiles extends StatelessWidget {
  const _Tiles({required this.day, required this.stats});

  final DiaryDay? day;
  final DashboardStats? stats;

  @override
  Widget build(BuildContext context) {
    final targets = day?.targets;
    final consumed = day?.consumed;
    final weight = stats?.currentWeightKg;
    final delta = stats?.weightDeltaKg;

    // `IntrinsicHeight` para os três tijolos terminarem na mesma linha mesmo quando um
    // deles quebra o detalhe em duas linhas. `stretch` sozinho não serve: dentro de uma
    // lista a altura é ilimitada, e esticar contra o infinito estoura o layout.
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: _Tile(
              label: 'Calorias',
              value: consumed == null ? '—' : Fmt.integer(consumed.kcal),
              detail: _gap(consumed?.kcal, targets?.kcal),
            ),
          ),
          const SizedBox(width: Space.xs),
          Expanded(
            child: _Tile(
              label: 'Proteína',
              value: consumed == null ? '—' : Fmt.grams(consumed.proteinG),
              detail: _gap(consumed?.proteinG, targets?.proteinG),
            ),
          ),
          const SizedBox(width: Space.xs),
          Expanded(
            child: _Tile(
              label: 'Peso',
              value: weight == null ? '—' : Fmt.kg(weight),
              // O sinal vai explícito porque "+0,3" e "−0,3" contam histórias opostas, e
              // cor sozinha não diria qual é qual para quem não distingue verde de vermelho.
              detail: delta == null
                  ? null
                  : '${Fmt.delta(delta, Fmt.kg)} no período',
            ),
          ),
        ],
      ),
    );
  }

  /// "−624 vs meta". Null quando não há meta com que comparar.
  ///
  /// Sem a unidade: ela está no número logo acima, dentro do mesmo tijolo. Com ela a linha
  /// passava de 105 dp e quebrava em duas, deixando os três tijolos de alturas diferentes.
  static String? _gap(num? consumed, num? target) {
    if (consumed == null || target == null || target <= 0) {
      return null;
    }
    final gap = (consumed - target).round();
    if (gap == 0) {
      return 'na meta';
    }
    return '${Fmt.delta(gap, Fmt.integer)} vs meta';
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
    final small = theme.textTheme.labelSmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(Space.sm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: small,
            ),
            const SizedBox(height: Space.xxs),
            // Três tijolos numa tela de 360 dp deixam ~105 dp para cada: o número encolhe
            // em vez de quebrar em duas linhas e desalinhar os vizinhos.
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                value,
                maxLines: 1,
                // O mesmo estilo numérico do anel da Hoje: são os três números que o
                // fechamento do dia entrega, e ler igual em todo lugar é metade do que faz
                // um app parecer um só produto.
                style: AppTypography.numeric(
                  size: 22,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ),
            const SizedBox(height: Space.xxs),
            if (detail != null)
              Text(
                detail!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: small,
              ),
          ],
        ),
      ),
    );
  }
}

/// O que o plano já diz sobre amanhã.
class _TomorrowCard extends ConsumerWidget {
  const _TomorrowCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final next = ref.watch(nextWorkoutProvider).valueOrNull;
    final diet = ref.watch(activeDietPlanProvider).valueOrNull;

    if (next == null && diet == null) {
      return const SizedBox.shrink();
    }

    final onContainer = theme.colorScheme.onPrimaryContainer;

    return Card(
      margin: EdgeInsets.zero,
      color: theme.colorScheme.primaryContainer,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Amanhã',
              style: theme.textTheme.titleSmall?.copyWith(color: onContainer),
            ),
            if (next != null) ...[
              const SizedBox(height: 8),
              Text(
                '${next.day.label} — ${next.exerciseCount} exercícios, '
                'cerca de ${next.estimatedMinutes} min.',
                style: theme.textTheme.bodyMedium?.copyWith(color: onContainer),
              ),
            ],
            if (diet != null) ...[
              const SizedBox(height: 6),
              Text(
                'Meta do dia: ${Fmt.kcal(diet.targets.kcal)} e '
                '${Fmt.grams(diet.targets.proteinG)} de proteína.',
                style: theme.textTheme.bodyMedium?.copyWith(color: onContainer),
              ),
              const SizedBox(height: 12),
              // O selo de revisão vem do plano ativo, e não de um texto fixo: quem já teve o
              // plano aprovado por um profissional não pode continuar lendo "aguardando".
              ReviewBadge(
                reviewStatus: diet.reviewStatus,
                reviewNote: diet.reviewNote,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// O que foi respondido — e onde essas respostas param.
///
/// A nota é curta e explícita de propósito. O app diz em outros lugares quando algo ainda
/// não saiu do aparelho (a fila de escrita, o selo de revisão), e esconder que o esforço e a
/// energia ficam aqui faria a pessoa esperar um ajuste que não vem.
class _AnswersNote extends StatelessWidget {
  const _AnswersNote({required this.answers});

  final DayCloseAnswers answers;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final said = [
      if (answers.effort != null) 'dia ${answers.effort!.label.toLowerCase()}',
      if (answers.energy != null)
        'energia ${answers.energy!.label.toLowerCase()}',
    ].join(' · ');

    if (said.isEmpty) {
      return const SizedBox.shrink();
    }

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
                  Icons.event_note_outlined,
                  size: 18,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Você marcou: $said.',
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Isso fica neste aparelho por enquanto — o servidor ainda não recebe o '
              'fechamento do dia. Sua pesagem, essa sim, já foi registrada.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Enunciado e opções de uma pergunta.
class _Question extends StatelessWidget {
  const _Question({
    required this.title,
    required this.help,
    required this.children,
  });

  final String title;
  final String help;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: theme.textTheme.headlineSmall),
        const SizedBox(height: Space.xs),
        Text(
          help,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: Space.xl),
        for (final child in children)
          Padding(
            padding: const EdgeInsets.only(bottom: Space.sm),
            child: child,
          ),
      ],
    );
  }
}

/// Uma opção de resposta. Alvo do tamanho de um cartão: é tocada com o polegar, deitado.
class _Option extends StatelessWidget {
  const _Option({
    required this.icon,
    required this.label,
    required this.detail,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String detail;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final foreground = selected
        ? theme.colorScheme.onPrimaryContainer
        : theme.colorScheme.onSurface;

    return Material(
      // `surfaceContainer`, e não `surface`: no claro `surface` é a cor do fundo da tela, e
      // a opção ficava com o mesmo preenchimento do que está atrás dela — sobrava só o fio
      // da borda para dizer que ali há algo a tocar.
      color: selected
          ? theme.colorScheme.primaryContainer
          : theme.colorScheme.surfaceContainer,
      shape: RoundedRectangleBorder(
        borderRadius: Radii.mdAll,
        side: BorderSide(
          color: selected
              ? Colors.transparent
              : theme.colorScheme.outlineVariant,
        ),
      ),
      child: InkWell(
        borderRadius: Radii.mdAll,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(Space.lg),
          child: Row(
            children: [
              Icon(
                icon,
                color: selected ? foreground : theme.colorScheme.primary,
              ),
              const SizedBox(width: Space.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: foreground,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      detail,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: selected
                            ? foreground
                            : theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              // A seta diz que a opção leva adiante, e não só marca. Sem ela as três caixas
              // parecem um grupo de rádio do qual ainda falta apertar "continuar".
              Icon(
                Icons.chevron_right,
                size: 20,
                color: selected
                    ? foreground
                    : theme.colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
