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
      // O botão que fecha o ciclo: é no diário que a falta aparece, e é dali que se
      // registra o que faltou.
      expect(find.text('Adicionar refeição por foto'), findsOne);
    });
  }
}
