import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/jobs/generation_controller.dart';
import '../../core/jobs/job_status.dart';
import '../../core/providers.dart';
import 'data/diet_models.dart';
import 'data/diet_repository.dart';

final dietRepositoryProvider = Provider<DietRepository>(
  (ref) => DietRepository(ref.watch(apiClientProvider)),
);

/// Dieta ativa. Null = ainda não gerou nenhuma.
final activeDietPlanProvider = FutureProvider<DietPlan?>(
  (ref) => ref.watch(dietRepositoryProvider).active(),
);

class DietGenerationController extends JobGenerationController {
  @override
  Future<String> enqueue() => ref.read(dietRepositoryProvider).generate();

  @override
  Future<void> reload() async {
    ref.invalidate(activeDietPlanProvider);
    await ref.read(activeDietPlanProvider.future);
  }

  @override
  String get startingLabel => 'Calculando suas metas…';

  @override
  String get genericFailure => 'A geração falhou. Tente novamente.';

  @override
  String stepLabel(JobState state) => switch (state) {
    JobState.pending => 'Na fila…',
    JobState.processing => 'Montando suas refeições…',
    _ => 'Finalizando…',
  };
}

final dietGenerationProvider =
    NotifierProvider<DietGenerationController, GenerationState>(
      DietGenerationController.new,
    );
