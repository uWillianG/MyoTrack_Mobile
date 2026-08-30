import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:myotrack/core/sync/sync_queue.dart';
import 'package:myotrack/core/theme.dart';
import 'package:myotrack/core/router.dart';
import 'package:myotrack/core/widgets/glass_segmented.dart';
import 'package:myotrack/features/analysis/analysis_page.dart';
import 'package:myotrack/features/coach/coach_fab.dart';
import 'package:myotrack/features/coach/coach_page.dart';
import 'package:myotrack/features/home/app_shell.dart';
import 'package:myotrack/features/home/home_page.dart';
import 'package:myotrack/features/home/account_destinations.dart';
import 'package:myotrack/features/home/account_sheet.dart';
import 'package:myotrack/features/logging/data/logging_models.dart';
import 'package:myotrack/features/logging/data/logging_repository.dart';
import 'package:myotrack/features/logging/logging_controller.dart';
import 'package:myotrack/features/nutrition/nutrition_page.dart';

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
            routes: [
              // Com o shell por fora, como na produção: a barra de abas não mora mais na
              // home, e um teste que montasse a home sozinha estaria exercitando uma barra
              // que o app não tem mais.
              ShellRoute(
                builder: (_, state, child) =>
                    AppShell(location: state.uri.path, child: child),
                routes: [
                  GoRoute(path: '/', builder: (_, _) => const HomePage()),
                  // A de verdade, e não uma tela de mentira: o botão do coach só cumpre o
                  // que promete se o destino existir, e é o `CoachPage` que o teste procura
                  // depois.
                  GoRoute(
                    path: Routes.coach,
                    builder: (_, _) => const CoachPage(),
                  ),
                ],
              ),
            ],
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
    // O segmentado da aba prova que é o conteúdo dela, e não só o título trocado. Pelo tipo e
    // não pelos rótulos: ele é só de ícone, e "Diário" e "Plano" não estão escritos em lugar
    // nenhum da tela — quem os carrega agora é o balão do toque longo e o leitor de tela.
    expect(find.byType(GlassSegmented<NutritionTab>), findsOne);
  });

  testWidgets('a barra continua na tela que a home empilha', (tester) async {
    // É o pedido inteiro desta mudança: sair da barra de abas para o coach deixava a pessoa
    // sem chão nenhum, com a seta do canto como único caminho de volta.
    final container = await pump(tester);

    container.read(homeTabProvider.notifier).state = HomeTab.nutrition;
    await tester.pumpAndSettle();

    await tester.tap(find.byType(CoachFab));
    await tester.pumpAndSettle();

    expect(find.byType(CoachPage), findsOne);
    expect(find.byType(NavigationBar), findsOne);
  });

  testWidgets('tocar numa aba desde uma tela empilhada volta para a aba', (
    tester,
  ) async {
    // Trocar a aba sem desempilhar acenderia o destino certo atrás de uma tela que continua
    // por cima — a barra pareceria quebrada justamente onde ela é o caminho de volta.
    final container = await pump(tester);

    await tester.tap(find.byType(CoachFab));
    await tester.pumpAndSettle();
    expect(find.byType(CoachPage), findsOne);

    await tester.tap(find.text('Nutrição').last);
    await tester.pumpAndSettle();

    expect(container.read(homeTabProvider), HomeTab.nutrition);
    expect(find.byType(CoachPage), findsNothing);
    expect(find.byType(GlassSegmented<NutritionTab>), findsOne);
  });

  testWidgets('o botão Registrar só existe na Hoje', (tester) async {
    final container = await pump(tester);

    expect(find.widgetWithText(FloatingActionButton, 'Registrar'), findsOne);

    container.read(homeTabProvider.notifier).state = HomeTab.progress;
    await tester.pumpAndSettle();

    expect(
      find.widgetWithText(FloatingActionButton, 'Registrar'),
      findsNothing,
    );
  });

  testWidgets('o botão do coach acompanha as quatro abas', (tester) async {
    // Ele é o contrário do `Registrar`: a dúvida que o coach responde nasce olhando qualquer
    // aba, e antes dele o único caminho até a conversa era a folha do avatar — dois toques e
    // um item no meio de seis, para o recurso que mais distingue o produto.
    final container = await pump(tester);

    for (final tab in HomeTab.values) {
      container.read(homeTabProvider.notifier).state = tab;
      await tester.pumpAndSettle();

      expect(find.byType(CoachFab), findsOne, reason: 'aba ${tab.label}');
      // O mesmo balão da folha da conta. Dois desenhos para o mesmo recurso fariam o usuário
      // achar que são dois recursos.
      expect(
        find.descendant(
          of: find.byType(CoachFab),
          matching: find.byIcon(Icons.chat_bubble_outline),
        ),
        findsOne,
        reason: 'aba ${tab.label}',
      );

      // E sempre no mesmo canto: botão que troca de lado conforme a aba obriga a procurá-lo
      // de novo a cada troca.
      expect(
        tester.getCenter(find.byType(CoachFab)).dx,
        greaterThan(smallPhone.width / 2),
        reason: 'aba ${tab.label}',
      );
    }
  });

  testWidgets('tocar no botão do coach abre a conversa', (tester) async {
    await pump(tester);

    await tester.tap(find.byType(CoachFab));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byType(CoachPage), findsOne);
  });

  testWidgets('os dois flutuantes da Hoje convivem na mesma navegação', (
    tester,
  ) async {
    // Eram dois `FloatingActionButton`, e dois deles na mesma árvore compartilham a etiqueta
    // de herói por omissão — a primeira navegação estourava em vez de navegar. O coach virou
    // vidro e saiu do tipo, o que resolve a colisão pela raiz; o que este teste ainda segura é
    // o resto, que continua valendo: um flutuante em cada ponta, e os dois tocáveis.
    await pump(tester);

    expect(find.byType(FloatingActionButton), findsOne);
    expect(find.byType(CoachFab), findsOne);

    // Um em cada ponta, e o coach na direita: se os dois caírem no mesmo canto eles se
    // sobrepõem, e o de baixo fica intocável sem nada estourar.
    final registrar = tester.getRect(
      find.widgetWithText(FloatingActionButton, 'Registrar'),
    );
    final coach = tester.getRect(find.byType(CoachFab));
    expect(registrar.right, lessThan(coach.left));

    await tester.tap(find.widgetWithText(FloatingActionButton, 'Registrar'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('O que você quer registrar?'), findsOne);
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
      // O Perfil trocou de lugar com o Progresso: saiu da barra de abas e entrou aqui.
      'Meu perfil',
      'Meu treino',
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

  testWidgets('a aba Progresso abre a evolução, e não o perfil', (
    tester,
  ) async {
    // A quarta aba trocou de assunto: era o Perfil — assinatura, medidas, exclusão de conta,
    // coisas que se mexe uma vez — e virou a pergunta que traz a pessoa de volta ao app.
    final container = await pump(tester);
    container.read(homeTabProvider.notifier).state = HomeTab.progress;
    await tester.pumpAndSettle();

    expect(find.text('Progresso'), findsWidgets);
    // E o Perfil continua alcançável: ele desceu para a folha do avatar, que é onde todo app
    // põe conta e configuração.
    expect(accountDestinations.first.route, Routes.profile);
  });
}
