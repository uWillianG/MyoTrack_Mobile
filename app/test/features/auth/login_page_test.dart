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
import 'package:myotrack/features/auth/login_page.dart';

/// O armazenamento real é Keychain/KeyStore, ausentes em teste de widget — e o login só
/// termina depois de gravar o par de tokens.
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
}

void main() {
  late DioAdapter adapter;
  late ApiClient api;

  const tokens = {'accessToken': 'a', 'refreshToken': 'r'};

  setUp(() {
    final dio = Dio(BaseOptions(baseUrl: 'http://localhost:8080'));
    adapter = DioAdapter(dio: dio);
    api = ApiClient(
      tokenStore: TokenStore(storage: _InMemoryStorage({})),
      dio: dio,
      refreshDio: dio,
    );

    // A tela pergunta quais provedores existem antes de desenhar. Sem esta rota a consulta
    // falharia e o teste passaria a medir o caminho de contingência.
    adapter.onGet(
      '/api/auth/providers',
      (server) => server.reply(200, {
        'google': false,
        'apple': false,
        'passwordReset': true,
      }),
    );
  });

  Future<void> pump(WidgetTester tester) async {
    // Uma tela de celular alto, e não os 800×600 do teste: o formulário de cadastro inteiro
    // cabe nela, que é como ele é usado. Na janela padrão o botão de enviar nasce abaixo da
    // dobra e cada teste viraria um exercício de rolagem.
    tester.view.physicalSize = const Size(400, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final router = GoRouter(
      initialLocation: '/login',
      routes: [
        GoRoute(path: '/login', builder: (_, _) => const LoginPage()),
        GoRoute(
          path: '/',
          builder: (_, _) => const Scaffold(body: Text('dentro do app')),
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
    await tester.pumpAndSettle();
  }

  Future<void> openRegister(WidgetTester tester) async {
    await tester.tap(find.text('Criar conta').first);
    await tester.pumpAndSettle();
  }

  Future<void> submit(WidgetTester tester, String label) async {
    await tester.tap(find.widgetWithText(FilledButton, label));
    await tester.pump();
  }

  Finder field(String label) => find.widgetWithText(TextFormField, label);

  testWidgets('o cadastro não sai do aparelho sem o nome', (tester) async {
    // Nenhuma rota de cadastro registrada no adapter: se a tela enviasse, o teste falharia
    // por resposta não encontrada em vez de pela mensagem abaixo.
    await pump(tester);
    await openRegister(tester);

    await tester.enterText(field('E-mail'), 'willian@exemplo.com');
    await tester.enterText(field('Senha'), 'Senha!Forte9');
    await tester.enterText(field('Confirmar senha'), 'Senha!Forte9');
    await submit(tester, 'Criar conta');

    expect(find.text('Informe seu nome.'), findsOneWidget);
  });

  testWidgets('uma inicial solta não é nome', (tester) async {
    await pump(tester);
    await openRegister(tester);

    await tester.enterText(field('Nome'), 'W');
    await tester.enterText(field('E-mail'), 'willian@exemplo.com');
    await tester.enterText(field('Senha'), 'Senha!Forte9');
    await tester.enterText(field('Confirmar senha'), 'Senha!Forte9');
    await submit(tester, 'Criar conta');

    expect(find.text('Nome muito curto.'), findsOneWidget);
  });

  testWidgets('o nome vai junto no cadastro, sem os espaços das pontas', (
    tester,
  ) async {
    adapter.onPost(
      '/api/auth/register',
      (server) => server.reply(200, tokens),
      data: {
        'email': 'willian@exemplo.com',
        'password': 'Senha!Forte9',
        'displayName': 'Willian',
      },
    );

    await pump(tester);
    await openRegister(tester);

    await tester.enterText(field('Nome'), '  Willian  ');
    await tester.enterText(field('E-mail'), 'willian@exemplo.com');
    await tester.enterText(field('Senha'), 'Senha!Forte9');
    await tester.enterText(field('Confirmar senha'), 'Senha!Forte9');
    await submit(tester, 'Criar conta');
    await tester.pumpAndSettle();

    expect(find.text('dentro do app'), findsOneWidget);
  });

  testWidgets('entrar não pede nome — o campo é do cadastro', (tester) async {
    // O campo continua montado enquanto está recolhido (é o que permite fechá-lo com
    // transição), então quem garante que ele não atrapalha o login é este caminho inteiro.
    adapter.onPost(
      '/api/auth/login',
      (server) => server.reply(200, tokens),
      data: {'email': 'willian@exemplo.com', 'password': 'senha-antiga'},
    );

    await pump(tester);

    await tester.enterText(field('E-mail'), 'willian@exemplo.com');
    await tester.enterText(field('Senha'), 'senha-antiga');
    await submit(tester, 'Entrar');
    await tester.pumpAndSettle();

    expect(find.text('dentro do app'), findsOneWidget);
  });

  testWidgets('trocar de modo não apaga o que já foi digitado', (tester) async {
    // Quem começou a se cadastrar e tocou em "Entrar" para conferir alguma coisa volta e
    // encontra o e-mail onde deixou. É o mesmo formulário, não duas telas.
    await pump(tester);
    await openRegister(tester);

    await tester.enterText(field('E-mail'), 'willian@exemplo.com');
    await tester.tap(find.text('Entrar').first);
    await tester.pumpAndSettle();
    await openRegister(tester);

    expect(find.text('willian@exemplo.com'), findsOneWidget);
  });

  testWidgets('o e-mail é conferido ao sair do campo, não só no envio', (
    tester,
  ) async {
    await pump(tester);

    await tester.enterText(field('E-mail'), 'willian');
    await tester.tap(field('Senha'));
    await tester.pumpAndSettle();

    expect(find.text('E-mail inválido.'), findsOneWidget);
  });
}
