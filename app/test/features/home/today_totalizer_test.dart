import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:myotrack/core/theme.dart';
import 'package:myotrack/features/diary/diary_controller.dart';
import 'package:myotrack/features/home/today_controller.dart';
import 'package:myotrack/features/home/today_page.dart';

import 'home_test_harness.dart';

/// O totalizador de kcal da Hoje, e as duas coisas que o mantinham parado.
///
/// A primeira: o refresh invalidava `diaryDayProvider`, que não busca nada — ele repassa o que
/// a família guardou, e invalidação desce para os dependentes em vez de subir para as
/// dependências. O número era o mesmo depois de puxar a lista, depois de fotografar um prato,
/// depois de fechar o dia.
///
/// A segunda: a Hoje lia "o dia aberto", que é o cursor do carrossel do diário. Quem arrastava
/// até ontem lá dentro voltava para uma Hoje somando ontem — e como as abas ficam montadas no
/// IndexedStack, ela nunca reconstruía sozinha para se corrigir.
///
/// Nenhum teste pegava as duas porque o harness sobrescrevia o repassador **e** a família: com
/// o falso no meio, a tela nunca atravessava a cadeia que usa de verdade.
void main() {
  const smallPhone = Size(360, 800);

  // 15h de uma terça: a faixa da tarde, em que o herói da tela é a nutrição — que é onde o
  // número grande mora.
  final tarde = DateTime(2026, 8, 4, 15);
  final ontem = DateTime(2026, 8, 3);

  Future<void> pump(WidgetTester tester, List<Override> overrides) async {
    tester.view.physicalSize = smallPhone;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [nowProvider.overrideWithValue(() => tarde), ...overrides],
        child: MaterialApp.router(
          theme: AppTheme.light(),
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

  /// Puxar a lista para baixo, longe do anel — que trata o arrasto vertical por conta própria
  /// e abriria a linha do tempo em vez de recarregar.
  Future<void> pullToRefresh(WidgetTester tester) async {
    await tester.dragFrom(const Offset(180, 700), const Offset(0, 320));
    await tester.pumpAndSettle();
  }

  testWidgets('puxar para atualizar refaz a busca do dia', (tester) async {
    // A meta é 2100: 1476 consumidos deixam 624, e 1800 deixam 300.
    var consumido = 1476;

    await pump(
      tester,
      homeOverrides(dayOf: (date) => diaryDay(kcal: consumido)),
    );
    expect(find.text('624'), findsOneWidget);

    // O prato que entrou por outra tela enquanto esta estava aberta.
    consumido = 1800;
    await pullToRefresh(tester);

    expect(
      find.text('300'),
      findsOneWidget,
      reason: 'o refresh precisa sair para a rede, e não reencostar no cache',
    );
    expect(find.text('624'), findsNothing);
  });

  testWidgets('a Hoje soma hoje, com o carrossel do diário parado em ontem', (
    tester,
  ) async {
    await pump(tester, [
      ...homeOverrides(
        dayOf: (date) =>
            diaryDay(kcal: date == ontem ? 900 : 1476, meals: const [900]),
      ),
      // É o que o carrossel deixa para trás quando alguém arrasta um dia e volta para a Hoje.
      diaryDateProvider.overrideWith((ref) => ontem),
    ]);

    // 2100 − 1476 = 624 (hoje). Se a tela seguisse o cursor, mostraria 1200.
    expect(find.text('624'), findsOneWidget);
    expect(find.text('1.200'), findsNothing);
  });
}
