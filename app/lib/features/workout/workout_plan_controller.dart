import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/jobs/generation_controller.dart';
import '../../core/jobs/job_status.dart';
import '../../core/providers.dart';
import 'data/workout_models.dart';
import 'data/workout_repository.dart';

final workoutRepositoryProvider = Provider<WorkoutRepository>(
  (ref) => WorkoutRepository(ref.watch(apiClientProvider)),
);

/// Plano ativo. Null = ainda não gerou nenhum.
final activeWorkoutPlanProvider = FutureProvider<WorkoutPlan?>(
  (ref) => ref.watch(workoutRepositoryProvider).active(),
);

/// Estado do botão "Gerar treino".
///
/// Fica separado do [activeWorkoutPlanProvider] de propósito: durante a geração a tela
/// continua mostrando o plano atual, em vez de piscar vazia por até um minuto.
class WorkoutGenerationController extends JobGenerationController {
  @override
  Future<String> enqueue() => ref.read(workoutRepositoryProvider).generate();

  @override
  Future<void> reload() async {
    ref.invalidate(activeWorkoutPlanProvider);
    await ref.read(activeWorkoutPlanProvider.future);
  }

  @override
  String get startingLabel => 'Enviando seu perfil…';

  @override
  String get genericFailure => 'A geração falhou. Tente novamente.';

  @override
  String stepLabel(JobState state) => switch (state) {
    JobState.pending => 'Na fila…',
    JobState.processing => 'Montando seu treino…',
    _ => 'Finalizando…',
  };
}

final workoutGenerationProvider =
    NotifierProvider<WorkoutGenerationController, GenerationState>(
      WorkoutGenerationController.new,
    );
