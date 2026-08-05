import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import 'account_sheet.dart';

/// Avatar da conta: iniciais do e-mail, e a porta para o resto do app.
///
/// Iniciais e não foto porque não há upload de avatar em lugar nenhum — um espaço reservado
/// para uma foto que nunca chega fica pior que a inicial.
///
/// Mora em arquivo próprio porque aparece em dois lugares: no alto da Hoje, que não tem barra
/// de título, e na barra superior das outras três abas.
class AccountAvatar extends ConsumerWidget {
  const AccountAvatar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final email = ref.watch(userEmailProvider).valueOrNull;

    return IconButton(
      onPressed: () => showAccountSheet(context),
      tooltip: 'Conta e mais',
      icon: CircleAvatar(
        radius: 16,
        backgroundColor: theme.colorScheme.surfaceContainerHigh,
        child: Text(
          initialsFrom(email),
          style: theme.textTheme.labelMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

/// Até duas letras a partir do e-mail: `rafael.souza@x.com` vira "RS", `willian@x.com` vira
/// "WI". Sem e-mail — sessão ainda carregando — fica o traço, que não parece nome de outra
/// pessoa.
String initialsFrom(String? email) {
  final local = (email ?? '').split('@').first.trim();
  if (local.isEmpty) {
    return '—';
  }

  final parts = local
      .split(RegExp(r'[._\-+\s]+'))
      .where((p) => p.isNotEmpty)
      .toList();
  if (parts.length >= 2) {
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }
  return local.substring(0, local.length >= 2 ? 2 : 1).toUpperCase();
}
