import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myotrack/core/jobs/generation_controller.dart';
import 'package:myotrack/core/theme.dart';
import 'package:myotrack/features/coach/coach_controller.dart';
import 'package:myotrack/features/coach/coach_page.dart';
import 'package:myotrack/features/home/today_controller.dart';

import '../home/home_test_harness.dart';

/// O coach é a única tela sem herói — a conversa é a tela. O que estes testes fixam é o que
/// sobra dessa decisão: o bloco só existe enquanto não há conversa, e a régua de dia só aparece
/// quando o dia muda.
void main() {
  const smallPhone = Size(360, 800);
  final agora = DateTime(2026, 8, 4, 15);

  Future<void> pump(WidgetTester tester, List<Override> overrides) async {
    tester.view.physicalSize = smallPhone;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [nowProvider.overrideWithValue(() => agora), ...overrides],
        child: MaterialApp(theme: AppTheme.dark(), home: const CoachPage()),
      ),
    );
    await tester.pump();
    await tester.pump();
  }

  group('daySeparator', () {
    CoachMessage em(String iso) => CoachMessage(id: iso, createdAt: iso);

    // A tabela é a razão de a função ser pura: "a segunda mensagem do mesmo dia não repete o
    // rótulo" é o tipo de regra que ninguém confere à mão em cada build.
    test('a primeira mensagem sempre abre um dia', () {
      final messages = [em('2026-08-04T09:00:00')];
      expect(daySeparator(messages, 0, agora), 'Hoje');
    });

    test('mensagem do mesmo dia não repete o rótulo', () {
      final messages = [em('2026-08-04T09:00:00'), em('2026-08-04T09:01:00')];
      expect(daySeparator(messages, 1, agora), isNull);
    });

    test('a virada do dia traz a régua de volta', () {
      final messages = [em('2026-08-03T22:00:00'), em('2026-08-04T07:00:00')];
      expect(daySeparator(messages, 0, agora), 'Ontem');
      expect(daySeparator(messages, 1, agora), 'Hoje');
    });

    test('mais de um dia atrás vira a data', () {
      final messages = [em('2026-07-28T10:00:00')];
      expect(daySeparator(messages, 0, agora), '28 de julho');
    });

    // Mensagem sem data é o que o servidor devolve enquanto a resposta ainda está sendo
    // gravada; ela não pode inventar uma régua.
    test('mensagem sem data não abre dia nenhum', () {
      expect(daySeparator([const CoachMessage(id: 'x')], 0, agora), isNull);
    });
  });

  testWidgets('sem conversa, o bloco diz o que ele sabe e o que ele não é', (
    tester,
  ) async {
    await pump(tester, homeOverrides());

    expect(find.textContaining('não substitui avaliação médica'), findsOne);
    // As sugestões são tocáveis: ler e ter que redigitar seria pedir o trabalho duas vezes.
    expect(find.text('Posso treinar com dor no ombro?'), findsOne);
  });

  testWidgets('com conversa, o bloco some e as réguas de dia aparecem', (
    tester,
  ) async {
    await pump(tester, homeOverrides(coachMessages: conversaComOCoach));

    expect(find.textContaining('não substitui avaliação médica'), findsNothing);
    // A conversa abre no fim: "Hoje" está à vista, e o dia anterior fica acima da dobra — numa
    // lista invertida e preguiçosa, ele ainda nem existe na árvore.
    expect(find.text('Hoje'), findsOne);

    await tester.scrollUntilVisible(
      find.text('Ontem'),
      200,
      // O da conversa, e não "o Scrollable": o campo de escrever tem um só dele, e
      // `find.byType(Scrollable)` acha os dois.
      scrollable: find.descendant(
        of: find.byType(ListView),
        matching: find.byType(Scrollable),
      ),
    );
    expect(find.text('Ontem'), findsOne);
  });

  testWidgets('enquanto o coach responde, o compositor fica bloqueado', (
    tester,
  ) async {
    await pump(tester, [
      ...homeOverrides(coachMessages: conversaComOCoach),
      coachProvider.overrideWith(_Thinking.new),
    ]);

    expect(find.text('O coach está pensando…'), findsOne);
    // Sem isto, uma segunda pergunta entraria na fila por cima da primeira.
    expect(tester.widget<TextField>(find.byType(TextField)).enabled, isFalse);
  });
}

/// O coach no meio de uma resposta.
class _Thinking extends CoachController {
  @override
  GenerationState build() =>
      const GenerationState(running: true, step: 'O coach está pensando…');
}
