import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:myotrack/core/theme.dart';
import 'package:myotrack/features/diary/diary_controller.dart';
import 'package:myotrack/features/diary/diary_page.dart';

import '../home/home_test_harness.dart';

/// O diário deixou de ser uma tela por dia e virou um carrossel: os sete últimos dias lado a
/// lado, alcançáveis por toque na tira de cima **ou** por arrasto no conteúdo.
///
/// O que estes testes prendem é o que o gesto pode quebrar sem quebrar nada visível: o dia
/// aberto continuar valendo para o resto do app, e o futuro continuar inalcançável.
void main() {
  const phone = Size(390, 844);

  Future<ProviderContainer> pump(WidgetTester tester) async {
    tester.view.physicalSize = phone;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final container = ProviderContainer(overrides: homeOverrides());
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(
          theme: AppTheme.dark(),
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

  testWidgets('arrastar para a direita volta um dia', (tester) async {
    final container = await pump(tester);
    final today = dateOnly(DateTime.now());

    expect(container.read(diaryDateProvider), today);

    // Para a direita puxa o dia anterior para dentro da tela, como virar uma página para trás.
    await tester.fling(find.byType(PageView), const Offset(300, 0), 900);
    await tester.pumpAndSettle();

    expect(
      container.read(diaryDateProvider),
      today.subtract(const Duration(days: 1)),
    );
  });

  testWidgets('em hoje, arrastar para a esquerda não inventa amanhã', (
    tester,
  ) async {
    // O diário registra o que foi comido, e um dia futuro só poderia estar vazio — o usuário
    // acharia que perdeu dados. No fim do curso o carrossel resiste e volta.
    final container = await pump(tester);
    final today = dateOnly(DateTime.now());

    await tester.fling(find.byType(PageView), const Offset(-300, 0), 900);
    await tester.pumpAndSettle();

    expect(container.read(diaryDateProvider), today);
  });

  testWidgets('tocar num dia da tira leva o carrossel até ele', (tester) async {
    final container = await pump(tester);
    final today = dateOnly(DateTime.now());
    final target = today.subtract(const Duration(days: 3));

    await tester.tap(find.text('${target.day}').first);
    await tester.pumpAndSettle();

    expect(container.read(diaryDateProvider), target);
  });

  testWidgets('mudar o dia por fora leva o carrossel junto', (tester) async {
    // Quem troca o dia nem sempre é o gesto: a folha de captura rápida e os links de
    // notificação escrevem no provider direto, e o carrossel tem de obedecer.
    final container = await pump(tester);
    final target = dateOnly(DateTime.now()).subtract(const Duration(days: 5));

    container.read(diaryDateProvider.notifier).state = target;
    await tester.pumpAndSettle();

    final page = tester
        .widget<PageView>(find.byType(PageView))
        .controller!
        .page;
    expect(page, DiaryView.days - 1 - 5);
  });
}
