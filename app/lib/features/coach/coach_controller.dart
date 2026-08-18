import 'dart:async';

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

  /// A pergunta em voo: já enviada, e ainda ausente da lista que veio do servidor.
  ///
  /// **A tela desenha ela como um balão comum enquanto o job roda.** Sem isso a mensagem só
  /// aparecia junto com a resposta — dez, vinte segundos olhando uma conversa que não
  /// registrou o que a pessoa acabou de dizer, que é como se perde a confiança de que o envio
  /// funcionou. A pergunta já está salva no servidor nesse meio-tempo; o que falta é só a
  /// lista ser recarregada, e é isso que o balão cobre.
  ///
  /// Amarrada a `running` de propósito: o balão otimista sai de cena no mesmo instante em que
  /// o [reload] traz o verdadeiro, e não há uma janela em que os dois existam.
  String? get pending => state.running && _pending.isNotEmpty ? _pending : null;

  @override
  GenerationState build() {
    // Falhou **depois** de enfileirar? A pergunta já está gravada no servidor, e o balão
    // otimista some junto com o `running` — sem esta recarga ela sumiria da tela e só
    // reapareceria na próxima vez que a conversa fosse aberta.
    //
    // Quando a falha é do próprio envio (limite diário, resposta anterior em curso), nada foi
    // gravado e isto vira uma releitura à toa da lista. É barato, e a alternativa seria a tela
    // ter que adivinhar de que lado o erro nasceu.
    listenSelf((previous, next) {
      if (previous?.running == true && next.error != null) {
        ref.invalidate(coachMessagesProvider);
      }
    });

    return super.build();
  }

  /// Aceita a pergunta e devolve false quando não há o que mandar.
  ///
  /// **Responde na hora, sem esperar o coach.** Ela já esperou a resposta inteira, e o campo de
  /// texto só era limpo quando a conversa voltava do servidor — de dez a quarenta segundos com
  /// a pergunta escrita em dois lugares ao mesmo tempo, no balão e no campo desabilitado.
  ///
  /// O `start()` solto não perde falha nenhuma: ele guarda tudo o que dá errado no próprio
  /// estado, que é de onde a tela tira o snackbar.
  bool ask(String content) {
    final text = content.trim();
    if (text.isEmpty || state.running) {
      return false;
    }
    _pending = text;
    unawaited(start());
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
