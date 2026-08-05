import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myotrack/core/theme.dart';
import 'package:myotrack/features/billing/billing_controller.dart';
import 'package:myotrack/features/billing/billing_page.dart';
import 'package:myotrack/features/home/today_controller.dart';

import '../home/home_test_harness.dart';

/// A tela onde um mal-entendido custa dinheiro. O que estes testes fixam é o que ela **nunca**
/// pode fazer: oferecer um botão de compra sem preço, esconder uma cobrança que falhou, ou
/// prometer que dá para cancelar por aqui.
void main() {
  const smallPhone = Size(360, 800);

  Future<void> pump(WidgetTester tester, List<Override> overrides) async {
    tester.view.physicalSize = smallPhone;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          nowProvider.overrideWithValue(() => DateTime(2026, 8, 4, 15)),
          ...overrides,
        ],
        child: MaterialApp(theme: AppTheme.dark(), home: const BillingPage()),
      ),
    );
    await tester.pumpAndSettle();
  }

  /// Rola até o alvo aparecer.
  ///
  /// O herói mais os três limites já enchem uma tela de 800 dp, e o que vem depois — a faixa
  /// que explica a loja indisponível, o "restaurar compras" — ainda **não existe** na árvore.
  Future<void> scrollTo(WidgetTester tester, Finder target) => tester
      .scrollUntilVisible(target, 200, scrollable: find.byType(Scrollable));

  testWidgets('no plano gratuito, o preço vem da loja e mora no botão', (
    tester,
  ) async {
    await pump(tester, billingOverrides());

    expect(find.text('Plano gratuito'), findsOne);
    expect(find.text('Assinar por R\$ 24,90'), findsOne);
    // A letra miúda precisa estar visível antes de alguém tocar.
    expect(find.textContaining('renova sozinha'), findsOne);
  });

  // O caso que motivou a ação ser nula em vez de um botão sem preço: tocar sem saber quanto
  // vai pagar é o pior que esta tela pode fazer.
  testWidgets('sem produto na loja, não há botão — e a tela explica', (
    tester,
  ) async {
    await pump(
      tester,
      billingOverrides(
        state: const BillingState(loadingStore: false, storeAvailable: false),
      ),
    );

    expect(find.textContaining('Assinar por'), findsNothing);

    await scrollTo(
      tester,
      find.textContaining('não está disponível neste aparelho'),
    );
    expect(find.textContaining('não está disponível neste aparelho'), findsOne);
  });

  testWidgets('enquanto a loja não responde, o botão espera sem convidar', (
    tester,
  ) async {
    await pump(
      tester,
      billingOverrides(state: const BillingState(loadingStore: true)),
    );

    final button = tester.widget<FilledButton>(find.byType(FilledButton));
    expect(button.onPressed, isNull);
    expect(find.text('Consultando a loja…'), findsOne);
  });

  testWidgets('no Pro, a tela diz quando renova e que a loja é quem manda', (
    tester,
  ) async {
    await pump(tester, billingOverrides(status: assinaturaPro));

    expect(find.text('MyoTrack Pro'), findsOne);
    expect(find.text('Renova em 28 de agosto'), findsOne);
    // Sem esta frase, o próximo passo do usuário é procurar um botão de cancelar que não
    // existe — e depois o suporte.
    expect(find.textContaining('gerenciada pela loja'), findsOne);
    expect(find.textContaining('Assinar por'), findsNothing);
  });

  // Cobrança falhada é a coisa mais importante da tela, e por isso vive no herói.
  testWidgets('cobrança falhada aparece, e não bloqueia o acesso', (
    tester,
  ) async {
    await pump(
      tester,
      billingOverrides(status: assinaturaPro.copyWith(paymentPastDue: true)),
    );

    expect(find.textContaining('A última cobrança falhou'), findsOne);
    // Continua sendo Pro: cortar o acesso durante a tolerância da loja puniria quem só
    // precisa trocar o cartão.
    expect(find.text('MyoTrack Pro'), findsOne);
  });

  testWidgets('a renovação de outro ano vem com o ano escrito', (tester) async {
    await pump(
      tester,
      billingOverrides(
        status: assinaturaPro.copyWith(currentPeriodEnd: '2027-03-14T00:00:00'),
      ),
    );

    expect(find.text('Renova em 14 de março de 2027'), findsOne);
  });
}
