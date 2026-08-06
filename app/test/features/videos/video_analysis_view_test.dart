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

    // Três análises no fixture, uma sem nota: a média conta duas, e o texto diz quantas.
    expect(find.text('78'), findsOne);
    expect(find.text('média de 2 execuções'), findsOne);
    expect(find.textContaining('não substitui um profissional'), findsNothing);
  });

  testWidgets('a lista traz exercício, hora e nota — e nada aberto', (
    tester,
  ) async {
    await pump(tester, homeOverrides(analyzedVideos: analisesDeVideo));

    // O dia é o rótulo do bloco, e as execuções dele são linhas.
    expect(find.text('Hoje'), findsOne);
    expect(find.text('2 execuções'), findsOne);
    expect(find.text('Agachamento livre'), findsOne);
    expect(find.text('18:20 · 82 / 100 · 8 repetições'), findsOne);

    // Nada da avaliação aparece antes do toque — nem o vídeo, nem as correções.
    expect(find.text('O que corrigir'), findsNothing);
    expect(find.text('Ver com o esqueleto'), findsNothing);
  });

  testWidgets('tocar no exercício abre a avaliação daquela série', (
    tester,
  ) async {
    await pump(tester, homeOverrides(analyzedVideos: analisesDeVideo));

    await tester.tap(find.text('Agachamento livre'));
    await tester.pumpAndSettle();

    expect(find.text('O que corrigir'), findsOne);
    expect(find.text('O que já está bom'), findsOne);
    // O lugar do vídeo aparece, mas o arquivo continua só baixando no toque.
    expect(find.text('Ver com o esqueleto'), findsOne);
    // E só aquela: a do mesmo dia continua fechada.
    expect(find.text('Supino reto'), findsOne);
    expect(find.textContaining('Escápulas presas'), findsNothing);
  });

  testWidgets('a análise que acabou de sair já vem aberta', (tester) async {
    await pump(tester, [
      ...homeOverrides(analyzedVideos: analisesDeVideo),
      videoAnalysisProvider.overrideWith(_JustAnalyzed.new),
    ]);

    // Sem nenhum toque: as correções da execução das 18:20 estão à vista.
    expect(find.text('O que corrigir'), findsOne);
    expect(find.textContaining('Joelho entrando'), findsOne);
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

    // Na linha fechada, nota nula é uma afirmação sobre o vídeo — nunca um zero.
    expect(find.text('07:45 · não avaliado · 5 repetições'), findsOne);

    await tester.tap(find.text('Levantamento terra'));
    await tester.pumpAndSettle();
    expect(find.textContaining('O quadril sai do quadro'), findsOne);
  });

  testWidgets('as correções e os acertos vêm em grupos nomeados', (
    tester,
  ) async {
    await pump(tester, homeOverrides(analyzedVideos: analisesDeVideo));
    await tester.tap(find.text('Agachamento livre'));
    await tester.pumpAndSettle();

    expect(find.text('O que corrigir'), findsOne);
    expect(find.text('O que já está bom'), findsOne);
    // Os instantes são o que permite achar o trecho no vídeo.
    expect(find.text('em 0:04, 0:12'), findsOne);
  });

  test('o histórico de execuções é agrupado pela data da análise', () {
    final days = groupAnalysesByDay(analisesDeVideo, DateTime(2026, 8, 4, 15));

    expect(days.map((d) => d.label), ['Hoje', '2 de agosto']);
    expect(days.first.items, hasLength(2));
  });
}

/// A mesma tela com uma análise em curso.
class _RunningAnalysis extends VideoAnalysisController {
  @override
  GenerationState build() =>
      const GenerationState(running: true, step: 'Analisando sua execução…');
}

/// A tela logo depois de uma análise terminar: o trabalho parou e o resultado é o da lista.
class _JustAnalyzed extends VideoAnalysisController {
  @override
  VideoAnalysis? get result => analisesDeVideo.first;
}
