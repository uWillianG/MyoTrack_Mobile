import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../core/jobs/generation_controller.dart';
import '../../core/jobs/job_status.dart';
import '../../core/network/api_client.dart';
import '../../core/providers.dart';

part 'coach_controller.freezed.dart';
part 'coach_controller.g.dart';

/// Uma mensagem da conversa — `GET /api/coach/messages`.
@freezed
abstract class CoachMessage with _$CoachMessage {
  const factory CoachMessage({
    required String id,

    /// True = escrita pelo usuário; false = resposta do coach.
    @Default(false) bool fromUser,
    @Default('') String content,
    String? createdAt,
  }) = _CoachMessage;

  factory CoachMessage.fromJson(Map<String, dynamic> json) =>
      _$CoachMessageFromJson(json);
}

class CoachRepository {
  CoachRepository(this._api);

  final ApiClient _api;

  /// A conversa em ordem cronológica, como o servidor já devolve.
  Future<List<CoachMessage>> messages() async {
    final json = await _api.get<List<dynamic>>('/api/coach/messages');
    return json
        .map((e) => CoachMessage.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Manda a pergunta e devolve o `jobId` da resposta.
  Future<String> send(String content) async {
    final json = await _api.post<Map<String, dynamic>>(
      '/api/coach/messages',
      body: {'content': content},
    );
    return json['jobId'] as String;
  }
}

final coachRepositoryProvider = Provider<CoachRepository>(
  (ref) => CoachRepository(ref.watch(apiClientProvider)),
);

final coachMessagesProvider = FutureProvider<List<CoachMessage>>(
  (ref) => ref.watch(coachRepositoryProvider).messages(),
);

/// Manda a pergunta e espera a resposta chegar.
///
/// Reusa o [JobGenerationController] como as demais análises: o coach é mais um job na
/// mesma fila, e a chave de IA vive só no worker.
class CoachController extends JobGenerationController {
  String _pending = '';

  /// Devolve false quando não há o que mandar.
  Future<bool> ask(String content) async {
    final text = content.trim();
    if (text.isEmpty || state.running) {
      return false;
    }
    _pending = text;
    await start();
    return true;
  }

  @override
  Future<String> enqueue() => ref.read(coachRepositoryProvider).send(_pending);

  @override
  Future<void> reload() async {
    ref.invalidate(coachMessagesProvider);
    await ref.read(coachMessagesProvider.future);
    _pending = '';
  }

  @override
  String get startingLabel => 'Enviando…';

  @override
  String get genericFailure => 'O coach não respondeu. Tente de novo.';

  @override
  String stepLabel(JobState state) => switch (state) {
    JobState.pending => 'Na fila…',
    JobState.processing => 'O coach está pensando…',
    _ => 'Finalizando…',
  };
}

final coachProvider = NotifierProvider<CoachController, GenerationState>(
  CoachController.new,
);
