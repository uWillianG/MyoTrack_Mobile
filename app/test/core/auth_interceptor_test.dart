import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';
import 'package:myotrack/core/auth/token_store.dart';
import 'package:myotrack/core/network/auth_interceptor.dart';

/// TokenStore em memória — o real usa Keychain/KeyStore, indisponíveis em teste de unidade.
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
  }) async {
    _values.remove(key);
  }
}

void main() {
  late Map<String, String> storage;
  late TokenStore tokens;
  late Dio dio;
  late Dio refreshDio;
  late DioAdapter adapter;
  late DioAdapter refreshAdapter;
  late int sessionExpiredCalls;

  setUp(() async {
    storage = {
      'myotrack.accessToken': 'access-velho',
      'myotrack.refreshToken': 'refresh-valido',
    };
    tokens = TokenStore(storage: _InMemoryStorage(storage));
    sessionExpiredCalls = 0;

    dio = Dio(BaseOptions(baseUrl: 'http://localhost:8080'));
    refreshDio = Dio(BaseOptions(baseUrl: 'http://localhost:8080'));
    adapter = DioAdapter(dio: dio);
    refreshAdapter = DioAdapter(dio: refreshDio);

    dio.interceptors.add(
      AuthInterceptor(
        tokenStore: tokens,
        refreshClient: refreshDio,
        onSessionExpired: () async => sessionExpiredCalls++,
      ),
    );
  });

  test('anexa o access token no header Authorization', () async {
    String? sentHeader;
    adapter.onGet('/api/profile', (server) {
      sentHeader = 'capturado';
      server.reply(200, {'ok': true});
    }, headers: {'Authorization': 'Bearer access-velho'});

    await dio.get<dynamic>('/api/profile');
    expect(sentHeader, 'capturado');
  });

  test('não manda token para os endpoints de /api/auth', () async {
    adapter.onPost(
      '/api/auth/login',
      (server) => server.reply(200, {'accessToken': 'a', 'refreshToken': 'b'}),
      data: {'email': 'x@y.com', 'password': 'z'},
    );

    final response = await dio.post<dynamic>(
      '/api/auth/login',
      data: {'email': 'x@y.com', 'password': 'z'},
    );
    expect(response.statusCode, 200);
  });

  test('no 401, renova a sessão e repete a requisição', () async {
    var profileCalls = 0;
    adapter.onGet('/api/profile', (server) {
      profileCalls++;
      // Primeira chamada com o token velho: 401. Depois da renovação: 200.
      if (profileCalls == 1) {
        server.reply(401, {'error': 'expirado'});
      } else {
        server.reply(200, {'nome': 'Willian'});
      }
    });
    refreshAdapter.onGet(
      '/api/profile',
      (server) => server.reply(200, {'nome': 'Willian'}),
    );
    refreshAdapter.onPost(
      '/api/auth/refresh',
      (server) => server.reply(200, {
        'accessToken': 'access-novo',
        'refreshToken': 'refresh-novo',
      }),
      data: {'refreshToken': 'refresh-valido'},
    );

    final response = await dio.get<dynamic>('/api/profile');

    expect(response.statusCode, 200);
    // A sessão renovada foi persistida.
    expect(storage['myotrack.accessToken'], 'access-novo');
    expect(storage['myotrack.refreshToken'], 'refresh-novo');
    expect(sessionExpiredCalls, 0);
  });

  test('refresh inválido limpa a sessão e avisa uma vez', () async {
    adapter.onGet(
      '/api/profile',
      (server) => server.reply(401, {'error': 'expirado'}),
    );
    refreshAdapter.onPost(
      '/api/auth/refresh',
      (server) =>
          server.reply(401, {'error': 'Refresh token inválido ou expirado.'}),
      data: {'refreshToken': 'refresh-valido'},
    );

    await expectLater(
      dio.get<dynamic>('/api/profile'),
      throwsA(isA<DioException>()),
    );

    expect(storage['myotrack.accessToken'], isNull);
    expect(storage['myotrack.refreshToken'], isNull);
    expect(sessionExpiredCalls, 1);
  });

  test(
    'requisições paralelas com 401 renovam UMA vez só — o backend rotaciona o refresh token',
    () async {
      var refreshCalls = 0;
      var profileCalls = 0;

      adapter.onGet('/api/profile', (server) {
        profileCalls++;
        if (profileCalls <= 3) {
          server.reply(401, {'error': 'expirado'});
        } else {
          server.reply(200, {'nome': 'Willian'});
        }
      });
      refreshAdapter.onGet(
        '/api/profile',
        (server) => server.reply(200, {'nome': 'Willian'}),
      );
      refreshAdapter.onPost('/api/auth/refresh', (server) {
        refreshCalls++;
        server.reply(200, {
          'accessToken': 'access-novo',
          'refreshToken': 'refresh-novo',
        });
      }, data: {'refreshToken': 'refresh-valido'});

      // Três chamadas simultâneas, como a tela inicial dispara.
      await Future.wait([
        dio.get<dynamic>('/api/profile'),
        dio.get<dynamic>('/api/profile'),
        dio.get<dynamic>('/api/profile'),
      ]);

      // Se cada uma renovasse por conta própria, a segunda usaria um refresh já
      // revogado pelo backend e derrubaria a sessão do usuário.
      expect(refreshCalls, 1);
    },
  );

  test('não tenta renovar duas vezes para a mesma requisição', () async {
    adapter.onGet(
      '/api/profile',
      (server) => server.reply(401, {'error': 'expirado'}),
    );
    refreshAdapter.onGet(
      '/api/profile',
      (server) => server.reply(401, {'error': 'expirado'}),
    );

    var refreshCalls = 0;
    refreshAdapter.onPost('/api/auth/refresh', (server) {
      refreshCalls++;
      server.reply(200, {
        'accessToken': 'access-novo',
        'refreshToken': 'refresh-novo',
      });
    }, data: {'refreshToken': 'refresh-valido'});

    await expectLater(
      dio.get<dynamic>('/api/profile'),
      throwsA(isA<DioException>()),
    );

    // O retry também deu 401, mas a marca `retriedAfterRefresh` impede o laço infinito.
    expect(refreshCalls, 1);
  });
}
