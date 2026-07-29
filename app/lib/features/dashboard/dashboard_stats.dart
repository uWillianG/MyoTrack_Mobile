import '../progress/progress_controller.dart';

/// Números do dashboard, montados a partir do que `/api/progress/*` devolve.
///
/// Os cálculos — volume de uma série, começo da semana, qual série é o recorde — vivem no
/// servidor, e só lá. Eles já existiam no `ProgressController` quando esta tela foi escrita, e
/// tê-los repetidos aqui em Dart significava duas implementações da mesma regra livres para
/// divergir em silêncio: o número da tela e o do relatório semanal viriam de contas
/// diferentes, e nada apontaria qual estava errado.
///
/// O que sobrou aqui é o que de fato é da tela: recortar a janela de doze semanas e preencher
/// com zero as semanas sem treino. Isso depende de quantas barras o gráfico mostra, e não é
/// resposta que um endpoint deva dar.
class DashboardStats {
  const DashboardStats({
    required this.weeklyVolume,
    required this.records,
    required this.weightSeries,
    required this.sessionsThisWeek,
  });

  /// Doze semanas, incluindo as vazias, terminando na semana corrente.
  final List<WeeklyVolume> weeklyVolume;
  final List<ExerciseRecord> records;
  final List<WeightPoint> weightSeries;
  final int sessionsThisWeek;

  bool get isEmpty =>
      records.isEmpty &&
      weightSeries.isEmpty &&
      weeklyVolume.every((w) => w.sessions == 0);

  /// Volume da semana corrente. Zero quando ainda não treinou nesta semana.
  double get volumeThisWeek =>
      weeklyVolume.isEmpty ? 0 : weeklyVolume.last.volumeKg.toDouble();

  /// Diferença de peso entre o primeiro e o último registro. Null com menos de dois pontos —
  /// uma "variação" a partir de uma medida só seria invenção.
  double? get weightDeltaKg => weightSeries.length < 2
      ? null
      : weightSeries.last.weightKg.toDouble() -
            weightSeries.first.weightKg.toDouble();

  double? get currentWeightKg =>
      weightSeries.isEmpty ? null : weightSeries.last.weightKg.toDouble();

  static const empty = DashboardStats(
    weeklyVolume: [],
    records: [],
    weightSeries: [],
    sessionsThisWeek: 0,
  );

  /// Quantas semanas o gráfico de volume cobre.
  ///
  /// Doze semanas mostram um bloco de treino inteiro e ainda cabem numa tela de celular sem
  /// virar um borrão de barras.
  static const int volumeWeeks = 12;

  static DashboardStats from({
    required List<WeeklyVolume> volume,
    required List<WeightPoint> weight,
    required List<ExerciseRecord> records,
    DateTime? now,
  }) {
    final window = _window(volume, _weekStart(now ?? DateTime.now()));

    return DashboardStats(
      weeklyVolume: window,
      // Ordenados pela carga, que é o que a lista mostra. O servidor ordena pelo 1RM
      // estimado, útil em outra leitura — aqui isso deixaria a lista fora de ordem à vista.
      records: [...records]..sort((a, b) => b.maxLoadKg.compareTo(a.maxLoadKg)),
      // A API já devolve em ordem, mas o gráfico quebra feio se algum dia não devolver.
      weightSeries: [...weight]..sort((a, b) => a.date.compareTo(b.date)),
      sessionsThisWeek: window.isEmpty ? 0 : window.last.sessions,
    );
  }

  /// As últimas [volumeWeeks] semanas, com as vazias preenchidas com zero.
  ///
  /// Semana vazia entra de propósito: omiti-la faria duas semanas distantes aparecerem lado a
  /// lado, e o gráfico contaria uma constância que não houve.
  static List<WeeklyVolume> _window(
    List<WeeklyVolume> volume,
    DateTime currentWeek,
  ) {
    final byWeek = {for (final week in volume) _dateOnly(week.weekStart): week};
    final firstWeek = currentWeek.subtract(
      const Duration(days: 7 * (volumeWeeks - 1)),
    );

    return [
      for (var i = 0; i < volumeWeeks; i++)
        () {
          final week = firstWeek.add(Duration(days: 7 * i));
          return byWeek[week] ?? WeeklyVolume(weekStart: week);
        }(),
    ];
  }

  /// Segunda-feira da semana da data.
  static DateTime _weekStart(DateTime date) {
    final day = _dateOnly(date);
    return day.subtract(Duration(days: day.weekday - DateTime.monday));
  }

  static DateTime _dateOnly(DateTime date) =>
      DateTime(date.year, date.month, date.day);
}
