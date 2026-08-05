import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:myotrack/core/sync/sync_queue.dart';
import 'package:myotrack/core/theme.dart';
import 'package:myotrack/features/analysis/analysis_page.dart';
import 'package:myotrack/features/home/home_page.dart';
import 'package:myotrack/features/home/account_sheet.dart';
import 'package:myotrack/features/logging/data/logging_models.dart';
import 'package:myotrack/features/logging/data/logging_repository.dart';
import 'package:myotrack/features/logging/log_session_controller.dart';

import 'home_test_harness.dart';

class _MockLoggingRepository extends Mock implements LoggingRepository {}

/// O shell é a primeira tela do app e a única que carrega quatro telas ao mesmo tempo. Estes
/// testes rodam na largura de um celular pequeno para que um estouro de layout em qualquer
/// uma das abas falhe aqui, e não no aparelho.
void main() {
  const smallPhone = Size(360, 800);

  setUpAll(() {
    registerFallbackValue(const MeasurementRequest(date: '2026-07-30'));
  });

  Future<ProviderContainer> pump(
    WidgetTester tester, {
    Brightness brightness = Brightness.light,
    List<Override> extraOverrides = const [],
  }) async {
    tester.view.physicalSize = smallPhone;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final container = ProviderContainer(
      overrides: [...homeOverrides(), ...extraOverrides],
    );
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

        final title = tab.title;
        if (title == null) {
          // A Hoje não tem barra de título: ela abre com o anel, e é a legenda dele que
          // prova que a aba certa está montada.
          expect(
            find.text('kcal restam'),
            findsOne,
            reason: 'aba ${tab.label}',
          );
        } else {
          expect(find.text(title), findsWidgets, reason: 'aba ${tab.label}');
        }
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

    // O item da folha, e não o botão do bloco de nutrição atrás dela: os dois têm o mesmo
    // rótulo de propósito — levam ao mesmo recurso, e vocabulário que muda entre dois
    // caminhos para a mesma coisa é o que faz o usuário achar que são coisas diferentes.
    await tester.tap(
      find.descendant(
        of: find.byType(ListTile),
        matching: find.text('Fotografar refeição'),
      ),
    );
    await tester.pumpAndSettle();

    expect(container.read(homeTabProvider), HomeTab.analysis);
    expect(container.read(analysisTabProvider), AnalysisTab.meal);
  });

  testWidgets('anotar peso pela captura rápida registra e avisa', (
    tester,
  ) async {
    // Mesmo diálogo do fechamento do dia, e mesma armadilha: o campo continua na tela
    // durante a animação de saída, e o POST volta depois. Se qualquer um dos dois for
    // amarrado ao widget que abriu o diálogo, isto quebra.
    final repository = _MockLoggingRepository();
    when(
      () => repository.logMeasurement(any()),
    ).thenAnswer((_) async => WriteOutcome.sent);

    await pump(
      tester,
      extraOverrides: [loggingRepositoryProvider.overrideWithValue(repository)],
    );

    await tester.tap(find.widgetWithText(FloatingActionButton, 'Registrar'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Anotar peso'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), '83,1');
    await tester.tap(find.widgetWithText(FilledButton, 'Salvar'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Peso registrado.'), findsOne);

    final captured =
        verify(() => repository.logMeasurement(captureAny())).captured.single
            as MeasurementRequest;
    expect(captured.weightKg, closeTo(83.1, 0.001));
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

  testWidgets('a aba Perfil mostra o perfil de quem já o tem', (tester) async {
    // Ela abria o assistente de cadastro, inclusive para quem já tinha perfil: a aba chamada
    // "Perfil" era a única do app que nunca mostrava o seu assunto.
    final container = await pump(tester);
    container.read(homeTabProvider.notifier).state = HomeTab.profile;
    await tester.pumpAndSettle();

    expect(find.text('Seu plano'), findsOne);
    expect(find.text('4 dias — ABCD'), findsOne);
  });
}
