import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';
import 'package:myotrack/core/auth/token_store.dart';
import 'package:myotrack/core/network/api_client.dart';
import 'package:myotrack/core/providers.dart';
import 'package:myotrack/features/auth/reset_password_page.dart';

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
  late ApiClient api;

  setUp(() {
    final dio = Dio(BaseOptions(baseUrl: 'http://localhost:8080'));
    adapter = DioAdapter(dio: dio);
    api = ApiClient(
      tokenStore: TokenStore(storage: const _InMemoryStorage()),
      dio: dio,
      refreshDio: dio,
    );
  });

  /// Monta a tela sob um roteador de verdade: os botões de saída usam `context.go`, que
  /// estoura sem um GoRouter na árvore.
  Future<void> pump(
    WidgetTester tester, {
    required String userId,
    required String token,
  }) async {
    final router = GoRouter(
      initialLocation: '/redefinir-senha',
      routes: [
        GoRoute(
          path: '/redefinir-senha',
          builder: (_, _) => ResetPasswordPage(userId: userId, token: token),
        ),
        GoRoute(
          path: '/login',
          builder: (_, _) => const Scaffold(body: Text('login')),
        ),
        GoRoute(
          path: '/esqueci-a-senha',
          builder: (_, _) => const Scaffold(body: Text('esqueci')),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [apiClientProvider.overrideWithValue(api)],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pump();
  }

  Future<void> fillAndSubmit(
    WidgetTester tester, {
    required String password,
    String? confirmation,
  }) async {
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Nova senha'),
      password,
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Confirmar nova senha'),
      confirmation ?? password,
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Redefinir senha'));
    await tester.pump();
  }

  testWidgets('link sem token não mostra o formulário', (tester) async {
    // Um link truncado no cliente de e-mail chega sem os parâmetros. Deixar digitar levaria
    // a pessoa a escolher uma senha duas vezes só para receber "link inválido" no fim.
    await pump(tester, userId: 'u1', token: '');

    expect(find.textContaining('Link inválido ou incompleto'), findsOneWidget);
    expect(find.text('Pedir novo link'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, 'Nova senha'), findsNothing);
  });

  testWidgets('senhas diferentes não chegam a sair do aparelho', (
    tester,
  ) async {
    // Nenhuma rota registrada no adapter: se a tela enviasse, o teste falharia por 404.
    await pump(tester, userId: 'u1', token: 't1');

    await fillAndSubmit(
      tester,
      password: 'Senha!Forte9',
      confirmation: 'Senha!Forte8',
    );

    expect(find.text('As senhas não conferem.'), findsOneWidget);
  });

  testWidgets('senha fraca é barrada pelas regras locais', (tester) async {
    // Aqui a composição vale, ao contrário do login: a senha está sendo criada agora.
    await pump(tester, userId: 'u1', token: 't1');

    await fillAndSubmit(tester, password: 'senha');

    expect(find.text('A senha não atende às regras abaixo.'), findsOneWidget);
  });

  testWidgets('envia uid e token do link junto da senha', (tester) async {
    adapter.onPost(
      '/api/auth/reset-password',
      (server) => server.reply(200, {
        'message': 'Senha redefinida. Entre com a nova senha.',
      }),
      // O uid e o token são a credencial inteira: sem eles o servidor recusa, e mandar os
      // errados redefiniria a senha de outra conta.
      data: {'userId': 'u1', 'token': 't1', 'password': 'Senha!Forte9'},
    );

    await pump(tester, userId: 'u1', token: 't1');
    await fillAndSubmit(tester, password: 'Senha!Forte9');
    await tester.pumpAndSettle();

    // Não autentica: o backend responde só uma mensagem, sem par de tokens. A tela confirma
    // e manda entrar com a senha nova.
    expect(
      find.text('Senha redefinida. Entre com a nova senha.'),
      findsOneWidget,
    );
    expect(find.text('Entrar com a nova senha'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, 'Nova senha'), findsNothing);
  });

  testWidgets('token expirado mostra a recusa do servidor', (tester) async {
    adapter.onPost(
      '/api/auth/reset-password',
      (server) => server.reply(400, {
        'error': 'Link inválido ou expirado. Peça um novo.',
      }),
      data: {'userId': 'u1', 'token': 't1', 'password': 'Senha!Forte9'},
    );

    await pump(tester, userId: 'u1', token: 't1');
    await fillAndSubmit(tester, password: 'Senha!Forte9');
    await tester.pumpAndSettle();

    expect(
      find.text('Link inválido ou expirado. Peça um novo.'),
      findsOneWidget,
    );
    // O formulário continua na tela: a pessoa pode pedir um link novo, não redigitar.
    expect(find.widgetWithText(FilledButton, 'Redefinir senha'), findsOneWidget);
  });
}
