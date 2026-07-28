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
}
