import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/auth/session.dart';
import '../../core/design/tokens.dart';
import '../../core/providers.dart';
import '../../core/router.dart';
import '../../core/widgets/button_spinner.dart';

/// Sair da conta.
///
/// **Não existia em tela nenhuma até aqui** — só dava para sair desinstalando o app ou
/// esperando a sessão vencer. O caminho todo já estava escrito e testado (desregistrar o push,
/// descartar os tokens); faltava um botão que o chamasse.
///
/// **Mora em arquivo próprio porque agora são dois botões**: um no rodapé da aba Conta, que é
/// onde se procura, e outro na tela de conta e privacidade, que é de onde ele veio. O que não
/// pode ser copiado é o diálogo: ele avisa que as escritas que ainda não subiram vão embora
/// junto, e uma segunda cópia é exatamente o tipo de coisa que acaba sem esse aviso.
class SignOutButton extends ConsumerStatefulWidget {
  const SignOutButton({super.key});

  @override
  ConsumerState<SignOutButton> createState() => _SignOutButtonState();
}

class _SignOutButtonState extends ConsumerState<SignOutButton> {
  bool _leaving = false;

  Future<void> _signOut(int pending) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => _SignOutDialog(pending: pending),
    );
    if (confirmed != true || !mounted) {
      return;
    }

    setState(() => _leaving = true);
    try {
      await ref.read(sessionCloserProvider).close();
    } finally {
      if (mounted) {
        setState(() => _leaving = false);
      }
    }

    if (mounted) {
      // Como na exclusão: a guarda do router já levaria ao login com a sessão limpa, mas ir
      // explicitamente evita depender da ordem em que o estado se propaga.
      context.go(Routes.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    // A contagem é observada aqui, e não lida dentro do `_signOut`: ela chega por stream, e um
    // `read` no instante do toque pegaria a fila ainda sem valor — o aviso de "isto vai ser
    // descartado" sumiria justamente quando há algo a perder.
    final pending = ref.watch(pendingWritesProvider).valueOrNull ?? 0;

    return OutlinedButton.icon(
      onPressed: _leaving ? null : () => _signOut(pending),
      icon: _leaving
          ? const ButtonSpinner(label: 'Saindo')
          : const Icon(Icons.logout),
      label: const Text('Sair da conta'),
      style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
    );
  }
}

class _SignOutDialog extends StatelessWidget {
  const _SignOutDialog({required this.pending});

  /// Quantas escritas ainda não subiram. Sair apaga o que é da pessoa neste aparelho, e a fila
  /// vai junto — avisar antes é a diferença entre descartar e perder.
  final int pending;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: const Text('Sair da conta?'),
      // Rolável: com a fonte do sistema ampliada, o aviso de fila pendente passa da altura do
      // diálogo e o botão "Sair" fica fora de alcance.
      scrollable: true,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Você vai precisar entrar de novo neste aparelho. Seus dados continuam no '
            'servidor.',
            style: theme.textTheme.bodyMedium,
          ),
          if (pending > 0) ...[
            const SizedBox(height: Space.sm),
            Text(
              pending == 1
                  ? '1 registro ainda não subiu e só existe neste aparelho. Sair agora '
                        'descarta esse registro.'
                  : '$pending registros ainda não subiram e só existem neste aparelho. '
                        'Sair agora descarta esses registros.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Sair'),
        ),
      ],
    );
  }
}
