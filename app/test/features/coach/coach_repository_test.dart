import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';
import 'package:myotrack/core/auth/token_store.dart';
import 'package:myotrack/core/network/api_client.dart';
import 'package:myotrack/core/network/api_exception.dart';
import 'package:myotrack/features/coach/coach_controller.dart';

class _InMemoryStorage extends FlutterSecureStorage {
  const _InMemoryStorage();

  @override
  Future<String?> read({
    required String key,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async => null;
}

void main() {
  late DioAdapter adapter;
  late CoachRepository repo;

  setUp(() {
    final dio = Dio(BaseOptions(baseUrl: 'http://localhost:8080'));
    adapter = DioAdapter(dio: dio);
    repo = CoachRepository(
      ApiClient(
        tokenStore: TokenStore(storage: const _InMemoryStorage()),
        dio: dio,
        refreshDio: dio,
      ),
    );
  });

  test('a conversa vem em ordem cronológica, pronta para desenhar', () async {
    // O servidor busca as 50 mais recentes e inverte. Se viessem ao contrário, a tela
    // mostraria a resposta antes da pergunta.
    adapter.onGet(
      '/api/coach/messages',
      (server) => server.reply(200, [
        {
          'id': 'm1',
          'fromUser': true,
          'content': 'Posso treinar com dor no ombro?',
          'createdAt': '2026-07-28T10:00:00Z',
        },
        {
          'id': 'm2',
          'fromUser': false,
          'content': 'Dor persistente merece avaliação de um profissional.',
          'createdAt': '2026-07-28T10:00:20Z',
        },
      ]),
    );

    final messages = await repo.messages();

    expect(messages.first.fromUser, isTrue);
    expect(messages.last.fromUser, isFalse);
    expect(messages.last.content, contains('profissional'));
  });

  test('enviar devolve o jobId que a tela acompanha', () async {
    adapter.onPost(
      '/api/coach/messages',
      (server) => server.reply(202, {'jobId': 'job-coach-1'}),
      data: {'content': 'O que comer depois do treino?'},
    );

    expect(await repo.send('O que comer depois do treino?'), 'job-coach-1');
  });

  test('uma pergunta por vez: a segunda é recusada com 409', () async {
    // Sem essa trava, três perguntas seguidas gerariam três jobs respondendo fora de ordem
    // e gastariam três chamadas de LLM.
    adapter.onPost(
      '/api/coach/messages',
      (server) =>
          server.reply(409, {'error': 'Aguarde a resposta anterior do coach.'}),
      data: {'content': 'e agora?'},
    );

    await expectLater(
      repo.send('e agora?'),
      throwsA(
        isA<ApiException>()
            .having((e) => e.statusCode, 'statusCode', 409)
            .having((e) => e.message, 'message', contains('Aguarde')),
      ),
    );
  });

  test('limite diário vira 429 com a oferta do Pro', () async {
    adapter.onPost(
      '/api/coach/messages',
      (server) => server.reply(429, {
        'error':
            'Limite diário de 10 mensagens ao coach atingido. Assine o Pro para ampliar.',
      }),
      data: {'content': 'mais uma'},
    );

    await expectLater(
      repo.send('mais uma'),
      throwsA(
        isA<ApiException>()
            .having((e) => e.isRateLimited, 'isRateLimited', isTrue)
            .having((e) => e.message, 'message', contains('Pro')),
      ),
    );
  });
}
