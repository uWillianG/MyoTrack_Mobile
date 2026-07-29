import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/iso_date.dart';
import '../../core/network/api_exception.dart';
import '../../core/providers.dart';
import '../../core/sync/sync_queue.dart';
import 'data/logging_models.dart';
import 'data/logging_repository.dart';

final loggingRepositoryProvider = Provider<LoggingRepository>(
  (ref) => LoggingRepository(
    ref.watch(apiClientProvider),
    ref.watch(localDatabaseProvider),
    ref.watch(syncQueueProvider),
  ),
);

/// Catálogo de exercícios (servidor ou cache local).
final exerciseCatalogProvider = FutureProvider<List<ExerciseOption>>(
  (ref) => ref.watch(loggingRepositoryProvider).exercises(),
);

final sessionHistoryProvider = FutureProvider<List<WorkoutSessionView>>(
  (ref) => ref.watch(loggingRepositoryProvider).sessions(),
);

/// Uma linha do formulário: uma série de um exercício.
///
/// Os números ficam como texto porque é isso que o usuário digita — guardar `double` faria
/// "82," virar null no meio da digitação e o campo se apagar sozinho.
class SetEntry {
  const SetEntry({this.exerciseId, this.reps = '', this.loadKg = '', this.rpe});

  final int? exerciseId;
  final String reps;
  final String loadKg;
  final int? rpe;

  SetEntry copyWith({
    int? exerciseId,
    String? reps,
    String? loadKg,
    int? rpe,
    bool clearRpe = false,
  }) {
    return SetEntry(
      exerciseId: exerciseId ?? this.exerciseId,
      reps: reps ?? this.reps,
      loadKg: loadKg ?? this.loadKg,
      rpe: clearRpe ? null : (rpe ?? this.rpe),
    );
  }

  /// Uma série só conta se tem exercício e repetições. A carga pode ser 0 (peso corporal).
  bool get isComplete =>
      exerciseId != null && _toInt(reps) != null && _toDouble(loadKg) != null;

  SetLogRequest toRequest(int setNumber) => SetLogRequest(
    exerciseId: exerciseId!,
    setNumber: setNumber,
    reps: _toInt(reps)!,
    loadKg: _toDouble(loadKg)!,
    rpe: rpe,
  );

  static int? _toInt(String value) => int.tryParse(value.trim());

  /// Aceita vírgula: é o separador decimal do teclado em pt-BR.
  static double? _toDouble(String value) {
    final normalized = value.trim().replaceAll(',', '.');
    if (normalized.isEmpty) {
      return null;
    }
    return double.tryParse(normalized);
  }
}

class LogSessionForm {
  LogSessionForm({
    DateTime? date,
    this.notes = '',
    this.bodyWeightKg = '',
    List<SetEntry>? sets,
  }) : date = date ?? DateTime.now(),
       sets = sets ?? const [SetEntry()];

  final DateTime date;
  final String notes;

  /// Peso corporal do dia, opcional. Fica aqui, e não numa tela separada, porque é o
  /// momento em que a pessoa já está na academia com a balança à mão — e é este número que
  /// destrava a geração da dieta.
  final String bodyWeightKg;

  final List<SetEntry> sets;

  LogSessionForm copyWith({
    DateTime? date,
    String? notes,
    String? bodyWeightKg,
    List<SetEntry>? sets,
  }) => LogSessionForm(
    date: date ?? this.date,
    notes: notes ?? this.notes,
    bodyWeightKg: bodyWeightKg ?? this.bodyWeightKg,
    sets: sets ?? this.sets,
  );

  double? get parsedBodyWeightKg => SetEntry._toDouble(bodyWeightKg);

  MeasurementRequest? toMeasurementRequest() {
    final weight = parsedBodyWeightKg;
    return weight == null
        ? null
        : MeasurementRequest(date: isoDate(date), weightKg: weight);
  }

  List<SetEntry> get completeSets => sets.where((s) => s.isComplete).toList();

  bool get canSubmit => completeSets.isNotEmpty;

  /// O `setNumber` é reatribuído por exercício: o backend usa esse par para ordenar, e
  /// numerar sequencialmente na tela inteira faria a 4ª série do supino virar "série 7".
  SessionRequest toRequest() {
    final counters = <int, int>{};
    final requests = <SetLogRequest>[];

    for (final entry in completeSets) {
      final next = (counters[entry.exerciseId!] ?? 0) + 1;
      counters[entry.exerciseId!] = next;
      requests.add(entry.toRequest(next));
    }

    return SessionRequest(
      date: isoDate(date),
      notes: notes.trim().isEmpty ? null : notes.trim(),
      sets: requests,
    );
  }
}

/// Resultado do envio, para a tela decidir o que dizer.
sealed class SubmitResult {
  const SubmitResult();
}

class SubmitSent extends SubmitResult {
  const SubmitSent();
}

class SubmitQueued extends SubmitResult {
  const SubmitQueued();
}

class SubmitFailed extends SubmitResult {
  const SubmitFailed(this.message);
  final String message;
}

class LogSessionController extends Notifier<LogSessionForm> {
  @override
  LogSessionForm build() => LogSessionForm();

  void setDate(DateTime date) => state = state.copyWith(date: date);

  void setNotes(String notes) => state = state.copyWith(notes: notes);

  void setBodyWeight(String value) =>
      state = state.copyWith(bodyWeightKg: value);

  void addSet() {
    // A nova linha herda o exercício da anterior: quem registra a 3ª série do supino não
    // deveria ter de escolher "supino" de novo.
    final last = state.sets.isEmpty ? const SetEntry() : state.sets.last;
    state = state.copyWith(
      sets: [
        ...state.sets,
        SetEntry(exerciseId: last.exerciseId, loadKg: last.loadKg),
      ],
    );
  }

  void removeSet(int index) {
    if (state.sets.length <= 1) {
      return;
    }
    final sets = [...state.sets]..removeAt(index);
    state = state.copyWith(sets: sets);
  }

  void updateSet(int index, SetEntry entry) {
    final sets = [...state.sets];
    sets[index] = entry;
    state = state.copyWith(sets: sets);
  }

  Future<SubmitResult> submit() async {
    if (!state.canSubmit) {
      return const SubmitFailed('Registre pelo menos uma série completa.');
    }

    final repository = ref.read(loggingRepositoryProvider);

    try {
      final outcome = await repository.logSession(state.toRequest());

      // O peso vai depois da sessão e num request separado: se ele falhar, o treino já está
      // salvo — que é o que não pode se perder.
      final measurement = state.toMeasurementRequest();
      if (measurement != null) {
        await repository.logMeasurement(measurement);
      }

      // Limpa o formulário mas mantém a data: registrar duas sessões no mesmo dia é comum.
      state = LogSessionForm(date: state.date);
      ref.invalidate(sessionHistoryProvider);

      return outcome == WriteOutcome.sent
          ? const SubmitSent()
          : const SubmitQueued();
    } on ApiException catch (e) {
      return SubmitFailed(e.message);
    }
  }
}

final logSessionProvider =
    NotifierProvider<LogSessionController, LogSessionForm>(
      LogSessionController.new,
    );
