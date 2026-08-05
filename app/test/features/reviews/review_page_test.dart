import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myotrack/core/theme.dart';
import 'package:myotrack/features/home/today_controller.dart';
import 'package:myotrack/features/reviews/review_controller.dart';
import 'package:myotrack/features/reviews/review_page.dart';

import '../home/home_test_harness.dart';

/// A fila de revisão é a única tela cuja família de cor muda com o segmentado — porque o que
/// ela alimenta muda junto. O resto do que estes testes fixam é a ponta da fila: quem revisa
/// abre pelo mais antigo, e "sem data" não é o mesmo que "antiquíssimo".
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
        child: MaterialApp(theme: AppTheme.dark(), home: const ReviewPage()),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('oldestPending', () {
    ReviewQueueItem em(String id, String? iso) =>
        ReviewQueueItem(id: id, createdAt: iso);

    test('fila vazia não tem ponta', () {
      expect(oldestPending(const []), isNull);
    });

    // O que a função existe para evitar: o mais antigo raramente é o primeiro que o servidor
    // devolve, e abrir o primeiro deixa o plano esquecido esquecido.
    test('a ponta não é o primeiro da lista', () {
      final items = [
        em('a', '2026-08-02T09:00:00'),
        em('b', '2026-07-29T18:00:00'),
        em('c', '2026-08-04T07:00:00'),
      ];
      expect(oldestPending(items)?.id, 'b');
    });

    test('item sem data fica de fora da comparação', () {
      final items = [
        em('sem-data', null),
        em('com-data', '2026-08-02T09:00:00'),
      ];
      expect(oldestPending(items)?.id, 'com-data');
    });

    // Fila inteira sem data ainda precisa de uma ponta: senão a manchete perde a ação.
    test('sem data nenhuma, a ponta é o primeiro', () {
      final items = [em('a', null), em('b', null)];
      expect(oldestPending(items)?.id, 'a');
    });
  });

  testWidgets('sem papel de revisor, a tela diz que não é para você', (
    tester,
  ) async {
    await pump(tester, homeOverrides());

    expect(find.text('Esta área é para revisores.'), findsOne);
    // A diferença que a tela precisa fazer: lista vazia pareceria "nada pendente".
    expect(find.textContaining('Nada pendente'), findsNothing);
  });

  testWidgets('a manchete conta a fila e a idade da ponta', (tester) async {
    await pump(
      tester,
      homeOverrides(
        reviewableKinds: ReviewKind.values,
        reviewQueue: filaDeRevisao,
      ),
    );

    expect(find.text('3'), findsOne);
    expect(find.text('esperando — o mais antigo, há 6 dias'), findsOne);
    expect(find.text('Revisar o mais antigo'), findsOne);
  });

  testWidgets('a fila vazia troca o número por um recado, e some a ação', (
    tester,
  ) async {
    await pump(tester, homeOverrides(reviewableKinds: ReviewKind.values));

    expect(find.text('Nada pendente.'), findsOne);
    expect(find.text('Revisar o mais antigo'), findsNothing);
  });

  testWidgets('o segmentado troca o assunto, e o rótulo do bloco junto', (
    tester,
  ) async {
    await pump(
      tester,
      homeOverrides(
        reviewableKinds: ReviewKind.values,
        reviewQueue: filaDeRevisao,
      ),
    );

    // "Treinos" aparece duas vezes: no segmentado e no rótulo do bloco.
    expect(find.text('Treinos'), findsExactly(2));
    expect(find.text('Dietas'), findsOne);

    await tester.tap(find.text('Dietas'));
    await tester.pumpAndSettle();

    expect(find.text('Dietas'), findsExactly(2));
    expect(find.text('Treinos'), findsOne);
  });

  testWidgets('cada linha da fila diz a espera, o aluno e a versão', (
    tester,
  ) async {
    await pump(
      tester,
      homeOverrides(
        reviewableKinds: ReviewKind.values,
        reviewQueue: filaDeRevisao,
      ),
    );

    expect(find.text('Esperando há 6 dias'), findsOne);
    expect(find.text('joao.p.ferreira@exemplo.com'), findsOne);
    expect(find.text('versão 5'), findsOne);
  });
}
