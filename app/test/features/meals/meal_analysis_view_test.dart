import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myotrack/core/jobs/generation_controller.dart';
import 'package:myotrack/core/theme.dart';
import 'package:myotrack/features/home/today_controller.dart';
import 'package:myotrack/features/meals/meal_analysis_controller.dart';
import 'package:myotrack/features/meals/meal_analysis_page.dart';

import '../home/home_test_harness.dart';

/// O herói da análise de refeição é o **estado do trabalho**: o convite enquanto nada corre, o
/// progresso enquanto a foto é analisada. O que estes testes fixam é a troca — e que o convite
/// só explica a IA para quem ainda não a viu funcionar.
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
        child: MaterialApp(
          theme: AppTheme.dark(),
          home: const Scaffold(body: MealAnalysisView()),
        ),
      ),
    );
    // Sem `pumpAndSettle`: com a análise em curso a barra de progresso é indeterminada, e uma
    // animação que nunca termina faria o `settle` estourar por tempo.
    await tester.pump();
    await tester.pump();
  }

  testWidgets('sem histórico, o herói explica o que a IA faz e o que não faz', (
    tester,
  ) async {
    await pump(tester, homeOverrides());

    expect(find.text('Fotografar prato'), findsOne);
    expect(find.textContaining('estimativa fica editável'), findsOne);
  });

  testWidgets('com histórico, o herói conta as refeições e cala a explicação', (
    tester,
  ) async {
    await pump(tester, homeOverrides(analyzedMeals: refeicoesAnalisadas));

    expect(find.text('2'), findsOne);
    expect(find.text('refeições'), findsOne);
    // Quem já analisou uma foto descobriu isso na primeira; repetir a cada abertura é ruído.
    expect(find.textContaining('estimativa fica editável'), findsNothing);
  });

  testWidgets('enquanto a análise corre, o herói vira o progresso', (
    tester,
  ) async {
    await pump(tester, [
      ...homeOverrides(),
      mealAnalysisProvider.overrideWith(_RunningAnalysis.new),
    ]);

    expect(find.text('Analisando'), findsOne);
    expect(find.text('Identificando os alimentos…'), findsOne);
    // O convite sai enquanto o trabalho corre: um botão de fotografar vivo aqui convidaria a
    // disparar uma segunda análise por cima da primeira.
    expect(find.text('Fotografar prato'), findsNothing);
  });

  testWidgets('a refeição de hoje se distingue da de outro dia pelo rótulo', (
    tester,
  ) async {
    await pump(tester, homeOverrides(analyzedMeals: refeicoesAnalisadas));

    expect(find.text('Hoje, 12:34'), findsOne);
    expect(find.text('3 de agosto, 20:10'), findsOne);
  });
}

/// A mesma tela com uma análise em curso.
class _RunningAnalysis extends MealAnalysisController {
  @override
  GenerationState build() =>
      const GenerationState(running: true, step: 'Identificando os alimentos…');
}
