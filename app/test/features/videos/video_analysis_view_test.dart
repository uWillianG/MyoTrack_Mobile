import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myotrack/core/jobs/generation_controller.dart';
import 'package:myotrack/core/theme.dart';
import 'package:myotrack/features/home/today_controller.dart';
import 'package:myotrack/features/videos/data/video_models.dart';
import 'package:myotrack/features/videos/video_analysis_controller.dart';
import 'package:myotrack/features/videos/video_analysis_page.dart';

import '../home/home_test_harness.dart';

/// A análise de execução tem duas regras que valem ser fixadas: o herói é o **estado do
/// trabalho**, e a nota nula **não é zero** — nem na média do bloco, nem no cartão.
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
          home: const Scaffold(body: VideoAnalysisView()),
        ),
      ),
    );
    // Sem `pumpAndSettle`: com a análise em curso a barra de progresso é indeterminada, e uma
    // animação que nunca termina faria o `settle` estourar por tempo.
    await tester.pump();
    await tester.pump();
  }

  /// Rola até o alvo aparecer.
  ///
  /// A lista é preguiçosa de propósito — cada cartão do histórico carrega um vídeo —, e o que
  /// está abaixo da dobra ainda **não existe** na árvore. Sem rolar, um `find.text` de segundo
  /// cartão falha por um motivo que não é o que o teste quer medir.
  Future<void> scrollTo(WidgetTester tester, Finder target) => tester
      .scrollUntilVisible(target, 200, scrollable: find.byType(Scrollable));

  group('scoreAverage', () {
    VideoAnalysis com(int? score) => VideoAnalysis(id: '$score', score: score);

    test('sem histórico não há média', () {
      expect(scoreAverage(const []), isNull);
    });

    // O caso que motivou a função existir: um vídeo tremido não é execução nota zero.
    test('vídeo não avaliável não conta como zero', () {
      expect(scoreAverage([com(null)]), isNull);
      expect(scoreAverage([com(80), com(null)]), (average: 80, count: 1));
    });

    test('a média arredonda e conta só o que foi avaliado', () {
      expect(scoreAverage([com(81), com(82), com(84)]), (
        average: 82,
        count: 3,
      ));
    });
  });

  testWidgets('sem histórico, o herói explica o que a IA faz e o que não faz', (
    tester,
  ) async {
    await pump(tester, homeOverrides());

    expect(find.text('Gravar série'), findsOne);
    expect(find.textContaining('não substitui um profissional'), findsOne);
    // O enquadramento é a instrução que decide se o vídeo será avaliável, e por isso vem
    // antes de a câmera abrir.
    expect(find.textContaining('corpo inteiro no quadro'), findsOne);
  });

  testWidgets('com histórico, o herói mostra a média das notas', (
    tester,
  ) async {
    await pump(tester, homeOverrides(analyzedVideos: analisesDeVideo));

    // Duas análises no fixture, uma sem nota: a média é de uma só, e o texto diz isso.
    expect(find.text('nota da sua execução'), findsOne);
    expect(find.textContaining('não substitui um profissional'), findsNothing);
  });

  testWidgets('enquanto a análise corre, o herói vira o progresso', (
    tester,
  ) async {
    await pump(tester, [
      ...homeOverrides(),
      videoAnalysisProvider.overrideWith(_RunningAnalysis.new),
    ]);

    expect(find.text('Analisando'), findsOne);
    expect(find.text('Analisando sua execução…'), findsOne);
    expect(find.text('Gravar série'), findsNothing);
  });

  testWidgets('o vídeo que não deu para avaliar diz o motivo, e não uma nota', (
    tester,
  ) async {
    await pump(tester, homeOverrides(analyzedVideos: analisesDeVideo));
    await scrollTo(tester, find.text('Levantamento terra'));

    expect(find.text('Não avaliado'), findsOne);
    expect(find.textContaining('O quadril sai do quadro'), findsOne);
  });

  testWidgets('as correções e os acertos vêm em grupos nomeados', (
    tester,
  ) async {
    await pump(tester, homeOverrides(analyzedVideos: analisesDeVideo));
    await scrollTo(tester, find.text('O que já está bom'));

    expect(find.text('O que corrigir'), findsOne);
    // Os instantes são o que permite achar o trecho no vídeo.
    expect(find.text('em 0:04, 0:12'), findsOne);
  });
}

/// A mesma tela com uma análise em curso.
class _RunningAnalysis extends VideoAnalysisController {
  @override
  GenerationState build() =>
      const GenerationState(running: true, step: 'Analisando sua execução…');
}
