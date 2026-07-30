import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';
import 'package:myotrack/core/auth/token_store.dart';
import 'package:myotrack/core/network/api_client.dart';
import 'package:myotrack/core/notifications/push_registration.dart';

/// Armazenamento em memória — o real usa Keychain/KeyStore, ausentes em teste de unidade.
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

/// Fonte de token controlável. No aparelho quem responde é o FCM.
class _FakeTokenSource implements PushTokenSource {
  /// Mutáveis em vez de parâmetros do construtor: cada teste ajusta só o que exercita, depois
  /// de o `setUp` já ter montado o registrador.
  bool granted = true;
  String? value = 'fcm-token-1';
  int permissionRequests = 0;

  @override
  Future<bool> requestPermission() async {
    permissionRequests++;
    return granted;
  }

  @override
  Future<String?> token() async => value;
}

void main() {
  late Dio dio;
  late DioAdapter adapter;
  late _FakeTokenSource tokens;
  late DeviceRegistrar registrar;

  setUp(() {
    dio = Dio(BaseOptions(baseUrl: 'http://localhost:8080'));
    adapter = DioAdapter(dio: dio);
    tokens = _FakeTokenSource();

    final api = ApiClient(
      tokenStore: TokenStore(storage: const _InMemoryStorage({})),
      dio: dio,
      refreshDio: dio,
    );
    registrar = DeviceRegistrar(api, tokens);

    // O desenvolvimento acontece no Windows; sem isto `defaultTargetPlatform` responderia
    // desktop e o registro sairia pelo caminho de "plataforma sem push".
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
  });

  tearDown(() => debugDefaultTargetPlatformOverride = null);

  group('registro do aparelho', () {
    test('manda o token e o wire name da plataforma', () async {
      // 'Android' e não 'android': é o wire name do enum DevicePlatform do backend, e o
      // errado volta 400 — que num login parece falha de autenticação.
      adapter.onPost(
        '/api/devices',
        (server) => server.reply(204, null),
        data: {'token': 'fcm-token-1', 'platform': 'Android'},
      );

      expect(await registrar.register(), isTrue);
    });

    test('no iOS manda "iOS"', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      adapter.onPost(
        '/api/devices',
        (server) => server.reply(204, null),
        data: {'token': 'fcm-token-1', 'platform': 'iOS'},
      );

      expect(await registrar.register(), isTrue);
    });

    test('sem autorização, não chama a API', () async {
      // No iOS a recusa é a resposta padrão do sistema: é caminho comum, não exceção. Sem a
      // guarda, o app registraria um token que nunca receberá nada.
      tokens.granted = false;

      expect(await registrar.register(), isFalse);
      // Nenhuma rota foi registrada no adapter: qualquer chamada aqui estouraria o teste.
    });

    test('autorizado mas sem token disponível, não chama a API', () async {
      // Janela real: a autorização é concedida e o FCM ainda não devolveu o token.
      tokens.value = null;

      expect(await registrar.register(), isFalse);
    });

    test('token vazio conta como ausente', () async {
      tokens.value = '';

      expect(await registrar.register(), isFalse);
    });

    test('em plataforma sem push, nem pede autorização', () async {
      // Desktop, no `flutter run -d windows`. Pedir permissão ali abriria um diálogo do sistema
      // por uma funcionalidade que não existe naquele alvo.
      debugDefaultTargetPlatformOverride = TargetPlatform.windows;

      expect(await registrar.register(), isFalse);
      expect(tokens.permissionRequests, 0);
    });

    test('falha da API não lança — o login precisa seguir', () async {
      // Este é o ponto: quem acabou de digitar a senha certa tem de chegar à tela inicial mesmo
      // que o registro de push falhe. O pior aceitável é ficar sem notificação até a próxima
      // abertura.
      adapter.onPost(
        '/api/devices',
        (server) => server.reply(500, {'error': 'boom'}),
        data: {'token': 'fcm-token-1', 'platform': 'Android'},
      );

      expect(await registrar.register(), isFalse);
    });
  });

  group('remoção ao sair da conta', () {
    test('manda o token no corpo do DELETE', () async {
      // Sem isto o aparelho seguiria recebendo notificação de quem saiu — e o token pertence ao
      // aparelho, então quem entrasse depois receberia no lugar.
      adapter.onDelete(
        '/api/devices',
        (server) => server.reply(204, null),
        data: {'token': 'fcm-token-1'},
      );

      await expectLater(registrar.unregister(), completes);
    });

    test('sem token, não chama a API', () async {
      tokens.value = null;

      await expectLater(registrar.unregister(), completes);
    });

    test('falha da API não impede sair da conta', () async {
      adapter.onDelete(
        '/api/devices',
        (server) => server.reply(500, {'error': 'boom'}),
        data: {'token': 'fcm-token-1'},
      );

      // O token de sessão é descartado de todo jeito; o registro órfão morre na próxima
      // tentativa de envio, quando o provedor o denunciar.
      await expectLater(registrar.unregister(), completes);
    });
  });

  test(
    'sem provedor configurado, a fonte padrão não autoriza nem devolve token',
    () async {
      // É o estado de hoje: não há projeto no Firebase. Devolver null em vez de lançar é o que
      // mantém o app inteiro funcionando sem push.
      const source = UnavailablePushTokens();

      expect(await source.requestPermission(), isFalse);
      expect(await source.token(), isNull);
    },
  );
}
