import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../logging/data/logging_models.dart';
import '../logging/logging_controller.dart';
import '../reviews/review_controller.dart';
import '../workout/data/workout_models.dart';
import '../workout/workout_plan_controller.dart';

/// O relógio.
///
/// Existe como provider porque a Hoje **muda de assunto conforme a hora**: de manhã ela abre
/// pelo treino, à tarde pelas calorias, à noite pelo fechamento do dia. Uma tela com esse
/// comportamento e um `DateTime.now()` cravado no `build` é uma tela cujo teste passa ou falha
/// dependendo da hora em que o CI rodar — e a versão das dez da noite ninguém conferiria nunca.
final nowProvider = Provider<DateTime Function()>((ref) => DateTime.now);

/// O treino que a rotação do plano indica como próximo.
///
/// **É sugestão, e a tela diz isso.** A escolha do dia continua sendo do usuário em
/// `/treinar` — a semana de quem treina não segue o calendário, e apontar "hoje é o B"
/// erraria em qualquer semana em que a pessoa pulou um dia ou trocou a ordem. O que dá para
/// afirmar sem chutar é outra coisa: qual dia veio depois do último registrado.
class NextWorkout {
  const NextWorkout({required this.day, required this.lastDoneAt});

  final WorkoutDay day;

  /// Quando este dia do plano foi treinado pela última vez. Null em quem nunca o registrou.
  final DateTime? lastDoneAt;

  int get exerciseCount => day.exercises.length;

  /// Quanto o dia deve durar, em minutos.
  ///
  /// Conta o descanso prescrito mais [_secondsPerSet] de execução por série. É estimativa e
  /// a tela a apresenta como "cerca de": o tempo real depende de quanto a academia está
  /// cheia, e prometer um número exato seria promessa que o app não controla.
  int get estimatedMinutes {
    final seconds = day.exercises.fold<int>(
      0,
      (total, e) => total + e.sets * (e.restSeconds + _secondsPerSet),
    );
    // Arredondado para cima em blocos de 5: "cerca de 48 min" sugere uma precisão que a
    // conta não tem.
    final minutes = (seconds / 60).ceil();
    return ((minutes / 5).ceil() * 5).clamp(5, 240);
  }

  /// Dias desde a última vez que este treino foi registrado. Null em quem nunca o fez.
  int? daysSince({DateTime? now}) {
    final last = lastDoneAt;
    if (last == null) {
      return null;
    }
    final today = _dateOnly(now ?? DateTime.now());
    return today.difference(_dateOnly(last)).inDays;
  }

  static const int _secondsPerSet = 45;
}

/// Sugestão de próximo treino, ou null quando não há plano ativo.
///
/// O histórico de sessões é opcional aqui: sem rede ele falha, e um erro nele não pode
/// esconder o cartão inteiro — sem histórico a sugestão é simplesmente o primeiro dia do
/// plano, que é o que faz sentido para quem acabou de gerar.
final nextWorkoutProvider = FutureProvider<NextWorkout?>((ref) async {
  final plan = await ref.watch(activeWorkoutPlanProvider.future);
  final days = plan?.days ?? const <WorkoutDay>[];
  if (days.isEmpty) {
    return null;
  }

  final ordered = [...days]..sort((a, b) => a.order.compareTo(b.order));
  final sessions = await ref.watch(recentSessionsProvider.future);

  final index = _nextDayIndex(ordered, sessions);
  final day = ordered[index];

  return NextWorkout(day: day, lastDoneAt: _lastDoneAt(day.id, sessions));
});

/// O dia seguinte ao último treinado, dando a volta no fim do plano.
///
/// Quem nunca registrou nada, e quem registrou só sessões avulsas (sem `workoutDayId`),
/// começa pelo primeiro dia.
int _nextDayIndex(List<WorkoutDay> ordered, List<WorkoutSessionView> sessions) {
  for (final session in sessions) {
    final index = ordered.indexWhere((d) => d.id == session.workoutDayId);
    if (index >= 0) {
      return (index + 1) % ordered.length;
    }
  }
  return 0;
}

DateTime? _lastDoneAt(String dayId, List<WorkoutSessionView> sessions) {
  for (final session in sessions) {
    if (session.workoutDayId == dayId) {
      return DateTime.tryParse(session.date);
    }
  }
  return null;
}

/// Histórico de sessões, mais recentes primeiro, tolerante a falha.
///
/// Envolve o [sessionHistoryProvider] em vez de substituí-lo: as telas que precisam saber
/// que a rede caiu continuam usando o original, e o hub — onde o histórico é acessório —
/// usa este.
final recentSessionsProvider = FutureProvider<List<WorkoutSessionView>>((
  ref,
) async {
  try {
    final sessions = await ref.watch(sessionHistoryProvider.future);
    return [...sessions]..sort((a, b) => b.date.compareTo(a.date));
  } catch (_) {
    return const [];
  }
});

/// Em quais dias dos últimos sete houve treino, do mais antigo para o mais recente.
///
/// Sete posições sempre, mesmo sem treino nenhum: a fileira de bolinhas é um calendário, e
/// omitir os dias vazios faria dois treinos distantes parecerem seguidos.
final weekStreakProvider = FutureProvider<List<bool>>((ref) async {
  final sessions = await ref.watch(recentSessionsProvider.future);
  final trained = <DateTime>{
    for (final session in sessions)
      if (DateTime.tryParse(session.date) case final date?) _dateOnly(date),
  };

  final today = _dateOnly(DateTime.now());
  return [
    for (var i = 6; i >= 0; i--)
      trained.contains(today.subtract(Duration(days: i))),
  ];
});

/// O que espera a revisão deste usuário.
class PendingReviews {
  const PendingReviews({this.counts = const {}, this.oldest});

  final Map<ReviewKind, int> counts;

  /// Quando o plano mais antigo da fila entrou. Null quando a fila está vazia — ou quando
  /// nenhum item trouxe data.
  final DateTime? oldest;

  int get total => counts.values.fold(0, (sum, n) => sum + n);

  /// Dias de espera do mais antigo. É o número que diz se a fila está atrasada: quatro
  /// planos de hoje e quatro de duas semanas atrás pedem urgências diferentes.
  int? daysWaiting({DateTime? now}) {
    final since = oldest;
    if (since == null) {
      return null;
    }
    return _dateOnly(now ?? DateTime.now()).difference(_dateOnly(since)).inDays;
  }

  static const empty = PendingReviews();
}

/// Quantos planos esperam a revisão deste usuário, e desde quando.
///
/// Só consulta as filas que os papéis do token permitem: pedir a de dietas a um personal
/// devolveria 403, e o cartão sumiria por causa de um erro que não é dele. Vazio significa
/// "não há o que revisar" **e também** "este usuário não é revisor" — nos dois casos o cartão
/// não aparece, que é o desfecho certo.
final pendingReviewsProvider = FutureProvider<PendingReviews>((ref) async {
  final kinds = await ref.watch(reviewableKindsProvider.future);
  if (kinds.isEmpty) {
    return PendingReviews.empty;
  }

  final repository = ref.watch(reviewRepositoryProvider);
  final counts = <ReviewKind, int>{};
  DateTime? oldest;

  for (final kind in kinds) {
    final List<ReviewQueueItem> items;
    try {
      items = await repository.pending(kind);
    } catch (_) {
      // Uma fila fora do ar não pode apagar a contagem da outra.
      continue;
    }

    counts[kind] = items.length;
    for (final item in items) {
      final created = DateTime.tryParse(item.createdAt ?? '');
      final current = oldest;
      if (created != null && (current == null || created.isBefore(current))) {
        oldest = created;
      }
    }
  }

  return PendingReviews(counts: counts, oldest: oldest);
});

DateTime _dateOnly(DateTime date) => DateTime(date.year, date.month, date.day);
