import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:myotrack/core/theme.dart';
import 'package:myotrack/features/analysis/analysis_page.dart';
import 'package:myotrack/features/home/home_page.dart';
import 'package:myotrack/features/home/account_sheet.dart';

import 'home_test_harness.dart';

/// O shell é a primeira tela do app e a única que carrega quatro telas ao mesmo tempo. Estes
/// testes rodam na largura de um celular pequeno para que um estouro de layout em qualquer
/// uma das abas falhe aqui, e não no aparelho.
void main() {
  const smallPhone = Size(360, 800);

  Future<ProviderContainer> pump(
    WidgetTester tester, {
    Brightness brightness = Brightness.light,
  }) async {
    tester.view.physicalSize = smallPhone;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final container = ProviderContainer(overrides: homeOverrides());
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(
          theme: brightness == Brightness.light
              ? AppTheme.light()
              : AppTheme.dark(),
          // Um roteador de verdade: os cartões da Hoje e os itens do Perfil chamam
          // `context.push`, que estoura sem GoRouter na árvore.
          routerConfig: GoRouter(
            routes: [GoRoute(path: '/', builder: (_, _) => const HomePage())],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return container;
  }

  for (final brightness in Brightness.values) {
    testWidgets('as quatro abas renderizam sem estouro (${brightness.name})', (
      tester,
    ) async {
      final container = await pump(tester, brightness: brightness);

      for (final tab in HomeTab.values) {
        container.read(homeTabProvider.notifier).state = tab;
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: 'aba ${tab.label}');
        expect(find.text(tab.title), findsWidgets);
      }
    });
  }

  testWidgets('tocar na barra troca a aba', (tester) async {
    final container = await pump(tester);

    await tester.tap(find.text('Nutrição').last);
    await tester.pumpAndSettle();

    expect(container.read(homeTabProvider), HomeTab.nutrition);
    // O segmentado da aba prova que é o conteúdo dela, e não só o título trocado.
    expect(find.text('Diário'), findsOneWidget);
    expect(find.text('Plano'), findsOneWidget);
  });

  testWidgets('o botão Registrar só existe na Hoje', (tester) async {
    final container = await pump(tester);

    expect(find.widgetWithText(FloatingActionButton, 'Registrar'), findsOne);

    container.read(homeTabProvider.notifier).state = HomeTab.profile;
    await tester.pumpAndSettle();

    expect(
      find.widgetWithText(FloatingActionButton, 'Registrar'),
      findsNothing,
    );
  });

  testWidgets('a captura rápida leva para Analisar na sub-aba certa', (
    tester,
  ) async {
    // É o atalho que justifica a folha existir: da Hoje até a câmera do prato sem passar
    // pela barra de navegação nem pelo segmentado.
    final container = await pump(tester);
    container.read(analysisTabProvider.notifier).state = AnalysisTab.form;

    await tester.tap(find.widgetWithText(FloatingActionButton, 'Registrar'));
    await tester.pumpAndSettle();
    expect(find.text('O que você quer registrar?'), findsOne);

    await tester.tap(find.text('Fotografar refeição'));
    await tester.pumpAndSettle();

    expect(container.read(homeTabProvider), HomeTab.analysis);
    expect(container.read(analysisTabProvider), AnalysisTab.meal);
  });

  testWidgets('o avatar guarda os destinos que saíram da home', (tester) async {
    // A home virou hub e deixou de listar tudo, e as quatro abas não comportam o resto. Se
    // algum destino sumir junto, o usuário perde o único caminho até ele — inclusive a
    // exclusão de conta, que as lojas exigem que seja fácil de achar.
    await pump(tester);

    await tester.tap(find.byType(CircleAvatar));
    await tester.pumpAndSettle();

    final sheet = find.byType(AccountSheet);
    expect(sheet, findsOne);

    for (final title in [
      'Progresso',
      'Meu treino',
      'Registrar treino',
      'Coach',
      'Assinatura',
      'Conta e privacidade',
    ]) {
      final item = find.descendant(of: sheet, matching: find.text(title));
      await tester.scrollUntilVisible(
        item,
        120,
        // A folha tem a própria rolagem, e a árvore inteira tem várias — sem dizer qual, o
        // `scrollUntilVisible` não sabe em qual rolar.
        scrollable: find
            .descendant(of: sheet, matching: find.byType(Scrollable))
            .first,
      );
      expect(item, findsOne, reason: title);
    }
  });

  testWidgets('as iniciais do avatar saem do e-mail da sessão', (tester) async {
    await pump(tester);

    expect(find.text('RS'), findsOne);
  });

  testWidgets('sem papel de revisor, Revisão não aparece na folha da conta', (
    tester,
  ) async {
    // Levaria o aluno a uma tela que o servidor recusa com 403.
    await pump(tester);

    await tester.tap(find.byType(CircleAvatar));
    await tester.pumpAndSettle();

    expect(
      find.descendant(
        of: find.byType(AccountSheet),
        matching: find.text('Revisão'),
      ),
      findsNothing,
    );
  });

  testWidgets('a aba Perfil abre o assistente em etapas', (tester) async {
    // O protótipo põe o onboarding aqui, e é o que quem toca em "Perfil" espera achar —
    // não um menu.
    final container = await pump(tester);
    container.read(homeTabProvider.notifier).state = HomeTab.profile;
    await tester.pumpAndSettle();

    expect(find.text('Etapa 1/5 · Você'), findsOne);
    expect(find.text('Quem está treinando'), findsOne);
  });
}
