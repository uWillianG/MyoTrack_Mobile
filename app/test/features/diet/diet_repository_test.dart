import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';
import 'package:myotrack/core/auth/token_store.dart';
import 'package:myotrack/core/network/api_client.dart';
import 'package:myotrack/core/network/api_exception.dart';
import 'package:myotrack/features/diet/data/diet_models.dart';
import 'package:myotrack/features/diet/data/diet_repository.dart';

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
  late DietRepository repo;

  setUp(() {
    final dio = Dio(BaseOptions(baseUrl: 'http://localhost:8080'));
    adapter = DioAdapter(dio: dio);
    repo = DietRepository(
      ApiClient(
        tokenStore: TokenStore(storage: const _InMemoryStorage()),
        dio: dio,
        refreshDio: dio,
      ),
    );
  });

  group('dieta ativa', () {
    test('desserializa metas, totais e refeições', () async {
      adapter.onGet(
        '/api/diet-plans/active',
        (server) => server.reply(200, {
          'id': 'p1',
          'name': 'Dieta v2',
          'calorieGoal': 'Surplus',
          'version': 2,
          'reviewStatus': 'NotReviewed',
          'targets': {'kcal': 3048, 'proteinG': 148, 'carbsG': 423, 'fatG': 85},
          'totals': {
            'kcal': 2812,
            'proteinG': 174.8,
            'carbsG': 383.5,
            'fatG': 75.8,
          },
          'meals': [
            {
              'id': 'm1',
              'order': 1,
              'name': 'Café da manhã',
              'items': [
                {
                  'id': 'i1',
                  'foodItemId': 7,
                  'foodName': 'Tapioca (goma hidratada)',
                  'quantityG': 140,
                  'kcal': 336,
                  'proteinG': 0.0,
                  'carbsG': 84.0,
                  'fatG': 0.0,
                },
              ],
            },
          ],
        }),
      );

      final plan = await repo.active();

      expect(plan, isNotNull);
      expect(plan!.calorieGoal, 'Surplus');
      expect(plan.targets.kcal, 3048);
      // Macros vêm com uma casa decimal do backend; arredondar aqui perderia informação.
      expect(plan.totals.proteinG, 174.8);
      expect(
        plan.meals.single.items.single.foodName,
        'Tapioca (goma hidratada)',
      );
    });

    test('404 vira null — é quem ainda não gerou dieta, não erro', () async {
      adapter.onGet(
        '/api/diet-plans/active',
        (server) => server.reply(404, null),
      );

      expect(await repo.active(), isNull);
    });

    test('500 continua sendo erro', () async {
      adapter.onGet(
        '/api/diet-plans/active',
        (server) => server.reply(500, {'error': 'Falha interna.'}),
      );

      await expectLater(repo.active(), throwsA(isA<ApiException>()));
    });
  });

  group('geração', () {
    test('devolve o jobId', () async {
      adapter.onPost(
        '/api/diet-plans/generate',
        (server) => server.reply(202, {'jobId': 'job-1'}),
      );

      expect(await repo.generate(), 'job-1');
    });

    test('sem peso registrado o backend explica o que falta', () async {
      adapter.onPost(
        '/api/diet-plans/generate',
        (server) => server.reply(400, {
          'error': 'Registre seu peso corporal antes de gerar a dieta.',
        }),
      );

      // A mensagem precisa chegar intacta à tela: é ela que diz o que fazer.
      await expectLater(
        repo.generate(),
        throwsA(
          isA<ApiException>().having(
            (e) => e.message,
            'message',
            contains('peso corporal'),
          ),
        ),
      );
    });

    test('409 quando já existe uma geração em andamento', () async {
      adapter.onPost(
        '/api/diet-plans/generate',
        (server) => server.reply(409, {
          'error': 'Já existe uma geração de dieta em andamento.',
        }),
      );

      await expectLater(
        repo.generate(),
        throwsA(isA<ApiException>().having((e) => e.statusCode, 'status', 409)),
      );
    });
  });

  test('histórico lista as versões', () async {
    adapter.onGet(
      '/api/diet-plans',
      (server) => server.reply(200, [
        {
          'id': 'p2',
          'name': 'Dieta v2',
          'calorieGoal': 'Surplus',
          'status': 'Active',
          'version': 2,
          'targetKcal': 3048,
        },
        {
          'id': 'p1',
          'name': 'Dieta v1',
          'calorieGoal': 'Surplus',
          'status': 'Archived',
          'version': 1,
          'targetKcal': 3048,
        },
      ]),
    );

    final history = await repo.history();

    expect(history.map((p) => p.version), [2, 1]);
    expect(history.first.status, 'Active');
  });

  group('rótulos', () {
    test('traduzem os objetivos calóricos', () {
      expect(DietLabels.calorieGoal('Deficit'), 'Déficit calórico');
      expect(DietLabels.calorieGoal('Surplus'), 'Superávit calórico');
    });

    test('valor desconhecido aparece cru em vez de sumir da tela', () {
      expect(DietLabels.calorieGoal('Recomposition'), 'Recomposition');
    });
  });
}
