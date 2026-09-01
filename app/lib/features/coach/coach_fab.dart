import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/design/materials.dart';
import '../../core/design/tokens.dart';
import '../../core/router.dart';

/// O botão do coach, flutuando no canto de todas as abas.
///
/// **Por que ele flutua.** O outro caminho até a conversa é trocar de aba e achar um item no
/// meio da lista da Conta — dois toques e uma lista para percorrer, para o recurso que mais
/// distingue o produto. E a dúvida que ele responde ("posso trocar esse exercício?", "isso cabe
/// na minha meta de hoje?") nasce olhando qualquer uma das abas em que ele aparece, não uma
/// delas em particular.
///
/// **O mesmo balão da linha "Coach" da aba Conta**, e não um segundo desenho para a mesma
/// coisa: dois caminhos até um recurso com vocabulários diferentes é o que faz o usuário achar
/// que são dois recursos.
///
/// **Por que não é esmeralda cheio.** Na Hoje ele divide a tira de baixo com o `Registrar`,
/// que é a ação principal da tela e já ocupa a cor cheia (§4 do design system: a coisa mais
/// berrante da tela é o que se quer que a pessoa faça). Dois botões cheios lado a lado
/// cancelariam os dois — o coach ganhou o canto da mão direita, e não precisa ganhar a cor
/// também.
///
/// **Ele é de vidro, e é o único flutuante que é.** Os dois moram sobre o conteúdo rolando, e
/// o material diz qual é qual sem precisar de rótulo: o `Registrar` é opaco porque é uma ação
/// que interrompe, o coach é translúcido porque é uma porta que fica aberta. Pelo mesmo motivo
/// o ícone é neutro e não esmeralda: sobre vidro, um traço da marca a 54 dp do botão da marca
/// faria os dois parecerem metades do mesmo controle.
class CoachFab extends StatelessWidget {
  const CoachFab({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Semantics(
      button: true,
      label: 'Falar com o coach',
      child: Tooltip(
        message: 'Falar com o coach',
        child: GlassPanel(
          radius: Radii.mdAll,
          // O borrão vale a passada aqui: ele flutua sobre a lista, e é o que passa por trás
          // dele que faz o vidro ler como vidro em vez de um cinza mais claro.
          blur: true,
          onTap: () => context.push(Routes.coach),
          child: SizedBox.square(
            dimension: 54,
            child: Icon(
              Icons.chat_bubble_outline,
              color: scheme.onSurface,
              size: 22,
            ),
          ),
        ),
      ),
    );
  }
}
