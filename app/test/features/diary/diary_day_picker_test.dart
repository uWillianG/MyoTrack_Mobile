import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:myotrack/core/theme.dart';
import 'package:myotrack/features/diary/diary_controller.dart';
import 'package:myotrack/features/diary/diary_page.dart';

import '../home/home_test_harness.dart';

/// O diário trocou as setas por sete alvos. O que estes testes fixam é o que a troca pode
/// quebrar: a semana continuar terminando em hoje, e o dia futuro continuar inalcançável.
void main() {
  const smallPhone = Size(360, 800);

  Future<ProviderContainer> pump(
    WidgetTester tester, {
    Brightness brightness = Brightness.light,
    List<Override> extra = const [],
  }) async {
    tester.view.physicalSize = smallPhone;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final container = ProviderContainer(
      overrides: [...homeOverrides(), ...extra],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(
          theme: brightness == Brightness.light
              ? AppTheme.light()
              : AppTheme.dark(),
          routerConfig: GoRouter(
            routes: [
              GoRoute(
                path: '/',
                builder: (_, _) => const Scaffold(body: DiaryView()),
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return container;
  }

  DateTime dateOnly(DateTime date) => DateTime(date.year, date.month, date.day);

  testWidgets('mostra os sete últimos dias, terminando em hoje', (
    tester,
  ) async {
    await pump(tester);

    final today = dateOnly(DateTime.now());
    for (var back = 0; back < 7; back++) {
      final day = today.subtract(Duration(days: back));
      expect(find.text('${day.day}'), findsWidgets, reason: '${day.day}');
    }

    // Amanhã não: o diário registra o que foi comido, e um dia futuro só poderia estar
    // vazio — o usuário acharia que perdeu dados.
    final tomorrow = today.add(const Duration(days: 1));
    expect(find.text('${tomorrow.day}'), findsNothing);
  });

  testWidgets('tocar num dia troca o dia aberto', (tester) async {
    final container = await pump(tester);

    final target = dateOnly(DateTime.now()).subtract(const Duration(days: 3));
    await tester.tap(find.text('${target.day}').first);
    await tester.pumpAndSettle();

    expect(container.read(diaryDateProvider), target);
  });

  for (final brightness in Brightness.values) {
    testWidgets('o diário cabe na tela (${brightness.name})', (tester) async {
      await pump(tester, brightness: brightness);

      expect(tester.takeException(), isNull);
      // O botão que fecha o ciclo: é no diário que a falta aparece, e é dali que se registra
      // o que faltou. Mesmo rótulo do herói da Hoje, de propósito — dois caminhos para o
      // mesmo recurso não podem ter nomes diferentes.
      expect(find.text('Fotografar refeição'), findsOne);
    });
  }

  testWidgets('o herói mostra o consumido, não o que resta', (tester) async {
    // É a diferença deliberada entre esta tela e a Hoje: a Hoje responde "quanto ainda cabe",
    // pergunta que só faz sentido hoje; o diário é navegável para trás, e "restam 624" num
    // sábado que já acabou não significa nada.
    await pump(tester);

    expect(find.text('1.476'), findsOne);
    expect(find.textContaining('de 2.100 kcal · faltam 624'), findsOne);
    expect(find.text('3 refeições registradas'), findsOne);
  });

  testWidgets('os macros aparecem contra a meta, e as calorias não', (
    tester,
  ) async {
    // As calorias são o número do herói; repeti-las na seção seria a mesma duplicação que a
    // Hoje evita ao tirar do mosaico o assunto promovido.
    await pump(tester);

    expect(find.text('Macros do dia'), findsOne);
    expect(find.text('110 / 172 g'), findsOne);
    expect(find.text('Calorias'), findsNothing);
  });

  testWidgets('as refeições viram linhas com a hora', (tester) async {
    await pump(tester);

    // A tela tem duas rolagens — o seletor de dias na horizontal e o corpo na vertical —, e
    // sem dizer qual o `scrollUntilVisible` não sabe em qual rolar.
    await tester.scrollUntilVisible(
      find.text('Refeições'),
      200,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.text('3 no diário'), findsOne);
    // A hora antes do número: a lista é cronológica, e é por ela que se acha a refeição que
    // se quer mexer.
    expect(find.text('420 kcal'), findsOne);
  });

  testWidgets('sem semana no diário, o gráfico não aparece', (tester) async {
    // Gráfico com sete barras zeradas parece defeito, não ausência de dado.
    await pump(tester);

    expect(find.text('Últimos 7 dias'), findsNothing);
  });

  testWidgets('com semana, o gráfico entra e diz a média', (tester) async {
    await pump(
      tester,
      extra: [...homeOverrides(day: diaryDay(week: semanaDeCalorias))],
    );

    await tester.scrollUntilVisible(
      find.text('Últimos 7 dias'),
      200,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.textContaining('média'), findsOne);
  });
}
