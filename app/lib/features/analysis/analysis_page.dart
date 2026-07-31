import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../meals/meal_analysis_page.dart';
import '../videos/video_analysis_page.dart';

/// O que a câmera está apontando para.
enum AnalysisTab {
  /// Foto do prato.
  meal('Refeição'),

  /// Vídeo da série.
  form('Execução');

  const AnalysisTab(this.label);

  final String label;
}

final analysisTabProvider = StateProvider<AnalysisTab>(
  (ref) => AnalysisTab.meal,
);

/// Aba Analisar: as duas capturas que passam por IA.
///
/// Juntas porque o gesto é o mesmo — apontar a câmera e esperar o servidor responder — e
/// porque as duas gastam a mesma cota diária da assinatura. Quem chega pela folha de captura
/// rápida já cai na sub-aba certa.
class AnalysisView extends ConsumerWidget {
  const AnalysisView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tab = ref.watch(analysisTabProvider);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: SegmentedButton<AnalysisTab>(
            segments: [
              for (final segment in AnalysisTab.values)
                ButtonSegment(value: segment, label: Text(segment.label)),
            ],
            selected: {tab},
            showSelectedIcon: false,
            onSelectionChanged: (selection) =>
                ref.read(analysisTabProvider.notifier).state = selection.first,
          ),
        ),
        Expanded(
          child: IndexedStack(
            index: tab.index,
            children: const [MealAnalysisView(), VideoAnalysisView()],
          ),
        ),
      ],
    );
  }
}
