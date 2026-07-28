import 'package:flutter_test/flutter_test.dart';
import 'package:myotrack/features/dashboard/dashboard_stats.dart';
import 'package:myotrack/features/logging/data/logging_models.dart';

void main() {
  // Uma quarta-feira: exercita o recuo até a segunda sem cair no caso trivial.
  final now = DateTime(2026, 7, 29);

  SetView set({required String name, required int reps, required num loadKg}) =>
      SetView(id: 's', exerciseName: name, reps: reps, loadKg: loadKg);

  WorkoutSessionView session({
    required String date,
    num totalVolumeKg = 0,
    List<SetView> sets = const [],
  }) => WorkoutSessionView(
    id: 'w-$date',
    date: date,
    totalVolumeKg: totalVolumeKg,
    sets: sets,
  );

  MeasurementView weight(String date, num? kg) =>
      MeasurementView(id: 'm-$date', date: date, weightKg: kg);

  DashboardStats build({
    List<WorkoutSessionView> sessions = const [],
    List<MeasurementView> measurements = const [],
  }) => DashboardStats.from(
    sessions: sessions,
    measurements: measurements,
    now: now,
  );

  group('volume por semana', () {
    test('semana sem treino entra com zero, e não some do gráfico', () {
      // Omitir a semana vazia colaria duas semanas distantes lado a lado, e o gráfico
      // contaria uma constância que não houve.
      final stats = build(
        sessions: [session(date: '2026-07-27', totalVolumeKg: 5000)],
      );

      expect(stats.weeklyVolume, hasLength(DashboardStats.volumeWeeks));
      expect(stats.weeklyVolume.last.volumeKg, 5000);
      expect(stats.weeklyVolume.first.volumeKg, 0);
      expect(stats.weeklyVolume.first.sessions, 0);
    });

    test('a última barra é sempre a semana corrente', () {
      final stats = build();

      expect(stats.weeklyVolume.last.weekStart, DateTime(2026, 7, 27));
      expect(stats.weeklyVolume.first.weekStart, DateTime(2026, 5, 11));
    });

    test('sessões da mesma semana somam na mesma barra', () {
      final stats = build(
        sessions: [
          session(date: '2026-07-27', totalVolumeKg: 3000),
          session(date: '2026-07-29', totalVolumeKg: 2500),
        ],
      );

      expect(stats.weeklyVolume.last.volumeKg, 5500);
      expect(stats.weeklyVolume.last.sessions, 2);
      expect(stats.sessionsThisWeek, 2);
    });

    test('sem o total do servidor, soma das séries', () {
      // Sessão que subiu pela fila offline pode chegar antes de o servidor recalcular o
      // total; um zero no meio do gráfico pareceria semana perdida.
      final stats = build(
        sessions: [
          session(
            date: '2026-07-28',
            sets: [
              set(name: 'Supino', reps: 10, loadKg: 60),
              set(name: 'Supino', reps: 8, loadKg: 60),
            ],
          ),
        ],
      );

      expect(stats.weeklyVolume.last.volumeKg, 10 * 60 + 8 * 60);
    });

    test('sessão antiga demais fica fora da janela', () {
      final stats = build(
        sessions: [session(date: '2025-01-05', totalVolumeKg: 9999)],
      );

      expect(stats.weeklyVolume.every((w) => w.volumeKg == 0), isTrue);
      // Mas continua contando no total de sessões — ela existiu.
      expect(stats.totalSessions, 1);
    });
  });

  group('recordes', () {
    test('guarda a maior carga por exercício, com reps e data', () {
      final stats = build(
        sessions: [
          session(
            date: '2026-07-20',
            sets: [set(name: 'Supino', reps: 8, loadKg: 70)],
          ),
          session(
            date: '2026-07-27',
            sets: [
              set(name: 'Supino', reps: 5, loadKg: 80),
              set(name: 'Agachamento', reps: 5, loadKg: 100),
            ],
          ),
        ],
      );

      final supino = stats.records.firstWhere(
        (r) => r.exerciseName == 'Supino',
      );
      expect(supino.loadKg, 80);
      expect(supino.reps, 5);
      expect(supino.date, DateTime(2026, 7, 27));
      // Ordenados do maior para o menor.
      expect(stats.records.first.exerciseName, 'Agachamento');
    });

    test('empate de carga fica com o mais recente', () {
      // Bater a mesma carga hoje diz mais sobre a forma atual do que tê-la batido em maio.
      final stats = build(
        sessions: [
          session(
            date: '2026-05-04',
            sets: [set(name: 'Supino', reps: 3, loadKg: 80)],
          ),
          session(
            date: '2026-07-27',
            sets: [set(name: 'Supino', reps: 6, loadKg: 80)],
          ),
        ],
      );

      expect(stats.records.single.reps, 6);
      expect(stats.records.single.date, DateTime(2026, 7, 27));
    });

    test('carga zero é peso corporal, não recorde de carga', () {
      final stats = build(
        sessions: [
          session(
            date: '2026-07-27',
            sets: [
              set(name: 'Barra fixa', reps: 12, loadKg: 0),
              set(name: 'Supino', reps: 8, loadKg: 60),
            ],
          ),
        ],
      );

      expect(stats.records.map((r) => r.exerciseName), ['Supino']);
    });
  });

  group('peso corporal', () {
    test('só entram medidas que têm peso', () {
      // Medir a cintura não é pesar-se; sem o filtro, o gráfico ganharia pontos em zero.
      final stats = build(
        measurements: [
          weight('2026-07-01', 84),
          weight('2026-07-15', null),
          weight('2026-07-28', 82.4),
        ],
      );

      expect(stats.weightSeries, hasLength(2));
      expect(stats.currentWeightKg, 82.4);
      expect(stats.weightDeltaKg, closeTo(-1.6, 0.001));
    });

    test('com um único registro não há variação a informar', () {
      // "Variação" a partir de uma medida só seria invenção.
      final stats = build(measurements: [weight('2026-07-28', 82)]);

      expect(stats.currentWeightKg, 82);
      expect(stats.weightDeltaKg, isNull);
    });

    test('ordena por data mesmo se a API não ordenar', () {
      final stats = build(
        measurements: [weight('2026-07-28', 82), weight('2026-07-01', 84)],
      );

      expect(stats.weightSeries.first.weightKg, 84);
      expect(stats.weightSeries.last.weightKg, 82);
    });
  });

  group('estado vazio', () {
    test('sem nada registrado, o dashboard se declara vazio', () {
      // É o que faz a home mostrar o próximo passo em vez de gráficos zerados, que
      // pareceriam defeito.
      expect(build().isEmpty, isTrue);
    });

    test('uma sessão já basta para não ser vazio', () {
      expect(build(sessions: [session(date: '2026-07-27')]).isEmpty, isFalse);
    });
  });

  test('data malformada é ignorada em vez de derrubar a tela', () {
    final stats = build(
      sessions: [session(date: 'sem-data', totalVolumeKg: 100)],
      measurements: [weight('', 80)],
    );

    expect(stats.weeklyVolume.every((w) => w.volumeKg == 0), isTrue);
    expect(stats.weightSeries, isEmpty);
  });
}
