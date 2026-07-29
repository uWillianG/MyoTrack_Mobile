import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';
import 'package:myotrack/core/auth/token_store.dart';
import 'package:myotrack/core/network/api_client.dart';
import 'package:myotrack/core/network/api_exception.dart';
import 'package:myotrack/features/reviews/review_controller.dart';

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
  late ReviewRepository repo;

  setUp(() {
    final dio = Dio(BaseOptions(baseUrl: 'http://localhost:8080'));
    adapter = DioAdapter(dio: dio);
    repo = ReviewRepository(
      ApiClient(
        tokenStore: TokenStore(storage: const _InMemoryStorage()),
        dio: dio,
        refreshDio: dio,
      ),
    );
  });

  group('fila', () {
    test('treino traz divisão, versão e o aluno', () async {
      adapter.onGet(
        '/api/reviews/workout-plans',
        (server) => server.reply(200, [
          {
            'id': 'p1',
            'name': 'Treino v2',
            'split': 'Upper/Lower',
            'goal': 'Hypertrophy',
            'version': 2,
            'createdAt': '2026-07-20T10:00:00Z',
            'student': 'aluno@exemplo.com',
          },
        ]),
      );

      final item = (await repo.pending(ReviewKind.workout)).single;

      expect(item.split, 'Upper/Lower');
      expect(item.version, 2);
      // O e-mail identifica de quem é o plano; sem ele a fila seria anônima.
      expect(item.student, 'aluno@exemplo.com');
    });

    test('dieta traz a meta calórica no lugar da divisão', () async {
      // Um modelo só serve as duas filas: os campos específicos vêm nulos no outro tipo.
      adapter.onGet(
        '/api/reviews/diet-plans',
        (server) => server.reply(200, [
          {
            'id': 'd1',
            'name': 'Dieta v1',
            'calorieGoal': 'Surplus',
            'version': 1,
            'createdAt': '2026-07-21T10:00:00Z',
            'targetKcal': 3100,
            'student': 'aluno@exemplo.com',
          },
        ]),
      );

      final item = (await repo.pending(ReviewKind.diet)).single;

      expect(item.targetKcal, 3100);
      expect(item.split, isNull);
    });

    test('sem o papel, o servidor recusa com 403', () async {
      // A tela esconde a área, mas quem decide é o servidor — este é o teste que garante
      // que a recusa dele chega como erro tratável.
      adapter.onGet(
        '/api/reviews/workout-plans',
        (server) =>
            server.reply(403, {'error': 'Você não tem permissão para isso.'}),
      );

      await expectLater(
        repo.pending(ReviewKind.workout),
        throwsA(
          isA<ApiException>().having((e) => e.statusCode, 'statusCode', 403),
        ),
      );
    });
  });

  group('decisão', () {
    test('aprovar manda status e observação', () async {
      adapter.onPost(
        '/api/reviews/workout-plans/p1',
        (server) => server.reply(204, null),
        data: {'status': 'Approved', 'note': 'Boa progressão.'},
      );

      await repo.decide(
        ReviewKind.workout,
        'p1',
        status: 'Approved',
        note: 'Boa progressão.',
      );
    });

    test('pedir mudanças na dieta', () async {
      adapter.onPost(
        '/api/reviews/diet-plans/d1',
        (server) => server.reply(204, null),
        data: {
          'status': 'ChangesRequested',
          'note': 'Proteína abaixo do alvo.',
        },
      );

      await repo.decide(
        ReviewKind.diet,
        'd1',
        status: 'ChangesRequested',
        note: 'Proteína abaixo do alvo.',
      );
    });

    test('o servidor recusa voltar ao estado inicial', () async {
      // NotReviewed é o estado de partida, não uma decisão: aceitá-lo deixaria o revisor
      // "desrevisar" um plano sem deixar rastro do porquê.
      adapter.onPost(
        '/api/reviews/workout-plans/p1',
        (server) => server.reply(400, {'error': 'Decisão inválida.'}),
        data: {'status': 'NotReviewed', 'note': null},
      );

      await expectLater(
        repo.decide(ReviewKind.workout, 'p1', status: 'NotReviewed'),
        throwsA(
          isA<ApiException>().having(
            (e) => e.message,
            'message',
            'Decisão inválida.',
          ),
        ),
      );
    });
  });
}
