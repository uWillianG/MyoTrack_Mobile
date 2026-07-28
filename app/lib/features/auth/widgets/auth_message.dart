import 'package:flutter/material.dart';

/// Faixa de mensagem acima dos formulários de autenticação.
///
/// O ícone tem padrão por tipo, mas é substituível: a confirmação do e-mail de redefinição
/// diz mais com um envelope do que com o "i" genérico.
class AuthMessage extends StatelessWidget {
  const AuthMessage.info(this.text, {this.icon = Icons.info_outline, super.key})
    : isError = false;

  const AuthMessage.error(
    this.text, {
    this.icon = Icons.error_outline,
    super.key,
  }) : isError = true;

  final String text;
  final IconData icon;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final background = isError
        ? scheme.errorContainer
        : scheme.primaryContainer;
    final foreground = isError
        ? scheme.onErrorContainer
        : scheme.onPrimaryContainer;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: foreground),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(color: foreground, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}
