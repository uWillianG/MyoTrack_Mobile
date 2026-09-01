import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:myotrack/core/router.dart';
import 'package:myotrack/core/theme.dart';
import 'package:myotrack/features/billing/billing_controller.dart';
import 'package:myotrack/features/billing/data/billing_models.dart';
import 'package:myotrack/features/billing/limit_reached_sheet.dart';

/// A parede do dia, e a porta que ela passou a ter.
///
/// O que estes testes fixam é **para quem a porta aparece**. Oferecer o Pro a um assinante é o
/// que o servidor já evita na própria mensagem de limite, e o app não pode desfazer isso do
/// lado de cá — nem por sorte, quando o plano ainda nem foi carregado.
void main() {
  const mensagem =
      'Limite diário de 10 análises de refeição atingido. Assine o Pro para '
      'ampliar.';

  Future<void> pump(
    WidgetTester tester, {
    required List<Override> overrides,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: overrides,
        child: MaterialApp.router(
          theme: AppTheme.dark(),
          // Roteador de verdade: sem uma rota de chegada o teste não distingue "levou à
          // assinatura" de "não fez nada".
          routerConfig: GoRouter(
            routes: [
              GoRoute(
                path: '/',
                builder: (context, _) => Scaffold(
                  body: Center(
                    child: Builder(
                      builder: (inner) => TextButton(
                        onPressed: () => showLimitReachedSheet(inner, mensagem),
                        child: const Text('abrir'),
                      ),
                    ),
                  ),
                ),
              ),
              GoRoute(
                path: Routes.billing,
                builder: (_, _) =>
                    const Scaffold(body: Center(child: Text('assinatura'))),
              ),
            ],
          ),
        ),
      ),
    );
    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();
  }

  List<Override> plano(SubscriptionStatus? status) => [
    subscriptionStatusProvider.overrideWith(
      (ref) async => status ?? const SubscriptionStatus(),
    ),
  ];

  testWidgets('no plano gratuito, a folha traz a frase do servidor e a porta', (
    tester,
  ) async {
    await pump(tester, overrides: plano(const SubscriptionStatus()));

    // A frase não é reescrita pelo app: só o servidor sabe o limite do ambiente.
    expect(find.textContaining('Limite diário de 10'), findsOne);
    expect(find.text('Ver o Pro'), findsOne);

    await tester.tap(find.text('Ver o Pro'));
    await tester.pumpAndSettle();

    expect(find.text('assinatura'), findsOne);
    // A folha precisa sair de cima da tela para onde ela mesma levou.
    expect(find.text('Ver o Pro'), findsNothing);
  });

  testWidgets('para quem já é Pro, não há o que oferecer', (tester) async {
    await pump(tester, overrides: plano(const SubscriptionStatus(plan: 'Pro')));

    expect(find.textContaining('Limite diário de 10'), findsOne);
    expect(find.text('Ver o Pro'), findsNothing);
    expect(find.text('Entendi'), findsOne);
  });

  // Um botão errado é pior que um botão a menos: a aba Conta continua sendo o caminho, e
  // oferecer o Pro a quem talvez já o tenha é o erro que não dá para desfazer depois do toque.
  testWidgets('com o plano ainda desconhecido, a folha só explica', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          // Nunca completa: é o que a tela vê enquanto a chamada está em voo.
          subscriptionStatusProvider.overrideWith(
            (ref) => Completer<SubscriptionStatus>().future,
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.dark(),
          home: Scaffold(
            body: Center(
              child: Builder(
                builder: (inner) => TextButton(
                  onPressed: () => showLimitReachedSheet(inner, mensagem),
                  child: const Text('abrir'),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Limite diário de 10'), findsOne);
    expect(find.text('Ver o Pro'), findsNothing);
  });
}
