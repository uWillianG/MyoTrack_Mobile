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
    String? illustratedPhotoUrl,
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
    'illustratedPhotoUrl': illustratedPhotoUrl,
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

  group('análise ilustrada', () {
    test('o modo vai como campo do multipart', () async {
      // É multipart, não JSON: o booleano viaja como texto.
      adapter.onPost(
        '/api/meal-analyses',
        (server) => server.reply(202, {'jobId': 'job-2'}),
        data: Matchers.any,
      );

      expect(
        await repo.analyze(
          photo: Uint8List.fromList([1]),
          fileName: 'refeicao.jpg',
          contentType: 'image/jpeg',
          illustrated: true,
        ),
        'job-2',
      );
    });

    test('quando existe, a foto anotada vem junto da original', () async {
      adapter.onGet(
        '/api/meal-analyses',
        (server) => server.reply(200, [
          analysisJson(
            illustratedPhotoUrl: 'https://storage/foto-ilustrada.jpg',
          ),
        ]),
        queryParameters: {'limit': 30},
      );

      final meal = (await repo.recent()).single;

      expect(meal.illustratedPhotoUrl, contains('ilustrada'));
      expect(meal.photoUrl, isNotNull);
    });

    test('sem o modo ilustrado, só a original', () async {
      // Null é estado normal: o modo não foi pedido, ou o modelo de imagem não tinha cota
      // e o desenho local também falhou. A análise vale igual.
      adapter.onGet(
        '/api/meal-analyses',
        (server) => server.reply(200, [analysisJson()]),
        queryParameters: {'limit': 30},
      );

      expect((await repo.recent()).single.illustratedPhotoUrl, isNull);
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

  group('refeição sem foto', () {
    test('a estimativa por texto devolve um jobId, e não itens', () async {
      // É o ponto do endpoint: ele **não grava nada**. O que volta é um job, e os itens
      // chegam no `resultJson` dele para o usuário conferir antes de salvar.
      adapter.onPost(
        '/api/meal-analyses/estimate',
        (server) => server.reply(202, {'jobId': 'job-texto'}),
        data: {'text': '2 ovos fritos e um pão francês'},
      );

      expect(
        await repo.estimateFromText('2 ovos fritos e um pão francês'),
        'job-texto',
      );
    });

    test('a estimativa gasta a mesma cota da foto e devolve 429', () async {
      // Mesmo balde, por decisão de produto: uma chamada de IA é uma chamada de IA. O app
      // reconhece o 429 para oferecer o Pro, venha ele da foto ou do texto.
      adapter.onPost(
        '/api/meal-analyses/estimate',
        (server) => server.reply(429, {
          'error':
              'Limite diário de 10 análises de refeição atingido. Assine o Pro para ampliar.',
        }),
        data: Matchers.any,
      );

      await expectLater(
        repo.estimateFromText('2 ovos fritos'),
        throwsA(
          isA<ApiException>().having(
            (e) => e.isRateLimited,
            'isRateLimited',
            isTrue,
          ),
        ),
      );
    });

    test('o corpo da refeição manual não carrega total nenhum', () {
      // Sem adaptador: o que se prova aqui é o **contrato**, não a rota. É o total que o
      // diário soma, e o servidor recusa recebê-lo pronto justamente para que a soma não
      // possa divergir dos itens — um `totalKcal` que vazasse para o corpo passaria
      // despercebido até alguém comparar dois números na tela.
      final body = const MealManualRequest(
        items: [
          MealManualItem(
            description: 'Arroz branco cozido',
            foodItemId: 12,
            quantityG: 150,
          ),
        ],
      ).toJson();

      expect(body.keys, unorderedEquals(['items', 'createdAt']));
      expect(
        const MealManualItem(
          description: 'Arroz branco cozido',
          foodItemId: 12,
          quantityG: 150,
        ).toJson(),
        {
          'description': 'Arroz branco cozido',
          'foodItemId': 12,
          'quantityG': 150,
          // Zerados de propósito: com vínculo de catálogo o servidor os recalcula da tabela,
          // e sem vínculo o zero em kcal é o que o faz derivá-la dos macros.
          'kcal': 0,
          'proteinG': 0,
          'carbsG': 0,
          'fatG': 0,
        },
      );
    });

    test('a refeição manual devolve o que o servidor gravou', () async {
      adapter.onPost(
        '/api/meal-analyses/manual',
        (server) => server.reply(201, {
          ...analysisJson(photoUrl: null),
          'source': 'Manual',
          'analysisJobId': null,
        }),
        // `Matchers.any` como no ajuste com itens: o `toJson` do freezed deixa a lista com os
        // objetos Dart dentro (é o `jsonEncode` do Dio que os converte), e comparar isso com
        // um mapa literal falha por tipo, não por conteúdo. O corpo é conferido no teste acima.
        data: Matchers.any,
      );

      final saved = await repo.createManual(
        const MealManualRequest(
          items: [
            MealManualItem(
              description: 'Arroz branco cozido',
              foodItemId: 12,
              quantityG: 150,
            ),
          ],
        ),
      );

      // O que volta é o que o **servidor** gravou, com os totais somados lá — e não o
      // rascunho que subiu. Mostrar de volta o que o cliente calculou esconderia justamente
      // as correções que ele aplica.
      expect(saved.totalKcal, 393);
      expect(saved.isManual, isTrue);
      expect(saved.analysisJobId, isNull);
    });

    test('a busca no catálogo aceita o texto em branco', () async {
      // Em branco é o começo do catálogo, e é o que a folha mostra antes da primeira tecla:
      // uma lista vazia ali pareceria catálogo vazio.
      adapter.onGet(
        '/api/foods',
        (server) => server.reply(200, [
          {
            'id': 1,
            'name': 'Arroz branco cozido',
            'kcalPer100g': 128,
            'proteinPer100g': 2.5,
            'carbsPer100g': 28.1,
            'fatPer100g': 0.2,
            'fiberPer100g': 1.6,
            'source': 'TACO',
          },
        ]),
        queryParameters: {'q': '', 'limit': 30},
      );

      final foods = await repo.foods();

      expect(foods.single.name, 'Arroz branco cozido');
      // Por 100 g, e o nome do campo diz isso: é a regra de três que separa 128 de 192.
      expect(foods.single.kcalPer100g, 128);
      expect(foods.single.fiberPer100g, 1.6);
    });

    test('a origem vem do servidor, e não da ausência de foto', () async {
      // `photoUrl` nula não responde a pergunta: a retenção (LGPD) apaga a foto de análises
      // antigas e deixa o resultado para trás, então "nunca teve foto" e "a foto expirou"
      // chegam idênticas ao app.
      adapter.onGet(
        '/api/meal-analyses/a1',
        (server) => server.reply(200, {
          ...analysisJson(photoUrl: null),
          'source': 'Manual',
        }),
      );

      final meal = await repo.byId('a1');

      expect(meal.isManual, isTrue);
    });

    test('sem o campo source, a refeição não passa por manual', () async {
      // É o que uma versão anterior da API responde, e nela toda refeição era de foto.
      adapter.onGet(
        '/api/meal-analyses/a1',
        (server) => server.reply(200, analysisJson()),
      );

      expect((await repo.byId('a1')).isManual, isFalse);
    });
  });
}
