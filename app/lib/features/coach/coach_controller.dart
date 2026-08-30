import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../core/jobs/generation_controller.dart';
import '../../core/jobs/job_status.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_exception.dart';
import '../../core/providers.dart';

part 'coach_controller.freezed.dart';
part 'coach_controller.g.dart';

/// Uma conversa da lista — `GET /api/coach/conversations`.
///
/// **A conversa é a unidade do coach, e não a mensagem.** Um fio único servia enquanto o app
/// tinha uma semana de uso; no segundo mês a dúvida sobre o ombro fica soterrada sob a dieta,
/// e não há como voltar a ela. Aqui cada assunto tem nome, data e um lugar na lista — que é
/// como qualquer chatbot se organiza, e pela mesma razão.
@freezed
abstract class CoachConversation with _$CoachConversation {
  const factory CoachConversation({
    required String id,

    /// O nome do assunto. Nasce da primeira pergunta e o servidor o reescreve com o que o
    /// modelo entendeu assim que a primeira resposta fica pronta.
    @Default('') String title,

    /// Quando a última mensagem entrou — é por ela que a lista ordena.
    String? updatedAt,

    /// Quantas mensagens ela tem. Não é enfeite: ao lado da data, é o que distingue uma
    /// pergunta solta de uma conversa em que se voltou três vezes.
    @Default(0) int messages,
  }) = _CoachConversation;

  factory CoachConversation.fromJson(Map<String, dynamic> json) =>
      _$CoachConversationFromJson(json);
}

/// Uma mensagem da conversa — `GET /api/coach/conversations/{id}/messages`.
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

/// O que o envio devolve: o job a acompanhar, e a conversa em que a pergunta caiu.
///
/// A conversa vem junto porque ela pode ter **acabado de nascer** — quem manda a primeira
/// pergunta de um assunto novo não tem id para mandar, e é a resposta do envio que diz qual
/// conversa a tela passou a ter aberta.
typedef SentQuestion = ({String jobId, String conversationId});

class CoachRepository {
  CoachRepository(this._api);

  final ApiClient _api;

  /// As conversas, da mais recente para a mais antiga — como o servidor já devolve.
  Future<List<CoachConversation>> conversations() async {
    final json = await _api.get<List<dynamic>>('/api/coach/conversations');
    return json
        .map((e) => CoachConversation.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// A conversa em ordem cronológica, como o servidor já devolve.
  Future<List<CoachMessage>> messages(String conversationId) async {
    final json = await _api.get<List<dynamic>>(
      '/api/coach/conversations/$conversationId/messages',
    );
    return json
        .map((e) => CoachMessage.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Manda a pergunta. Sem [conversationId], ela abre uma conversa nova.
  Future<SentQuestion> send(String content, {String? conversationId}) async {
    final json = await _api.post<Map<String, dynamic>>(
      '/api/coach/messages',
      // O `?` deixa a chave de fora quando não há conversa: é a diferença entre "manda para
      // esta" e "abre uma nova", e um `null` no corpo diria a terceira coisa.
      body: {'content': content, 'conversationId': ?conversationId},
    );
    return (
      jobId: json['jobId'] as String,
      conversationId: json['conversationId'] as String,
    );
  }

  Future<void> remove(String conversationId) =>
      _api.delete<void>('/api/coach/conversations/$conversationId');
}

final coachRepositoryProvider = Provider<CoachRepository>(
  (ref) => CoachRepository(ref.watch(apiClientProvider)),
);

final coachConversationsProvider = FutureProvider<List<CoachConversation>>(
  (ref) => ref.watch(coachRepositoryProvider).conversations(),
);

/// As mensagens da conversa aberta — vazia quando a conversa é nova.
///
/// Conversa nova não existe no servidor até a primeira pergunta ser enviada, e por isso não há
/// o que carregar: a lista vazia é o que faz a tela desenhar o convite em vez de um erro.
final coachMessagesProvider = FutureProvider<List<CoachMessage>>((ref) async {
  final open = ref.watch(openConversationProvider);
  if (open == null) {
    // **Espera a lista antes de dizer que não há nada.** Sem conversa aberta são dois casos
    // muito diferentes: quem nunca perguntou nada, e quem tem dez conversas e está sem rede.
    // Esperar aqui faz o segundo cair no erro da tela, com o botão de tentar de novo — e de
    // quebra tira o piscar do convite no instante antes de a conversa mais recente abrir.
    await ref.watch(coachConversationsProvider.future);
    return const [];
  }
  return ref.watch(coachRepositoryProvider).messages(open);
});

final openConversationProvider = NotifierProvider<OpenConversation, String?>(
  OpenConversation.new,
);

/// Qual conversa a tela mostra. `null` é a conversa **nova** — a que ainda não tem id.
///
/// **Ela abre na mais recente, e não em branco.** O coach não é um assistente ao qual se
/// chega com uma pergunta pronta: a dúvida nasce olhando a Hoje, e quase sempre é a
/// continuação do que já se estava conversando. Abrir sempre numa tela vazia esconderia a
/// conversa de ontem atrás de um botão e faria o recurso parecer que esqueceu tudo — que é
/// exatamente a impressão que as conversas separadas vieram desfazer.
class OpenConversation extends Notifier<String?> {
  /// True depois que alguém escolheu uma conversa — na lista, no botão de nova, ou mandando
  /// uma pergunta. Antes disso vale a mais recente, e quem diz qual é é o servidor.
  bool _chosen = false;

  @override
  String? build() {
    // **Escuta, e não observa.** A lista chega da rede depois de a tela já estar desenhada, e
    // é na chegada dela que a conversa mais recente vira a aberta. Um `watch` aqui refaria
    // esta decisão a cada recarga da lista — e jogaria de volta para a mais recente quem
    // estivesse lendo uma conversa antiga.
    ref.listen(coachConversationsProvider, (previous, next) {
      final conversations = next.valueOrNull;
      if (_chosen || conversations == null || conversations.isEmpty) {
        return;
      }
      state = conversations.first.id;
    }, fireImmediately: true);

    return null;
  }

  /// Abre uma conversa da lista; `null` começa uma nova.
  ///
  /// Reabrir a que já está aberta não é um evento: sem esta guarda, mandar uma pergunta na
  /// conversa corrente a "abriria" de novo e faria a tela recarregar as mensagens duas vezes.
  void open(String? id) {
    _chosen = true;
    if (state == id) {
      return;
    }
    state = id;
  }

  /// A conversa [id] deixou de existir.
  ///
  /// Se era a aberta, a tela volta a não ter escolha nenhuma — e a próxima lista que chegar a
  /// leva para a mais recente que sobrou, ou para o convite quando não sobrou nenhuma.
  void forget(String id) {
    if (state != id) {
      return;
    }
    _chosen = false;
    state = null;
  }
}

/// Manda a pergunta e espera a resposta chegar.
///
/// Reusa o [JobGenerationController] como as demais análises: o coach é mais um job na
/// mesma fila, e a chave de IA vive só no worker.
class CoachController extends JobGenerationController {
  String _pending = '';

  /// A conversa em que a pergunta em voo caiu — a aberta, ou a que o envio acabou de criar.
  String? _answering;

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
        _reopen();
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

  /// Apaga a conversa. O erro sai pelo mesmo snackbar de sempre.
  ///
  /// Recusa enquanto uma resposta está a caminho: o job responde numa conversa que já teria
  /// deixado de existir, e a pessoa veria a espera terminar em nada.
  Future<bool> remove(String id) async {
    if (state.running) {
      return false;
    }
    try {
      await ref.read(coachRepositoryProvider).remove(id);
      ref.read(openConversationProvider.notifier).forget(id);
      ref.invalidate(coachConversationsProvider);
      return true;
    } on ApiException catch (e) {
      state = GenerationState(error: e.message);
      return false;
    } catch (_) {
      state = const GenerationState(
        error: 'Não foi possível apagar a conversa.',
      );
      return false;
    }
  }

  @override
  Future<String> enqueue() async {
    final sent = await ref
        .read(coachRepositoryProvider)
        .send(_pending, conversationId: ref.read(openConversationProvider));

    // A pergunta pode ter aberto uma conversa nova: o id dela só existe a partir daqui.
    _answering = sent.conversationId;
    return sent.jobId;
  }

  @override
  Future<void> reload() async {
    _reopen();
    // O título e a ordem da lista mudaram: a conversa subiu para o topo, e se foi a primeira
    // resposta dela o servidor trocou o título provisório pelo assunto que o modelo leu.
    ref.invalidate(coachConversationsProvider);
    ref.invalidate(coachMessagesProvider);
    await ref.read(coachMessagesProvider.future);
    _pending = '';
  }

  /// Aponta a tela para a conversa que recebeu a pergunta.
  ///
  /// Vale para a conversa nova, que passa a ter id, e é inócuo para a que já estava aberta.
  void _reopen() {
    if (_answering case final id?) {
      ref.read(openConversationProvider.notifier).open(id);
      _answering = null;
    }
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
