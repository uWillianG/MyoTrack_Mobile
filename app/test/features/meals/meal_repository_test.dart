import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';
import 'package:myotrack/core/auth/token_store.dart';
import 'package:myotrack/core/network/api_client.dart';
import 'package:myotrack/core/network/api_exception.dart';
import 'package:myotrack/features/meals/data/meal_models.dart';
import 'package:myotrack/features/meals/data/meal_repository.dart';

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
  late MealRepository repo;

  setUp(() {
    final dio = Dio(BaseOptions(baseUrl: 'http://localhost:8080'));
    adapter = DioAdapter(dio: dio);
    repo = MealRepository(
      ApiClient(
        tokenStore: TokenStore(storage: const _InMemoryStorage()),
        dio: dio,
        refreshDio: dio,
      ),
    );
  });

  Map<String, dynamic> analysisJson({
    bool userAdjusted = false,
    bool excludedFromDiary = false,
    String? photoUrl = 'https://storage/foto.jpg',
  }) => {
    'id': 'a1',
    'analysisJobId': 'j1',
    'items': [
      {
        'description': 'Arroz branco cozido',
        'foodItemId': 12,
        'quantityG': 150,
        'kcal': 195,
        'proteinG': 3.6,
        'carbsG': 42,
        'fatG': 0.3,
      },
      {
        'description': 'Filé de frango grelhado',
        'foodItemId': null,
        'quantityG': 120,
        'kcal': 198,
        'proteinG': 37.2,
        'carbsG': 0,
        'fatG': 4.3,
      },
    ],
    'totalKcal': 393,
    'totalProteinG': 40.8,
    'totalCarbsG': 42,
    'totalFatG': 4.6,
    'userAdjusted': userAdjusted,
    'excludedFromDiary': excludedFromDiary,
    'photoUrl': photoUrl,
    'createdAt': '2026-07-28T12:30:00Z',
  };

  group('envio da foto', () {
    test('devolve o jobId que a tela vai acompanhar', () async {
      adapter.onPost(
        '/api/meal-analyses',
        (server) => server.reply(202, {'jobId': 'job-1'}),
        data: Matchers.any,
      );

      final jobId = await repo.analyze(
        photo: Uint8List.fromList([1, 2, 3]),
        fileName: 'refeicao.jpg',
        contentType: 'image/jpeg',
      );

      expect(jobId, 'job-1');
    });

    test('limite diário vira ApiException com a mensagem do servidor', () async {
      // O backend responde 429 para o app poder oferecer o Pro em vez de só mostrar erro.
      adapter.onPost(
        '/api/meal-analyses',
        (server) => server.reply(429, {
          'error':
              'Limite diário de 10 análises de refeição atingido. Assine o Pro para ampliar.',
        }),
        data: Matchers.any,
      );

      await expectLater(
        repo.analyze(
          photo: Uint8List.fromList([1]),
          fileName: 'refeicao.jpg',
          contentType: 'image/jpeg',
        ),
        throwsA(
          isA<ApiException>()
              .having((e) => e.isRateLimited, 'isRateLimited', isTrue)
              .having((e) => e.message, 'message', contains('Assine o Pro')),
        ),
      );
    });
  });

  group('leitura', () {
    test('histórico traz itens e totais', () async {
      adapter.onGet(
        '/api/meal-analyses',
        (server) => server.reply(200, [analysisJson()]),
        queryParameters: {'limit': 30},
      );

      final meals = await repo.recent();

      expect(meals, hasLength(1));
      expect(meals.single.items, hasLength(2));
      expect(meals.single.totalKcal, 393);
      expect(meals.single.items.first.description, 'Arroz branco cozido');
      expect(meals.single.items.first.foodItemId, 12);
      // Sem vínculo com o catálogo é null, e não zero — zero seria um id.
      expect(meals.single.items.last.foodItemId, isNull);
    });

    test('foto expirada pela retenção não invalida a análise', () async {
      // A LGPD manda apagar a imagem; os macros continuam valendo, e a tela só esconde a
      // foto em vez de sumir com o registro.
      adapter.onGet(
        '/api/meal-analyses',
        (server) => server.reply(200, [analysisJson(photoUrl: null)]),
        queryParameters: {'limit': 30},
      );

      final meal = (await repo.recent()).single;

      expect(meal.photoUrl, isNull);
      expect(meal.totalKcal, 393);
    });

    test('inteiro e decimal são aceitos no mesmo campo', () async {
      // O backend serializa BigDecimal: o mesmo campo vem "42" ou "42.0" conforme o valor.
      adapter.onGet(
        '/api/meal-analyses',
        (server) => server.reply(200, [
          {...analysisJson(), 'totalKcal': 393.0, 'totalCarbsG': 42},
        ]),
        queryParameters: {'limit': 30},
      );

      final meal = (await repo.recent()).single;

      expect(meal.totalKcal, 393.0);
      expect(meal.totalCarbsG, 42);
    });
  });

  group('correção manual', () {
    test('tirar do diário manda só o campo que mudou', () async {
      adapter.onPut(
        '/api/meal-analyses/a1',
        (server) => server.reply(200, analysisJson(excludedFromDiary: true)),
        data: {'items': null, 'excludedFromDiary': true},
      );

      final updated = await repo.adjust(
        'a1',
        const MealAdjustRequest(excludedFromDiary: true),
      );

      expect(updated.excludedFromDiary, isTrue);
    });

    test('o total recalculado vem do servidor, não do cliente', () async {
      // O cliente manda itens; quem soma é o backend. Aqui a resposta traz 500 kcal e é
      // esse número que a tela passa a mostrar.
      adapter.onPut(
        '/api/meal-analyses/a1',
        (server) => server.reply(200, {
          ...analysisJson(userAdjusted: true),
          'totalKcal': 500,
        }),
        data: Matchers.any,
      );

      final updated = await repo.adjust(
        'a1',
        const MealAdjustRequest(
          items: [
            MealAnalysisItem(
              description: 'Arroz branco cozido',
              quantityG: 300,
              kcal: 390,
              proteinG: 7.2,
              carbsG: 84,
              fatG: 0.6,
            ),
          ],
        ),
      );

      expect(updated.totalKcal, 500);
      expect(updated.userAdjusted, isTrue);
    });
  });
}
