import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myotrack/core/design/blocks.dart';
import 'package:myotrack/core/theme.dart';
import 'package:myotrack/features/videos/form_scrubber.dart';

/// A avaliação de execução tinha duas metades sem relação: o vídeo com o esqueleto e a lista
/// do que corrigir. A lista dizia "em 0:02" e cabia ao usuário achar 0:02 numa barra de sete
/// segundos com o polegar.
///
/// O que estes testes prendem é a ligação entre elas — nos dois sentidos, porque cada um
/// responde uma pergunta diferente e é fácil implementar só um.
void main() {
  Future<void> pump(
    WidgetTester tester,
    Playhead playhead, {
    List<double> marks = const [2, 4],
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark(),
        home: Scaffold(
          body: Column(
            children: [
              FormScrubber(
                playhead: playhead,
                marks: marks,
                colors: Blocks.workout(Brightness.dark),
                playing: false,
                onTogglePlay: () {},
              ),
              IssueRow(
                playhead: playhead,
                message: 'Lombar arredondando na subida',
                marks: const [2],
                colors: Blocks.workout(Brightness.dark),
              ),
              IssueRow(
                playhead: playhead,
                message: 'Quadril subindo antes da barra',
                marks: const [4],
                colors: Blocks.workout(Brightness.dark),
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  /// A correção só está "acesa" quando o retângulo dela ganhou cor de fundo.
  bool lit(WidgetTester tester, String message) {
    final container = tester.widget<AnimatedContainer>(
      find
          .ancestor(
            of: find.text(message),
            matching: find.byType(AnimatedContainer),
          )
          .first,
    );
    final decoration = container.decoration! as BoxDecoration;
    return decoration.color != Colors.transparent;
  }

  testWidgets('a correção do instante acende quando o vídeo passa por ele', (
    tester,
  ) async {
    final playhead = Playhead()..onSeek = (_) {};
    addTearDown(playhead.dispose);
    await pump(tester, playhead);

    playhead.report(seconds: 0, duration: 7);
    await tester.pumpAndSettle();
    expect(lit(tester, 'Lombar arredondando na subida'), isFalse);
    expect(lit(tester, 'Quadril subindo antes da barra'), isFalse);

    playhead.report(seconds: 2, duration: 7);
    await tester.pumpAndSettle();
    expect(lit(tester, 'Lombar arredondando na subida'), isTrue);
    // Uma de cada vez: duas acesas ao mesmo tempo não diriam qual delas está acontecendo.
    expect(lit(tester, 'Quadril subindo antes da barra'), isFalse);

    playhead.report(seconds: 4, duration: 7);
    await tester.pumpAndSettle();
    expect(lit(tester, 'Lombar arredondando na subida'), isFalse);
    expect(lit(tester, 'Quadril subindo antes da barra'), isTrue);
  });

  testWidgets('tocar na correção leva o vídeo ao instante dela', (
    tester,
  ) async {
    final sought = <double>[];
    final playhead = Playhead()..onSeek = sought.add;
    addTearDown(playhead.dispose);
    await pump(tester, playhead);
    playhead.report(seconds: 0, duration: 7);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Quadril subindo antes da barra'));
    await tester.pumpAndSettle();

    expect(sought, [4]);
  });

  testWidgets('sem vídeo aberto, a correção não promete um atalho', (
    tester,
  ) async {
    // Prometer "toque para ir ao instante" antes de haver para onde ir é pior que não
    // prometer nada: a pessoa toca, não acontece nada, e passa a desconfiar do resto.
    final playhead = Playhead();
    addTearDown(playhead.dispose);
    await pump(tester, playhead);

    expect(playhead.canSeek, isFalse);
    expect(find.textContaining('toque para ir ao instante'), findsNothing);
    expect(find.text('em 0:02'), findsOne);
  });

  testWidgets('arrastar a barra busca o instante já no encostar', (
    tester,
  ) async {
    // Responder na soltura é o que faz um controle parecer um controle remoto com pilha
    // fraca. O toque já busca.
    final sought = <double>[];
    final playhead = Playhead()..onSeek = sought.add;
    addTearDown(playhead.dispose);
    await pump(tester, playhead);
    playhead.report(seconds: 0, duration: 7);
    await tester.pumpAndSettle();

    final track = tester.getRect(find.byKey(FormScrubber.trackKey));
    final gesture = await tester.startGesture(
      Offset(track.left + track.width / 2, track.center.dy),
    );
    // Tempo de o reconhecedor de toque vencer a disputa — e nenhum evento de soltura ainda: o
    // dedo continua na tela, e o instante já foi buscado.
    await tester.pump(const Duration(milliseconds: 150));

    expect(sought, hasLength(1));
    expect(sought.single, closeTo(3.5, 0.3));

    await gesture.up();
    await tester.pumpAndSettle();
  });
}
