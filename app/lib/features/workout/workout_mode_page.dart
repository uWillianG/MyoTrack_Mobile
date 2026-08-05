import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/design/blocks.dart';
import '../../core/design/format.dart';
import '../../core/design/tokens.dart';
import '../../core/design/typography.dart';
import '../../core/notifications/rest_alarm.dart';
import '../../core/router.dart';
import '../../core/widgets/blocks.dart';
import '../../core/widgets/empty_state.dart';
import '../logging/log_session_controller.dart';
import 'data/workout_models.dart';
import 'rest_timer.dart';
import 'workout_mode_controller.dart';
import 'workout_plan_controller.dart';

/// Modo treino: conduz o dia escolhido série a série, com o descanso entre elas.
///
/// Separado da tela de plano (`/treino`, que é consulta) e da de registro (`/registrar`, que é
/// lançamento depois do fato) porque o uso é outro: aqui o aparelho fica apoiado no banco, a
/// mão está ocupada e cada toque precisa ser grande e óbvio.
///
/// **A manchete troca de assunto quando o descanso começa.** Durante a série ela é a série —
/// exercício, número e alvo, legíveis de longe. Quando o cronômetro parte, ele toma o bloco em
/// cor cheia: é a única coisa que muda sozinha na tela, e é justamente para vê-la que a pessoa
/// olha o aparelho de dois metros de distância.
///
/// **Os campos ficam fora do herói.** Caixa de texto sobre cor cheia perde o contraste que o
/// tema garante no fundo normal, e digitar carga com a mão suada é a operação que menos pode
/// falhar aqui.
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

/// Escolha do dia. Um plano tem vários, e adivinhar qual é o de hoje erraria: a semana de quem
/// treina não segue o calendário.
class _DayPicker extends ConsumerWidget {
  const _DayPicker({required this.plan});

  final WorkoutPlan? plan;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colors = Blocks.workout(theme.brightness);
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
      padding: const EdgeInsets.fromLTRB(Space.gutter, 4, Space.gutter, 32),
      children: [
        HeroBlock(
          colors: colors,
          label: 'Treinar',
          icon: Icons.fitness_center,
          child: Text(
            'Qual treino\né o de hoje?',
            style: theme.textTheme.displaySmall?.copyWith(color: colors.onTone),
          ),
        ),
        for (final day in workout.days) ...[
          const SizedBox(height: Space.sm),
          BlockSection(
            colors: colors,
            label: day.label,
            icon: Icons.play_circle_outline,
            trailing: day.exercises.length == 1
                ? '1 exercício'
                : '${day.exercises.length} exercícios',
            onEdit: () => _start(ref, day),
            child: Text(
              // Os primeiros exercícios: é o que distingue dois dias com nomes parecidos
              // quando a pessoa não lembra qual era o A e qual era o B.
              day.exercises.take(3).map((e) => e.exerciseName).join(' · '),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall,
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _start(WidgetRef ref, WorkoutDay day) async {
    ref.read(workoutModeProvider.notifier).startDay(day);
    // O pedido de permissão sai aqui, com o treino começando: é o momento em que o aviso de
    // fim de descanso faz sentido para quem lê o diálogo.
    final alarm = ref.read(restAlarmProvider);
    if (alarm is RestNotifications) {
      await alarm.requestPermission();
    }
  }
}

class _SessionView extends ConsumerWidget {
  const _SessionView({required this.session});

  final WorkoutModeState session;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colors = Blocks.workout(theme.brightness);
    final progress = session.current;
    final timer = ref.watch(restTimerProvider);

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
          padding: const EdgeInsets.fromLTRB(Space.gutter, 4, Space.gutter, 32),
          children: [
            // O herói: o descanso quando ele corre, a série quando não.
            if (timer.isIdle)
              _CurrentSetHero(progress: progress, colors: colors)
            else
              _RestHero(progress: progress, colors: colors),
            const SizedBox(height: Space.sm),
            _SetEntrySection(progress: progress, colors: colors),
            const SizedBox(height: Space.sm),
            _SetListSection(progress: progress, colors: colors),
            const SizedBox(height: Space.lg),
            Row(
              children: [
                if (!session.isFirstExercise) ...[
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () =>
                          ref.read(workoutModeProvider.notifier).previous(),
                      child: const Text('Anterior'),
                    ),
                  ),
                  const SizedBox(width: Space.xs),
                ],
                Expanded(
                  child: session.isLastExercise
                      ? FilledButton(
                          onPressed: session.submitting
                              ? null
                              : () => _finish(context, ref),
                          child: session.submitting
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text('Concluir treino'),
                        )
                      : FilledButton(
                          onPressed: () =>
                              ref.read(workoutModeProvider.notifier).next(),
                          child: const Text('Próximo exercício'),
                        ),
                ),
              ],
            ),
            if (!session.isLastExercise) ...[
              const SizedBox(height: Space.xs),
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

// ---------------------------------------------------------------------------------------
// As duas manchetes
// ---------------------------------------------------------------------------------------

/// A série que vem agora.
class _CurrentSetHero extends StatelessWidget {
  const _CurrentSetHero({required this.progress, required this.colors});

  final ExerciseProgress progress;
  final BlockColors colors;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final exercise = progress.exercise;

    return HeroBlock(
      colors: colors,
      label: progress.isComplete
          ? 'Série extra'
          : 'Série ${progress.nextSetNumber} de ${exercise.sets}',
      icon: Icons.fitness_center,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            exercise.exerciseName,
            style: theme.textTheme.headlineSmall?.copyWith(
              color: colors.onTone,
            ),
          ),
          const SizedBox(height: Space.xs),
          Text(
            '${exercise.repsMin}–${exercise.repsMax} repetições'
            '  ·  ${exercise.restSeconds}s de descanso',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colors.onTone.withValues(alpha: 0.85),
            ),
          ),
          if (exercise.notes case final notes? when notes.isNotEmpty) ...[
            const SizedBox(height: Space.xs),
            Text(
              notes,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colors.onTone.withValues(alpha: 0.85),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// O descanso, enquanto ele corre.
///
/// **É o maior número do app**, e de propósito: o aparelho está apoiado no banco a dois metros
/// de distância, e o tempo restante é a única informação que a pessoa precisa dali.
class _RestHero extends ConsumerWidget {
  const _RestHero({required this.progress, required this.colors});

  final ExerciseProgress progress;
  final BlockColors colors;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final timer = ref.watch(restTimerProvider);
    final controller = ref.read(restTimerProvider.notifier);
    final finished = timer.isFinished;

    return HeroBlock(
      colors: colors,
      label: finished ? 'Descanso terminado' : 'Descanso',
      icon: Icons.timer_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            finished ? 'Pode ir' : timer.label,
            style: AppTypography.numeric(
              size: finished ? 44 : 64,
              color: colors.onTone,
            ),
          ),
          const SizedBox(height: Space.sm),
          if (!finished)
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: timer.progress,
                minHeight: 8,
                color: colors.onTone,
                backgroundColor: colors.onTone.withValues(alpha: 0.25),
              ),
            ),
          const SizedBox(height: Space.sm),
          // A próxima série fica à vista durante o descanso: é o que a pessoa precisa saber
          // antes de voltar para a barra, e procurar por isso rolando com a mão ocupada é o
          // atrito que o modo treino existe para evitar.
          Text(
            progress.isComplete
                ? 'Depois: próximo exercício'
                : 'Depois: série ${progress.nextSetNumber} de '
                      '${progress.exercise.sets} · ${progress.exercise.exerciseName}',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colors.onTone.withValues(alpha: 0.85),
            ),
          ),
          const SizedBox(height: Space.md),
          Row(
            children: [
              Expanded(
                child: _RestButton(
                  label: '+30 s',
                  colors: colors,
                  onPressed: () =>
                      controller.extend(const Duration(seconds: 30)),
                ),
              ),
              if (!finished) ...[
                const SizedBox(width: Space.xs),
                Expanded(
                  child: _RestButton(
                    label: timer.isPaused ? 'Retomar' : 'Pausar',
                    colors: colors,
                    onPressed: timer.isPaused
                        ? controller.resume
                        : controller.pause,
                  ),
                ),
              ],
              const SizedBox(width: Space.xs),
              Expanded(
                child: _RestButton(
                  label: finished ? 'Dispensar' : 'Pular',
                  colors: colors,
                  filled: true,
                  onPressed: controller.stop,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Botão do bloco de descanso. 48 dp de altura: é tocado com a mão suada, de pé.
class _RestButton extends StatelessWidget {
  const _RestButton({
    required this.label,
    required this.colors,
    required this.onPressed,
    this.filled = false,
  });

  final String label;
  final BlockColors colors;
  final VoidCallback onPressed;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final style = ButtonStyle(
      minimumSize: const WidgetStatePropertyAll(Size.fromHeight(48)),
      padding: const WidgetStatePropertyAll(EdgeInsets.zero),
    );

    return filled
        ? FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: colors.onTone,
              foregroundColor: colors.tone,
            ).merge(style),
            onPressed: onPressed,
            child: Text(label),
          )
        : OutlinedButton(
            style: OutlinedButton.styleFrom(
              foregroundColor: colors.onTone,
              side: BorderSide(color: colors.onTone.withValues(alpha: 0.45)),
            ).merge(style),
            onPressed: onPressed,
            child: Text(label),
          );
  }
}

// ---------------------------------------------------------------------------------------
// As séries
// ---------------------------------------------------------------------------------------

/// O que já foi feito e o que falta, neste exercício.
class _SetListSection extends ConsumerWidget {
  const _SetListSection({required this.progress, required this.colors});

  final ExerciseProgress progress;
  final BlockColors colors;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return BlockSection(
      colors: colors,
      label: 'Séries',
      icon: Icons.format_list_numbered,
      trailing: '${progress.done.length} de ${progress.exercise.sets}',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < progress.done.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: Space.xxs),
              child: Row(
                children: [
                  Icon(Icons.check_circle, size: 18, color: colors.ink),
                  const SizedBox(width: Space.xs),
                  Expanded(
                    child: Text(
                      'Série ${i + 1}  ·  ${progress.done[i].reps} reps  ·  '
                      '${Fmt.kg(progress.done[i].loadKg)}'
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
              padding: const EdgeInsets.only(bottom: Space.xxs),
              child: Row(
                children: [
                  Icon(
                    Icons.circle_outlined,
                    size: 18,
                    color: theme.colorScheme.outline,
                  ),
                  const SizedBox(width: Space.xs),
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
      ),
    );
  }
}

/// Campos da série atual.
///
/// `StatefulWidget` porque os controladores de texto precisam sobreviver aos rebuilds do
/// timer, que acontecem a cada segundo.
class _SetEntrySection extends ConsumerStatefulWidget {
  const _SetEntrySection({required this.progress, required this.colors});

  final ExerciseProgress progress;
  final BlockColors colors;

  @override
  ConsumerState<_SetEntrySection> createState() => _SetEntrySectionState();
}

class _SetEntrySectionState extends ConsumerState<_SetEntrySection> {
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
  void didUpdateWidget(_SetEntrySection oldWidget) {
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

    // A carga fica: a série seguinte quase sempre repete o peso, e redigitar com a mão suada
    // é o tipo de atrito que faz a pessoa parar de registrar.
    _reps.clear();

    if (rest != null) {
      ref.read(restTimerProvider.notifier).start(rest);
    } else {
      ref.read(restTimerProvider.notifier).stop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final progress = widget.progress;

    return BlockSection(
      colors: widget.colors,
      label: progress.isComplete
          ? 'Registrar série extra'
          : 'Registrar a série ${progress.nextSetNumber}',
      icon: Icons.add_circle_outline,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _reps,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(labelText: 'Repetições'),
                ),
              ),
              const SizedBox(width: Space.sm),
              Expanded(
                child: TextField(
                  controller: _load,
                  // Vírgula é o separador decimal do teclado brasileiro; o ponto entra para
                  // quem usa teclado físico ou layout de outro idioma.
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                  ],
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _record(),
                  decoration: const InputDecoration(labelText: 'Carga (kg)'),
                ),
              ),
            ],
          ),
          const SizedBox(height: Space.md),
          Row(
            children: [
              Text('RPE', style: theme.textTheme.titleSmall),
              const SizedBox(width: Space.xs),
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
          const SizedBox(height: Space.md),
          FilledButton(
            onPressed: _record,
            // 56 dp: é o alvo mais tocado da tela, com a mão suada e de pé.
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(56),
            ),
            child: Text(
              progress.isComplete ? 'Registrar série extra' : 'Concluir série',
            ),
          ),
        ],
      ),
    );
  }
}
