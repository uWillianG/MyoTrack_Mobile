import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';
import 'package:myotrack/core/auth/token_store.dart';
import 'package:myotrack/core/network/api_client.dart';
import 'package:myotrack/core/network/api_exception.dart';
import 'package:myotrack/features/reports/report_controller.dart';

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
  late ReportRepository repo;

  setUp(() {
    final dio = Dio(BaseOptions(baseUrl: 'http://localhost:8080'));
    adapter = DioAdapter(dio: dio);
    repo = ReportRepository(
      ApiClient(
        tokenStore: TokenStore(storage: const _InMemoryStorage()),
        dio: dio,
        refreshDio: dio,
      ),
    );
  });

  Map<String, dynamic> reportJson({
    Map<String, dynamic>? metrics,
    Object? narrative = const {
      'summary': 'Semana consistente, com volume acima da anterior.',
      'highlights': ['Três treinos completos.'],
      'recommendations': ['Registre o peso mais de uma vez na semana.'],
    },
  }) => {
    'id': 'r1',
    'weekStart': '2026-07-20',
    'metrics':
        metrics ??
        {
          'weekStart': '2026-07-20',
          'sessions': 3,
          'totalSets': 42,
          'totalVolumeKg': 18450.5,
          'volumeChangePercent': 12.4,
          'topExercise': 'Agachamento',
          'topExerciseVolumeKg': 5200.0,
          'weightStartKg': 84.0,
          'weightEndKg': 83.1,
          'weightChangeKg': -0.9,
          'mealsLogged': 9,
          'daysWithMealLogged': 4,
          'avgKcalPerLoggedDay': 2180,
        },
    'narrative': narrative,
    'createdAt': '2026-07-27T09:00:00Z',
  };

  test('lê métricas e narrativa do relatório mais recente', () async {
    adapter.onGet(
      '/api/reports/weekly',
      (server) => server.reply(200, reportJson()),
    );

    final report = (await repo.latest())!;

    expect(report.metrics.sessions, 3);
    expect(report.metrics.totalVolumeKg, 18450.5);
    expect(report.metrics.volumeChangePercent, 12.4);
    expect(report.metrics.topExercise, 'Agachamento');
    expect(report.narrative!.highlights, hasLength(1));
    expect(report.narrative!.recommendations, hasLength(1));
  });

  test('sem relatório ainda, 404 vira null e não erro', () async {
    // Quem instalou o app hoje não tem semana fechada. Tratar como falha encheria a tela de
    // aviso vermelho num estado perfeitamente normal.
    adapter.onGet('/api/reports/weekly', (server) => server.reply(404, null));

    expect(await repo.latest(), isNull);
  });

  test('sem IA configurada, o relatório vale pelos números', () async {
    // narrative nulo é estado normal, não erro: o servidor grava o relatório mesmo sem o
    // texto, porque as métricas são calculadas em código.
    adapter.onGet(
      '/api/reports/weekly',
      (server) => server.reply(200, reportJson(narrative: null)),
    );

    final report = (await repo.latest())!;

    expect(report.narrative, isNull);
    expect(report.metrics.sessions, 3);
  });

  test('campos nulos das métricas sobrevivem à desserialização', () async {
    // "Sem semana anterior", "uma pesagem só" e "nenhuma refeição" chegam como null, e o
    // card precisa distinguir isso de zero — zero afirmaria algo que não foi medido.
    adapter.onGet(
      '/api/reports/weekly',
      (server) => server.reply(
        200,
        reportJson(
          metrics: {
            'weekStart': '2026-07-20',
            'sessions': 1,
            'totalSets': 8,
            'totalVolumeKg': 2400,
            'volumeChangePercent': null,
            'topExercise': null,
            'weightChangeKg': null,
            'mealsLogged': 0,
            'daysWithMealLogged': 0,
            'avgKcalPerLoggedDay': null,
          },
        ),
      ),
    );

    final metrics = (await repo.latest())!.metrics;

    expect(metrics.volumeChangePercent, isNull);
    expect(metrics.topExercise, isNull);
    expect(metrics.weightChangeKg, isNull);
    expect(metrics.avgKcalPerLoggedDay, isNull);
    expect(metrics.sessions, 1);
  });

  test('erro de verdade continua sendo erro', () async {
    // Só o 404 vira null. Um 500 não pode virar "você não tem relatório".
    adapter.onGet(
      '/api/reports/weekly',
      (server) => server.reply(500, {'error': 'boom'}),
    );

    await expectLater(repo.latest(), throwsA(isA<ApiException>()));
  });
}
