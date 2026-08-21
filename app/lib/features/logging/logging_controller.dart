import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import 'data/logging_models.dart';
import 'data/logging_repository.dart';

final loggingRepositoryProvider = Provider<LoggingRepository>(
  (ref) => LoggingRepository(
    ref.watch(apiClientProvider),
    ref.watch(syncQueueProvider),
  ),
);

final sessionHistoryProvider = FutureProvider<List<WorkoutSessionView>>(
  (ref) => ref.watch(loggingRepositoryProvider).sessions(),
);

/// Resultado do envio, para a tela decidir o que dizer.
///
/// Três respostas e não duas porque "não subiu" tem dois significados que a pessoa precisa
/// distinguir: a série guardada na fila sobe sozinha quando a rede voltar, e a recusada pelo
/// servidor não sobe nunca sem alguém mexer.
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
