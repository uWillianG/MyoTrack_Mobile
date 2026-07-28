import '../logging/data/logging_models.dart';

/// Volume levantado numa semana.
class WeeklyVolume {
  const WeeklyVolume({
    required this.weekStart,
    required this.volumeKg,
    required this.sessions,
  });

  /// Segunda-feira da semana.
  final DateTime weekStart;
  final double volumeKg;
  final int sessions;
}

/// Maior carga já registrada num exercício.
class PersonalRecord {
  const PersonalRecord({
    required this.exerciseName,
    required this.loadKg,
    required this.reps,
    required this.date,
  });

  final String exerciseName;
  final double loadKg;
  final int reps;
  final DateTime date;
}

/// Um ponto da curva de peso corporal.
class WeightPoint {
  const WeightPoint({required this.date, required this.weightKg});

  final DateTime date;
  final double weightKg;
}

/// Números do dashboard, calculados a partir do histórico.
///
/// Tudo aqui é função pura sobre o que a API já devolve: nenhum endpoint novo foi preciso
/// para o B10. Ficar separado da tela é o que permite testar as contas — que são a parte que
/// erra em silêncio, porque um gráfico bonito com número errado não parece quebrado.
class DashboardStats {
  const DashboardStats({
    required this.weeklyVolume,
    required this.records,
    required this.weightSeries,
    required this.totalSessions,
    required this.sessionsThisWeek,
  });

  final List<WeeklyVolume> weeklyVolume;
  final List<PersonalRecord> records;
  final List<WeightPoint> weightSeries;
  final int totalSessions;
  final int sessionsThisWeek;

  bool get isEmpty =>
      totalSessions == 0 && weightSeries.isEmpty && records.isEmpty;

  /// Volume da semana corrente. Zero quando ainda não treinou nesta semana.
  double get volumeThisWeek =>
      weeklyVolume.isEmpty ? 0 : weeklyVolume.last.volumeKg;

  /// Diferença de peso entre o primeiro e o último registro. Null com menos de dois pontos —
  /// uma "variação" a partir de uma medida só seria invenção.
  double? get weightDeltaKg => weightSeries.length < 2
      ? null
      : weightSeries.last.weightKg - weightSeries.first.weightKg;

  double? get currentWeightKg =>
      weightSeries.isEmpty ? null : weightSeries.last.weightKg;

  static const empty = DashboardStats(
    weeklyVolume: [],
    records: [],
    weightSeries: [],
    totalSessions: 0,
    sessionsThisWeek: 0,
  );

  /// Quantas semanas o gráfico de volume cobre.
  ///
  /// Doze semanas mostram um bloco de treino inteiro e ainda cabem numa tela de celular sem
  /// virar um borrão de barras.
  static const int volumeWeeks = 12;

  static DashboardStats from({
    required List<WorkoutSessionView> sessions,
    required List<MeasurementView> measurements,
    DateTime? now,
  }) {
    final today = _dateOnly(now ?? DateTime.now());
    final currentWeek = _weekStart(today);

    return DashboardStats(
      weeklyVolume: _volumeByWeek(sessions, currentWeek),
      records: _recordsByExercise(sessions),
      weightSeries: _weightSeries(measurements),
      totalSessions: sessions.length,
      sessionsThisWeek: sessions.where((s) {
        final date = _parseDate(s.date);
        return date != null && _weekStart(date) == currentWeek;
      }).length,
    );
  }

  /// Uma barra por semana, incluindo as sem treino.
  ///
  /// Semana vazia entra com zero de propósito: omiti-la faria duas semanas distantes
  /// aparecerem lado a lado, e o gráfico contaria uma constância que não houve.
  static List<WeeklyVolume> _volumeByWeek(
    List<WorkoutSessionView> sessions,
    DateTime currentWeek,
  ) {
    final firstWeek = currentWeek.subtract(
      const Duration(days: 7 * (volumeWeeks - 1)),
    );

    final volumes = <DateTime, double>{};
    final counts = <DateTime, int>{};

    for (final session in sessions) {
      final date = _parseDate(session.date);
      if (date == null) {
        continue;
      }
      final week = _weekStart(date);
      if (week.isBefore(firstWeek) || week.isAfter(currentWeek)) {
        continue;
      }
      volumes[week] = (volumes[week] ?? 0) + _volumeOf(session);
      counts[week] = (counts[week] ?? 0) + 1;
    }

    return [
      for (var i = 0; i < volumeWeeks; i++)
        () {
          final week = firstWeek.add(Duration(days: 7 * i));
          return WeeklyVolume(
            weekStart: week,
            volumeKg: volumes[week] ?? 0,
            sessions: counts[week] ?? 0,
          );
        }(),
    ];
  }

  /// O volume vem do servidor quando ele mandou; senão é somado das séries.
  ///
  /// A queda importa: uma sessão que subiu pela fila offline pode chegar ao histórico antes
  /// de o servidor recalcular o total, e um zero no meio do gráfico pareceria semana perdida.
  static double _volumeOf(WorkoutSessionView session) {
    if (session.totalVolumeKg > 0) {
      return session.totalVolumeKg.toDouble();
    }
    return session.sets.fold<double>(
      0,
      (sum, set) => sum + set.reps * set.loadKg.toDouble(),
    );
  }

  /// Maior carga por exercício, com as repetições e a data em que aconteceu.
  ///
  /// Empate de carga fica com o mais recente: bater a mesma carga hoje diz mais sobre a
  /// forma atual do que tê-la batido há seis meses.
  static List<PersonalRecord> _recordsByExercise(
    List<WorkoutSessionView> sessions,
  ) {
    final best = <String, PersonalRecord>{};

    for (final session in sessions) {
      final date = _parseDate(session.date);
      if (date == null) {
        continue;
      }
      for (final set in session.sets) {
        final name = set.exerciseName.trim();
        // Carga zero é peso corporal: legítimo como treino, mas não é recorde de carga.
        if (name.isEmpty || set.loadKg <= 0) {
          continue;
        }

        final load = set.loadKg.toDouble();
        final current = best[name];
        final isBetter =
            current == null ||
            load > current.loadKg ||
            (load == current.loadKg && date.isAfter(current.date));

        if (isBetter) {
          best[name] = PersonalRecord(
            exerciseName: name,
            loadKg: load,
            reps: set.reps,
            date: date,
          );
        }
      }
    }

    return best.values.toList()..sort((a, b) => b.loadKg.compareTo(a.loadKg));
  }

  /// Só os registros que têm peso — medida de cintura não entra na curva de peso.
  static List<WeightPoint> _weightSeries(List<MeasurementView> measurements) {
    final points = <WeightPoint>[];

    for (final measurement in measurements) {
      final weight = measurement.weightKg;
      final date = _parseDate(measurement.date);
      if (weight == null || weight <= 0 || date == null) {
        continue;
      }
      points.add(WeightPoint(date: date, weightKg: weight.toDouble()));
    }

    // A API já devolve ordenado, mas o gráfico quebra feio se algum dia não devolver.
    return points..sort((a, b) => a.date.compareTo(b.date));
  }

  /// Segunda-feira da semana da data.
  static DateTime _weekStart(DateTime date) {
    final day = _dateOnly(date);
    return day.subtract(Duration(days: day.weekday - DateTime.monday));
  }

  static DateTime _dateOnly(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  /// `YYYY-MM-DD` como data local.
  ///
  /// `DateTime.parse` num "2026-07-28" puro devolve horário local à meia-noite, que é o que
  /// se quer; o `Z` de um ISO completo deslocaria o dia para quem treina à noite no Brasil.
  static DateTime? _parseDate(String? value) {
    if (value == null || value.length < 10) {
      return null;
    }
    return DateTime.tryParse(value.substring(0, 10));
  }
}
