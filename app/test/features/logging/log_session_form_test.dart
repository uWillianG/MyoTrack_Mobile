import 'package:flutter_test/flutter_test.dart';
import 'package:myotrack/features/logging/log_session_controller.dart';

void main() {
  SetEntry set({
    int? exerciseId = 1,
    String reps = '10',
    String loadKg = '60',
    int? rpe,
  }) => SetEntry(exerciseId: exerciseId, reps: reps, loadKg: loadKg, rpe: rpe);

  group('SetEntry', () {
    test('só está completa com exercício e repetições', () {
      expect(set().isComplete, isTrue);
      expect(set(exerciseId: null).isComplete, isFalse);
      expect(set(reps: '').isComplete, isFalse);
      expect(set(reps: 'abc').isComplete, isFalse);
    });

    test('carga zero é válida — peso corporal', () {
      // Barra fixa e prancha não têm carga externa; exigir um número maior que zero
      // impediria de registrá-las.
      expect(set(loadKg: '0').isComplete, isTrue);
      expect(set(loadKg: '0').toRequest(1).loadKg, 0);
    });

    test('aceita vírgula como separador decimal', () {
      // É o que o teclado em pt-BR oferece.
      expect(set(loadKg: '82,5').toRequest(1).loadKg, 82.5);
      expect(set(loadKg: '82.5').toRequest(1).loadKg, 82.5);
    });

    test('carga em branco invalida a série', () {
      expect(set(loadKg: '').isComplete, isFalse);
    });

    test('clearRpe remove o valor, que copyWith sozinho não faria', () {
      final comRpe = set(rpe: 8);
      expect(comRpe.copyWith(clearRpe: true).rpe, isNull);
      // Sem a flag, passar null cairia no `?? this.rpe` e manteria o 8.
      expect(comRpe.copyWith().rpe, 8);
    });
  });

  group('LogSessionForm', () {
    test('séries incompletas são ignoradas no envio', () {
      final form = LogSessionForm(
        sets: [
          set(),
          const SetEntry(), // linha vazia recém-adicionada
          set(reps: '8'),
        ],
      );

      expect(form.completeSets, hasLength(2));
      expect(form.canSubmit, isTrue);
      expect(form.toRequest().sets, hasLength(2));
    });

    test('sem nenhuma série completa não dá para enviar', () {
      expect(LogSessionForm(sets: const [SetEntry()]).canSubmit, isFalse);
    });

    test('setNumber é contado por exercício, não pela posição na tela', () {
      final form = LogSessionForm(
        sets: [
          set(exerciseId: 1),
          set(exerciseId: 1),
          set(exerciseId: 2),
          set(exerciseId: 1),
          set(exerciseId: 2),
        ],
      );

      final sets = form.toRequest().sets;

      // Numerar pela posição faria a 3ª série do supino virar "série 4" — e o backend
      // ordena o histórico por (exercício, número).
      expect(sets.map((s) => '${s.exerciseId}:${s.setNumber}'), [
        '1:1',
        '1:2',
        '2:1',
        '1:3',
        '2:2',
      ]);
    });

    test('a data vai em ISO, que é o formato que o backend espera', () {
      final form = LogSessionForm(date: DateTime(2026, 3, 7), sets: [set()]);

      expect(form.toRequest().date, '2026-03-07');
    });

    test('observação em branco vira null em vez de string vazia', () {
      expect(
        LogSessionForm(notes: '   ', sets: [set()]).toRequest().notes,
        isNull,
      );
      expect(
        LogSessionForm(notes: ' pesado ', sets: [set()]).toRequest().notes,
        'pesado',
      );
    });

    test('peso corporal em branco não gera medida', () {
      expect(LogSessionForm(sets: [set()]).toMeasurementRequest(), isNull);
    });

    test('peso corporal preenchido vira uma medida na mesma data', () {
      final form = LogSessionForm(
        date: DateTime(2026, 3, 7),
        bodyWeightKg: '82,5',
        sets: [set()],
      );

      final measurement = form.toMeasurementRequest();

      expect(measurement, isNotNull);
      expect(measurement!.weightKg, 82.5);
      expect(measurement.date, '2026-03-07');
    });
  });
}
