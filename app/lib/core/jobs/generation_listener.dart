import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// A segunda vez que `core/` aponta para `features/` — a primeira é o `router.dart`, que é a
// raiz de composição. A alternativa aqui era escrever o `if (limitReached)` seis vezes, nas
// seis telas de IA, que é exatamente a divergência que este arquivo existe para impedir: o
// bloco abaixo já nasceu copiado seis vezes antes de virar função.
import '../../features/billing/limit_reached_sheet.dart';
import 'generation_controller.dart';

/// O que uma tela de IA faz com o que o job devolveu de errado.
///
/// **Nasceu seis vezes igual** — na análise de refeição, na de vídeo, no coach, na estimativa
/// manual, no treino e na dieta —, sempre o mesmo `ref.listen` com o mesmo snackbar. Com um
/// segundo caminho a mais, a sétima cópia divergiria: bastaria alguém acrescentar o desvio de
/// cota em cinco telas e esquecer a sexta para o limite virar um aviso mudo justamente onde
/// ninguém foi olhar.
///
/// Dois destinos, e a diferença é se há o que fazer a respeito:
///
/// - **Erro comum** vira snackbar, como sempre foi. É passageiro, a tela continua útil, e não
///   há ação a oferecer além de tentar de novo.
/// - **Cota do dia** ([GenerationState.limitReached]) abre a folha da assinatura. Aqui existe
///   uma saída, e um aviso que some em quatro segundos é o app dizendo que ela existe e
///   retirando a frase antes de alguém poder segui-la.
///
/// [dismiss] vem por callback porque os seis providers têm tipos concretos distintos e
/// `NotifierProvider` é invariante — cada tela passa o `dismissError` do seu, que já é da base.
void listenGenerationState(
  WidgetRef ref,
  BuildContext context,
  ProviderListenable<GenerationState> provider, {
  required VoidCallback dismiss,
}) {
  ref.listen<GenerationState>(provider, (previous, next) {
    final message = next.error;
    if (message == null || message == previous?.error) {
      return;
    }
    // A tela pode ter saído entre o envio e a resposta — a espera de um job de IA dura
    // minutos, e a de vídeo mais ainda.
    if (!context.mounted) {
      return;
    }

    if (next.limitReached) {
      unawaited(showLimitReachedSheet(context, message));
    } else {
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(SnackBar(content: Text(message)));
    }

    // Some com o erro depois de ele virar tela, para não reaparecer no próximo rebuild.
    dismiss();
  });
}
