import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/design/blocks.dart';
import '../../core/design/format.dart';
import '../../core/design/materials.dart';
import '../../core/design/tokens.dart';
import '../../core/design/typography.dart';
import '../../core/router.dart';
import '../../core/widgets/blocks.dart';
import '../achievements/achievements_controller.dart';
import '../achievements/data/rewards_repository.dart';
import '../dashboard/dashboard_controller.dart';
import '../diary/data/diary_models.dart';
import '../diary/diary_controller.dart';
import '../profile/onboarding_controller.dart';
import 'account_avatar.dart';
import 'today_ring.dart';
import 'today_controller.dart';

/// Hoje: uma superfície, e o assunto do momento no topo.
///
/// **A tela tem uma forma só, e ela se reorganiza conforme a hora.** No alto, o herói —
/// que responde a única pergunta que importa naquele momento do dia: de manhã, qual treino é
/// hoje; à tarde, quanto ainda cabe de comida; à noite, fechar o dia. Abaixo dele, o resto do
/// app em cartões, um por assunto, cada um com a tinta da sua família.
///
/// **Por que assim, depois de três tentativas erradas.** A primeira empilhou seis cartões
/// brancos idênticos e o usuário não sabia por onde começar. A segunda cortou até sobrar um
/// anel e um botão, e ficou vazia sem ficar bonita — o que provou que o problema nunca foi
/// quantidade. A terceira acertou a hierarquia e errou o material: cada bloco ganhou um fundo
/// pintado na cor do assunto, e a tela virou um mosaico de sete retângulos coloridos brigando
/// entre si — separava bem os assuntos e parecia um painel de instrumentos.
///
/// O que ficou de pé de cada uma: **a hora decide o herói** (a segunda), **a cor pertence ao
/// assunto** (a terceira) — e a correção é de portador. O fundo é sempre o mesmo vidro; a cor
/// vive na tinta. Quem separa as peças agora é profundidade e escala, não área de cor.
///
/// **E o herói deixou de ser só um bloco maior.** Sendo a nutrição, ele é o anel — que colapsa
/// para dentro da barra ao rolar e guarda o dia inteiro atrás de si, a um puxão. Ver
/// [TodayRingHero].
///
/// **O assunto promovido sai do resto.** Ele não aparece duas vezes.
class TodayView extends ConsumerStatefulWidget {
  const TodayView({super.key});

  @override
  ConsumerState<TodayView> createState() => _TodayViewState();
}

class _TodayViewState extends ConsumerState<TodayView> {
  final ScrollController _scroll = ScrollController();

  /// 0 no topo da lista, 1 com o herói fora de cena.
  ///
  /// Um `ValueNotifier` e não `setState`: o cabeçalho é a única coisa que muda com a rolagem, e
  /// reconstruir a lista inteira a cada quadro de rolagem é o jeito mais caro possível de
  /// desenhar um borrão.
  final ValueNotifier<double> _collapse = ValueNotifier(0);

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scroll.removeListener(_onScroll);
    _scroll.dispose();
    _collapse.dispose();
    super.dispose();
  }

  void _onScroll() {
    // 150 dp: a altura em que o número grande já saiu do enquadramento. Antes disso a barra
    // materializando marcaria uma divisão que ainda não existe.
    _collapse.value = (_scroll.offset / 150).clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    final headerHeight = MediaQuery.paddingOf(context).top + _headerBar;

    // O cabeçalho **flutua sobre a lista**, e não acima dela: é o que permite ao conteúdo
    // passar por baixo do vidro, que é a única razão de o vidro existir.
    return Stack(
      children: [
        RefreshIndicator(
          // Empurrado para baixo do cabeçalho: no lugar padrão o indicador nasce atrás do
          // vidro e a pessoa vê um borrão girando.
          edgeOffset: headerHeight,
          onRefresh: () async {
            ref.invalidate(diaryDayProvider);
            ref.invalidate(dashboardStatsProvider);
            ref.invalidate(nextWorkoutProvider);
            ref.invalidate(pendingReviewsProvider);
            await ref.read(diaryDayProvider.future);
          },
          child: ListView(
            controller: _scroll,
            padding: EdgeInsets.fromLTRB(
              Space.gutter,
              headerHeight + Space.xs,
              Space.gutter,
              // O respiro de baixo passa do botão flutuante e da barra de abas: sem ele o
              // último cartão para debaixo dos dois e a rolagem acaba antes de tirá-lo de lá.
              Space.huge + listBottomInset(context),
            ),
            children: [
              const _DateLine(),
              _Mosaic(scrollController: _scroll),
            ],
          ),
        ),
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: _TodayHeader(collapse: _collapse),
        ),
      ],
    );
  }
}

/// A altura da tira de título, abaixo do recorte do sistema.
const double _headerBar = 46;

/// O cabeçalho da Hoje: o nome da aba, o anel em miniatura e o avatar.
///
/// **Ele chega com a rolagem.** No topo da lista não há nada por baixo dele para borrar, e uma
/// barra já materializada ali só desenharia uma divisão onde a tela é contínua. Conforme o
/// conteúdo sobe, o véu e o borrão entram juntos — e o número que estava no anel grande
/// reaparece em miniatura, para que a resposta que trouxe a pessoa ao app não saia da tela só
/// porque ela rolou para ver o treino.
class _TodayHeader extends StatelessWidget {
  const _TodayHeader({required this.collapse});

  final ValueListenable<double> collapse;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ValueListenableBuilder<double>(
      valueListenable: collapse,
      builder: (context, p, _) {
        // Só depois de o anel grande ter saído de cena: os dois na tela ao mesmo tempo seriam
        // o mesmo número duas vezes.
        //
        // **E não basta deixá-lo transparente.** Um `Opacity(0)` continua na árvore: o leitor
        // de tela anuncia "624 kcal" duas vezes numa tela que mostra o número uma vez, e o
        // teste que conta o número na tela passa a contar dois. Invisível aqui quer dizer
        // inexistente.
        final compact = ((p - 0.45) / 0.4).clamp(0.0, 1.0);

        return GlassChrome(
          opacity: p,
          edge: GlassEdgeSide.bottom,
          child: SafeArea(
            bottom: false,
            child: SizedBox(
              height: _headerBar,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: Space.gutter),
                child: Row(
                  children: [
                    Expanded(
                      child: Text('Hoje', style: theme.textTheme.titleLarge),
                    ),
                    if (compact > 0) ...[
                      Opacity(opacity: compact, child: const _CompactRing()),
                      const SizedBox(width: Space.xs),
                    ],
                    const AccountAvatar(),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// O anel do herói, em 22 dp, com o número ao lado.
class _CompactRing extends ConsumerWidget {
  const _CompactRing();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final day = ref.watch(diaryDayProvider).valueOrNull;
    final targets = day?.targets;

    if (day == null || targets == null || targets.kcal <= 0) {
      return const SizedBox.shrink();
    }

    final left = math.max(0, (targets.kcal - day.consumed.kcal).round());
    final colors = Blocks.nutrition(theme.brightness);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        CalorieRing(
          progress: day.consumed.kcal / targets.kcal,
          colors: colors,
          diameter: 22,
          stroke: 3,
        ),
        const SizedBox(width: 6),
        Text(
          Fmt.integer(left),
          style: AppTypography.numeric(
            size: 16,
            color: theme.colorScheme.onSurface,
            weight: FontWeight.w700,
          ),
        ),
        const SizedBox(width: 3),
        Text(
          'kcal',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

/// "terça, 4 de agosto", acima do herói.
///
/// Uma tela chamada Hoje que em lugar nenhum dizia que dia era.
class _DateLine extends ConsumerWidget {
  const _DateLine();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(top: Space.xs, bottom: Space.md),
      child: Text(
        _todayLabel(ref.watch(nowProvider)()),
        style: theme.textTheme.titleSmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

/// "terça, 4 de agosto".
String _todayLabel(DateTime date) => Fmt.weekdayDayMonth(date);

// ---------------------------------------------------------------------------------------
// Quem é o herói
// ---------------------------------------------------------------------------------------

/// Os quatro assuntos que podem abrir a tela.
enum HeroKind {
  /// Ainda não há plano nenhum: a tela inteira vira o caminho para montá-lo.
  onboarding,
  workout,
  nutrition,
  closeDay,
}

/// **A regra da manchete: a hora decide a ordem, o estado decide o que é elegível.**
///
/// Função pura e no topo do arquivo porque é a única decisão de produto desta tela, e decisão
/// de produto enterrada dentro de um `build` é decisão que ninguém revisa. Recebe a hora em
/// vez de ler o relógio pelo mesmo motivo — assim as onze da noite são testáveis.
///
/// - **Manhã (5h–12h)**: o treino, se ainda não foi feito. O dia começa por ele, e quem abre o
///   app cedo está decidindo se vai à academia.
/// - **Dia (12h–20h)**: as calorias. É a pergunta que traz a pessoa ao app na fila do
///   restaurante, e a única que ela não consegue responder de cabeça.
/// - **Noite (20h–5h)**: fechar o dia. Às nove da manhã esse convite pede algo que ainda não
///   aconteceu; às dez da noite ele é a próxima coisa a fazer.
///
/// Fora da faixa, cai para o próximo elegível — o que garante que sempre há um herói, e que
/// ele nunca é um bloco vazio.
HeroKind pickHero({
  required int hour,
  required bool workoutPending,
  required bool hasWorkoutPlan,
  required bool hasDiet,
}) {
  // Sem plano **nem** dieta é usuário recém-chegado. Faltando só um dos dois, o que falta vira
  // um ladrilho de configuração no mosaico, e a tela continua servindo para o que já existe.
  if (!hasWorkoutPlan && !hasDiet) {
    return HeroKind.onboarding;
  }

  final evening = hour >= 20 || hour < 5;
  final morning = hour >= 5 && hour < 12;

  if (evening) {
    return HeroKind.closeDay;
  }
  if (morning && workoutPending) {
    return HeroKind.workout;
  }
  if (hasDiet) {
    return HeroKind.nutrition;
  }
  if (workoutPending) {
    return HeroKind.workout;
  }
  return HeroKind.closeDay;
}

// ---------------------------------------------------------------------------------------
// O mosaico
// ---------------------------------------------------------------------------------------

class _Mosaic extends ConsumerWidget {
  const _Mosaic({required this.scrollController});

  /// A rolagem da tela, que o anel precisa conhecer para devolver a ela o arrasto para cima.
  final ScrollController scrollController;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final brightness = theme.brightness;
    final dayAsync = ref.watch(diaryDayProvider);
    final workoutAsync = ref.watch(nextWorkoutProvider);

    // Enquanto o diário não respondeu não dá para escolher o herói, e trocá-lo depois faria a
    // tela inteira saltar de cor. Um bloco cinza do tamanho certo é mais honesto.
    if (dayAsync.isLoading || workoutAsync.isLoading) {
      return const _MosaicSkeleton();
    }

    if (dayAsync.hasError && workoutAsync.hasError) {
      return _MosaicError(
        onRetry: () {
          ref.invalidate(diaryDayProvider);
          ref.invalidate(nextWorkoutProvider);
        },
      );
    }

    final now = ref.watch(nowProvider)();
    final day = dayAsync.valueOrNull;
    final targets = day?.targets;
    final hasDiet = targets != null && targets.kcal > 0;
    final next = workoutAsync.valueOrNull;
    final workoutPending = next != null && next.daysSince(now: now) != 0;

    final hero = pickHero(
      hour: now.hour,
      workoutPending: workoutPending,
      hasWorkoutPlan: next != null,
      hasDiet: hasDiet,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _hero(context, ref, hero, day: day, next: next, hasDiet: hasDiet),
        const SizedBox(height: Space.sm),
        // O treino, quando não é ele o herói. Ver [_WorkoutCard] para por que ele deixou de
        // ser um ladrilho de meia largura.
        if (hero != HeroKind.workout && next != null) ...[
          _WorkoutCard(next: next, colors: Blocks.workout(brightness)),
          const SizedBox(height: Space.sm),
        ],
        TileGrid(
          tiles: _tiles(
            context,
            ref,
            hero: hero,
            brightness: brightness,
            day: day,
            next: next,
            hasDiet: hasDiet,
          ),
        ),
      ],
    );
  }

  Widget _hero(
    BuildContext context,
    WidgetRef ref,
    HeroKind kind, {
    required DiaryDay? day,
    required NextWorkout? next,
    required bool hasDiet,
  }) {
    final brightness = Theme.of(context).brightness;

    return switch (kind) {
      HeroKind.onboarding => _OnboardingHero(day: day),
      HeroKind.workout => _WorkoutHero(
        next: next!,
        colors: Blocks.workout(brightness),
      ),
      // A nutrição virou o anel: mesmo assunto, mesma pergunta, outro corpo — e agora com o
      // dia inteiro guardado atrás dele. Ver [TodayRingHero].
      HeroKind.nutrition => TodayRingHero(
        day: day!,
        colors: Blocks.nutrition(brightness),
        scrollController: scrollController,
      ),
      HeroKind.closeDay => _CloseDayHero(
        day: day,
        next: next,
        hasDiet: hasDiet,
        colors: Blocks.neutral(Theme.of(context).colorScheme),
      ),
    };
  }

  /// O resto do app, um ladrilho por assunto. Só entram os que têm o que dizer, e nunca o que
  /// já é o herói.
  List<Tile> _tiles(
    BuildContext context,
    WidgetRef ref, {
    required HeroKind hero,
    required Brightness brightness,
    required DiaryDay? day,
    required NextWorkout? next,
    required bool hasDiet,
  }) {
    final scheme = Theme.of(context).colorScheme;
    final now = ref.watch(nowProvider)();
    final tiles = <Tile>[];

    if (hero != HeroKind.nutrition && hasDiet) {
      final targets = day!.targets!;
      final left = math.max(0, (targets.kcal - day.consumed.kcal).round());
      tiles.add(
        Tile(
          colors: Blocks.nutrition(brightness),
          label: 'Nutrição',
          icon: Icons.restaurant,
          value: Fmt.integer(left),
          detail: 'kcal restam',
          onTap: () => context.push(Routes.diary),
        ),
      );
    }

    // A proteína, que saiu de dentro do herói. É a pergunta que a escolha do prato à noite
    // ainda corrige, e o único macro que a pessoa erra por falta — os outros dois estão
    // inteiros na aba Nutrição, e repeti-los aqui era ruído.
    if (hasDiet && day!.targets!.proteinG > 0) {
      final targets = day.targets!;
      final left = math.max(
        0,
        (targets.proteinG - day.consumed.proteinG).round(),
      );
      tiles.add(
        Tile(
          colors: Blocks.nutrition(brightness),
          label: 'Proteína',
          icon: Icons.egg,
          // O que falta, e não o que já foi: é o número que muda a escolha do próximo prato.
          // O mesmo raciocínio do herói, que mostra caloria restante e não consumida.
          value: left == 0 ? 'Batida' : Fmt.grams(left),
          detail: left == 0
              ? 'meta do dia alcançada'
              : 'faltam de ${Fmt.grams(targets.proteinG)}',
          onTap: () => context.push(Routes.diary),
        ),
      );
    }

    // A semana: o número contra a meta do perfil, e os sete pontos embaixo. "3 treinos" não
    // diz se a semana está indo bem; "3 de 4" diz.
    final stats = ref.watch(dashboardStatsProvider).valueOrNull;
    final streak = ref.watch(weekStreakProvider).valueOrNull;
    if (stats != null && !stats.isEmpty) {
      final goal = ref
          .watch(userProfileProvider)
          .valueOrNull
          ?.trainingDaysPerWeek;
      tiles.add(
        Tile(
          colors: Blocks.progress(brightness),
          label: 'Semana',
          icon: Icons.local_fire_department,
          value: goal != null && goal > 0
              ? '${stats.sessionsThisWeek}/$goal'
              : '${stats.sessionsThisWeek}',
          detail: stats.sessionsThisWeek == 1 ? 'treino' : 'treinos',
          footer: streak == null
              ? null
              : _WeekDots(days: streak, colors: Blocks.progress(brightness)),
          onTap: () => context.push(Routes.progress),
        ),
      );
    }

    // O peso, ao lado da semana e na mesma cor: os dois medem tempo passando e os dois levam
    // a `/progresso`. A variação vem com o sinal escrito — quem emagrece e quem ganha massa
    // querem sinais opostos, e o app não tem por que julgar qual é o bom.
    final weight = stats?.currentWeightKg;
    if (weight != null) {
      final delta = stats!.weightDeltaKg;
      tiles.add(
        Tile(
          colors: Blocks.progress(brightness),
          label: 'Peso',
          icon: Icons.monitor_weight,
          value: Fmt.kg(weight),
          detail: delta == null || delta.abs() < 0.05
              ? 'sem variação no período'
              : '${Fmt.delta(delta, Fmt.kg)} no período',
          onTap: () => context.push(Routes.progress),
        ),
      );
    }

    // A sequência de semanas. É o número que rende plano Pro por constância, e não aparecia em
    // lugar nenhum fora da tela de conquistas — o mecanismo de recompensa do produto estava
    // invisível para quem não fosse procurá-lo.
    //
    // A partir de duas semanas: "1 semana seguida" é o estado de qualquer pessoa que treinou
    // uma vez, e anunciá-lo como conquista esvazia o que a palavra significa.
    final streakWeeks = ref
        .watch(rewardStatusProvider)
        .valueOrNull
        ?.streakWeeks;
    if (streakWeeks != null && streakWeeks >= 2) {
      tiles.add(
        Tile(
          colors: Blocks.award(brightness),
          label: 'Sequência',
          icon: Icons.whatshot,
          value: '$streakWeeks',
          detail: 'semanas seguidas',
          onTap: () => context.push(Routes.progress),
        ),
      );
    }

    // **Só quando há novidade.** Um ladrilho permanente de "veja suas conquistas" vira mais um
    // ícone a ignorar, e a próxima conquista de verdade chegaria no mesmo lugar sem chamar
    // atenção nenhuma.
    final unseen = ref.watch(unseenAchievementsProvider);
    if (unseen > 0) {
      tiles.add(
        Tile(
          colors: Blocks.award(brightness),
          label: 'Conquista',
          icon: Icons.emoji_events,
          value: '$unseen',
          detail: unseen == 1 ? 'nova' : 'novas',
          onTap: () => context.push(Routes.progress),
        ),
      );
    }

    // O passo que falta, quando falta só um. Faltando os dois, quem cuida é o herói.
    if (hero != HeroKind.onboarding) {
      if (!hasDiet) {
        tiles.add(
          Tile(
            colors: Blocks.neutral(scheme),
            label: 'Falta',
            icon: Icons.tune,
            value: 'Dieta',
            detail: 'Gere para ter meta',
            onTap: () => context.push(Routes.dietPlan),
          ),
        );
      }
      if (next == null) {
        tiles.add(
          Tile(
            colors: Blocks.neutral(scheme),
            label: 'Falta',
            icon: Icons.tune,
            value: 'Treino',
            detail: 'Gere seu plano',
            onTap: () => context.push(Routes.workoutPlan),
          ),
        );
      }
    }

    // Fila de revisão. Só existe para quem revisa, e só quando há o que revisar.
    final pending =
        ref.watch(pendingReviewsProvider).valueOrNull ?? PendingReviews.empty;
    if (pending.total > 0) {
      // `now` e não o relógio do sistema: `daysWaiting` recebe a data justamente para esta
      // espera ser testável, e sem passá-la o teste desta linha muda de resposta conforme o
      // dia em que o CI roda.
      final waiting = pending.daysWaiting(now: now);
      tiles.add(
        Tile(
          colors: Blocks.neutral(scheme),
          label: 'Revisor',
          icon: Icons.fact_check,
          value: '${pending.total}',
          // Quatro planos de hoje e quatro de duas semanas atrás são a mesma contagem e
          // urgências bem diferentes.
          detail: switch (waiting) {
            null => pending.total == 1 ? 'plano na fila' : 'planos na fila',
            0 => 'na fila, desde hoje',
            1 => 'na fila, desde ontem',
            _ => 'na fila, há $waiting dias',
          },
          onTap: () => context.push(Routes.review),
        ),
      );
    }

    // Fechar o dia vira ladrilho quando não é o herói — de dia ele não aparece de jeito
    // nenhum, porque pediria algo que ainda não aconteceu.
    if (hero != HeroKind.closeDay && now.hour >= 20) {
      tiles.add(
        Tile(
          colors: Blocks.neutral(scheme),
          label: 'Fechar o dia',
          icon: Icons.bedtime,
          value: '3',
          detail: 'perguntas rápidas',
          onTap: () => context.push(Routes.dayClose),
        ),
      );
    }

    return tiles;
  }
}

// ---------------------------------------------------------------------------------------
// Os heróis
// ---------------------------------------------------------------------------------------

/// O treino do dia, quando não é ele o herói.
///
/// **Era um ladrilho de meia largura, e a conta não fechava.** Num quadrado de 146 dp cabia
/// "55 min" e o nome do dia cortado ao meio; para saber o que ia treinar, a pessoa tinha de
/// abrir outra tela — e para *começar*, mais uma. É o segundo assunto do app inteiro reduzido
/// a um selo.
///
/// Em largura cheia ele diz o que a pergunta pede: qual treino, quanto dura, quando foi a
/// última vez, os primeiros exercícios — e traz o botão de começar junto. O que ele **não**
/// vira é um segundo herói: o fundo é o mesmo vidro dos outros cartões, e a única coisa em cor
/// cheia é o botão.
class _WorkoutCard extends StatelessWidget {
  const _WorkoutCard({required this.next, required this.colors});

  final NextWorkout next;
  final BlockColors colors;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final days = next.daysSince();
    final done = days == 0;
    final exercises = next.day.exercises;

    return GlassPanel(
      radius: Radii.xlAll,
      tint: colors.ink.withValues(alpha: 0.06),
      padding: const EdgeInsets.all(Space.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.fitness_center, size: 17, color: colors.ink),
              const SizedBox(width: 6),
              Text(
                'TREINO DE HOJE',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: colors.ink,
                  letterSpacing: 0.6,
                ),
              ),
            ],
          ),
          const SizedBox(height: Space.sm),
          Text(next.day.label, style: theme.textTheme.headlineSmall),
          const SizedBox(height: Space.xxs),
          Text(
            [
              next.exerciseCount == 1
                  ? '1 exercício'
                  : '${next.exerciseCount} exercícios',
              '${next.estimatedMinutes} min',
              // A recência só entra quando existe: "último há 0 dias" em quem nunca treinou
              // este dia seria mentira, e a ausência da frase já diz que é a primeira vez.
              if (days != null)
                switch (days) {
                  0 => 'feito hoje',
                  1 => 'feito ontem',
                  _ => 'feito há $days dias',
                },
            ].join(' · '),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: Space.md),
          Row(
            children: [
              Expanded(
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: colors.ink,
                    foregroundColor: colors.wash,
                    minimumSize: const Size.fromHeight(50),
                  ),
                  // Leva à escolha do dia em `/treinar`, e não direto ao treino sugerido. A
                  // diferença é de um toque, e existe porque a sugestão pode estar errada —
                  // quem trocou a ordem da semana acharia o app teimoso se ele começasse
                  // sozinho o treino errado, com as mãos já na barra.
                  onPressed: () => context.push(Routes.workoutMode),
                  child: Text(done ? 'Treinar de novo' : 'Começar'),
                ),
              ),
              const SizedBox(width: Space.sm),
              SizedBox.square(
                dimension: 50,
                child: IconButton(
                  onPressed: () => context.push(Routes.workoutPlan),
                  tooltip: 'Ver o plano inteiro',
                  icon: Icon(Icons.list_alt, color: colors.ink),
                  style: IconButton.styleFrom(
                    backgroundColor: colors.ink.withValues(alpha: 0.12),
                    shape: const RoundedRectangleBorder(
                      borderRadius: Radii.smAll,
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (exercises.isNotEmpty) ...[
            const SizedBox(height: Space.md),
            // Três, e o resto contado. A lista inteira é a tela do plano; aqui ela serve para
            // reconhecer o treino, não para conferi-lo.
            for (final exercise in exercises.take(3))
              Padding(
                padding: const EdgeInsets.only(bottom: 7),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        exercise.exerciseName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                    const SizedBox(width: Space.sm),
                    Text(
                      '${exercise.sets} × '
                      '${exercise.repsMin}–${exercise.repsMax}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            if (exercises.length > 3)
              Text(
                'e mais ${exercises.length - 3} '
                '${exercises.length - 3 == 1 ? 'exercício' : 'exercícios'}',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
          ],
        ],
      ),
    );
  }
}

/// Qual treino é hoje, e quanto ele deve durar.
///
/// O botão leva à escolha do dia em `/treinar`, e não direto ao treino sugerido. A diferença é
/// de um toque, e existe porque a sugestão pode estar errada — quem trocou a ordem da semana
/// acharia o app teimoso se ele começasse sozinho o treino errado, com as mãos já na barra.
class _WorkoutHero extends StatelessWidget {
  const _WorkoutHero({required this.next, required this.colors});

  final NextWorkout next;
  final BlockColors colors;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final days = next.daysSince();

    return HeroBlock(
      colors: colors,
      label: 'Treino de hoje',
      icon: Icons.fitness_center,
      action: HeroAction(
        label: 'Começar treino',
        onPressed: () => context.push(Routes.workoutMode),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            next.day.label,
            style: theme.textTheme.headlineSmall?.copyWith(
              color: colors.onGlass,
            ),
          ),
          const SizedBox(height: Space.md),
          HeroFigure(
            value: '${next.estimatedMinutes}',
            unit: 'min',
            colors: colors,
            detail: [
              next.exerciseCount == 1
                  ? '1 exercício'
                  : '${next.exerciseCount} exercícios',
              // A recência só entra quando existe: "último há 0 dias" em quem nunca treinou
              // este dia seria mentira, e a ausência da frase já diz que é a primeira vez.
              if (days != null)
                switch (days) {
                  1 => 'feito ontem',
                  _ => 'último há $days dias',
                },
            ].join(' · '),
          ),
        ],
      ),
    );
  }
}

/// O fechamento da noite, com o que o dia rendeu.
class _CloseDayHero extends StatelessWidget {
  const _CloseDayHero({
    required this.day,
    required this.next,
    required this.hasDiet,
    required this.colors,
  });

  final DiaryDay? day;
  final NextWorkout? next;
  final bool hasDiet;
  final BlockColors colors;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final trained = next?.daysSince() == 0;

    return HeroBlock(
      colors: colors,
      label: 'Fechar o dia',
      icon: Icons.bedtime,
      action: HeroAction(
        label: 'Responder',
        onPressed: () => context.push(Routes.dayClose),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Como foi hoje?',
            style: theme.textTheme.headlineMedium?.copyWith(
              color: colors.onGlass,
            ),
          ),
          const SizedBox(height: Space.xs),
          Text(
            // O resumo do dia em uma linha, para a pessoa responder com o dia na cabeça em
            // vez de tentar lembrar.
            [
              if (hasDiet && day != null) Fmt.kcal(day!.consumed.kcal),
              if (trained) 'treino feito' else 'sem treino',
            ].join(' · '),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colors.onGlass.withValues(alpha: 0.8),
            ),
          ),
          const SizedBox(height: Space.sm),
          Text(
            'Três perguntas: esforço, peso e energia.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colors.onGlass.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }
}

/// **A tela de quem acabou de chegar.**
///
/// Sem plano nem dieta, todo ladrilho se esconderia e sobraria uma tela em branco: quem chega
/// ao produto encontrava o pior estado dele. Aqui a tela inteira vira o caminho.
///
/// A numeração é literal, não decorativa — tanto o treino quanto a dieta são gerados a partir
/// do perfil, então a ordem carrega informação.
class _OnboardingHero extends ConsumerWidget {
  const _OnboardingHero({required this.day});

  final DiaryDay? day;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final brightness = theme.brightness;
    final colors = Blocks.nutrition(brightness);
    final profile = ref.watch(userProfileProvider);

    // Chamada que ainda não voltou, ou que falhou, é "não sei" — e "não sei" não vira um passo
    // aberto. Sem rede o app anunciaria a quem treina nele há meses que o perfil não existe.
    final profileDone = !profile.hasError && profile.valueOrNull != null;

    final steps = [
      ('Complete seu perfil', profileDone, Routes.profile),
      ('Gere seu treino', false, Routes.workoutPlan),
      ('Gere sua dieta', false, Routes.dietPlan),
    ];

    return HeroBlock(
      colors: colors,
      label: 'Bem-vindo',
      icon: Icons.auto_awesome,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Vamos montar\nseu plano.',
            style: theme.textTheme.displaySmall?.copyWith(
              color: colors.onGlass,
            ),
          ),
          const SizedBox(height: Space.sm),
          Text(
            'Três passos, e o app passa a saber quanto você precisa comer e '
            'treinar por dia.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colors.onGlass.withValues(alpha: 0.85),
            ),
          ),
          const SizedBox(height: Space.lg),
          for (var i = 0; i < steps.length; i++)
            _Step(
              number: i + 1,
              label: steps[i].$1,
              done: steps[i].$2,
              colors: colors,
              // Passo cumprido vira registro, não destino: um alvo de toque que não leva a
              // lugar novo ensina a desconfiar dos outros.
              onTap: steps[i].$2 ? null : () => context.push(steps[i].$3),
            ),
        ],
      ),
    );
  }
}

class _Step extends StatelessWidget {
  const _Step({
    required this.number,
    required this.label,
    required this.done,
    required this.colors,
    required this.onTap,
  });

  final int number;
  final String label;
  final bool done;
  final BlockColors colors;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: Radii.smAll,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: Space.sm),
        child: Row(
          children: [
            Container(
              width: 26,
              height: 26,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: colors.ink.withValues(alpha: done ? 1 : 0.18),
              ),
              // O visto não é só cor: quem não distingue as duas precisa do símbolo.
              child: done
                  ? Icon(Icons.check, size: 15, color: colors.wash)
                  : Text(
                      '$number',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: colors.ink,
                      ),
                    ),
            ),
            const SizedBox(width: Space.sm),
            Expanded(
              child: Text(
                label,
                style: theme.textTheme.titleSmall?.copyWith(
                  color: colors.onGlass,
                  decoration: done ? TextDecoration.lineThrough : null,
                  decorationColor: colors.onGlass.withValues(alpha: 0.6),
                ),
              ),
            ),
            if (!done)
              Icon(
                Icons.chevron_right,
                size: 20,
                color: colors.onGlass.withValues(alpha: 0.7),
              ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------------------
// Peças de desenho
// ---------------------------------------------------------------------------------------

/// Sete pontos no pé do ladrilho da semana, do dia mais antigo até hoje.
class _WeekDots extends StatelessWidget {
  const _WeekDots({required this.days, required this.colors});

  final List<bool> days;
  final BlockColors colors;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '${days.where((d) => d).length} dos últimos sete dias com treino',
      child: Row(
        children: [
          for (var i = 0; i < days.length; i++) ...[
            if (i > 0) const SizedBox(width: 5),
            // Cheio contra vazado, e não duas opacidades da mesma cor: a 25% o ponto ainda
            // lia como "meio treinado" num tamanho deste. O anel vazio não tem essa ambiguidade
            // — e continua legível para quem não distingue as duas cores.
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: days[i] ? colors.ink : Colors.transparent,
                border: days[i]
                    ? null
                    : Border.all(
                        color: colors.ink.withValues(alpha: 0.4),
                        width: 1.5,
                      ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// A tela enquanto as chamadas não voltam.
///
/// Blocos do tamanho exato dos de verdade. Sem isto a tela nasce vazia e empurra tudo para
/// baixo quando a resposta chega — e o salto é mais visível que a espera.
///
/// **E é o mesmo vidro dos blocos de verdade**, não um cinza qualquer: a espera passa a ser o
/// cartão ainda sem conteúdo, e a chegada do dado não troca a superfície debaixo dele.
class _MosaicSkeleton extends StatelessWidget {
  const _MosaicSkeleton();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GlassPanel(child: SizedBox(height: 236)),
        SizedBox(height: Space.sm),
        Row(
          children: [
            Expanded(
              child: GlassPanel(child: SizedBox(height: Tile.height)),
            ),
            SizedBox(width: Space.sm),
            Expanded(
              child: GlassPanel(child: SizedBox(height: Tile.height)),
            ),
          ],
        ),
      ],
    );
  }
}

/// As duas chamadas que sustentam a tela falharam. Uma só falhando não chega aqui — o herói
/// cai para o assunto que ainda respondeu.
class _MosaicError extends StatelessWidget {
  const _MosaicError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      height: 236,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHigh,
        borderRadius: Radii.xlAll,
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
            'Não foi possível carregar seu dia.',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: Space.xs),
          TextButton(onPressed: onRetry, child: const Text('Tentar de novo')),
        ],
      ),
    );
  }
}
