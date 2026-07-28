import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';
import 'package:myotrack/core/auth/token_store.dart';
import 'package:myotrack/core/network/api_client.dart';
import 'package:myotrack/core/network/api_exception.dart';
import 'package:myotrack/features/videos/data/video_repository.dart';

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
  late VideoRepository repo;

  setUp(() {
    final dio = Dio(BaseOptions(baseUrl: 'http://localhost:8080'));
    adapter = DioAdapter(dio: dio);
    repo = VideoRepository(
      ApiClient(
        tokenStore: TokenStore(storage: const _InMemoryStorage()),
        dio: dio,
        refreshDio: dio,
      ),
    );
  });

  group('exercícios avaliáveis', () {
    test('vêm do servidor, não embutidos no app', () async {
      // Um exercício novo no serviço de visão passa a aparecer sem publicar versão nova.
      adapter.onGet(
        '/api/video-analyses/supported-exercises',
        (server) => server.reply(200, [
          {'slug': 'squat', 'label': 'Agachamento'},
          {'slug': 'bench_press', 'label': 'Supino'},
        ]),
      );

      final options = await repo.exercises();

      expect(options, hasLength(2));
      expect(options.first.slug, 'squat');
      expect(options.first.label, 'Agachamento');
    });
  });

  group('envio em dois passos', () {
    test('a URL assinada vem com a chave que o passo 2 confirma', () async {
      adapter.onPost(
        '/api/video-analyses/presign',
        (server) => server.reply(200, {
          'mediaKey': 'videos/u1/v1.mp4',
          'uploadUrl': 'https://storage/put?sig=abc',
          'expiresInSeconds': 1800,
        }),
        data: {'contentType': 'video/mp4'},
      );

      final ticket = await repo.requestUpload('video/mp4');

      expect(ticket.mediaKey, 'videos/u1/v1.mp4');
      expect(ticket.uploadUrl, contains('sig=abc'));
    });

    test(
      'analyze devolve o jobId depois de o arquivo já estar no storage',
      () async {
        adapter.onPost(
          '/api/video-analyses',
          (server) => server.reply(202, {'jobId': 'job-9'}),
          data: {'mediaKey': 'videos/u1/v1.mp4', 'exercise': 'squat'},
        );

        expect(
          await repo.analyze(mediaKey: 'videos/u1/v1.mp4', exercise: 'squat'),
          'job-9',
        );
      },
    );

    test('limite diário vira ApiException já no pedido da URL', () async {
      // Recusar antes do upload é o ponto: o usuário não sobe 80 MB para descobrir depois.
      adapter.onPost(
        '/api/video-analyses/presign',
        (server) => server.reply(429, {
          'error':
              'Limite diário de 5 análises de vídeo atingido. Assine o Pro para ampliar.',
        }),
        data: {'contentType': 'video/mp4'},
      );

      await expectLater(
        repo.requestUpload('video/mp4'),
        throwsA(
          isA<ApiException>().having(
            (e) => e.isRateLimited,
            'isRateLimited',
            isTrue,
          ),
        ),
      );
    });
  });

  group('leitura do resultado', () {
    Map<String, dynamic> analysisJson({
      Object? score = 76,
      String? notEvaluableReason,
      String? overlayVideoUrl = 'https://storage/overlay.mp4',
    }) => {
      'id': 'a1',
      'analysisJobId': 'j1',
      'analyzedExercise': 'squat',
      'score': score,
      'repCount': 8,
      'result': {
        'issues': [
          {
            'code': 'insufficient_depth',
            'message': 'Profundidade insuficiente.',
            'timestampsSec': [3.2, 11.5],
          },
        ],
        'correctPoints': [
          {
            'code': 'excessive_trunk_lean',
            'message': 'Tronco firme na descida.',
          },
        ],
        'metrics': {'pose_coverage': 0.91, 'duration_sec': 24.3},
        'notEvaluableReason': ?notEvaluableReason,
      },
      'videoUrl': 'https://storage/v1.mp4',
      'overlayVideoUrl': overlayVideoUrl,
      'createdAt': '2026-07-28T12:30:00Z',
    };

    test('erros trazem os instantes para achar o trecho no vídeo', () async {
      adapter.onGet(
        '/api/video-analyses',
        (server) => server.reply(200, [analysisJson()]),
        queryParameters: {'limit': 20},
      );

      final analysis = (await repo.recent()).single;

      expect(analysis.score, 76);
      expect(analysis.repCount, 8);
      expect(analysis.result.issues.single.timestampsSec, [3.2, 11.5]);
      expect(analysis.result.correctPoints, hasLength(1));
    });

    test('score nulo é "não avaliado", e não zero', () async {
      // A diferença importa: zero afirma execução péssima, nulo afirma que não deu para ver.
      adapter.onGet(
        '/api/video-analyses',
        (server) => server.reply(200, [
          analysisJson(
            score: null,
            notEvaluableReason: 'Pose detectada em poucos frames.',
            overlayVideoUrl: null,
          ),
        ]),
        queryParameters: {'limit': 20},
      );

      final analysis = (await repo.recent()).single;

      expect(analysis.score, isNull);
      expect(analysis.result.notEvaluableReason, contains('poucos frames'));
      expect(analysis.overlayVideoUrl, isNull);
    });

    test('métricas novas do serviço não quebram o app', () async {
      // As heurísticas evoluem; um campo novo em metrics não pode exigir versão nova.
      adapter.onGet(
        '/api/video-analyses',
        (server) => server.reply(200, [
          {
            ...analysisJson(),
            'result': {
              'issues': [],
              'correctPoints': [],
              'metrics': {'metrica_que_ainda_nao_existia': 42},
            },
          },
        ]),
        queryParameters: {'limit': 20},
      );

      final analysis = (await repo.recent()).single;

      expect(analysis.result.metrics['metrica_que_ainda_nao_existia'], 42);
    });
  });
}
