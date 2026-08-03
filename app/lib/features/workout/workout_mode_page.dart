import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/design/tokens.dart';
import '../../core/notifications/rest_alarm.dart';
import '../../core/router.dart';
import '../../core/widgets/empty_state.dart';
import '../logging/log_session_controller.dart';
import 'data/workout_models.dart';
import 'rest_timer.dart';
import 'workout_mode_controller.dart';
import 'workout_plan_controller.dart';

/// Modo treino: conduz o dia escolhido série a série, com o descanso entre elas.
///
/// Separado da tela de plano (`/treino`, que é consulta) e da de registro (`/registrar`,
/// que é lançamento depois do fato) porque o uso é outro: aqui o aparelho fica apoiado no
/// banco, a mão está ocupada e cada toque precisa ser grande e óbvio.
class WorkoutModePage extends ConsumerWidget {
  const WorkoutModePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(workoutModeProvider);
    if (session != null) {
      return _SessionView(session: session);
    }

    final planAsync = ref.watch(activeWorkoutPlanProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Treinar')),
      body: planAsync.when(
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
        data: (plan) => _DayPicker(plan: plan),
      ),
    );
  }
}

/// Escolha do dia. Um plano tem vários, e adivinhar qual é o de hoje erraria: a semana de
/// quem treina não segue o calendário.
class _DayPicker extends ConsumerWidget {
  const _DayPicker({required this.plan});

  final WorkoutPlan? plan;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workout = plan;
    if (workout == null || workout.days.isEmpty) {
      return EmptyState(
        icon: Icons.fitness_center_outlined,
        title: 'Você ainda não tem um treino ativo.',
        detail: 'Gere seu plano para poder treinar por ele.',
        action: FilledButton.tonal(
          onPressed: () => context.push(Routes.workoutPlan),
          child: const Text('Ir para o treino'),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(Space.gutter, 8, Space.gutter, 16),
      children: [
        Text(
          'Qual treino é o de hoje?',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 12),
        for (final day in workout.days)
          Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
              title: Text(day.label),
              subtitle: Text('${day.exercises.length} exercícios'),
              trailing: const Icon(Icons.play_arrow),
              onTap: () async {
                ref.read(workoutModeProvider.notifier).startDay(day);
                // O pedido de permissão sai aqui, com o treino começando: é o momento em
                // que o aviso de fim de descanso faz sentido para quem lê o diálogo.
                final alarm = ref.read(restAlarmProvider);
                if (alarm is RestNotifications) {
                  await alarm.requestPermission();
                }
              },
            ),
          ),
      ],
    );
  }
}

class _SessionView extends ConsumerWidget {
  const _SessionView({required this.session});

  final WorkoutModeState session;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progress = session.current;
    final exercise = progress.exercise;
    final theme = Theme.of(context);

    return PopScope(
      // Sair no meio do treino joga fora as séries registradas — elas só existem em memória
      // até o envio no fim.
      canPop: !session.canFinish,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) {
          return;
        }
        if (await _confirmLeave(context) && context.mounted) {
          await ref.read(restTimerProvider.notifier).stop();
          ref.read(workoutModeProvider.notifier).leave();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(session.day.label),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(20),
            child: Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(
                'Exercício ${session.currentIndex + 1} de '
                '${session.exercises.length}  ·  '
                '${session.totalSetsDone} séries feitas',
                style: theme.textTheme.labelMedium,
              ),
            ),
          ),
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(Space.gutter, 8, Space.gutter, 16),
          children: [
            Text(exercise.exerciseName, style: theme.textTheme.headlineSmall),
            const SizedBox(height: 4),
            Text(
              '${exercise.sets} × ${exercise.repsMin}–${exercise.repsMax}'
              '  ·  ${exercise.restSeconds}s de descanso',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            if (exercise.notes != null && exercise.notes!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(exercise.notes!, style: theme.textTheme.bodySmall),
            ],
            const SizedBox(height: 16),

            _SetList(progress: progress),
            const SizedBox(height: 16),

            const _RestTimerCard(),
            const SizedBox(height: 16),

            _SetEntryForm(progress: progress),
            const SizedBox(height: 24),

            Row(
              children: [
                if (!session.isFirstExercise)
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () =>
                          ref.read(workoutModeProvider.notifier).previous(),
                      icon: const Icon(Icons.chevron_left),
                      label: const Text('Anterior'),
                    ),
                  ),
                if (!session.isFirstExercise) const SizedBox(width: 8),
                Expanded(
                  child: session.isLastExercise
                      ? FilledButton.icon(
                          onPressed: session.submitting
                              ? null
                              : () => _finish(context, ref),
                          icon: session.submitting
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.check),
                          label: const Text('Concluir treino'),
                        )
                      : FilledButton.icon(
                          onPressed: () =>
                              ref.read(workoutModeProvider.notifier).next(),
                          icon: const Icon(Icons.chevron_right),
                          label: const Text('Próximo'),
                        ),
                ),
              ],
            ),
            if (!session.isLastExercise) ...[
              const SizedBox(height: 8),
              TextButton(
                onPressed: session.submitting
                    ? null
                    : () => _finish(context, ref),
                child: const Text('Encerrar treino agora'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _finish(BuildContext context, WidgetRef ref) async {
    final dropped = session.unsendableSets;
    if (dropped > 0 && !await _confirmDropped(context, dropped)) {
      return;
    }

    await ref.read(restTimerProvider.notifier).stop();
    final result = await ref.read(workoutModeProvider.notifier).finish();

    if (!context.mounted) {
      return;
    }

    final message = switch (result) {
      SubmitSent() => 'Treino registrado.',
      SubmitQueued() => 'Sem conexão: o treino sobe assim que der.',
      SubmitFailed(:final message) => message,
    };
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(message)));

    if (result is! SubmitFailed) {
      context.go(Routes.home);
    }
  }

  Future<bool> _confirmLeave(BuildContext context) async {
    final leave = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sair do treino?'),
        content: const Text('As séries registradas até aqui serão perdidas.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Continuar treinando'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Sair'),
          ),
        ],
      ),
    );
    return leave ?? false;
  }

  Future<bool> _confirmDropped(BuildContext context, int dropped) async {
    final go = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Algumas séries não serão enviadas'),
        content: Text(
          '$dropped ${dropped == 1 ? 'série está' : 'séries estão'} em '
          'exercícios que não constam no catálogo, e o servidor não aceita '
          'registro sem ele. O resto do treino será enviado normalmente.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Voltar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Enviar assim mesmo'),
          ),
        ],
      ),
    );
    return go ?? false;
  }
}

class _SetList extends ConsumerWidget {
  const _SetList({required this.progress});

  final ExerciseProgress progress;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < progress.done.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              children: [
                Icon(
                  Icons.check_circle,
                  size: 18,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Série ${i + 1}  ·  ${progress.done[i].reps} reps  ·  '
                    '${_kg(progress.done[i].loadKg)} kg'
                    '${progress.done[i].rpe != null ? '  ·  RPE ${progress.done[i].rpe}' : ''}',
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
                if (i == progress.done.length - 1)
                  IconButton(
                    onPressed: () =>
                        ref.read(workoutModeProvider.notifier).undoLastSet(),
                    icon: const Icon(Icons.undo, size: 18),
                    tooltip: 'Desfazer última série',
                  ),
              ],
            ),
          ),
        for (var i = 0; i < progress.remainingSets; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              children: [
                Icon(
                  Icons.circle_outlined,
                  size: 18,
                  color: theme.colorScheme.outline,
                ),
                const SizedBox(width: 8),
                Text(
                  'Série ${progress.done.length + i + 1}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  /// Sem casa decimal quando é inteiro: "60 kg" e não "60.0 kg".
  static String _kg(double value) =>
      value == value.roundToDouble() ? '${value.round()}' : '$value';
}

/// Campos da série atual. `StatefulWidget` porque os controladores de texto precisam
/// sobreviver aos rebuilds do timer, que acontecem a cada segundo.
class _SetEntryForm extends ConsumerStatefulWidget {
  const _SetEntryForm({required this.progress});

  final ExerciseProgress progress;

  @override
  ConsumerState<_SetEntryForm> createState() => _SetEntryFormState();
}

class _SetEntryFormState extends ConsumerState<_SetEntryForm> {
  final _reps = TextEditingController();
  final _load = TextEditingController();
  int? _rpe;

  @override
  void dispose() {
    _reps.dispose();
    _load.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(_SetEntryForm oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Trocou de exercício: a carga do anterior não serve de sugestão para o próximo.
    if (oldWidget.progress.exercise.id != widget.progress.exercise.id) {
      _reps.clear();
      _load.clear();
      _rpe = null;
    }
  }

  void _record() {
    final reps = int.tryParse(_reps.text.trim());
    final load = double.tryParse(_load.text.trim().replaceAll(',', '.'));

    if (reps == null || reps <= 0 || load == null || load < 0) {
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(
          const SnackBar(content: Text('Informe repetições e carga.')),
        );
      return;
    }

    final rest = ref
        .read(workoutModeProvider.notifier)
        .recordSet(reps: reps, loadKg: load, rpe: _rpe);

    // A carga fica: a série seguinte quase sempre repete o peso, e redigitar com a mão
    // suada é o tipo de atrito que faz a pessoa parar de registrar.
    _reps.clear();

    if (rest != null) {
      ref.read(restTimerProvider.notifier).start(rest);
    } else {
      ref.read(restTimerProvider.notifier).stop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final progress = widget.progress;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          progress.isComplete
              ? 'Série extra'
              : 'Série ${progress.nextSetNumber}',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _reps,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Repetições',
                  isDense: true,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: _load,
                // Vírgula é o separador decimal do teclado brasileiro; o ponto entra
                // para quem usa teclado físico ou layout de outro idioma.
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                ],
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _record(),
                decoration: const InputDecoration(
                  labelText: 'Carga (kg)',
                  isDense: true,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Text('RPE', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(width: 8),
            Expanded(
              child: Wrap(
                spacing: 4,
                children: [
                  for (final value in const [6, 7, 8, 9, 10])
                    ChoiceChip(
                      label: Text('$value'),
                      selected: _rpe == value,
                      onSelected: (selected) =>
                          setState(() => _rpe = selected ? value : null),
                    ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        FilledButton.tonalIcon(
          onPressed: _record,
          icon: const Icon(Icons.add),
          label: Text(
            progress.isComplete ? 'Registrar série extra' : 'Concluir série',
          ),
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
        ),
      ],
    );
  }
}

class _RestTimerCard extends ConsumerWidget {
  const _RestTimerCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timer = ref.watch(restTimerProvider);
    final controller = ref.read(restTimerProvider.notifier);
    final theme = Theme.of(context);

    if (timer.isIdle) {
      return const SizedBox.shrink();
    }

    final finished = timer.isFinished;
    return Card(
      color: finished
          ? theme.colorScheme.primaryContainer
          : theme.colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              finished ? 'Descanso terminado' : 'Descanso',
              style: theme.textTheme.labelLarge?.copyWith(
                color: finished ? theme.colorScheme.onPrimaryContainer : null,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              finished ? 'Pode ir' : timer.label,
              style: theme.textTheme.displaySmall?.copyWith(
                fontWeight: FontWeight.bold,
                fontFeatures: const [FontFeature.tabularFigures()],
                color: finished ? theme.colorScheme.onPrimaryContainer : null,
              ),
            ),
            if (!finished) ...[
              const SizedBox(height: 12),
              LinearProgressIndicator(value: timer.progress),
            ],
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                TextButton.icon(
                  onPressed: () =>
                      controller.extend(const Duration(seconds: 30)),
                  icon: const Icon(Icons.more_time),
                  label: const Text('+30s'),
                ),
                if (!finished)
                  TextButton.icon(
                    onPressed: timer.isPaused
                        ? controller.resume
                        : controller.pause,
                    icon: Icon(timer.isPaused ? Icons.play_arrow : Icons.pause),
                    label: Text(timer.isPaused ? 'Retomar' : 'Pausar'),
                  ),
                TextButton.icon(
                  onPressed: controller.stop,
                  icon: const Icon(Icons.skip_next),
                  label: Text(finished ? 'Dispensar' : 'Pular'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
