import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/jobs/generation_controller.dart';
import '../../core/router.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/review_badge.dart';
import 'data/workout_models.dart';
import 'workout_plan_controller.dart';

/// Plano de treino ativo. Porte de `frontend/src/pages/WorkoutPlanPage.tsx`.
///
/// A tabela da SPA vira cartão por dia com uma linha por exercício: em 360 dp de largura,
/// cinco colunas lado a lado ficariam ilegíveis ou exigiriam rolagem horizontal.
class WorkoutPlanPage extends ConsumerWidget {
  const WorkoutPlanPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final planAsync = ref.watch(activeWorkoutPlanProvider);
    final generation = ref.watch(workoutGenerationProvider);

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
      appBar: AppBar(
        title: Text(planAsync.valueOrNull?.name ?? 'Seu treino'),
        actions: [
          // Quem está olhando o plano é candidato a começar o treino agora.
          if (planAsync.valueOrNull != null)
            IconButton(
              onPressed: () => context.push(Routes.workoutMode),
              icon: const Icon(Icons.play_circle_outline),
              tooltip: 'Treinar este plano',
            ),
        ],
      ),
      body: RefreshIndicator(
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
          data: (plan) => _PlanBody(plan: plan, generation: generation),
        ),
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        child: FilledButton.icon(
          onPressed: generation.running
              ? null
              : () => ref.read(workoutGenerationProvider.notifier).start(),
          icon: generation.running
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.auto_awesome),
          label: Text(
            generation.running
                ? (generation.step ?? 'Gerando…')
                : planAsync.valueOrNull == null
                ? 'Gerar treino'
                : 'Regenerar treino',
          ),
        ),
      ),
    );
  }
}

class _PlanBody extends StatelessWidget {
  const _PlanBody({required this.plan, required this.generation});

  final WorkoutPlan? plan;
  final GenerationState generation;

  @override
  Widget build(BuildContext context) {
    if (plan == null) {
      return EmptyState(
        icon: Icons.fitness_center_outlined,
        title: 'Você ainda não tem um treino ativo.',
        detail: generation.running
            ? 'Isso pode levar até um minuto.'
            : 'Complete o perfil e toque em "Gerar treino".',
        action: generation.running
            ? null
            : TextButton(
                onPressed: () => context.push(Routes.profile),
                child: const Text('Ir para o perfil'),
              ),
      );
    }

    final workout = plan!;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      children: [
        Row(
          children: [
            Expanded(
              child: ReviewBadge(
                reviewStatus: workout.reviewStatus,
                reviewNote: workout.reviewNote,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'v${workout.version} · ${workout.split}',
              style: Theme.of(context).textTheme.labelMedium,
            ),
          ],
        ),
        const SizedBox(height: 12),
        for (final day in workout.days) _DayCard(day: day),
      ],
    );
  }
}

class _DayCard extends StatelessWidget {
  const _DayCard({required this.day});

  final WorkoutDay day;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            width: double.infinity,
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Text(
              day.label,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          for (final exercise in day.exercises)
            _ExerciseTile(
              exercise: exercise,
              isLast: exercise == day.exercises.last,
            ),
        ],
      ),
    );
  }
}

class _ExerciseTile extends StatelessWidget {
  const _ExerciseTile({required this.exercise, required this.isLast});

  final WorkoutExercise exercise;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: isLast
          ? null
          : BoxDecoration(
              border: Border(
                bottom: BorderSide(color: theme.colorScheme.outlineVariant),
              ),
            ),
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(exercise.exerciseName, style: theme.textTheme.bodyLarge),
                const SizedBox(height: 2),
                Text(
                  '${exercise.sets} × ${exercise.repsMin}–${exercise.repsMax}'
                  '  ·  ${exercise.restSeconds}s de descanso',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                if (exercise.notes != null && exercise.notes!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    exercise.notes!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
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
