import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/design/blocks.dart';
import '../../core/design/tokens.dart';
import '../../core/widgets/glass_segmented.dart';
import '../diary/diary_page.dart';
import '../diet/diet_plan_page.dart';

/// As duas metades da nutrição.
enum NutritionTab {
  /// O que foi comido.
  diary('Diário', Icons.receipt_long),

  /// O que foi prescrito.
  plan('Plano', Icons.assignment_outlined);

  const NutritionTab(this.label, this.icon);

  /// Não aparece escrito no segmentado, que é só de ícone — é o balão do toque longo e o que o
  /// leitor de tela anuncia. Ver [GlassSegmented].
  final String label;

  /// **O assunto, não o talher** — e, antes disso, não o que a barra de baixo já desenha.
  ///
  /// Um garfo dos dois lados seria aqui o mesmo erro que uma câmera dos dois lados seria na
  /// Analisar: o controle desenhado e sem dizer nada. O que separa as metades é **registro
  /// contra prescrição**.
  ///
  /// A primeira tentativa foi herdar o ícone que o herói de cada tela já usa — calendário do
  /// [DiaryView], cardápio do [DietPlanView] —, na esperança de que o segmentado fosse a
  /// miniatura do que aparece ao tocar. Não se sustentou na tela montada: a barra de abas
  /// desenha `Icons.today` em "Hoje" e `Icons.restaurant` em "Nutrição", e o par herdado
  /// repetia as duas silhuetas a poucos centímetros delas. Dois controles com o mesmo desenho
  /// e destinos diferentes na mesma tela custam mais do que a herança rendia — quem olha de
  /// relance não sabe qual dos dois calendários acabou de tocar.
  ///
  /// O par novo sai do que as duas metades **são**: documentos. Ambas listam alimento, porção
  /// e caloria; o que difere é de quem é a lista. O diário é o **extrato** — o que de fato
  /// entrou, fechado, item por item, com a borda serrilhada de quem imprime depois do fato. O
  /// plano é a **prancheta** — o que foi entregue para seguir, e que continua valendo esteja
  /// ou não cumprido. Nenhum dos dois se repete em lugar nenhum do app.
  final IconData icon;
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
///
/// **O segmentado é o compacto, de ícone.** São duas opções de uma palavra cada: em largura
/// cheia isso vira uma tira de 350 dp com "Diário" e "Plano" boiando no meio de dois alvos
/// grandes demais para o que decidem, e ela atravessa a primeira faixa da tela — justamente
/// onde o herói do dia precisa caber sem rolagem. Encolhido a 134 o controle diz a mesma coisa
/// e devolve a faixa ao conteúdo, que é o que se veio ver.
class NutritionView extends ConsumerWidget {
  const NutritionView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tab = ref.watch(nutritionTabProvider);

    // **A esmeralda nas duas, e não uma cor por metade como na Analisar.** Lá o segmentado
    // atravessa duas famílias — refeição é esmeralda, execução é índigo — e a cor da escolhida
    // é o que antecipa para onde se vai. Aqui as duas metades são nutrição, e quem diz qual está
    // valendo é a pastilha; a cor sobra para o outro trabalho dela, que é dizer de quem é este
    // controle. Deixá-lo neutro seria o certo para um filtro que não pertence a família nenhuma
    // — um seletor de período —, e é exatamente o que ele passaria a parecer pousado sobre uma
    // tela que é verde de ponta a ponta nas duas metades.
    final ink = Blocks.nutrition(Theme.of(context).brightness).ink;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(Space.gutter, 8, Space.gutter, 0),
          child: GlassSegmented<NutritionTab>(
            compact: true,
            segments: [
              for (final segment in NutritionTab.values)
                GlassSegment(
                  value: segment,
                  icon: segment.icon,
                  label: segment.label,
                  color: ink,
                ),
            ],
            value: tab,
            onChanged: (next) =>
                ref.read(nutritionTabProvider.notifier).state = next,
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
