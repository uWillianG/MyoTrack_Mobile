import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';
import 'package:myotrack/core/auth/token_store.dart';
import 'package:myotrack/core/network/api_client.dart';
import 'package:myotrack/core/network/api_exception.dart';
import 'package:myotrack/features/privacy/privacy_controller.dart';

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
}

void main() {
  late DioAdapter adapter;
  late PrivacyRepository repo;

  setUp(() {
    final dio = Dio(BaseOptions(baseUrl: 'http://localhost:8080'));
    adapter = DioAdapter(dio: dio);
    repo = PrivacyRepository(
      ApiClient(
        tokenStore: TokenStore(storage: const _InMemoryStorage({})),
        dio: dio,
        refreshDio: dio,
      ),
    );
  });

  test('confirmação vai no corpo, nunca na URL', () async {
    // Senha em query string acaba no log do servidor e no histórico de proxies. É por isso
    // que o DELETE deste app aceita corpo.
    adapter.onDelete(
      '/api/privacy/account',
      (server) => server.reply(204, null),
      data: {'password': 'Tr0vao!Verde9'},
    );

    await repo.deleteAccount('Tr0vao!Verde9');
  });

  test('senha errada vira a mensagem do servidor', () async {
    adapter.onDelete(
      '/api/privacy/account',
      (server) => server.reply(400, {'error': 'Senha incorreta.'}),
      data: {'password': 'errada'},
    );

    await expectLater(
      repo.deleteAccount('errada'),
      throwsA(
        isA<ApiException>().having(
          (e) => e.message,
          'message',
          'Senha incorreta.',
        ),
      ),
    );
  });

  test('conta de login social confirma com o e-mail', () async {
    // Quem entrou com Google ou Apple não tem senha. Sem esta alternativa, o titular ficaria
    // sem como exercer o direito de eliminação — e a tela ficaria sem saída.
    adapter.onDelete(
      '/api/privacy/account',
      (server) => server.reply(204, null),
      data: {'password': 'willian@exemplo.com'},
    );

    await repo.deleteAccount('willian@exemplo.com');
  });

  group('export de dados', () {
    test('o pedido não leva destinatário', () async {
      // O servidor manda sempre para o e-mail da própria conta. Aceitar um endereço aqui
      // transformaria isto numa forma de exfiltrar os dados de quem deixasse a sessão aberta.
      adapter.onPost(
        '/api/privacy/export/email',
        (server) => server.reply(202, null),
        data: null,
      );

      await repo.emailExport();
    });

    test('ambiente sem SMTP responde 503 em vez de fingir que enviou', () async {
      // Este é um direito do titular: dizer "enviado" para um e-mail que nunca sai seria
      // pior que recusar.
      adapter.onPost(
        '/api/privacy/export/email',
        (server) => server.reply(503, {
          'error': 'O envio por e-mail não está disponível neste ambiente.',
        }),
        data: null,
      );

      await expectLater(
        repo.emailExport(),
        throwsA(
          isA<ApiException>()
              .having((e) => e.statusCode, 'statusCode', 503)
              .having((e) => e.isRetryable, 'isRetryable', isTrue),
        ),
      );
    });
  });

  test('confirmação errada em conta social explica o que digitar', () async {
    adapter.onDelete(
      '/api/privacy/account',
      (server) => server.reply(400, {
        'error': 'Para confirmar, digite o e-mail da sua conta.',
      }),
      data: {'password': 'qualquer'},
    );

    await expectLater(
      repo.deleteAccount('qualquer'),
      throwsA(
        isA<ApiException>().having(
          (e) => e.message,
          'message',
          contains('digite o e-mail'),
        ),
      ),
    );
  });
}
