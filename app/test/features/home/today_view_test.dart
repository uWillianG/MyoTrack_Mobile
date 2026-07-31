import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:myotrack/core/theme.dart';
import 'package:myotrack/features/home/today_page.dart';
import 'package:myotrack/features/reviews/review_controller.dart';

import 'home_test_harness.dart';

/// A Hoje é a primeira coisa que o usuário vê, e todo cartão dela depende de uma chamada que
/// pode falhar ou vir vazia. O que estes testes fixam é a regra que vale para todos: cartão
/// só aparece quando tem o que dizer.
void main() {
  const smallPhone = Size(360, 800);

  Future<void> pump(
    WidgetTester tester,
    List<Override> overrides, {
    Brightness brightness = Brightness.light,
  }) async {
    tester.view.physicalSize = smallPhone;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: overrides,
        child: MaterialApp.router(
          theme: brightness == Brightness.light
              ? AppTheme.light()
              : AppTheme.dark(),
          routerConfig: GoRouter(
            routes: [
              GoRoute(
                path: '/',
                builder: (_, _) => const Scaffold(body: TodayView()),
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  for (final brightness in Brightness.values) {
    testWidgets('o dia completo cabe na tela (${brightness.name})', (
      tester,
    ) async {
      await pump(
        tester,
        homeOverrides(reviewCounts: const {ReviewKind.workout: 3}),
        brightness: brightness,
      );

      expect(tester.takeException(), isNull);
      // 2.100 de meta menos 1.476 consumidas: o número grande é o que ainda cabe, não o
      // que já foi comido.
      expect(find.text('624'), findsOne);
      expect(find.text('kcal restam'), findsOne);
      expect(find.textContaining('Faltam 62 g de proteína'), findsOne);
      expect(find.text('Treino B · Peito e tríceps'), findsOne);
      expect(find.text('Sua semana'), findsOne);
      expect(find.text('Fechar o dia'), findsOne);
    });
  }

  testWidgets('o próximo treino diz o tamanho e a última vez', (tester) async {
    await pump(tester, homeOverrides());

    // 6 exercícios × 4 séries × (90s de descanso + 45s de execução) = 54 min, arredondado
    // para cima em blocos de 5.
    expect(
      find.textContaining('6 exercícios · cerca de 55 min · último há'),
      findsOne,
    );
  });

  testWidgets('sem plano de treino, o cartão de treinar some', (tester) async {
    // Um "Treinar agora" que leva a uma tela vazia é pior que cartão nenhum.
    await pump(tester, homeOverrides(hasNextWorkout: false));

    expect(find.text('Treinar agora'), findsNothing);
    // O resto do hub continua de pé.
    expect(find.text('Fechar o dia'), findsOne);
  });

  testWidgets('sem dieta gerada, o anel dá lugar ao consumido', (tester) async {
    // Meta zero faria o anel aparecer sempre estourado, e "0 kcal restam" seria mentira.
    await pump(tester, homeOverrides(day: diaryDay(withTargets: false)));

    expect(find.text('kcal restam'), findsNothing);
    expect(find.text('1.476'), findsOne);
    expect(find.textContaining('Gere sua dieta'), findsOne);
  });

  testWidgets('sem fila de revisão, o cartão do revisor não aparece', (
    tester,
  ) async {
    await pump(tester, homeOverrides());

    // O cartão é o último da lista e nasceria fora da janela; rolar até o fim é o que
    // separa "não existe" de "ainda não foi construído".
    await tester.drag(find.byType(ListView), const Offset(0, -600));
    await tester.pumpAndSettle();

    expect(find.text('Revisor'), findsNothing);
  });

  testWidgets('com fila, o cartão do revisor soma as duas filas', (
    tester,
  ) async {
    await pump(
      tester,
      homeOverrides(
        reviewCounts: const {ReviewKind.workout: 2, ReviewKind.diet: 2},
      ),
    );
    await tester.drag(find.byType(ListView), const Offset(0, -600));
    await tester.pumpAndSettle();

    expect(find.text('Revisor'), findsOne);
    expect(find.text('4 planos aguardando você'), findsOne);
    expect(find.text('2 treinos · 2 dietas'), findsOne);
  });
}
