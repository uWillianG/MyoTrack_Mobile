import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';
import 'package:myotrack/core/auth/token_store.dart';
import 'package:myotrack/core/network/api_client.dart';
import 'package:myotrack/core/network/api_exception.dart';
import 'package:myotrack/features/workout/data/workout_repository.dart';

/// Armazenamento em memória — o real usa Keychain/KeyStore, ausentes em teste de unidade.
class _InMemoryStorage extends FlutterSecureStorage {
  const _InMemoryStorage(this._values);

  final Map<String, String> _values;

  @override
  Future<String?> read({
    required String key,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async => _values[key];

  @override
  Future<void> write({
    required String key,
    required String? value,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    if (value == null) {
      _values.remove(key);
    } else {
      _values[key] = value;
    }
  }
}

void main() {
  late DioAdapter adapter;
  late WorkoutRepository repo;

  setUp(() {
    final dio = Dio(BaseOptions(baseUrl: 'http://localhost:8080'));
    adapter = DioAdapter(dio: dio);
    repo = WorkoutRepository(
      ApiClient(
        tokenStore: TokenStore(storage: const _InMemoryStorage({})),
        dio: dio,
        refreshDio: dio,
      ),
    );
  });

  group('plano ativo', () {
    test('desserializa dias e exercícios em ordem', () async {
      adapter.onGet(
        '/api/workout-plans/active',
        (server) => server.reply(200, {
          'id': 'p1',
          'name': 'Treino ABC v2',
          'split': 'ABC',
          'goal': 'Hypertrophy',
          'version': 2,
          'reviewStatus': 'Approved',
          'reviewNote': null,
          'days': [
            {
              'id': 'd1',
              'order': 1,
              'label': 'A — Peito/Tríceps',
              'exercises': [
                {
                  'id': 'e1',
                  'exerciseId': 1,
                  'exerciseName': 'Supino reto com barra',
                  'muscleGroup': 'Chest',
                  'tutorialVideoUrl': null,
                  'sets': 4,
                  'repsMin': 8,
                  'repsMax': 12,
                  'restSeconds': 90,
                  'notes': 'Grupo priorizado',
                },
              ],
            },
          ],
        }),
      );

      final plan = await repo.active();

      expect(plan, isNotNull);
      expect(plan!.version, 2);
      expect(plan.reviewStatus, 'Approved');
      expect(plan.days.single.label, 'A — Peito/Tríceps');
      expect(plan.days.single.exercises.single.sets, 4);
      expect(plan.days.single.exercises.single.notes, 'Grupo priorizado');
    });

    test('404 vira null — é quem ainda não gerou treino, não erro', () async {
      adapter.onGet(
        '/api/workout-plans/active',
        (server) => server.reply(404, null),
      );

      expect(await repo.active(), isNull);
    });

    test('500 continua sendo erro — não pode virar "sem treino"', () async {
      adapter.onGet(
        '/api/workout-plans/active',
        (server) => server.reply(500, {'error': 'Falha interna.'}),
      );

      // Confundir os dois casos faria a tela oferecer "Gerar treino" a quem já tem um,
      // e uma regeneração acidental arquiva o plano em uso.
      await expectLater(repo.active(), throwsA(isA<ApiException>()));
    });

    test('campo desconhecido no JSON não quebra o app publicado', () async {
      adapter.onGet(
        '/api/workout-plans/active',
        (server) => server.reply(200, {
          'id': 'p1',
          'name': 'Treino AB',
          'split': 'AB',
          'goal': 'Hypertrophy',
          'campoNovoDoServidor': 42,
          'days': <dynamic>[],
        }),
      );

      final plan = await repo.active();

      expect(plan!.name, 'Treino AB');
      // Defaults cobrem o que o servidor não mandou.
      expect(plan.version, 1);
      expect(plan.reviewStatus, 'NotReviewed');
    });
  });

  group('geração', () {
    test('devolve o jobId para o JobWatcher acompanhar', () async {
      adapter.onPost(
        '/api/workout-plans/generate',
        (server) => server.reply(202, {'jobId': 'job-1'}),
      );

      expect(await repo.generate(), 'job-1');
    });

    test(
      '409 (geração já em andamento) chega com a mensagem do backend',
      () async {
        adapter.onPost(
          '/api/workout-plans/generate',
          (server) => server.reply(409, {
            'error': 'Já existe uma geração de treino em andamento.',
          }),
        );

        await expectLater(
          repo.generate(),
          throwsA(
            isA<ApiException>().having(
              (e) => e.message,
              'message',
              'Já existe uma geração de treino em andamento.',
            ),
          ),
        );
      },
    );

    test('sem perfil o backend responde 400 com a orientação certa', () async {
      adapter.onPost(
        '/api/workout-plans/generate',
        (server) => server.reply(400, {
          'error': 'Complete o onboarding antes de gerar o treino.',
        }),
      );

      await expectLater(
        repo.generate(),
        throwsA(
          isA<ApiException>().having(
            (e) => e.message,
            'message',
            contains('onboarding'),
          ),
        ),
      );
    });
  });

  test('histórico lista as versões', () async {
    adapter.onGet(
      '/api/workout-plans',
      (server) => server.reply(200, [
        {
          'id': 'p2',
          'name': 'Treino ABC v2',
          'split': 'ABC',
          'status': 'Active',
          'version': 2,
        },
        {
          'id': 'p1',
          'name': 'Treino ABC v1',
          'split': 'ABC',
          'status': 'Archived',
          'version': 1,
        },
      ]),
    );

    final history = await repo.history();

    expect(history.map((p) => p.version), [2, 1]);
    expect(history.first.status, 'Active');
  });
}
