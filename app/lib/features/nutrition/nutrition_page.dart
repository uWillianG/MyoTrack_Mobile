import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/design/tokens.dart';
import '../diary/diary_page.dart';
import '../diet/diet_plan_page.dart';

/// As duas metades da nutrição.
enum NutritionTab {
  /// O que foi comido.
  diary('Diário'),

  /// O que foi prescrito.
  plan('Plano');

  const NutritionTab(this.label);

  final String label;
}

final nutritionTabProvider = StateProvider<NutritionTab>(
  (ref) => NutritionTab.diary,
);

/// Aba Nutrição: diário e plano lado a lado.
///
/// Estavam em duas rotas sem ligação nenhuma — `/diario` e `/dieta` —, e a pergunta que leva
/// a uma leva à outra: "comi o que era para comer?" só se responde com as duas à vista. O
/// segmentado é o que troca; as telas em si são as mesmas de sempre, e as rotas continuam
/// existindo para os links de fora.
class NutritionView extends ConsumerWidget {
  const NutritionView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tab = ref.watch(nutritionTabProvider);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(Space.gutter, 8, Space.gutter, 0),
          child: SegmentedButton<NutritionTab>(
            segments: [
              for (final segment in NutritionTab.values)
                ButtonSegment(value: segment, label: Text(segment.label)),
            ],
            selected: {tab},
            showSelectedIcon: false,
            onSelectionChanged: (selection) =>
                ref.read(nutritionTabProvider.notifier).state = selection.first,
          ),
        ),
        Expanded(
          child: IndexedStack(
            index: tab.index,
            children: const [DiaryView(), DietPlanView()],
          ),
        ),
      ],
    );
  }
}
