import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/design/blocks.dart';
import '../../core/design/format.dart';
import '../../core/design/tokens.dart';
import '../../core/router.dart';
import '../../core/widgets/blocks.dart';
import '../achievements/achievements_controller.dart';
import '../achievements/data/rewards_repository.dart';
import '../dashboard/dashboard_controller.dart';
import '../diary/data/diary_models.dart';
import '../diary/diary_controller.dart';
import '../profile/onboarding_controller.dart';
import 'account_avatar.dart';
import 'today_controller.dart';

/// Hoje: um mosaico, e o assunto do momento no topo.
///
/// **A tela tem uma forma só, e ela se reorganiza conforme a hora.** No alto, um bloco em cor
/// cheia — o herói — que responde a única pergunta que importa naquele momento do dia: de
/// manhã, qual treino é hoje; à tarde, quanto ainda cabe de comida; à noite, fechar o dia.
/// Abaixo dele, o resto do app em ladrilhos lavados, um por assunto, cada um com a cor da sua
/// família.
///
/// **Por que assim, depois de duas tentativas erradas.** A primeira empilhou seis cartões
/// brancos idênticos e o usuário não sabia por onde começar. A segunda cortou até sobrar um
/// anel e um botão, e ficou vazia sem ficar bonita — o que provou que o problema nunca foi
/// quantidade. Era que tudo tinha o mesmo peso e a mesma cor, e o app parecia o que era: um
/// projeto Flutter novo com um verde. O mosaico resolve os dois de uma vez: a cor separa os
/// assuntos sem precisar de rótulo, e a promoção de um deles a herói resolve "o que faço
/// primeiro" sem esconder o resto.
///
/// **O assunto promovido sai do mosaico.** Ele não aparece duas vezes.
class TodayView extends ConsumerWidget {
  const TodayView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(diaryDayProvider);
        ref.invalidate(dashboardStatsProvider);
        ref.invalidate(nextWorkoutProvider);
        ref.invalidate(pendingReviewsProvider);
        await ref.read(diaryDayProvider.future);
      },
      child: ListView(
        // O respiro de baixo passa do botão flutuante: sem ele o último ladrilho para debaixo
        // do "Registrar" e a rolagem acaba antes de tirá-lo de lá.
        padding: const EdgeInsets.fromLTRB(Space.gutter, 0, Space.gutter, 148),
        children: const [_TopRow(), _Mosaic()],
      ),
    );
  }
}

/// A data e o avatar, no lugar da barra de título.
///
/// A barra do Material gastava esta tira escrevendo "MyoTrack" — a única coisa que quem abriu
/// o app já sabe. Uma tela chamada Hoje que em lugar nenhum dizia que dia era.
class _TopRow extends ConsumerWidget {
  const _TopRow();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.only(top: Space.xs, bottom: Space.md),
        child: Row(
          children: [
            Expanded(
              child: Text(
                _todayLabel(ref.watch(nowProvider)()),
                style: theme.textTheme.titleSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            const AccountAvatar(),
          ],
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
  const _Mosaic();

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
      HeroKind.nutrition => _NutritionHero(
        day: day!,
        colors: Blocks.nutrition(brightness),
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

    if (hero != HeroKind.workout && next != null) {
      final done = next.daysSince() == 0;
      tiles.add(
        Tile(
          colors: Blocks.workout(brightness),
          label: 'Treino',
          icon: Icons.fitness_center,
          value: done ? 'Feito' : '${next.estimatedMinutes} min',
          detail: next.day.label,
          onTap: () => context.push(Routes.workoutMode),
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
      final waiting = pending.daysWaiting();
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

/// Quanto ainda cabe hoje, e a barra de refeições.
class _NutritionHero extends StatelessWidget {
  const _NutritionHero({required this.day, required this.colors});

  final DiaryDay day;
  final BlockColors colors;

  @override
  Widget build(BuildContext context) {
    final targets = day.targets!;
    final consumed = day.consumed;
    final left = math.max(0, (targets.kcal - consumed.kcal).round());

    return HeroBlock(
      colors: colors,
      label: 'Nutrição',
      icon: Icons.restaurant,
      // "Fotografar" e não "Registrar": o botão flutuante da tela já diz Registrar, e dois
      // botões com o mesmo verbo fazem o usuário procurar a diferença entre eles. Este leva
      // direto à câmera, que é o caminho mais curto e o melhor recurso do app.
      action: HeroAction(
        label: 'Fotografar refeição',
        onPressed: () => context.push(Routes.mealAnalysis),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // O número é o que **resta**, e não o que foi comido: às três da tarde a pergunta é
          // quanto ainda dá para comer, e transformar 1.476 em 624 é uma conta que ninguém
          // deveria fazer de cabeça na fila do restaurante.
          //
          // A linha da proteína saiu daqui e virou ladrilho: ela é outra pergunta ("estou
          // batendo a proteína?"), e como frase dentro do herói ela empurrava o bloco para
          // metade da tela sem ganhar o destaque que um número teria.
          HeroFigure(
            value: Fmt.integer(left),
            unit: 'kcal restam',
            colors: colors,
            detail:
                '${Fmt.integer(consumed.kcal)} de ${Fmt.kcal(targets.kcal)}',
          ),
          const SizedBox(height: Space.md),
          MealBar(
            slices: MealBar.slicesOf(
              mealKcal: [
                for (final entry in day.entries)
                  if (!entry.excludedFromDiary) entry.totalKcal,
              ],
              consumed: consumed.kcal,
              target: targets.kcal,
            ),
            colors: colors,
          ),
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
              color: colors.onTone,
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
              color: colors.onTone,
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
              color: colors.onTone.withValues(alpha: 0.8),
            ),
          ),
          const SizedBox(height: Space.sm),
          Text(
            'Três perguntas: esforço, peso e energia.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colors.onTone.withValues(alpha: 0.8),
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
            style: theme.textTheme.displaySmall?.copyWith(color: colors.onTone),
          ),
          const SizedBox(height: Space.sm),
          Text(
            'Três passos, e o app passa a saber quanto você precisa comer e '
            'treinar por dia.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colors.onTone.withValues(alpha: 0.85),
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
                color: colors.onTone.withValues(alpha: done ? 1 : 0.18),
              ),
              // O visto não é só cor: quem não distingue as duas precisa do símbolo.
              child: done
                  ? Icon(Icons.check, size: 15, color: colors.tone)
                  : Text(
                      '$number',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: colors.onTone,
                      ),
                    ),
            ),
            const SizedBox(width: Space.sm),
            Expanded(
              child: Text(
                label,
                style: theme.textTheme.titleSmall?.copyWith(
                  color: colors.onTone,
                  decoration: done ? TextDecoration.lineThrough : null,
                  decorationColor: colors.onTone.withValues(alpha: 0.6),
                ),
              ),
            ),
            if (!done)
              Icon(
                Icons.chevron_right,
                size: 20,
                color: colors.onTone.withValues(alpha: 0.7),
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

/// O mosaico enquanto as chamadas não voltam.
///
/// Blocos cinzas do tamanho exato dos de verdade. Sem isto a tela nasce vazia e empurra tudo
/// para baixo quando a resposta chega — e o salto é mais visível que a espera.
class _MosaicSkeleton extends StatelessWidget {
  const _MosaicSkeleton();

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.surfaceContainerHigh;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          height: 236,
          decoration: BoxDecoration(color: color, borderRadius: Radii.xlAll),
        ),
        const SizedBox(height: Space.sm),
        Row(
          children: [
            for (var i = 0; i < 2; i++) ...[
              if (i > 0) const SizedBox(width: Space.sm),
              Expanded(
                child: Container(
                  height: Tile.height,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: Radii.lgAll,
                  ),
                ),
              ),
            ],
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
