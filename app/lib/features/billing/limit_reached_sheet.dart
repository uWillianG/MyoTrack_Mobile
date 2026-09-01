import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/design/tokens.dart';
import '../../core/router.dart';
import 'billing_controller.dart';

/// A parede do dia, com uma porta.
///
/// **É a resposta a um toque, e não um aviso que chega sozinho.** A regra das conquistas — sem
/// diálogo por cima de outra tarefa — vale para o que ninguém pediu; aqui a pessoa acabou de
/// tocar em analisar e a recusa *é* o resultado daquele toque. O que havia antes era um
/// snackbar: o app dizendo a coisa mais importante do dia e a retirando quatro segundos depois,
/// sem oferecer o destino que a própria frase nomeia.
///
/// **Neutra, como toda a assinatura deste app.** Bater no teto não é falha da pessoa nem do
/// app, então não usa a cor de erro; e cobrança é procedimento, então não usa a família festiva.
Future<void> showLimitReachedSheet(BuildContext context, String message) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    // Rolável: a frase do servidor tem número e nome de plano, e com a fonte do sistema
    // ampliada ela passa de qualquer teto fixo.
    isScrollControlled: true,
    builder: (_) => _LimitReachedSheet(message: message),
  );
}

class _LimitReachedSheet extends ConsumerWidget {
  const _LimitReachedSheet({required this.message});

  /// A frase pronta do servidor. Não é reescrita aqui: só ele sabe qual limite está
  /// configurado no ambiente, e um número copiado para o app mentiria no dia em que ele mudasse.
  final String message;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    // **Só oferece o Pro a quem ainda não tem.** Vem do plano, e não de procurar "Assine o Pro"
    // dentro da frase — o servidor já omite o convite para assinante, e ler o texto para
    // descobrir isso quebraria na primeira reescrita lá. Status ainda não carregado não ganha
    // botão: a aba Conta continua sendo o caminho, e um botão errado é pior que um botão a
    // menos.
    final isPro = ref.watch(subscriptionStatusProvider).valueOrNull?.isPro;

    return SafeArea(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            Space.gutter,
            0,
            Space.gutter,
            Space.md,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.speed_outlined,
                    size: 20,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: Space.sm),
                  Expanded(
                    child: Text(message, style: theme.textTheme.titleSmall),
                  ),
                ],
              ),
              const SizedBox(height: Space.sm),
              Text(
                'A cota volta amanhã. O resto do app continua funcionando '
                'normalmente hoje.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: Space.md),
              if (isPro == false)
                FilledButton(
                  onPressed: () {
                    // Fecha a folha antes de navegar: sem isto ela sobreviveria por cima da
                    // tela de assinatura.
                    Navigator.of(context).pop();
                    context.push(Routes.billing);
                  },
                  child: const Text('Ver o Pro'),
                ),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: TextButton.styleFrom(
                    foregroundColor: theme.colorScheme.onSurfaceVariant,
                  ),
                  child: Text(isPro == false ? 'Agora não' : 'Entendi'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
