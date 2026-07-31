import 'package:flutter/material.dart';

/// Mensagem centralizada de estado vazio ou de erro, com uma ação opcional.
///
/// É um `ListView`, e não uma `Column`: o `RefreshIndicator` precisa de um scrollable para
/// reconhecer o gesto — sem isso o "puxar para atualizar" não funciona justamente na tela
/// vazia, que é onde o usuário mais tenta.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.detail,
    this.action,
  }) : inline = false;

  /// Versão para usar **dentro** de um scrollable que já existe.
  ///
  /// O construtor comum é um `ListView`, e um `ListView` dentro de outro não tem altura
  /// limitada — a tela quebra em "Vertical viewport was given unbounded height". É o caso
  /// do diário, onde a mensagem de "nenhuma refeição" divide a lista com os totais do dia.
  const EmptyState.inline({
    super.key,
    required this.icon,
    required this.title,
    this.detail,
    this.action,
  }) : inline = true;

  final IconData icon;
  final String title;
  final String? detail;
  final Widget? action;
  final bool inline;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final children = _children(theme);

    if (inline) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
        child: Column(children: children),
      );
    }

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 64),
      children: children,
    );
  }

  List<Widget> _children(ThemeData theme) {
    return [
      Icon(icon, size: 48, color: theme.colorScheme.outline),
      const SizedBox(height: 16),
      Text(
        title,
        textAlign: TextAlign.center,
        style: theme.textTheme.titleMedium,
      ),
      if (detail != null) ...[
        const SizedBox(height: 8),
        Text(
          detail!,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
      if (action != null) ...[
        const SizedBox(height: 16),
        Center(child: action),
      ],
    ];
  }
}
