import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';
import 'package:myotrack/core/auth/token_store.dart';
import 'package:myotrack/core/network/api_client.dart';
import 'package:myotrack/core/network/api_exception.dart';
import 'package:myotrack/features/billing/data/billing_repository.dart';

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
  late BillingRepository repo;

  setUp(() {
    final dio = Dio(BaseOptions(baseUrl: 'http://localhost:8080'));
    adapter = DioAdapter(dio: dio);
    repo = BillingRepository(
      ApiClient(
        tokenStore: TokenStore(storage: const _InMemoryStorage()),
        dio: dio,
        refreshDio: dio,
      ),
    );
  });

  Map<String, dynamic> statusJson({
    String plan = 'Free',
    String? provider,
    bool paymentPastDue = false,
    bool managedByStore = false,
    String? currentPeriodEnd,
  }) => {
    'plan': plan,
    'maxMealAnalysesPerDay': plan == 'Pro' ? 50 : 10,
    'maxVideoAnalysesPerDay': plan == 'Pro' ? 20 : 5,
    'maxCoachMessagesPerDay': plan == 'Pro' ? 50 : 10,
    'currentPeriodEnd': currentPeriodEnd,
    'provider': provider,
    'paymentPastDue': paymentPastDue,
    'managedByStore': managedByStore,
  };

  group('status', () {
    test('plano gratuito traz os limites do servidor', () async {
      // Os limites são configuráveis por ambiente; fixá-los no app mentiria no dia em que
      // forem ajustados.
      adapter.onGet(
        '/api/billing',
        (server) => server.reply(200, statusJson()),
      );

      final status = await repo.status();

      expect(status.isPro, isFalse);
      expect(status.maxMealAnalysesPerDay, 10);
      expect(status.managedByStore, isFalse);
    });

    test('assinatura de loja se declara gerenciada por ela', () async {
      // É o que faz a tela mostrar "cancele nos ajustes" em vez de um botão que não funciona.
      adapter.onGet(
        '/api/billing',
        (server) => server.reply(
          200,
          statusJson(
            plan: 'Pro',
            provider: 'AppStore',
            managedByStore: true,
            currentPeriodEnd: '2026-08-28T00:00:00Z',
          ),
        ),
      );

      final status = await repo.status();

      expect(status.isPro, isTrue);
      expect(status.provider, 'AppStore');
      expect(status.managedByStore, isTrue);
      expect(status.currentPeriodEnd, startsWith('2026-08-28'));
    });

    test('cobrança falhada é avisada sem tirar o acesso', () async {
      adapter.onGet(
        '/api/billing',
        (server) =>
            server.reply(200, statusJson(plan: 'Pro', paymentPastDue: true)),
      );

      final status = await repo.status();

      // Continua Pro durante a tolerância da loja: cortar antes puniria quem só precisa
      // atualizar o cartão.
      expect(status.isPro, isTrue);
      expect(status.paymentPastDue, isTrue);
    });
  });

  group('validação do recibo', () {
    test('o Pro só vale depois da palavra do servidor', () async {
      adapter.onPost(
        '/api/billing/apple/verify',
        (server) =>
            server.reply(200, statusJson(plan: 'Pro', provider: 'AppStore')),
        data: {
          'receipt': 'recibo-da-apple',
          'productId': 'myotrack.pro.monthly',
        },
      );

      final status = await repo.verifyReceipt(
        store: 'apple',
        receipt: 'recibo-da-apple',
        productId: 'myotrack.pro.monthly',
      );

      expect(status.isPro, isTrue);
    });

    test('recibo recusado não libera nada', () async {
      // O benefício nunca vem da palavra do cliente: sem validação, o Pro estaria a um
      // recibo forjado de distância.
      adapter.onPost(
        '/api/billing/google/verify',
        (server) =>
            server.reply(400, {'error': 'Não foi possível validar a compra.'}),
        data: {'receipt': 'forjado', 'productId': null},
      );

      await expectLater(
        repo.verifyReceipt(store: 'google', receipt: 'forjado'),
        throwsA(
          isA<ApiException>()
              .having((e) => e.statusCode, 'statusCode', 400)
              .having((e) => e.isRetryable, 'isRetryable', isFalse),
        ),
      );
    });

    test(
      'ambiente sem verificador responde 503, e isso é reprocessável',
      () async {
        // 503 é o servidor sem verificador configurado. Diferente do 400: aqui a compra pode
        // ser válida, então a pendência deve continuar para tentar de novo.
        adapter.onPost(
          '/api/billing/apple/verify',
          (server) => server.reply(503, {
            'error': 'Pagamentos ainda não estão disponíveis neste ambiente.',
          }),
          data: {'receipt': 'recibo', 'productId': null},
        );

        await expectLater(
          repo.verifyReceipt(store: 'apple', receipt: 'recibo'),
          throwsA(
            isA<ApiException>().having(
              (e) => e.isRetryable,
              'isRetryable',
              isTrue,
            ),
          ),
        );
      },
    );
  });
}
