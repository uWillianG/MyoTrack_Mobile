import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/design/blocks.dart';
import '../../core/design/tokens.dart';
import '../../core/widgets/glass_segmented.dart';
import '../meals/meal_analysis_page.dart';
import '../videos/video_analysis_page.dart';

/// O que a câmera está apontando para.
enum AnalysisTab {
  /// Foto do prato.
  meal('Refeição', Icons.restaurant),

  /// Vídeo da série.
  form('Execução', Icons.fitness_center);

  const AnalysisTab(this.label, this.icon);

  /// Não aparece escrito no segmentado — é o balão do toque longo e o que o leitor de tela
  /// anuncia. Ver [GlassSegmented].
  final String label;

  /// **O assunto, não a câmera.** As duas metades desta aba são a mesma ferramenta apontada
  /// para coisas diferentes; ícone de câmera nas duas não separaria nada. Garfo e halter são
  /// os mesmos ícones que Nutrição e Treino já usam no resto do app.
  final IconData icon;
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

    final brightness = Theme.of(context).brightness;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(Space.gutter, 8, Space.gutter, 0),
          child: GlassSegmented<AnalysisTab>(
            compact: true,
            segments: [
              GlassSegment(
                value: AnalysisTab.meal,
                icon: AnalysisTab.meal.icon,
                label: AnalysisTab.meal.label,
                // A cor da metade que está por baixo: a análise de refeição é esmeralda e a
                // de execução é índigo, e o segmentado passa a anunciar para onde se vai.
                color: Blocks.nutrition(brightness).ink,
              ),
              GlassSegment(
                value: AnalysisTab.form,
                icon: AnalysisTab.form.icon,
                label: AnalysisTab.form.label,
                color: Blocks.workout(brightness).ink,
              ),
            ],
            value: tab,
            onChanged: (next) =>
                ref.read(analysisTabProvider.notifier).state = next,
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
