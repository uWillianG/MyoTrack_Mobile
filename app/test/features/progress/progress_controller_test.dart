import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';
import 'package:myotrack/core/auth/token_store.dart';
import 'package:myotrack/core/network/api_client.dart';
import 'package:myotrack/features/progress/progress_controller.dart';

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
  late ProgressRepository repo;

  setUp(() {
    final dio = Dio(BaseOptions(baseUrl: 'http://localhost:8080'));
    adapter = DioAdapter(dio: dio);
    repo = ProgressRepository(
      ApiClient(
        tokenStore: TokenStore(storage: const _InMemoryStorage()),
        dio: dio,
        refreshDio: dio,
      ),
    );
  });

  Map<String, dynamic> suggestionJson({
    String action = 'Increase',
    Object? nextLoadKg = 62.5,
    int targetReps = 8,
    String? lastSessionDate = '2026-07-27',
  }) => {
    'workoutDayId': 'd1',
    'dayLabel': 'Treino A',
    'exerciseId': 12,
    'exerciseName': 'Supino reto',
    'sets': 3,
    'repsMin': 8,
    'repsMax': 12,
    'restSeconds': 90,
    'lastSessionDate': lastSessionDate,
    'lastSets': [
      {'reps': 12, 'loadKg': 60},
      {'reps': 12, 'loadKg': 60},
    ],
    'action': action,
    'nextLoadKg': nextLoadKg,
    'targetReps': targetReps,
    'incrementKg': 2.5,
  };

  test('lê a sugestão com carga, faixa e ação', () async {
    adapter.onGet(
      '/api/progress/suggestions',
      (server) => server.reply(200, [suggestionJson()]),
    );

    final suggestion = (await repo.suggestions()).single;

    expect(suggestion.exerciseId, 12);
    expect(suggestion.nextLoadKg, 62.5);
    expect(suggestion.action, 'Increase');
    expect(suggestion.hasHistory, isTrue);
  });

  group('a frase explica o porquê, não só o quanto', () {
    // O texto é o que faz a pessoa confiar no número em vez de achar que o app sorteou.
    test('subir a carga cita o topo da faixa', () {
      expect(
        ProgressSuggestion.fromJson(suggestionJson()).label,
        contains('topo da faixa'),
      );
    });

    test('manter a carga cita a meta de repetições', () {
      final suggestion = ProgressSuggestion.fromJson(
        suggestionJson(action: 'ProgressReps', targetReps: 12),
      );

      expect(suggestion.label, contains('12 repetições'));
    });

    test('série abaixo do mínimo pede consolidar', () {
      expect(
        ProgressSuggestion.fromJson(
          suggestionJson(action: 'Consolidate'),
        ).label,
        contains('consolide'),
      );
    });

    test('sem histórico, começa pela carga do plano', () {
      final suggestion = ProgressSuggestion.fromJson(
        suggestionJson(action: 'Start', lastSessionDate: null),
      );

      expect(suggestion.hasHistory, isFalse);
      expect(suggestion.label, contains('carga sugerida do plano'));
    });
  });

  test('sem carga sugerida, ainda há o que dizer', () async {
    // Exercício novo num plano que não trouxe carga: a frase sozinha orienta.
    adapter.onGet(
      '/api/progress/suggestions',
      (server) => server.reply(200, [
        suggestionJson(
          action: 'Start',
          nextLoadKg: null,
          lastSessionDate: null,
        ),
      ]),
    );

    final suggestion = (await repo.suggestions()).single;

    expect(suggestion.nextLoadKg, isNull);
    expect(suggestion.label, isNotEmpty);
  });

  test('plano sem exercícios devolve lista vazia, e não erro', () async {
    adapter.onGet(
      '/api/progress/suggestions',
      (server) => server.reply(200, []),
    );

    expect(await repo.suggestions(), isEmpty);
  });

  group('agregados do dashboard', () {
    test('volume traz a semana, o total e quantos treinos houve', () async {
      adapter.onGet(
        '/api/progress/volume',
        (server) => server.reply(200, [
          {'weekStart': '2026-07-20', 'volumeKg': 12400.5, 'sessions': 3},
          {'weekStart': '2026-07-27', 'volumeKg': 5000, 'sessions': 2},
        ]),
      );

      final volume = await repo.weeklyVolume();

      // A data vem sem fuso ("2026-07-20") e vira meia-noite local: um ISO com Z
      // deslocaria a semana de quem treina à noite no Brasil.
      expect(volume.first.weekStart, DateTime(2026, 7, 20));
      expect(volume.first.volumeKg, 12400.5);
      expect(volume.last.sessions, 2);
    });

    test('peso corporal vem em ordem crescente de data', () async {
      adapter.onGet(
        '/api/progress/weight',
        (server) => server.reply(200, [
          {'date': '2026-07-01', 'weightKg': 84},
          {'date': '2026-07-28', 'weightKg': 82.4},
        ]),
      );

      final points = await repo.weight();

      expect(points.first.date, DateTime(2026, 7, 1));
      expect(points.last.weightKg, 82.4);
    });

    test('recorde traz a carga máxima com as repetições daquela série', () async {
      adapter.onGet(
        '/api/progress/records',
        (server) => server.reply(200, [
          {
            'exerciseId': 12,
            'name': 'Supino reto',
            'maxLoadKg': 100,
            'maxLoadDate': '2026-07-27',
            'maxLoadReps': 3,
            'bestE1RmKg': 116.7,
            'e1RmReps': 5,
            'e1RmLoadKg': 100,
            'e1RmDate': '2026-07-20',
          },
        ]),
      );

      final record = (await repo.records()).single;

      // "100 kg" sozinho não diz se foram três repetições ou dez.
      expect(record.maxLoadReps, 3);
      expect(record.maxLoadDate, DateTime(2026, 7, 27));
      // O melhor 1RM raramente é a série mais pesada: 5×100 estima mais que 3×100.
      expect(record.bestE1RmKg, 116.7);
      expect(record.e1RmDate, DateTime(2026, 7, 20));
    });

    test('recorde sem 1RM estimado ainda é uma carga válida', () async {
      // Acontece quando as repetições não permitem estimativa; sumir com a linha seria
      // esconder um recorde real.
      adapter.onGet(
        '/api/progress/records',
        (server) => server.reply(200, [
          {'exerciseId': 12, 'name': 'Supino reto', 'maxLoadKg': 100},
        ]),
      );

      final record = (await repo.records()).single;

      expect(record.maxLoadKg, 100);
      expect(record.bestE1RmKg, isNull);
      expect(record.maxLoadDate, isNull);
    });
  });
}
