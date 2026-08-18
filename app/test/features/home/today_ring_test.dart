import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:myotrack/core/theme.dart';
import 'package:myotrack/features/home/today_controller.dart';
import 'package:myotrack/features/home/today_page.dart';
import 'package:myotrack/features/home/today_ring.dart';

import 'home_test_harness.dart';

/// O anel da Hoje é a peça que mais depende de gesto no app, e gesto é o que teste de widget
/// mais deixa passar: tudo compila, tudo desenha, e nada se move.
///
/// O que estes testes prendem é o comportamento que o desenho promete — que o painel siga o
/// dedo, que um peteleco curto conte tanto quanto um arrasto longo, e que o número do herói
/// sobreviva à rolagem em miniatura.
void main() {
  const phone = Size(390, 844);

  Future<ProviderContainer> pump(
    WidgetTester tester, {
    List<Override> extra = const [],
  }) async {
    tester.view.physicalSize = phone;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final container = ProviderContainer(
      overrides: [
        // Uma terça às 15h: a faixa em que a hora promove a nutrição a herói, que é quando o
        // anel existe. Fora dela quem abre a tela é o treino, e não há anel para arrastar.
        nowProvider.overrideWithValue(() => DateTime(2026, 8, 4, 15)),
        ...homeOverrides(),
        ...extra,
      ],
    );
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
                builder: (_, _) => const Scaffold(body: TodayView()),
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return container;
  }

  final timeline = find.text('O DIA ATÉ AGORA');

  /// Um arrasto no anel, em passos e com hora marcada.
  ///
  /// **As duas coisas importam, e a segunda pega desprevenido.** Passo a passo porque um salto
  /// único não deixa amostra para o rastreador de velocidade; **com `timeStamp`** porque o
  /// `moveBy` do `flutter_test` carimba todo evento na hora zero por omissão — e um arrasto em
  /// que o tempo não anda tem velocidade zero, por mais longe que ele vá. Sem isso, o teste do
  /// peteleco mediria distância e afirmaria estar medindo intenção.
  ///
  /// [stepMs] é o que separa um peteleco de um arrasto pensado.
  Future<void> dragRing(
    WidgetTester tester,
    double dy, {
    int steps = 6,
    int stepMs = 16,
  }) async {
    final gesture = await tester.startGesture(
      tester.getCenter(find.byType(CalorieRing)),
    );
    var elapsed = Duration.zero;
    for (var i = 0; i < steps; i++) {
      elapsed += Duration(milliseconds: stepMs);
      await gesture.moveBy(Offset(0, dy / steps), timeStamp: elapsed);
      await tester.pump(Duration(milliseconds: stepMs));
    }
    await gesture.up(timeStamp: elapsed);
    await tester.pumpAndSettle();
  }

  testWidgets('o anel abre a linha do dia e volta a fechá-la', (tester) async {
    await pump(tester);

    expect(timeline, findsNothing);

    await tester.tap(find.byType(CalorieRing));
    await tester.pumpAndSettle();
    expect(timeline, findsOne);

    await tester.tap(find.byType(CalorieRing));
    await tester.pumpAndSettle();
    expect(timeline, findsNothing);
  });

  testWidgets('a linha do dia lista as refeições lançadas, com a hora', (
    tester,
  ) async {
    await pump(tester);

    await tester.tap(find.byType(CalorieRing));
    await tester.pumpAndSettle();

    // O harness lança três refeições no dia, e o painel mostra as três com o que cada uma
    // somou. A hora sai formatada no fuso da máquina, então o que se confere aqui é o número.
    expect(find.text('420'), findsOne);
    expect(find.text('760'), findsOne);
    expect(find.text('296'), findsOne);
  });

  testWidgets('o painel segue o dedo antes de o dedo sair', (tester) async {
    // É a diferença entre um painel e um botão disfarçado: se ele só se mexe na soltura, todo
    // o resto do desenho — projeção de momento, elástico do limite — não tem o que corrigir.
    await pump(tester);

    final gesture = await tester.startGesture(
      tester.getCenter(find.byType(CalorieRing)),
    );
    var elapsed = Duration.zero;
    for (var i = 0; i < 6; i++) {
      elapsed += const Duration(milliseconds: 16);
      await gesture.moveBy(const Offset(0, 10), timeStamp: elapsed);
      await tester.pump(const Duration(milliseconds: 16));
    }

    // Ainda com o dedo na tela.
    expect(timeline, findsOne);

    await gesture.up(timeStamp: elapsed);
    await tester.pumpAndSettle();
  });

  testWidgets('um peteleco curto abre o painel inteiro', (tester) async {
    // Quem decide o destino é a velocidade, não a distância percorrida: 24 dp num gesto rápido
    // projetam muito além da metade, e obrigar a arrastar os 190 dp inteiros seria trocar
    // intenção por percurso.
    await pump(tester);

    // 90 dp em 96 ms. Descontada a folga que o reconhecedor come antes de aceitar o arrasto,
    // o painel andou menos da metade do curso — pela distância ele voltaria. Quem o abre é a
    // velocidade.
    await dragRing(tester, 90, steps: 6, stepMs: 16);

    expect(timeline, findsOne);
  });

  testWidgets('arrastar devagar até pouco abaixo do meio devolve o painel', (
    tester,
  ) async {
    await pump(tester);

    // A mesma distância do peteleco acima, em trinta vezes o tempo: sem velocidade na
    // soltura, a projeção quase não passa de onde o dedo parou.
    await dragRing(tester, 40, steps: 6, stepMs: 100);

    expect(timeline, findsNothing);
  });

  testWidgets('para cima com o painel fechado, o anel devolve a rolagem', (
    tester,
  ) async {
    // O anel ocupa quase um terço da tela. Um objeto desse tamanho que engole o gesto de rolar
    // faz o app parecer preso — e a Hoje inteira fica inalcançável para quem pousa o polegar
    // no meio dela.
    await pump(tester);

    final scroll = tester.widget<ListView>(find.byType(ListView)).controller!;
    expect(scroll.offset, 0);

    await dragRing(tester, -120);

    expect(scroll.offset, greaterThan(0));
    expect(timeline, findsNothing);
  });

  testWidgets('rolando, o número do herói reaparece na barra', (tester) async {
    // O anel grande sai de cena, e com ele sairia a única resposta que trouxe a pessoa ao app.
    await pump(tester);

    // Um anel só na tela, o grande.
    expect(find.byType(CalorieRing), findsOne);
    expect(find.text('kcal'), findsNothing);

    await tester.drag(find.byType(ListView), const Offset(0, -400));
    await tester.pumpAndSettle();

    // O segundo anel é a miniatura do cabeçalho, que só existe depois de o grande sair do
    // enquadramento — e ela leva o número junto.
    expect(find.byType(CalorieRing), findsNWidgets(2));
    expect(find.text('kcal'), findsOne);
  });
}
