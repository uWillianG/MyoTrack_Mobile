import 'package:flutter_test/flutter_test.dart';
import 'package:myotrack/features/dashboard/dashboard_stats.dart';
import 'package:myotrack/features/progress/progress_controller.dart';

/// O que sobrou de conta na tela depois de o cálculo ir para `/api/progress/*`: a janela de
/// doze semanas e o preenchimento das vazias. O resto — volume de uma série, começo da
/// semana, qual série é o recorde — é do servidor, e é testado lá.
void main() {
  // Uma quarta-feira: exercita o recuo até a segunda sem cair no caso trivial.
  final now = DateTime(2026, 7, 29);

  WeeklyVolume week(String start, {num volumeKg = 0, int sessions = 1}) =>
      WeeklyVolume(
        weekStart: DateTime.parse(start),
        volumeKg: volumeKg,
        sessions: sessions,
      );

  WeightPoint weight(String date, num kg) =>
      WeightPoint(date: DateTime.parse(date), weightKg: kg);

  ExerciseRecord record(String name, num loadKg) =>
      ExerciseRecord(name: name, maxLoadKg: loadKg);

  DashboardStats build({
    List<WeeklyVolume> volume = const [],
    List<WeightPoint> weight = const [],
    List<ExerciseRecord> records = const [],
  }) => DashboardStats.from(
    volume: volume,
    weight: weight,
    records: records,
    now: now,
  );

  group('janela de volume', () {
    test('semana sem treino entra com zero, e não some do gráfico', () {
      // Omitir a semana vazia colaria duas semanas distantes lado a lado, e o gráfico
      // contaria uma constância que não houve. O servidor só manda as que têm registro.
      final stats = build(
        volume: [week('2026-07-27', volumeKg: 5000, sessions: 2)],
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

    test('os treinos da semana corrente vêm da última barra', () {
      final stats = build(
        volume: [week('2026-07-27', volumeKg: 5500, sessions: 2)],
      );

      expect(stats.sessionsThisWeek, 2);
      expect(stats.volumeThisWeek, 5500);
    });

    test('semana antiga demais fica fora da janela', () {
      final stats = build(
        volume: [week('2025-01-06', volumeKg: 9999, sessions: 3)],
      );

      expect(stats.weeklyVolume.every((w) => w.volumeKg == 0), isTrue);
      expect(stats.sessionsThisWeek, 0);
    });
  });

  group('recordes', () {
    test('ordena pela carga, que é o que a lista mostra', () {
      // O servidor ordena pelo 1RM estimado — leitura útil em outro lugar, mas aqui
      // deixaria a lista fora de ordem à vista de quem lê as cargas.
      final stats = build(
        records: [record('Supino', 80), record('Agachamento', 100)],
      );

      expect(stats.records.map((r) => r.name), ['Agachamento', 'Supino']);
    });
  });

  group('peso corporal', () {
    test('variação é do primeiro ao último ponto', () {
      final stats = build(
        weight: [weight('2026-07-01', 84), weight('2026-07-28', 82.4)],
      );

      expect(stats.currentWeightKg, 82.4);
      expect(stats.weightDeltaKg, closeTo(-1.6, 0.001));
    });

    test('com um único registro não há variação a informar', () {
      // "Variação" a partir de uma medida só seria invenção.
      final stats = build(weight: [weight('2026-07-28', 82)]);

      expect(stats.currentWeightKg, 82);
      expect(stats.weightDeltaKg, isNull);
    });

    test('ordena por data mesmo se a API não ordenar', () {
      final stats = build(
        weight: [weight('2026-07-28', 82), weight('2026-07-01', 84)],
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

    test('uma semana com treino já basta para não ser vazio', () {
      expect(build(volume: [week('2026-07-27')]).isEmpty, isFalse);
    });

    test('semana com treino fora da janela não conta como conteúdo', () {
      // A janela é o que a tela mostra: um treino de 2025 deixaria a home afirmando ter
      // dados enquanto todos os doze gráficos aparecem zerados.
      expect(build(volume: [week('2025-01-06')]).isEmpty, isTrue);
    });
  });
}
