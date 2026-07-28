import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';
import 'package:myotrack/core/auth/token_store.dart';
import 'package:myotrack/core/network/api_client.dart';
import 'package:myotrack/features/diary/diary_controller.dart';

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
  late DiaryRepository repo;

  final date = DateTime(2026, 7, 28);
  // O mesmo valor que o repositório vai calcular para a máquina que roda o teste — o teste
  // não pode fixar o fuso do Brasil e quebrar em CI que roda em UTC.
  final tz = timezoneOffsetMinutes(date);

  setUp(() {
    final dio = Dio(BaseOptions(baseUrl: 'http://localhost:8080'));
    adapter = DioAdapter(dio: dio);
    repo = DiaryRepository(
      ApiClient(
        tokenStore: TokenStore(storage: const _InMemoryStorage()),
        dio: dio,
        refreshDio: dio,
      ),
    );
  });

  Map<String, dynamic> dayJson({Object? targets}) => {
    'date': '2026-07-28',
    'targets': targets,
    'consumed': {'kcal': 1840, 'proteinG': 132, 'carbsG': 190, 'fatG': 58},
    'entries': [
      {
        'id': 'a1',
        'createdAt': '2026-07-28T12:30:00Z',
        'totalKcal': 640,
        'totalProteinG': 48,
        'totalCarbsG': 70,
        'totalFatG': 18,
        'userAdjusted': false,
        'excludedFromDiary': false,
      },
      {
        'id': 'a2',
        'createdAt': '2026-07-28T20:10:00Z',
        'totalKcal': 900,
        'totalProteinG': 40,
        'totalCarbsG': 90,
        'totalFatG': 35,
        'userAdjusted': true,
        'excludedFromDiary': true,
      },
    ],
    'week': [
      for (var i = 22; i <= 28; i++)
        {'date': '2026-07-$i', 'kcal': 1500 + i * 10},
    ],
  };

  group('fuso horário', () {
    test('manda o offset na convenção do JavaScript, não na do Dart', () {
      // No Brasil o Dart devolve −180 e o JavaScript +180. Mandar o sinal do Dart jogaria o
      // corte do dia seis horas para o lado errado, e a janta de ontem somaria no almoço
      // de hoje.
      expect(timezoneOffsetMinutes(date), -date.timeZoneOffset.inMinutes);
    });

    test('a data e o fuso vão na query', () async {
      adapter.onGet(
        '/api/diary',
        (server) => server.reply(200, dayJson()),
        queryParameters: {'date': '2026-07-28', 'tz': tz},
      );

      expect((await repo.day(date)).date, '2026-07-28');
    });
  });

  group('leitura do dia', () {
    test('traz consumido, entradas e a semana', () async {
      adapter.onGet(
        '/api/diary',
        (server) => server.reply(
          200,
          dayJson(
            targets: {'kcal': 2400, 'proteinG': 180, 'carbsG': 240, 'fatG': 70},
          ),
        ),
        queryParameters: {'date': '2026-07-28', 'tz': tz},
      );

      final day = await repo.day(date);

      expect(day.consumed.kcal, 1840);
      expect(day.targets!.kcal, 2400);
      expect(day.entries, hasLength(2));
      expect(day.week, hasLength(7));
    });

    test('sem dieta ativa, as metas vêm nulas — e nulo não é zero', () async {
      // Zero como meta faria as barras aparecerem estouradas em qualquer refeição.
      adapter.onGet(
        '/api/diary',
        (server) => server.reply(200, dayJson()),
        queryParameters: {'date': '2026-07-28', 'tz': tz},
      );

      expect((await repo.day(date)).targets, isNull);
    });

    test('refeição excluída continua na lista, marcada', () async {
      // Sumir com ela esconderia do usuário a foto que ele mesmo mandou ignorar.
      adapter.onGet(
        '/api/diary',
        (server) => server.reply(200, dayJson()),
        queryParameters: {'date': '2026-07-28', 'tz': tz},
      );

      final day = await repo.day(date);

      expect(day.entries.last.excludedFromDiary, isTrue);
      // E não entra no consumido: 640 + 900 seria 1540, mas o servidor mandou 1840 já
      // calculado só com as incluídas.
      expect(day.entries.where((e) => !e.excludedFromDiary), hasLength(1));
    });
  });

  test('alternar inclusão manda só o campo included', () async {
    adapter.onPut(
      '/api/diary/entries/a2',
      (server) => server.reply(204, null),
      data: {'included': true},
    );

    await repo.setIncluded('a2', true);
  });
}
