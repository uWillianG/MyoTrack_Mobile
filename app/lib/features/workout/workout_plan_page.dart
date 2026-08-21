import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/design/blocks.dart';
import '../../core/design/format.dart';
import '../../core/design/tokens.dart';
import '../../core/jobs/generation_controller.dart';
import '../../core/router.dart';
import '../../core/widgets/blocks.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/review_badge.dart';
import '../progress/progress_controller.dart';
import 'data/workout_models.dart';
import 'workout_plan_controller.dart';

/// Plano de treino ativo.
///
/// **Pergunta: o que eu faço em cada dia? Ação: treinar agora.**
///
/// É a tela de consulta do treino — a de execução é `/treinar`. As duas continuam separadas
/// de propósito: aqui a pessoa está sentada escolhendo o dia, e lá ela está de pé com a mão
/// na barra.
///
/// **A carga sugerida fica junto do exercício**, e não numa tela de "progressão": o número só é
/// útil no momento em que se olha o que vai fazer.
class WorkoutPlanPage extends ConsumerWidget {
  const WorkoutPlanPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final planAsync = ref.watch(activeWorkoutPlanProvider);

    // O erro vira snackbar em vez de ocupar espaço fixo: a mensagem é passageira e a tela
    // continua útil (o plano anterior segue lá).
    ref.listen(workoutGenerationProvider, (previous, next) {
      if (next.error != null && next.error != previous?.error) {
        ScaffoldMessenger.of(context)
          ..clearSnackBars()
          ..showSnackBar(SnackBar(content: Text(next.error!)));
        ref.read(workoutGenerationProvider.notifier).dismissError();
      }
    });

    return Scaffold(
      appBar: AppBar(title: Text(planAsync.valueOrNull?.name ?? 'Seu treino')),
      body: const WorkoutPlanView(),
    );
  }
}

/// O plano sem a barra de título.
class WorkoutPlanView extends ConsumerWidget {
  const WorkoutPlanView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final planAsync = ref.watch(activeWorkoutPlanProvider);
    final generation = ref.watch(workoutGenerationProvider);

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(activeWorkoutPlanProvider);
        await ref.read(activeWorkoutPlanProvider.future);
      },
      child: planAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => EmptyState(
          icon: Icons.cloud_off_outlined,
          title: 'Não foi possível carregar seu treino.',
          detail: '$error',
          action: FilledButton.tonal(
            onPressed: () => ref.invalidate(activeWorkoutPlanProvider),
            child: const Text('Tentar de novo'),
          ),
        ),
        data: (plan) => _Body(plan: plan, generation: generation),
      ),
    );
  }
}

class _Body extends ConsumerWidget {
  const _Body({required this.plan, required this.generation});

  final WorkoutPlan? plan;
  final GenerationState generation;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colors = Blocks.workout(theme.brightness);

    final regenerate = generation.running
        ? null
        : () => ref.read(workoutGenerationProvider.notifier).start();
    final regenerateLabel = generation.running
        ? (generation.step ?? 'Gerando…')
        : plan == null
        ? 'Gerar treino'
        : 'Regenerar treino';

    return ListView(
      padding: EdgeInsets.fromLTRB(
        Space.gutter,
        4,
        Space.gutter,
        screenBottomInset(context),
      ),
      children: [
        if (plan == null)
          _NoPlanHero(
            generation: generation,
            colors: colors,
            action: HeroAction(label: regenerateLabel, onPressed: regenerate),
          )
        else ...[
          _PlanHero(plan: plan!, colors: colors),
          for (final day in plan!.days) ...[
            const SizedBox(height: Space.sm),
            _DaySection(day: day, colors: colors),
          ],
          const SizedBox(height: Space.lg),
          // Regenerar fica no fim, e não na ação do herói: a ação frequente desta tela é
          // treinar, e refazer o plano é o que se faz uma vez por bloco. Trocar as duas de
          // lugar poria a operação destrutiva no alvo mais fácil de acertar.
          OutlinedButton.icon(
            onPressed: regenerate,
            icon: generation.running
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.auto_awesome),
            label: Text(regenerateLabel),
          ),
        ],
      ],
    );
  }
}

/// O plano em uma linha: quantos dias, qual divisão, e o caminho para começar.
class _PlanHero extends StatelessWidget {
  const _PlanHero({required this.plan, required this.colors});

  final WorkoutPlan plan;
  final BlockColors colors;

  @override
  Widget build(BuildContext context) {
    final exercises = plan.days.fold<int>(
      0,
      (total, day) => total + day.exercises.length,
    );

    return HeroBlock(
      colors: colors,
      label: 'Seu treino',
      icon: Icons.fitness_center,
      // Quem está olhando o plano é candidato a começar o treino agora — e a escolha do dia
      // acontece lá, porque a semana de quem treina não segue o calendário.
      action: HeroAction(
        label: 'Treinar agora',
        onPressed: () => context.push(Routes.workoutMode),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          HeroFigure(
            value: '${plan.days.length}',
            unit: plan.days.length == 1 ? 'dia' : 'dias',
            colors: colors,
            detail: [
              plan.split,
              exercises == 1 ? '1 exercício' : '$exercises exercícios',
              'v${plan.version}',
            ].join(' · '),
          ),
          // O selo da revisão fica no herói: ele diz se este plano já passou por um humano, e
          // é a primeira coisa que muda a confiança de quem vai seguir.
          const SizedBox(height: Space.sm),
          Align(
            alignment: Alignment.centerLeft,
            child: ReviewBadge(
              reviewStatus: plan.reviewStatus,
              reviewNote: plan.reviewNote,
              onGlass: colors.onGlass,
            ),
          ),
        ],
      ),
    );
  }
}

/// Sem plano, o herói é o convite.
class _NoPlanHero extends StatelessWidget {
  const _NoPlanHero({
    required this.generation,
    required this.colors,
    required this.action,
  });

  final GenerationState generation;
  final BlockColors colors;
  final HeroAction action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        HeroBlock(
          colors: colors,
          label: 'Seu treino',
          icon: Icons.fitness_center,
          action: action,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Você ainda não\ntem um treino.',
                style: theme.textTheme.displaySmall?.copyWith(
                  color: colors.onGlass,
                ),
              ),
              const SizedBox(height: Space.sm),
              Text(
                generation.running
                    ? 'Isso pode levar até um minuto.'
                    : 'Ele é montado a partir do seu perfil: experiência, objetivo, '
                          'dias por semana e o que você tem à mão.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colors.onGlass.withValues(alpha: 0.85),
                ),
              ),
            ],
          ),
        ),
        if (!generation.running) ...[
          const SizedBox(height: Space.sm),
          TextButton(
            onPressed: () => context.push(Routes.profile),
            child: const Text('Ir para o perfil'),
          ),
        ],
      ],
    );
  }
}

/// Um dia do plano e os exercícios dele.
class _DaySection extends StatelessWidget {
  const _DaySection({required this.day, required this.colors});

  final WorkoutDay day;
  final BlockColors colors;

  @override
  Widget build(BuildContext context) {
    return BlockSection(
      colors: colors,
      label: day.label,
      icon: Icons.today_outlined,
      trailing: day.exercises.length == 1
          ? '1 exercício'
          : '${day.exercises.length} exercícios',
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          for (var i = 0; i < day.exercises.length; i++) ...[
            if (i > 0)
              Divider(
                height: 1,
                indent: Space.md,
                endIndent: Space.md,
                color: colors.ink.withValues(alpha: 0.14),
              ),
            _ExerciseRow(exercise: day.exercises[i], colors: colors),
          ],
        ],
      ),
    );
  }
}

class _ExerciseRow extends ConsumerWidget {
  const _ExerciseRow({required this.exercise, required this.colors});

  final WorkoutExercise exercise;
  final BlockColors colors;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    // A sugestão de progressão é complemento: se não vier, o exercício continua legível.
    final suggestion = exercise.exerciseId == null
        ? null
        : ref
              .watch(suggestionsByExerciseProvider)
              .valueOrNull?[exercise.exerciseId!];

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        Space.md,
        Space.sm,
        Space.xs,
        Space.sm,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(exercise.exerciseName, style: theme.textTheme.titleSmall),
                const SizedBox(height: 1),
                Text(
                  '${exercise.sets} × ${exercise.repsMin}–${exercise.repsMax}'
                  '  ·  ${exercise.restSeconds}s de descanso',
                  style: theme.textTheme.bodySmall,
                ),
                if (exercise.notes case final notes? when notes.isNotEmpty) ...[
                  const SizedBox(height: 1),
                  Text(notes, style: theme.textTheme.bodySmall),
                ],
                if (suggestion != null) ...[
                  const SizedBox(height: Space.xs),
                  _NextLoad(suggestion: suggestion, colors: colors),
                ],
              ],
            ),
          ),
          IconButton(
            onPressed: () => _openTutorial(context, exercise),
            icon: const Icon(Icons.play_circle_outline),
            tooltip: exercise.tutorialVideoUrl == null
                ? 'Buscar vídeo no TikTok'
                : 'Ver como fazer',
          ),
        ],
      ),
    );
  }

  /// Abre o vídeo do exercício. Sem URL resolvida pelo backend, cai na busca do TikTok —
  /// mesmo comportamento da SPA, para o usuário nunca ficar sem referência de execução.
  Future<void> _openTutorial(
    BuildContext context,
    WorkoutExercise exercise,
  ) async {
    final url = exercise.tutorialVideoUrl != null
        ? Uri.parse(exercise.tutorialVideoUrl!)
        : Uri.https('www.tiktok.com', '/search', {
            'q': 'como fazer ${exercise.exerciseName} academia',
          });

    // externalApplication: abre o app do TikTok se estiver instalado, e o navegador se não.
    final opened = await launchUrl(url, mode: LaunchMode.externalApplication);
    if (!opened && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível abrir o vídeo.')),
      );
    }
  }
}

/// A carga da próxima sessão, calculada a partir do que foi registrado.
class _NextLoad extends StatelessWidget {
  const _NextLoad({required this.suggestion, required this.colors});

  final ProgressSuggestion suggestion;
  final BlockColors colors;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final load = suggestion.nextLoadKg;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.trending_up, size: 14, color: colors.ink),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            load == null
                ? suggestion.label
                : '${Fmt.kg(load)} × ${suggestion.targetReps}'
                      '  ·  ${suggestion.label}',
            style: theme.textTheme.bodySmall?.copyWith(color: colors.ink),
          ),
        ),
      ],
    );
  }
}
