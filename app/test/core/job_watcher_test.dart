import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myotrack/core/auth/token_store.dart';
import 'package:myotrack/core/jobs/job_watcher.dart';
import 'package:myotrack/core/network/api_client.dart';
import 'package:myotrack/core/network/api_exception.dart';

/// Armazenamento em memória — o real usa Keychain/KeyStore, indisponíveis em teste.
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

  @override
  Future<void> delete({
    required String key,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async => _values.remove(key);
}

/// Responde as requisições sem rede e guarda o que foi pedido.
///
/// Um adapter escrito à mão em vez de mock: o teste principal depende de o SSE **falhar**, e
/// é exatamente o comportamento do adapter nessa hora que estava sendo verificado errado.
class _RecordingAdapter implements HttpClientAdapter {
  _RecordingAdapter({
    required this.sseStatus,
    required this.jobResponses,
    this.sseStream,
  });

  /// Status devolvido em `/stream`. 400 reproduz o "multiple bearer tokens".
  final int sseStatus;

  /// Corpos devolvidos em `GET /api/jobs/{id}`, um por chamada.
  final List<Map<String, dynamic>> jobResponses;

  /// Corpo do SSE quando ele **aceita** a conexão. Um stream que não fecha reproduz o
  /// servidor segurando a conexão enquanto o job não anda, que é o caso em que a espera
  /// ficava sem prazo nenhum.
  final Stream<Uint8List>? sseStream;

  final List<RequestOptions> requests = [];
  int _pollCount = 0;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);

    if (options.path.endsWith('/stream')) {
      final aberto = sseStream;
      if (aberto != null) {
        return ResponseBody(
          aberto,
          200,
          headers: {
            Headers.contentTypeHeader: ['text/event-stream'],
          },
        );
      }
      return ResponseBody.fromString('', sseStatus);
    }

    final body = jobResponses[_pollCount.clamp(0, jobResponses.length - 1)];
    _pollCount++;
    return ResponseBody.fromString(
      jsonEncode(body),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

ApiClient _clientWith(_RecordingAdapter adapter) {
  final dio = Dio(BaseOptions(baseUrl: 'http://localhost:8080'))
    ..httpClientAdapter = adapter;
  final refreshDio = Dio()..httpClientAdapter = adapter;

  return ApiClient(
    tokenStore: TokenStore(
      storage: const _InMemoryStorage({
        'myotrack.accessToken': 'tok',
        'myotrack.refreshToken': 'ref',
      }),
    ),
    dio: dio,
    refreshDio: refreshDio,
  );
}

void main() {
  test('SSE recusado cai para polling e entrega o estado final', () async {
    // O defeito real: o servidor concluía o job e a tela mostrava erro genérico, porque a
    // falha do SSE escapava do `watch` em vez de acionar o polling.
    final adapter = _RecordingAdapter(
      sseStatus: 400,
      jobResponses: [
        {'id': 'j1', 'type': 'MealPhoto', 'status': 'Processing'},
        {
          'id': 'j1',
          'type': 'MealPhoto',
          'status': 'Completed',
          'resultJson': '{"mealAnalysisId":"m1"}',
        },
      ],
    );

    final states = await JobWatcher(_clientWith(adapter)).watch('j1').toList();

    expect(states.last.succeeded, isTrue);
    expect(
      adapter.requests.where((r) => r.path.contains('/api/jobs/j1')).length,
      greaterThan(1),
      reason: 'depois do SSE recusado, o polling precisa assumir',
    );
  });

  test('não manda o token na query do SSE', () async {
    // Header e query juntos fazem o Spring Security recusar com 400 antes de escolher um, e
    // o token ainda vazaria na URL, que vai para o log do sistema.
    final adapter = _RecordingAdapter(
      sseStatus: 400,
      jobResponses: [
        {'id': 'j1', 'type': 'MealPhoto', 'status': 'Failed', 'lastError': 'x'},
      ],
    );

    await JobWatcher(_clientWith(adapter)).watch('j1').toList();

    final sse = adapter.requests.firstWhere((r) => r.path.endsWith('/stream'));
    expect(sse.queryParameters.containsKey('access_token'), isFalse);
    expect(sse.headers['Authorization'], 'Bearer tok');
  });

  test('SSE aberto não faz a espera durar mais que o prazo', () async {
    // O defeito real: o teto de 2 minutos era do polling, e o SSE passava por baixo dele. Com
    // o stream aceito e o job parado na fila, quem mandava na espera era o servidor — 15
    // minutos de tela girando antes da primeira consulta. É o que se via como "trava".
    final aberto = StreamController<Uint8List>();
    addTearDown(aberto.close);

    final adapter = _RecordingAdapter(
      sseStatus: 200,
      sseStream: aberto.stream,
      jobResponses: [
        {'id': 'j1', 'type': 'MealPhoto', 'status': 'Pending'},
      ],
    );

    final relogio = Stopwatch()..start();

    await expectLater(
      JobWatcher(
        _clientWith(adapter),
      ).watch('j1', within: const Duration(milliseconds: 300)).toList(),
      throwsA(isA<ApiException>()),
    );

    expect(relogio.elapsed, lessThan(const Duration(seconds: 5)));
  });

  test('fila parada e job lento dão notícias diferentes', () async {
    // Insistir contra uma fila que ninguém processa só gasta a cota do dia, que é contada
    // por job enfileirado. As duas avarias giram a mesma barra e pedem conselhos opostos.
    Future<String> mensagemDe(String status) async {
      final aberto = StreamController<Uint8List>();
      addTearDown(aberto.close);

      final adapter = _RecordingAdapter(
        sseStatus: 200,
        sseStream: aberto.stream,
        jobResponses: [
          {'id': 'j1', 'type': 'MealPhoto', 'status': status},
        ],
      );

      try {
        await JobWatcher(
          _clientWith(adapter),
        ).watch('j1', within: const Duration(milliseconds: 200)).toList();
        return '';
      } on ApiException catch (e) {
        return e.message;
      }
    }

    expect(await mensagemDe('Pending'), contains('nada começou a processá-lo'));
    expect(await mensagemDe('Processing'), contains('demorou mais'));
  });

  test('o prazo esgotado ainda dá a última olhada no job', () async {
    // Sem esta consulta, um job que termina no segundo em que a espera acaba viraria erro
    // com o resultado pronto do outro lado.
    final aberto = StreamController<Uint8List>();
    addTearDown(aberto.close);

    final adapter = _RecordingAdapter(
      sseStatus: 200,
      sseStream: aberto.stream,
      jobResponses: [
        {
          'id': 'j1',
          'type': 'MealPhoto',
          'status': 'Completed',
          'resultJson': '{"items":[]}',
        },
      ],
    );

    final states = await JobWatcher(
      _clientWith(adapter),
    ).watch('j1', within: const Duration(milliseconds: 200)).toList();

    expect(states.last.succeeded, isTrue);
  });

  test('job que falha no servidor chega com a mensagem do backend', () async {
    final adapter = _RecordingAdapter(
      sseStatus: 400,
      jobResponses: [
        {
          'id': 'j1',
          'type': 'MealPhoto',
          'status': 'Failed',
          'lastError': 'A análise de refeição está indisponível no momento.',
        },
      ],
    );

    final states = await JobWatcher(_clientWith(adapter)).watch('j1').toList();

    expect(states.last.succeeded, isFalse);
    expect(states.last.lastError, contains('indisponível'));
  });
}
