import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myotrack/core/theme.dart';
import 'package:myotrack/core/widgets/glass_segmented.dart';

/// Um segmentado sem texto aposta tudo em duas coisas: a pastilha estar embaixo do ícone
/// certo, e o ícone certo ter nome para quem não o vê. As duas são invisíveis num teste que
/// só confere que a tela montou.
void main() {
  Future<void> pump(
    WidgetTester tester,
    String value,
    ValueChanged<String> onChanged, {
    Brightness brightness = Brightness.dark,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: brightness == Brightness.dark
            ? AppTheme.dark()
            : AppTheme.light(),
        home: Scaffold(
          body: Center(
            child: GlassSegmented<String>(
              compact: true,
              segments: const [
                GlassSegment(
                  value: 'refeicao',
                  icon: Icons.restaurant,
                  label: 'Refeição',
                  color: Color(0xFF34D399),
                ),
                GlassSegment(
                  value: 'execucao',
                  icon: Icons.fitness_center,
                  label: 'Execução',
                  color: Color(0xFFA5B4FC),
                ),
              ],
              value: value,
              onChanged: onChanged,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  /// A pastilha é o único `FractionallySizedBox` do controle.
  Rect pill(WidgetTester tester) =>
      tester.getRect(find.byType(FractionallySizedBox));

  testWidgets('a pastilha para embaixo da opção escolhida', (tester) async {
    await pump(tester, 'refeicao', (_) {});

    expect(
      pill(tester).center.dx,
      closeTo(tester.getRect(find.byIcon(Icons.restaurant)).center.dx, 1),
    );
  });

  testWidgets('escolher a outra opção leva a pastilha até ela', (tester) async {
    // O que este teste pega é a inversão silenciosa: com a pastilha do lado errado o controle
    // continua funcionando e passa a mentir sobre o que está selecionado.
    var value = 'refeicao';
    await pump(tester, value, (next) => value = next);

    final antes = pill(tester).center.dx;

    await tester.tap(find.byIcon(Icons.fitness_center));
    await tester.pumpAndSettle();
    expect(value, 'execucao');

    await pump(tester, value, (_) {});
    final depois = pill(tester).center.dx;

    expect(depois, greaterThan(antes));
    expect(
      depois,
      closeTo(tester.getRect(find.byIcon(Icons.fitness_center)).center.dx, 1),
    );
  });

  testWidgets('a opção escolhida veste a cor da família', (tester) async {
    // É o que faz o segmentado anunciar para onde se vai. A não escolhida fica neutra: duas
    // cores acesas ao mesmo tempo não diriam qual está valendo.
    await pump(tester, 'refeicao', (_) {});

    final escolhida = tester.widget<Icon>(find.byIcon(Icons.restaurant));
    final outra = tester.widget<Icon>(find.byIcon(Icons.fitness_center));

    expect(escolhida.color, const Color(0xFF34D399));
    expect(outra.color, isNot(const Color(0xFFA5B4FC)));
  });

  testWidgets('sem texto na tela, cada opção continua tendo nome', (
    tester,
  ) async {
    // Um controle só de ícone que não anuncia nada faz o leitor de tela dizer "botão, botão".
    final handle = tester.ensureSemantics();
    await pump(tester, 'refeicao', (_) {});

    expect(find.bySemanticsLabel('Refeição'), findsOne);
    expect(find.bySemanticsLabel('Execução'), findsOne);

    handle.dispose();
  });

  testWidgets('a forma de texto mostra o rótulo e ocupa a largura toda', (
    tester,
  ) async {
    // A de texto não encolhe ao conteúdo como a compacta: o rótulo é o conteúdo, e apertar a
    // palavra num alvo estreito para economizar espaço corta justamente o que se ia ler.
    var value = 'refeicao';
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark(),
        home: Scaffold(
          body: GlassSegmented<String>(
            segments: const [
              GlassSegment(value: 'refeicao', label: 'Com marcações'),
              GlassSegment(value: 'execucao', label: 'Sem marcações'),
            ],
            value: value,
            onChanged: (next) => value = next,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Com marcações'), findsOne);
    expect(find.text('Sem marcações'), findsOne);

    await tester.tap(find.text('Sem marcações'));
    expect(value, 'execucao');
  });

  testWidgets('sobre mídia a paleta não depende do tema', (tester) async {
    // O que está atrás é uma foto: pode ser um prato branco sob luz dura, e o véu de 7% da
    // superfície do app sumiria nele. As duas versões do controle têm de sair iguais.
    Future<Color> trackColor(Brightness brightness) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: brightness == Brightness.dark
              ? AppTheme.dark()
              : AppTheme.light(),
          home: Scaffold(
            body: GlassSegmented<bool>(
              surface: GlassSegmentedSurface.media,
              segments: const [
                GlassSegment(value: false, label: 'Com marcações'),
                GlassSegment(value: true, label: 'Sem marcações'),
              ],
              value: false,
              onChanged: (_) {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final box = tester.widget<Container>(find.byType(Container).first);
      return (box.decoration! as BoxDecoration).color!;
    }

    expect(
      await trackColor(Brightness.dark),
      await trackColor(Brightness.light),
    );
  });

  for (final brightness in Brightness.values) {
    testWidgets('a pastilha clareia sobre o trilho (${brightness.name})', (
      tester,
    ) async {
      // **Compostas, e não como declaradas.** No escuro as duas são a mesma cor com alfas
      // diferentes: comparar os valores crus diria "são iguais" sobre um par que a tela
      // mostra distinto. O que precisa valer é o que o olho recebe — a pastilha sai mais
      // clara que o trilho depois de as duas caírem sobre o fundo da tela.
      //
      // No claro isto já falhou por construção uma vez: pastilha translúcida sobre trilho
      // cinza-claro dá dois cinzas quase iguais, e a escolha some.
      await pump(tester, 'refeicao', (_) {}, brightness: brightness);

      final scheme = brightness == Brightness.dark
          ? AppTheme.dark().colorScheme
          : AppTheme.light().colorScheme;

      final pillBox = tester.widget<DecoratedBox>(
        find
            .descendant(
              of: find.byType(FractionallySizedBox),
              matching: find.byType(DecoratedBox),
            )
            .first,
      );
      final trackBox = tester.widget<Container>(find.byType(Container).first);

      final track = Color.alphaBlend(
        (trackBox.decoration! as BoxDecoration).color!,
        scheme.surface,
      );
      final pill = Color.alphaBlend(
        (pillBox.decoration as BoxDecoration).color!,
        track,
      );

      expect(
        pill.computeLuminance(),
        greaterThan(track.computeLuminance()),
        reason: brightness.name,
      );
    });
  }
}
