import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/iso_date.dart';
import '../../core/network/api_exception.dart';
import '../../core/sync/sync_queue.dart';
import '../logging/data/logging_models.dart';
import '../logging/log_session_controller.dart';
import 'data/workout_models.dart';

/// Uma série cumprida durante o treino.
class SetRecord {
  const SetRecord({required this.reps, required this.loadKg, this.rpe});

  final int reps;
  final double loadKg;
  final int? rpe;
}

/// Quanto já foi feito de um exercício do dia.
class ExerciseProgress {
  const ExerciseProgress({required this.exercise, this.done = const []});

  final WorkoutExercise exercise;
  final List<SetRecord> done;

  bool get isComplete => done.length >= exercise.sets;

  /// Número da próxima série, contado por exercício — é o que o backend usa para ordenar.
  int get nextSetNumber => done.length + 1;

  /// Séries que o plano ainda espera. Nunca negativo: fazer série a mais é permitido.
  int get remainingSets =>
      (exercise.sets - done.length) < 0 ? 0 : exercise.sets - done.length;

  ExerciseProgress copyWith({List<SetRecord>? done}) =>
      ExerciseProgress(exercise: exercise, done: done ?? this.done);
}

/// Treino em andamento.
class WorkoutModeState {
  const WorkoutModeState({
    required this.day,
    required this.exercises,
    this.currentIndex = 0,
    this.submitting = false,
  });

  final WorkoutDay day;
  final List<ExerciseProgress> exercises;
  final int currentIndex;
  final bool submitting;

  ExerciseProgress get current => exercises[currentIndex];

  bool get isFirstExercise => currentIndex == 0;
  bool get isLastExercise => currentIndex >= exercises.length - 1;

  int get completedExercises => exercises.where((e) => e.isComplete).length;

  int get totalSetsDone =>
      exercises.fold(0, (count, e) => count + e.done.length);

  /// Sem nenhuma série não há o que enviar — e um POST vazio criaria uma sessão fantasma
  /// no histórico.
  bool get canFinish => totalSetsDone > 0;

  /// Séries que ficariam de fora do envio por estarem num exercício sem id de catálogo.
  ///
  /// O plano pode trazer um exercício solto, sem correspondente em `/api/exercises`, e o
  /// `POST /api/sessions` exige o id. Some-las caladamente faria o volume do histórico não
  /// bater com o que a pessoa levantou.
  int get unsendableSets => exercises
      .where((e) => e.exercise.exerciseId == null)
      .fold(0, (count, e) => count + e.done.length);

  WorkoutModeState copyWith({
    List<ExerciseProgress>? exercises,
    int? currentIndex,
    bool? submitting,
  }) => WorkoutModeState(
    day: day,
    exercises: exercises ?? this.exercises,
    currentIndex: currentIndex ?? this.currentIndex,
    submitting: submitting ?? this.submitting,
  );

  SessionRequest toRequest(DateTime date) {
    final sets = <SetLogRequest>[];

    for (final progress in exercises) {
      final exerciseId = progress.exercise.exerciseId;
      if (exerciseId == null) {
        continue;
      }
      var setNumber = 0;
      for (final record in progress.done) {
        setNumber++;
        sets.add(
          SetLogRequest(
            exerciseId: exerciseId,
            setNumber: setNumber,
            reps: record.reps,
            loadKg: record.loadKg,
            rpe: record.rpe,
          ),
        );
      }
    }

    // O workoutDayId amarra a sessão ao dia do plano — é o que deixa o backend comparar o
    // que foi prescrito com o que foi feito e sugerir progressão.
    return SessionRequest(
      date: isoDate(date),
      workoutDayId: day.id,
      sets: sets,
    );
  }
}

/// Conduz o treino: qual exercício, quais séries já foram, e o envio no fim.
///
/// Null enquanto nenhum dia foi escolhido — a tela mostra a lista de dias nesse caso.
class WorkoutModeController extends Notifier<WorkoutModeState?> {
  @override
  WorkoutModeState? build() => null;

  void startDay(WorkoutDay day) {
    state = WorkoutModeState(
      day: day,
      exercises: day.exercises
          .map((e) => ExerciseProgress(exercise: e))
          .toList(),
    );
  }

  void leave() => state = null;

  /// Guarda a série e devolve quanto descansar antes da próxima.
  ///
  /// Null quando não há por que descansar: o exercício acabou de fechar e o próximo passo é
  /// trocar de aparelho, não esperar parado.
  Duration? recordSet({required int reps, required double loadKg, int? rpe}) {
    final current = state;
    if (current == null) {
      return null;
    }

    final progress = current.current;
    final updated = progress.copyWith(
      done: [
        ...progress.done,
        SetRecord(reps: reps, loadKg: loadKg, rpe: rpe),
      ],
    );

    final exercises = [...current.exercises];
    exercises[current.currentIndex] = updated;
    state = current.copyWith(exercises: exercises);

    return updated.isComplete
        ? null
        : Duration(seconds: progress.exercise.restSeconds);
  }

  /// Desfaz a última série do exercício atual — errar o número é comum com a mão suada.
  void undoLastSet() {
    final current = state;
    if (current == null || current.current.done.isEmpty) {
      return;
    }
    final done = [...current.current.done]..removeLast();
    final exercises = [...current.exercises];
    exercises[current.currentIndex] = current.current.copyWith(done: done);
    state = current.copyWith(exercises: exercises);
  }

  void goTo(int index) {
    final current = state;
    if (current == null || index < 0 || index >= current.exercises.length) {
      return;
    }
    state = current.copyWith(currentIndex: index);
  }

  void next() {
    final current = state;
    if (current != null && !current.isLastExercise) {
      goTo(current.currentIndex + 1);
    }
  }

  void previous() {
    final current = state;
    if (current != null && !current.isFirstExercise) {
      goTo(current.currentIndex - 1);
    }
  }

  /// Envia a sessão. Sem rede ela fica na fila local e sobe depois.
  Future<SubmitResult> finish({DateTime? date}) async {
    final current = state;
    if (current == null || !current.canFinish) {
      return const SubmitFailed('Registre pelo menos uma série.');
    }

    state = current.copyWith(submitting: true);

    try {
      final outcome = await ref
          .read(loggingRepositoryProvider)
          .logSession(current.toRequest(date ?? DateTime.now()));

      ref.invalidate(sessionHistoryProvider);
      state = null;

      return outcome == WriteOutcome.sent
          ? const SubmitSent()
          : const SubmitQueued();
    } on ApiException catch (e) {
      state = current.copyWith(submitting: false);
      return SubmitFailed(e.message);
    }
  }
}

final workoutModeProvider =
    NotifierProvider<WorkoutModeController, WorkoutModeState?>(
      WorkoutModeController.new,
    );
