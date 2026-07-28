import 'package:dio/dio.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';
import 'package:myotrack/core/auth/token_store.dart';
import 'package:myotrack/core/db/local_database.dart';
import 'package:myotrack/core/network/api_client.dart';
import 'package:myotrack/core/network/api_exception.dart';
import 'package:myotrack/core/sync/sync_queue.dart';

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
  late LocalDatabase db;
  late DioAdapter adapter;
  late SyncQueue queue;

  setUp(() {
    db = LocalDatabase.forTesting(NativeDatabase.memory());

    final dio = Dio(BaseOptions(baseUrl: 'http://localhost:8080'));
    adapter = DioAdapter(dio: dio);
    queue = SyncQueue(
      ApiClient(
        tokenStore: TokenStore(storage: const _InMemoryStorage()),
        dio: dio,
        refreshDio: dio,
      ),
      db,
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

  test('replaceExercises troca o catálogo inteiro', () async {
    await db.replaceExercises([
      CachedExercisesCompanion.insert(
        id: const Value(1),
        name: 'Supino reto com barra',
        muscleGroup: 'Chest',
        equipment: 'Barbell',
      ),
    ]);
    expect((await db.exercises()).single.name, 'Supino reto com barra');

    // Exercício removido no servidor não pode continuar selecionável no aparelho.
    await db.replaceExercises([
      CachedExercisesCompanion.insert(
        id: const Value(2),
        name: 'Agachamento livre com barra',
        muscleGroup: 'Quadriceps',
        equipment: 'Barbell',
      ),
    ]);

    final rows = await db.exercises();
    expect(rows, hasLength(1));
    expect(rows.single.id, 2);
  });
}
