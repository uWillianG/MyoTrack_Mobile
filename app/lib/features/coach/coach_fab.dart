import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/design/tokens.dart';
import '../../core/router.dart';

/// O botão do coach, flutuando no canto de todas as abas.
///
/// **Por que ele flutua.** Até aqui só se chegava na conversa abrindo a folha do avatar e
/// achando um item no meio de seis — dois toques para o recurso que mais distingue o produto.
/// E a dúvida que ele responde ("posso trocar esse exercício?", "isso cabe na minha meta de
/// hoje?") nasce olhando qualquer uma das quatro abas, não uma delas em particular.
///
/// **O mesmo balão da folha da conta**, e não um segundo desenho para a mesma coisa: dois
/// caminhos até um recurso com vocabulários diferentes é o que faz o usuário achar que são
/// dois recursos.
///
/// **Por que não é esmeralda cheio.** Na Hoje ele divide a tira de baixo com o `Registrar`,
/// que é a ação principal da tela e já ocupa a cor cheia (§4 do design system: a coisa mais
/// berrante da tela é o que se quer que a pessoa faça). Dois botões cheios lado a lado
/// cancelariam os dois. Aqui a superfície é neutra e o esmeralda fica só no traço do ícone —
/// o coach ganhou o canto da mão direita, e não precisa ganhar a cor também.
class CoachFab extends StatelessWidget {
  const CoachFab({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = scheme.brightness == Brightness.dark;

    return FloatingActionButton.small(
      // Sem tag própria os dois flutuantes da Hoje entram no mesmo voo de herói e a primeira
      // navegação estoura. O nome é fixo porque só existe um destes na árvore.
      heroTag: 'coach-fab',
      onPressed: () => context.push(Routes.coach),
      tooltip: 'Falar com o coach',
      backgroundColor: isDark
          ? scheme.surfaceContainerHigh
          : scheme.surfaceContainerLowest,
      foregroundColor: scheme.primary,
      // A mesma física de elevação do resto do app: no claro, sombra; no escuro, superfície
      // mais clara com 1 px de borda — sombra preta sobre preto é sujeira, não altura.
      shape: RoundedRectangleBorder(
        borderRadius: Radii.mdAll,
        side: isDark
            ? BorderSide(color: scheme.outlineVariant)
            : BorderSide.none,
      ),
      child: const Icon(Icons.chat_bubble_outline),
    );
  }
}
