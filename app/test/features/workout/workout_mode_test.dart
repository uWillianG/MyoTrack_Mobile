import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myotrack/features/workout/data/workout_models.dart';
import 'package:myotrack/features/workout/workout_mode_controller.dart';

WorkoutExercise _exercise({
  required String id,
  int? exerciseId,
  String name = 'Supino reto',
  int sets = 3,
  int restSeconds = 90,
}) => WorkoutExercise(
  id: id,
  exerciseId: exerciseId,
  exerciseName: name,
  sets: sets,
  restSeconds: restSeconds,
);

void main() {
  late ProviderContainer container;

  final day = WorkoutDay(
    id: 'dia-1',
    order: 1,
    label: 'Treino A — Peito e tríceps',
    exercises: [
      _exercise(id: 'we-1', exerciseId: 10, sets: 3, restSeconds: 90),
      _exercise(
        id: 'we-2',
        exerciseId: 20,
        name: 'Crucifixo',
        sets: 2,
        restSeconds: 60,
      ),
    ],
  );

  setUp(() {
    container = ProviderContainer();
    addTearDown(container.dispose);
  });

  WorkoutModeController controller() =>
      container.read(workoutModeProvider.notifier);
  WorkoutModeState state() => container.read(workoutModeProvider)!;

  group('condução do treino', () {
    test('começa no primeiro exercício, sem nada feito', () {
      controller().startDay(day);

      expect(state().currentIndex, 0);
      expect(state().current.exercise.exerciseName, 'Supino reto');
      expect(state().totalSetsDone, 0);
      expect(state().canFinish, isFalse);
    });

    test('série registrada devolve o descanso daquele exercício', () {
      controller().startDay(day);

      final rest = controller().recordSet(reps: 10, loadKg: 60);

      expect(rest, const Duration(seconds: 90));
      expect(state().current.done.length, 1);
      expect(state().current.nextSetNumber, 2);
    });

    test('a última série do exercício não pede descanso', () {
      // Fechar o exercício significa trocar de aparelho, não esperar parado olhando o timer.
      controller().startDay(day);
      controller().recordSet(reps: 10, loadKg: 60);
      controller().recordSet(reps: 9, loadKg: 60);

      expect(controller().recordSet(reps: 8, loadKg: 60), isNull);
      expect(state().current.isComplete, isTrue);
    });

    test('série extra é aceita depois de fechar o exercício', () {
      controller().startDay(day);
      for (var i = 0; i < 3; i++) {
        controller().recordSet(reps: 10, loadKg: 60);
      }

      controller().recordSet(reps: 6, loadKg: 60);

      expect(state().current.done.length, 4);
      // Nunca negativo: quatro séries feitas de três previstas não é "-1 restante".
      expect(state().current.remainingSets, 0);
    });

    test('desfazer tira só a última série', () {
      controller().startDay(day);
      controller().recordSet(reps: 10, loadKg: 60);
      controller().recordSet(reps: 8, loadKg: 62.5);

      controller().undoLastSet();

      expect(state().current.done.length, 1);
      expect(state().current.done.single.reps, 10);
    });

    test('desfazer sem nenhuma série não quebra', () {
      controller().startDay(day);

      controller().undoLastSet();

      expect(state().current.done, isEmpty);
    });

    test('navegação para nas pontas', () {
      controller().startDay(day);

      controller().previous();
      expect(state().currentIndex, 0);

      controller().next();
      expect(state().currentIndex, 1);
      expect(state().isLastExercise, isTrue);

      controller().next();
      expect(state().currentIndex, 1);
    });

    test('cada exercício conta as próprias séries', () {
      controller().startDay(day);
      controller().recordSet(reps: 10, loadKg: 60);
      controller().next();

      final rest = controller().recordSet(reps: 12, loadKg: 20);

      // O descanso é o do crucifixo (60s), não o do supino.
      expect(rest, const Duration(seconds: 60));
      expect(state().exercises[0].done.length, 1);
      expect(state().exercises[1].done.length, 1);
      expect(state().totalSetsDone, 2);
    });
  });

  group('corpo do POST /api/sessions', () {
    test('amarra a sessão ao dia do plano', () {
      controller().startDay(day);
      controller().recordSet(reps: 10, loadKg: 60);

      final request = state().toRequest(DateTime(2026, 7, 28));

      expect(request.workoutDayId, 'dia-1');
      expect(request.date, '2026-07-28');
    });

    test('numera as séries por exercício, não pela tela toda', () {
      // Numerando corrido, a 1ª série do crucifixo viraria "série 4" e o backend ordenaria
      // o histórico errado.
      controller().startDay(day);
      controller().recordSet(reps: 10, loadKg: 60);
      controller().recordSet(reps: 9, loadKg: 60);
      controller().recordSet(reps: 8, loadKg: 60);
      controller().next();
      controller().recordSet(reps: 12, loadKg: 20);
      controller().recordSet(reps: 11, loadKg: 20);

      final sets = state().toRequest(DateTime(2026, 7, 28)).sets;

      expect(sets.length, 5);
      expect(sets.where((s) => s.exerciseId == 10).map((s) => s.setNumber), [
        1,
        2,
        3,
      ]);
      expect(sets.where((s) => s.exerciseId == 20).map((s) => s.setNumber), [
        1,
        2,
      ]);
    });

    test('leva o RPE quando foi informado', () {
      controller().startDay(day);
      controller().recordSet(reps: 10, loadKg: 60, rpe: 8);
      controller().recordSet(reps: 9, loadKg: 60);

      final sets = state().toRequest(DateTime(2026, 7, 28)).sets;

      expect(sets[0].rpe, 8);
      expect(sets[1].rpe, isNull);
    });

    test('exercício sem id de catálogo fica de fora, mas é contado', () {
      // O POST exige exerciseId. Descartar calado faria o volume do histórico não bater
      // com o que a pessoa levantou — por isso a tela pergunta antes de enviar.
      final withLoose = day.copyWith(
        exercises: [
          ...day.exercises,
          _exercise(id: 'we-3', name: 'Alongamento livre', sets: 1),
        ],
      );
      controller().startDay(withLoose);
      controller().recordSet(reps: 10, loadKg: 60);
      controller().goTo(2);
      controller().recordSet(reps: 1, loadKg: 0);

      final request = state().toRequest(DateTime(2026, 7, 28));

      expect(request.sets.length, 1);
      expect(request.sets.single.exerciseId, 10);
      expect(state().unsendableSets, 1);
    });

    test('carga zero é válida — é peso corporal', () {
      controller().startDay(day);
      controller().recordSet(reps: 15, loadKg: 0);

      expect(state().toRequest(DateTime(2026, 7, 28)).sets.single.loadKg, 0);
    });
  });

  test('sair descarta o treino em andamento', () {
    controller().startDay(day);
    controller().recordSet(reps: 10, loadKg: 60);

    controller().leave();

    expect(container.read(workoutModeProvider), isNull);
  });
}
