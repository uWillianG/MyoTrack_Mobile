import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:myotrack/core/providers.dart';
import 'package:myotrack/core/router.dart';
import 'package:myotrack/features/auth/reset_password_page.dart';

/// O link de redefinição chega de fora do app, montado pelo backend. Se a rota não existir,
/// o usuário cai no `errorBuilder` — e não há como descobrir isso em teste de unidade,
/// porque o defeito está justamente na tabela de rotas.
void main() {
  const link = '/redefinir-senha?uid=uid-1&token=token-do-email';

  Future<GoRouter> pumpApp(
    WidgetTester tester, {
    required bool loggedIn,
  }) async {
    final container = ProviderContainer(
      overrides: [authStateProvider.overrideWith((ref) async => loggedIn)],
    );
    addTearDown(container.dispose);

    final router = container.read(routerProvider);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    // Deixa a sessão resolver e o splash sair da frente antes de abrir o link.
    await tester.pumpAndSettle();
    return router;
  }

  group('deep link de redefinição de senha', () {
    testWidgets('abre a tela com uid e token da query', (tester) async {
      final router = await pumpApp(tester, loggedIn: false);

      router.go(link);
      await tester.pumpAndSettle();

      final page = tester.widget<ResetPasswordPage>(
        find.byType(ResetPasswordPage),
      );
      expect(page.userId, 'uid-1');
      expect(page.token, 'token-do-email');
      expect(find.textContaining('Rota não encontrada'), findsNothing);
    });

    testWidgets('continua acessível com sessão aberta', (tester) async {
      // Quem esqueceu a senha pode estar logado neste mesmo aparelho. A guarda que manda
      // rota pública para a home não pode valer aqui, ou o link vira um pulo para a home.
      final router = await pumpApp(tester, loggedIn: true);

      router.go(link);
      await tester.pumpAndSettle();

      expect(find.byType(ResetPasswordPage), findsOneWidget);
    });

    testWidgets('link sem os parâmetros oferece pedir outro', (tester) async {
      // Cliente de e-mail que trunca o link entrega isto. Sem tratamento, a tela pediria
      // uma senha nova para depois falhar com "link inválido" vindo do servidor.
      final router = await pumpApp(tester, loggedIn: false);

      router.go('/redefinir-senha');
      await tester.pumpAndSettle();

      expect(find.text('Pedir novo link'), findsOneWidget);
      expect(find.text('Redefinir senha'), findsNothing);
    });
  });
}
