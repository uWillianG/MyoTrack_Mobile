import 'package:dio/dio.dart';
import 'package:drift/native.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';
import 'package:myotrack/core/auth/token_store.dart';
import 'package:myotrack/core/db/local_database.dart';
import 'package:myotrack/core/network/api_client.dart';
import 'package:myotrack/core/network/api_exception.dart';
import 'package:myotrack/core/sync/sync_queue.dart';
import 'package:myotrack/core/sync/sync_scheduler.dart';

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

/// Conta os pedidos de esvaziamento sem envolver o WorkManager.
class _FakeScheduler implements SyncScheduler {
  int requests = 0;

  @override
  Future<void> requestFlush() async => requests++;
}

void main() {
  late LocalDatabase db;
  late DioAdapter adapter;
  late SyncQueue queue;
  late _FakeScheduler scheduler;

  setUp(() {
    db = LocalDatabase.forTesting(NativeDatabase.memory());
    scheduler = _FakeScheduler();

    final dio = Dio(BaseOptions(baseUrl: 'http://localhost:8080'));
    adapter = DioAdapter(dio: dio);
    queue = SyncQueue(
      ApiClient(
        tokenStore: TokenStore(storage: const _InMemoryStorage()),
        dio: dio,
        refreshDio: dio,
      ),
      db,
      scheduler: scheduler,
    );
  });

  tearDown(() => db.close());

  const body = {'date': '2026-07-27', 'sets': []};

  group('envio direto', () {
    test('com rede, sobe na hora e nada fica pendente', () async {
      adapter.onPost(
        '/api/sessions',
        (server) => server.reply(200, {'id': 's1'}),
        data: Matchers.any,
      );

      expect(await queue.submit('/api/sessions', body), WriteOutcome.sent);
      expect(await queue.pendingCount(), 0);
    });

    test('sem rede, guarda localmente em vez de perder o treino', () async {
      adapter.onPost(
        '/api/sessions',
        (server) => server.throws(
          -1,
          DioException.connectionError(
            requestOptions: RequestOptions(path: '/api/sessions'),
            reason: 'offline',
          ),
        ),
        data: Matchers.any,
      );

      expect(await queue.submit('/api/sessions', body), WriteOutcome.queued);
      expect(await queue.pendingCount(), 1);
    });

    test('500 também fica pendente — o servidor pode voltar', () async {
      adapter.onPost(
        '/api/sessions',
        (server) => server.reply(500, {'error': 'boom'}),
        data: Matchers.any,
      );

      expect(await queue.submit('/api/sessions', body), WriteOutcome.queued);
      expect(await queue.pendingCount(), 1);
    });

    test('400 propaga e NÃO entra na fila', () async {
      adapter.onPost(
        '/api/sessions',
        (server) =>
            server.reply(400, {'error': 'Registre pelo menos uma série.'}),
        data: Matchers.any,
      );

      // Enfileirar algo que o servidor recusa entupiria a fila para sempre: a mesma
      // requisição seria recusada de novo em toda tentativa.
      await expectLater(
        queue.submit('/api/sessions', body),
        throwsA(isA<ApiException>()),
      );
      expect(await queue.pendingCount(), 0);
    });
  });

  group('flush', () {
    test('envia o que estava pendente, em ordem de criação', () async {
      final enviados = <String>[];
      adapter.onPost('/api/sessions', (server) {
        enviados.add('sessao');
        server.reply(200, {'id': 's'});
      }, data: Matchers.any);
      adapter.onPost('/api/measurements', (server) {
        enviados.add('medida');
        server.reply(200, {'id': 'm'});
      }, data: Matchers.any);

      await db.enqueue('/api/sessions', '{"a":1}');
      await db.enqueue('/api/measurements', '{"b":2}');

      expect(await queue.flush(), 2);
      expect(enviados, ['sessao', 'medida']);
      expect(await queue.pendingCount(), 0);
    });

    test('para no primeiro erro de rede e mantém o resto na fila', () async {
      adapter.onPost(
        '/api/sessions',
        (server) => server.throws(
          -1,
          DioException.connectionError(
            requestOptions: RequestOptions(path: '/api/sessions'),
            reason: 'offline',
          ),
        ),
        data: Matchers.any,
      );

      await db.enqueue('/api/sessions', '{"a":1}');
      await db.enqueue('/api/sessions', '{"b":2}');

      expect(await queue.flush(), 0);
      // Insistir com a conexão caída só gastaria bateria.
      expect(await queue.pendingCount(), 2);
    });

    test('descarta o que o servidor recusa, para não travar a fila', () async {
      // Uma rota por corpo: o primeiro registro é inválido, o segundo é bom.
      adapter.onPost(
        '/api/sessions',
        (server) =>
            server.reply(400, {'error': 'Exercício inexistente na sessão.'}),
        data: {'ruim': true},
      );
      adapter.onPost(
        '/api/sessions',
        (server) => server.reply(200, {'id': 's2'}),
        data: {'bom': true},
      );

      await db.enqueue('/api/sessions', '{"ruim":true}');
      await db.enqueue('/api/sessions', '{"bom":true}');

      // Uma entrada permanentemente inválida na frente bloquearia todas as seguintes.
      expect(await queue.flush(), 1);
      expect(await queue.pendingCount(), 0);
    });

    test('o que foi recusado sai da fila mas não some', () async {
      // Este é o teste que o descarte não tinha: ele saía da fila, e pronto. O registro
      // evaporava — junto com o motivo, porque a linha que acabara de guardá-lo era apagada
      // em seguida. Um treino inteiro sumia sem nada na tela, e numa sincronização em
      // background isso acontecia com o app fechado.
      adapter.onPost(
        '/api/measurements',
        (server) => server.reply(422, {'error': 'Peso fora da faixa válida.'}),
        data: Matchers.any,
      );

      await db.enqueue(
        '/api/measurements',
        '{"date":"2026-07-28","weightKg":8}',
      );

      expect(await queue.flush(), 0);
      expect(await queue.pendingCount(), 0);

      final descartada = (await queue.discarded()).single;
      expect(descartada.endpoint, '/api/measurements');
      // O payload vai junto: é a diferença entre "um registro falhou" e "a pesagem do dia 28".
      expect(descartada.payload, contains('weightKg'));
      expect(descartada.error, contains('faixa'));
    });

    test('o 401 não vai para as recusadas — ele continua na fila', () async {
      adapter.onPost(
        '/api/sessions',
        (server) => server.reply(401, {'error': 'Sua sessão expirou.'}),
        data: Matchers.any,
      );

      await db.enqueue('/api/sessions', '{"a":1}');
      await queue.flush();

      // Avisar que o treino foi recusado quando ele só está esperando um login seria assustar
      // à toa — e pior, o texto do aviso manda refazer um registro que não se perdeu.
      expect(await queue.discarded(), isEmpty);
      expect(await queue.pendingCount(), 1);
    });

    test('dispensar o aviso apaga as recusadas', () async {
      await db.enqueue('/api/sessions', '{"a":1}');
      await db.discardPending((await db.pending()).single, 'recusado');
      expect(await queue.discarded(), hasLength(1));

      await queue.clearDiscarded();

      // O payload de uma escrita recusada é dado pessoal guardado sem prazo, e existia só
      // para poder ser mostrado uma vez.
      expect(await queue.discarded(), isEmpty);
    });

    test('401 mantém a escrita na fila — é sessão, não conteúdo', () async {
      // O 4xx que se descarta é o corpo recusado. O 401 é outra coisa: o treino continua
      // válido e sobe assim que houver login. Descartar aqui perderia o treino inteiro por
      // um token vencido, e em background isso aconteceria sem ninguém ver.
      adapter.onPost(
        '/api/sessions',
        (server) => server.reply(401, {'error': 'Sua sessão expirou.'}),
        data: Matchers.any,
      );

      await db.enqueue('/api/sessions', '{"a":1}');
      await db.enqueue('/api/sessions', '{"b":2}');

      expect(await queue.flush(), 0);
      expect(await queue.pendingCount(), 2);
      // A tentativa fica registrada para diagnóstico.
      expect((await db.pending()).first.attempts, 1);
    });
  });

  group('agendamento em background', () {
    test('escrita que fica pendente pede o esvaziamento', () async {
      adapter.onPost(
        '/api/sessions',
        (server) => server.throws(
          -1,
          DioException.connectionError(
            requestOptions: RequestOptions(path: '/api/sessions'),
            reason: 'offline',
          ),
        ),
        data: Matchers.any,
      );

      await queue.submit('/api/sessions', body);

      // É o que faz o sistema acordar o app quando a rede voltar; sem isto a fila só
      // andaria na próxima escrita do usuário.
      expect(scheduler.requests, 1);
    });

    test('escrita que sobe na hora não agenda nada', () async {
      adapter.onPost(
        '/api/sessions',
        (server) => server.reply(200, {'id': 's1'}),
        data: Matchers.any,
      );

      await queue.submit('/api/sessions', body);

      expect(scheduler.requests, 0);
    });
  });

  test('submit esvazia a fila antes de mandar o novo', () async {
    final ordem = <String>[];
    adapter.onPost('/api/sessions', (server) {
      ordem.add('pendente');
      server.reply(200, {'id': 'antigo'});
    }, data: {'antigo': true});
    adapter.onPost('/api/sessions', (server) {
      ordem.add('novo');
      server.reply(200, {'id': 'novo'});
    }, data: body);

    await db.enqueue('/api/sessions', '{"antigo":true}');
    expect(await queue.submit('/api/sessions', body), WriteOutcome.sent);

    // A ordem no servidor precisa bater com a ordem em que o usuário criou os registros.
    expect(ordem, ['pendente', 'novo']);
    expect(await queue.pendingCount(), 0);
  });

  test('watchPendingCount reflete o que entra e o que sai', () async {
    expect(await queue.watchPendingCount().first, 0);

    final id = await db.enqueue('/api/sessions', '{"a":1}');
    expect(await queue.watchPendingCount().first, 1);

    await db.removePending(id);
    expect(await queue.watchPendingCount().first, 0);
  });

  test('recordAttempt incrementa as tentativas', () async {
    final id = await db.enqueue('/api/sessions', '{"a":1}');

    await db.recordAttempt(id, 'falhou');
    await db.recordAttempt(id, 'falhou de novo');

    final row = (await db.pending()).single;
    expect(row.attempts, 2);
    expect(row.lastError, 'falhou de novo');
  });
}
