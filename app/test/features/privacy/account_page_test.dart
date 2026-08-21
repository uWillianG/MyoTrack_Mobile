import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:myotrack/core/auth/session.dart';
import 'package:myotrack/core/network/api_exception.dart';
import 'package:myotrack/core/providers.dart';
import 'package:myotrack/core/router.dart';
import 'package:myotrack/core/theme.dart';
import 'package:myotrack/features/billing/billing_controller.dart';
import 'package:myotrack/features/billing/data/billing_models.dart';
import 'package:myotrack/features/privacy/account_page.dart';
import 'package:myotrack/features/privacy/privacy_controller.dart';

class _MockPrivacyRepository extends Mock implements PrivacyRepository {}

/// Fecha a sessão sem tocar em Keychain nem em banco: aqui o que importa é **se** e **como**
/// ela foi fechada. O que ela apaga de verdade é assunto de `test/core/session_test.dart`.
class _SpyCloser implements SessionCloser {
  int closed = 0;
  bool? notifiedServer;

  @override
  Future<void> close({bool notifyServer = true}) async {
    closed++;
    notifiedServer = notifyServer;
  }
}

/// Recebe o arquivo no lugar da folha de compartilhamento do sistema.
class _SpySink implements ExportSink {
  String? filename;
  String? contents;

  @override
  Future<void> deliver(String filename, String contents) async {
    this.filename = filename;
    this.contents = contents;
  }
}

/// A tela da conta.
///
/// **O que se testa aqui é o que a revisão das lojas confere e o que a LGPD exige**, e as duas
/// coisas se resumem a uma: que os caminhos de sair, levar os dados embora e apagar a conta
/// continuem alcançáveis mesmo quando alguma parte da tela não carrega. A tela também é a
/// única do app que faz uma pergunta irreversível — daí a atenção ao que o diálogo pede, e a
/// quem ele pede.
void main() {
  late _MockPrivacyRepository repository;
  late _SpyCloser closer;
  late _SpySink sink;

  const comSenha = AccountSummary(
    email: 'ana@exemplo.com',
    createdAt: null,
    hasPassword: true,
  );

  setUp(() {
    repository = _MockPrivacyRepository();
    closer = _SpyCloser();
    sink = _SpySink();

    when(() => repository.consents()).thenAnswer((_) async => const []);
    when(() => repository.export()).thenAnswer((_) async => {'account': {}});
    when(() => repository.emailExport()).thenAnswer((_) async {});
    when(() => repository.deleteAccount(any())).thenAnswer((_) async {});
  });

  Future<void> pump(
    WidgetTester tester, {
    AsyncValue<AccountSummary> summary = const AsyncValue.data(comSenha),
    // Nulo deixa em pé o que o teste já tiver combinado com o repositório — é como o caso de
    // falha na leitura da trilha chega até aqui sem ser sobrescrito.
    List<ConsentEntry>? consents,
    int pending = 0,
    SubscriptionStatus subscription = const SubscriptionStatus(),
  }) async {
    // Alta o bastante para a tela inteira caber sem rolagem: o que se está medindo é o que a
    // tela mostra, não o quanto ela rola.
    tester.view.physicalSize = const Size(400, 2000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    if (consents != null) {
      when(() => repository.consents()).thenAnswer((_) async => consents);
    }

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          privacyRepositoryProvider.overrideWithValue(repository),
          sessionCloserProvider.overrideWithValue(closer),
          exportSinkProvider.overrideWithValue(sink),
          accountSummaryProvider.overrideWith(
            (ref) => switch (summary) {
              AsyncData(:final value) => Future.value(value),
              _ => Future<AccountSummary>.error(
                ApiException('O servidor falhou.'),
              ),
            },
          ),
          subscriptionStatusProvider.overrideWith((ref) async => subscription),
          userEmailProvider.overrideWith((ref) async => 'jwt@exemplo.com'),
          pendingWritesProvider.overrideWith((ref) => Stream.value(pending)),
        ],
        child: MaterialApp.router(
          theme: AppTheme.light(),
          // Roteador de verdade: sair e excluir terminam em `context.go`, e sem uma rota de
          // login para chegar o teste não distingue "foi embora" de "não fez nada".
          routerConfig: GoRouter(
            routes: [
              GoRoute(path: '/', builder: (_, _) => const AccountPage()),
              GoRoute(
                path: Routes.login,
                builder: (_, _) =>
                    const Scaffold(body: Center(child: Text('tela de login'))),
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  /// Abre o diálogo de exclusão.
  Future<void> abrirExclusao(WidgetTester tester) async {
    await tester.tap(
      find.widgetWithText(OutlinedButton, 'Excluir minha conta'),
    );
    await tester.pumpAndSettle();
  }

  group('sua conta', () {
    testWidgets('diz de qual conta se trata', (tester) async {
      // Num aparelho que já foi de outra pessoa, é a única forma de ter certeza antes de
      // apagar alguma coisa.
      await pump(
        tester,
        summary: AsyncValue.data(
          AccountSummary(
            email: 'ana@exemplo.com',
            createdAt: DateTime(2026, 3, 12),
            hasPassword: true,
          ),
        ),
      );

      expect(find.text('ana@exemplo.com'), findsOne);
      expect(find.text('No MyoTrack desde 12 de março de 2026'), findsOne);
    });

    testWidgets('sem o resumo, o e-mail vem do token', (tester) async {
      await pump(tester, summary: const AsyncValue.loading());

      // O JWT já carrega o e-mail, e chega sem rede: a tela diz de quem é a conta mesmo com
      // o servidor fora do ar.
      expect(find.text('jwt@exemplo.com'), findsOne);
    });
  });

  group('quando o resumo da conta não carrega', () {
    testWidgets('a exclusão continua na tela', (tester) async {
      // A falha de uma leitura secundária não pode tirar do titular o direito de apagar a
      // conta — nem esconder da revisão da loja o botão que ela veio conferir.
      await pump(tester, summary: const AsyncValue.loading());

      expect(
        find.widgetWithText(OutlinedButton, 'Excluir minha conta'),
        findsOne,
      );
      expect(find.widgetWithText(OutlinedButton, 'Sair da conta'), findsOne);
      expect(find.text('Baixar meus dados'), findsOne);
    });

    testWidgets('o diálogo volta a explicar as duas formas', (tester) async {
      await pump(tester, summary: const AsyncValue.loading());
      await abrirExclusao(tester);

      expect(find.widgetWithText(TextField, 'Senha ou e-mail'), findsOne);
      expect(find.textContaining('Google ou Apple'), findsOne);
    });
  });

  group('o diálogo de exclusão', () {
    testWidgets('pede a senha de quem tem uma', (tester) async {
      await pump(tester);
      await abrirExclusao(tester);

      expect(find.widgetWithText(TextField, 'Senha'), findsOne);
      expect(
        find.text('Para confirmar, digite a senha da sua conta.'),
        findsOne,
      );
    });

    testWidgets('pede o e-mail de quem entrou com Google ou Apple', (
      tester,
    ) async {
      await pump(
        tester,
        summary: const AsyncValue.data(
          AccountSummary(
            email: 'ana@exemplo.com',
            createdAt: null,
            hasPassword: false,
          ),
        ),
      );
      await abrirExclusao(tester);

      expect(find.widgetWithText(TextField, 'E-mail da conta'), findsOne);
      // Sem o olho de "mostrar senha": esconder o que se digita num campo que não é segredo
      // só atrapalha a conferência.
      expect(find.byIcon(Icons.visibility_off), findsNothing);
      expect(
        tester.widget<TextField>(find.byType(TextField)).obscureText,
        isFalse,
      );
    });

    testWidgets('campo vazio não apaga nada', (tester) async {
      await pump(tester);
      await abrirExclusao(tester);

      await tester.tap(find.widgetWithText(FilledButton, 'Excluir'));
      await tester.pumpAndSettle();

      verifyNever(() => repository.deleteAccount(any()));
      expect(find.text('Excluir a conta?'), findsOne);
    });

    testWidgets('o erro do servidor aparece, e a conta continua de pé', (
      tester,
    ) async {
      // É a mensagem do servidor que corrige o app quando ele pediu a coisa errada.
      when(
        () => repository.deleteAccount(any()),
      ).thenThrow(ApiException('Senha incorreta.', statusCode: 400));

      await pump(tester);
      await abrirExclusao(tester);
      await tester.enterText(find.byType(TextField), 'errada');
      await tester.tap(find.widgetWithText(FilledButton, 'Excluir'));
      await tester.pumpAndSettle();

      expect(find.text('Senha incorreta.'), findsOne);
      expect(closer.closed, 0);
    });

    testWidgets('apagar fecha a sessão e leva ao login', (tester) async {
      await pump(tester);
      await abrirExclusao(tester);
      await tester.enterText(find.byType(TextField), 'Tr0vao!Verde9');
      await tester.tap(find.widgetWithText(FilledButton, 'Excluir'));
      await tester.pumpAndSettle();

      verify(() => repository.deleteAccount('Tr0vao!Verde9')).called(1);
      expect(closer.closed, 1);
      // O servidor já apagou os registros de push junto com a conta: avisá-lo de novo seria
      // uma ida à rede com o token de uma conta que não existe mais.
      expect(closer.notifiedServer, isFalse);
      expect(find.text('tela de login'), findsOne);
    });
  });

  group('sair da conta', () {
    testWidgets('avisa o que ainda não subiu antes de descartar', (
      tester,
    ) async {
      // Sair apaga o que é da pessoa neste aparelho, e a fila vai junto: avisar antes é a
      // diferença entre descartar e perder.
      await pump(tester, pending: 2);

      await tester.tap(find.widgetWithText(OutlinedButton, 'Sair da conta'));
      await tester.pumpAndSettle();

      expect(find.textContaining('2 registros ainda não subiram'), findsOne);
      expect(closer.closed, 0);
    });

    testWidgets('sem fila pendente, não inventa um aviso', (tester) async {
      await pump(tester);

      await tester.tap(find.widgetWithText(OutlinedButton, 'Sair da conta'));
      await tester.pumpAndSettle();

      expect(find.textContaining('ainda não'), findsNothing);
    });

    testWidgets('confirmar encerra a sessão e leva ao login', (tester) async {
      await pump(tester);

      await tester.tap(find.widgetWithText(OutlinedButton, 'Sair da conta'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Sair'));
      await tester.pumpAndSettle();

      expect(closer.closed, 1);
      // Aqui o servidor precisa saber: o registro de push é do aparelho e sobreviveria à
      // saída, entregando notificação de quem saiu para quem entrar depois.
      expect(closer.notifiedServer, isTrue);
      expect(find.text('tela de login'), findsOne);
    });

    testWidgets('desistir não encerra nada', (tester) async {
      await pump(tester);

      await tester.tap(find.widgetWithText(OutlinedButton, 'Sair da conta'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(TextButton, 'Cancelar'));
      await tester.pumpAndSettle();

      expect(closer.closed, 0);
      expect(find.text('tela de login'), findsNothing);
    });
  });

  group('seus dados', () {
    testWidgets('baixar entrega o arquivo ao sistema', (tester) async {
      when(() => repository.export()).thenAnswer(
        (_) async => {'account': {}, 'workoutSessions': <dynamic>[]},
      );

      await pump(tester);
      await tester.tap(find.text('Baixar meus dados'));
      await tester.pumpAndSettle();

      verify(() => repository.export()).called(1);
      // O nome é o mesmo que o servidor dá ao anexo do e-mail: os dois caminhos entregam um
      // arquivo com a mesma cara.
      expect(sink.filename, matches(RegExp(r'^myotrack-dados-\d{8}\.json$')));
      expect(sink.contents, contains('workoutSessions'));
    });

    testWidgets('o que falha no caminho vira recado na tela', (tester) async {
      when(() => repository.export()).thenThrow(
        ApiException('Sem conexão com o servidor. Verifique sua internet.'),
      );

      await pump(tester);
      await tester.tap(find.text('Baixar meus dados'));
      await tester.pumpAndSettle();

      expect(find.byType(SnackBar), findsOne);
      expect(find.textContaining('Sem conexão'), findsOne);
    });

    testWidgets('o envio por e-mail continua existindo', (tester) async {
      await pump(tester);
      await tester.tap(find.text('Enviar para o e-mail da conta'));
      await tester.pumpAndSettle();

      verify(() => repository.emailExport()).called(1);
      expect(
        find.text('Enviamos seus dados para o e-mail da sua conta.'),
        findsOne,
      );
    });
  });

  group('o que você autorizou', () {
    testWidgets('lista o aceite com a data e a versão', (tester) async {
      await pump(
        tester,
        consents: [
          ConsentEntry(
            type: 'HealthData',
            termsVersion: '1.0',
            grantedAt: DateTime(2026, 3, 12),
          ),
        ],
      );

      expect(find.text('Tratamento dos dados de saúde'), findsOne);
      expect(find.text('Aceito em 12 de março de 2026 · versão 1.0'), findsOne);
    });

    testWidgets('sem trilha, diz o que a ausência significa', (tester) async {
      await pump(tester);

      expect(
        find.textContaining('O aceite é gravado quando você cria seu perfil'),
        findsOne,
      );
    });

    testWidgets('falhar aqui não tira a exclusão da tela', (tester) async {
      when(() => repository.consents()).thenThrow(ApiException('Falhou.'));

      await pump(tester);

      expect(
        find.text('Não foi possível ler seus consentimentos agora.'),
        findsOne,
      );
      expect(
        find.widgetWithText(OutlinedButton, 'Excluir minha conta'),
        findsOne,
      );
    });
  });

  group('o aviso da assinatura', () {
    testWidgets('aparece para quem assina pela loja', (tester) async {
      // É dinheiro: quem assina pela loja continua sendo cobrado depois de apagar a conta.
      await pump(
        tester,
        subscription: const SubscriptionStatus(
          plan: 'Pro',
          managedByStore: true,
        ),
      );

      expect(find.textContaining('gerenciada pela loja'), findsOne);
    });

    testWidgets('não aparece para quem nunca assinou', (tester) async {
      // Fixo na tela, ele era um recado que não é para você — e é assim que se aprende a não
      // ler o que está escrito ali.
      await pump(tester);

      expect(find.textContaining('gerenciada pela loja'), findsNothing);
    });
  });
}
