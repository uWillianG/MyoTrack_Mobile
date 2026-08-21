import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myotrack/core/widgets/pressable.dart';

/// O aperto do toque só vale se acontecer no instante do encosto. Esperar a soltura é
/// exatamente o que se está tentando corrigir, e a diferença entre as duas coisas não aparece
/// em nenhum teste que apenas confira que a tela montou.
void main() {
  Future<void> pump(
    WidgetTester tester, {
    bool enabled = true,
    bool reducedMotion = false,
  }) async {
    await tester.pumpWidget(
      MediaQuery(
        data: MediaQueryData(disableAnimations: reducedMotion),
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: Center(
            child: PressableScale(
              enabled: enabled,
              // Pintado, e não uma caixa vazia: o `Listener` respeita o alvo do filho, que é
              // o certo — quem recebe o toque é o botão que ele embrulha, não um retângulo
              // invisível maior que ele.
              child: const ColoredBox(
                color: Color(0xFF000000),
                child: SizedBox(height: 52, width: 200),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Pelo retângulo na tela, e não pelo tamanho de layout: a escala é pintura, não medida —
  /// `getSize` devolveria 200 com o botão apertado ou solto.
  double scale(WidgetTester tester) =>
      tester.getRect(find.byType(SizedBox)).width / 200;

  testWidgets('encolhe no encosto do dedo, antes de soltar', (tester) async {
    await pump(tester);
    expect(scale(tester), 1);

    final gesture = await tester.startGesture(
      tester.getCenter(find.byType(PressableScale)),
    );
    // Alguns quadros, e nenhuma soltura: se o aperto dependesse do `pointerUp`, aqui ainda
    // estaria em 1.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 48));
    expect(scale(tester), lessThan(1));

    await gesture.up();
    await tester.pumpAndSettle();
    expect(scale(tester), moveTo(1));
  });

  testWidgets('desistir arrastando para fora devolve o tamanho', (
    tester,
  ) async {
    await pump(tester);

    final gesture = await tester.startGesture(
      tester.getCenter(find.byType(PressableScale)),
    );
    await tester.pump(const Duration(milliseconds: 48));
    await gesture.cancel();
    await tester.pumpAndSettle();

    expect(scale(tester), moveTo(1));
  });

  testWidgets('desligado não cede ao toque', (tester) async {
    // O botão está esperando a resposta do servidor. Ceder ao toque prometeria uma segunda
    // tentativa que não vai acontecer.
    await pump(tester, enabled: false);

    final gesture = await tester.startGesture(
      tester.getCenter(find.byType(PressableScale)),
    );
    await tester.pump(const Duration(milliseconds: 48));
    expect(scale(tester), 1);

    await gesture.up();
  });

  testWidgets('movimento reduzido tira o deslocamento, não a resposta', (
    tester,
  ) async {
    // Quem pediu menos movimento continua com o respingo e a mudança de cor do Material —
    // o que sai é o objeto se mexendo.
    await pump(tester, reducedMotion: true);

    final gesture = await tester.startGesture(
      tester.getCenter(find.byType(PressableScale)),
    );
    await tester.pump(const Duration(milliseconds: 48));
    expect(scale(tester), 1);

    await gesture.up();
  });
}

/// A mola assenta em 1, mas não em exatamente 1: ela chega por aproximação.
Matcher moveTo(double value) => closeTo(value, 0.005);
