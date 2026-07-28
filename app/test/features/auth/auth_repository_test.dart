import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';
import 'package:myotrack/core/auth/token_store.dart';
import 'package:myotrack/core/network/api_client.dart';
import 'package:myotrack/core/network/api_exception.dart';
import 'package:myotrack/features/auth/data/auth_repository.dart';

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

void main() {
  late Map<String, String> storage;
  late Dio dio;
  late DioAdapter adapter;
  late AuthRepository repo;

  const tokens = {'accessToken': 'access-1', 'refreshToken': 'refresh-1'};

  setUp(() {
    storage = {};
    dio = Dio(BaseOptions(baseUrl: 'http://localhost:8080'));
    adapter = DioAdapter(dio: dio);

    final api = ApiClient(
      tokenStore: TokenStore(storage: _InMemoryStorage(storage)),
      dio: dio,
      refreshDio: dio,
    );
    repo = AuthRepository(api);
  });

  group('providers', () {
    test('lê quais formas de login o servidor oferece', () async {
      adapter.onGet(
        '/api/auth/providers',
        (server) => server.reply(200, {
          'google': true,
          'apple': true,
          'passwordReset': false,
        }),
      );

      final providers = await repo.providers();

      expect(providers.google, isTrue);
      expect(providers.apple, isTrue);
      expect(providers.passwordReset, isFalse);
    });

    test(
      'campo ausente vira false — servidor antigo não conhece "apple"',
      () async {
        adapter.onGet(
          '/api/auth/providers',
          (server) =>
              server.reply(200, {'google': true, 'passwordReset': true}),
        );

        expect((await repo.providers()).apple, isFalse);
      },
    );
  });

  group('autenticação persiste a sessão', () {
    test('login grava o par de tokens', () async {
      adapter.onPost(
        '/api/auth/login',
        (server) => server.reply(200, tokens),
        data: {'email': 'a@b.com', 'password': 'Tr0vao!Verde9'},
      );

      await repo.login(email: 'a@b.com', password: 'Tr0vao!Verde9');

      expect(storage['myotrack.accessToken'], 'access-1');
      expect(storage['myotrack.refreshToken'], 'refresh-1');
    });

    test('cadastro grava o par de tokens', () async {
      adapter.onPost(
        '/api/auth/register',
        (server) => server.reply(200, tokens),
        data: {
          'email': 'a@b.com',
          'password': 'Tr0vao!Verde9',
          'displayName': 'Willian',
        },
      );

      await repo.register(
        email: 'a@b.com',
        password: 'Tr0vao!Verde9',
        displayName: 'Willian',
      );

      expect(storage['myotrack.accessToken'], 'access-1');
    });

    test('login com Google grava o par de tokens', () async {
      adapter.onPost(
        '/api/auth/google/id-token',
        (server) => server.reply(200, tokens),
        data: {'idToken': 'token-do-google'},
      );

      await repo.signInWithGoogle('token-do-google');

      expect(storage['myotrack.accessToken'], 'access-1');
    });

    test('login com Apple envia o nome junto — só há esta chance', () async {
      // A Apple entrega o nome apenas na primeira autorização, e fora do token.
      adapter.onPost(
        '/api/auth/apple/id-token',
        (server) => server.reply(200, tokens),
        data: {'idToken': 'token-da-apple', 'displayName': 'Willian Siqueira'},
      );

      await repo.signInWithApple(
        idToken: 'token-da-apple',
        displayName: 'Willian Siqueira',
      );

      expect(storage['myotrack.accessToken'], 'access-1');
    });

    test('nos logins seguintes da Apple o nome vai nulo', () async {
      adapter.onPost(
        '/api/auth/apple/id-token',
        (server) => server.reply(200, tokens),
        data: {'idToken': 'token-da-apple', 'displayName': null},
      );

      await repo.signInWithApple(idToken: 'token-da-apple');

      expect(storage['myotrack.accessToken'], 'access-1');
    });
  });

  group('falhas', () {
    test('credenciais inválidas viram a mensagem do backend', () async {
      adapter.onPost(
        '/api/auth/login',
        (server) => server.reply(401, {'error': 'Credenciais inválidas.'}),
        data: {'email': 'a@b.com', 'password': 'errada'},
      );

      await expectLater(
        repo.login(email: 'a@b.com', password: 'errada'),
        throwsA(
          isA<ApiException>().having(
            (e) => e.message,
            'message',
            'Credenciais inválidas.',
          ),
        ),
      );
      // Sessão não pode ter sido gravada.
      expect(storage, isEmpty);
    });

    test('erros de política de senha vêm todos, não só o primeiro', () async {
      adapter.onPost(
        '/api/auth/register',
        (server) => server.reply(400, {
          'errors': [
            'A senha precisa ter pelo menos um símbolo (ex.: !, @, #).',
            'Essa senha é muito comum — escolha outra, menos previsível.',
          ],
        }),
        data: {'email': 'a@b.com', 'password': 'senha123', 'displayName': null},
      );

      await expectLater(
        repo.register(email: 'a@b.com', password: 'senha123'),
        throwsA(
          isA<ApiException>().having((e) => e.errors.length, 'errors', 2),
        ),
      );
    });
  });

  group('recuperação de senha', () {
    test('devolve a mensagem neutra do servidor', () async {
      adapter.onPost(
        '/api/auth/forgot-password',
        (server) => server.reply(200, {
          'message':
              'Se houver uma conta com esse e-mail, o link de redefinição foi enviado.',
        }),
        data: {'email': 'a@b.com'},
      );

      // A mensagem é idêntica exista ou não a conta — a tela não deve deduzir nada dela.
      expect(
        await repo.forgotPassword('a@b.com'),
        contains('Se houver uma conta'),
      );
    });
  });

  test('logout apaga a sessão', () async {
    storage['myotrack.accessToken'] = 'access-1';
    storage['myotrack.refreshToken'] = 'refresh-1';

    await repo.logout();

    expect(storage, isEmpty);
  });
}
