import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router.dart';
import 'privacy_controller.dart';

/// Conta e privacidade.
///
/// A exclusão fica em tela própria, alcançável direto da tela inicial, e não escondida dentro
/// do perfil: as duas lojas exigem que todo app que permite criar conta permita apagá-la, e a
/// Apple pede explicitamente que o caminho seja fácil de achar. Enterrá-la em um submenu é
/// motivo de recusa na revisão.
class AccountPage extends ConsumerWidget {
  const AccountPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Conta e privacidade')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        children: [
          Card(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Excluir minha conta',
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Apaga definitivamente sua conta e tudo que está nela: treinos, dieta, '
                    'histórico de séries, medidas, fotos de refeição e vídeos.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Não há como desfazer, e não há cópia de segurança.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: () => _confirm(context, ref),
                    icon: const Icon(Icons.delete_forever_outlined),
                    label: const Text('Excluir minha conta'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: theme.colorScheme.error,
                      side: BorderSide(color: theme.colorScheme.error),
                      minimumSize: const Size.fromHeight(48),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          // O export vem antes do aviso da assinatura e depois da exclusão: são os dois
          // direitos do titular na LGPD, e ficam juntos.
          _ExportCard(),
          const SizedBox(height: 12),
          Text(
            'Se você tem assinatura ativa, cancele-a também nos ajustes de assinaturas do '
            'seu aparelho: excluir a conta aqui não cancela a cobrança da loja.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirm(BuildContext context, WidgetRef ref) async {
    final deleted = await showDialog<bool>(
      context: context,
      // Fechar tocando fora seria fácil demais para uma ação irreversível, mas também
      // impediria desistir sem ler — o botão "Cancelar" cobre isso.
      barrierDismissible: false,
      builder: (_) => const _ConfirmDialog(),
    );

    if (deleted == true && context.mounted) {
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(
          const SnackBar(content: Text('Sua conta foi excluída.')),
        );
      // A guarda do router já levaria ao login com a sessão limpa; ir explicitamente evita
      // depender da ordem em que o estado se propaga.
      context.go(Routes.login);
    }
  }
}

class _ConfirmDialog extends ConsumerStatefulWidget {
  const _ConfirmDialog();

  @override
  ConsumerState<_ConfirmDialog> createState() => _ConfirmDialogState();
}

class _ConfirmDialogState extends ConsumerState<_ConfirmDialog> {
  final _confirmation = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _confirmation.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final text = _confirmation.text.trim();
    if (text.isEmpty) {
      return;
    }

    final deleted = await ref.read(deleteAccountProvider.notifier).delete(text);
    if (deleted && mounted) {
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(deleteAccountProvider);
    final theme = Theme.of(context);

    return AlertDialog(
      title: const Text('Excluir a conta?'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tudo será apagado definitivamente. Para confirmar, digite sua senha.',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 4),
          // O app não tem como saber se a conta foi criada com senha ou por login social, e
          // não há endpoint que diga. Em vez de adivinhar, a tela explica as duas formas —
          // e quem decide qual vale é o servidor, cuja mensagem de erro orienta o resto.
          Text(
            'Se você entrou com Google ou Apple, digite o e-mail da sua conta.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _confirmation,
            obscureText: _obscure,
            autocorrect: false,
            enabled: !state.deleting,
            onSubmitted: (_) => _submit(),
            decoration: InputDecoration(
              labelText: 'Senha ou e-mail',
              suffixIcon: IconButton(
                icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility),
                tooltip: _obscure ? 'Mostrar' : 'Ocultar',
                onPressed: () => setState(() => _obscure = !_obscure),
              ),
            ),
          ),
          if (state.error != null) ...[
            const SizedBox(height: 12),
            Text(
              state.error!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: state.deleting
              ? null
              : () => Navigator.of(context).pop(false),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: state.deleting ? null : _submit,
          style: FilledButton.styleFrom(
            backgroundColor: theme.colorScheme.error,
            foregroundColor: theme.colorScheme.onError,
          ),
          child: state.deleting
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Excluir'),
        ),
      ],
    );
  }
}

/// Pedido do export de dados (LGPD).
class _ExportCard extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final sending = ref.watch(exportProvider).sending;

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Baixar meus dados', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              'Enviamos um arquivo com tudo que temos sobre você — perfil, planos, treinos, '
              'medidas e análises — para o e-mail da sua conta.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.tonalIcon(
              onPressed: sending ? null : () => _request(context, ref),
              icon: sending
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.mail_outline),
              label: const Text('Enviar por e-mail'),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _request(BuildContext context, WidgetRef ref) async {
    final message = await ref.read(exportProvider.notifier).request();
    if (message.isNotEmpty && context.mounted) {
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(SnackBar(content: Text(message)));
    }
  }
}
