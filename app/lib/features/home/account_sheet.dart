import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/design/tokens.dart';
import '../reviews/review_controller.dart';
import 'account_destinations.dart';
import 'account_notices.dart';

/// O que fica atrás do avatar da barra superior.
///
/// **A aba Conta assumiu o papel principal, e esta folha virou o atalho.** A mesma lista mora
/// nos dois lugares de propósito: a aba é onde se procura conta, plano e privacidade quando se
/// está pensando nisso; a folha é o caminho de uma mão só a partir de onde a pessoa já está,
/// sem trocar de aba nem perder o que estava lendo — que é o que o avatar sempre foi.
///
/// **O que impede os dois de divergirem é [accountDestinations]**: nenhum dos dois escreve a
/// lista à mão. A folha mostra os destinos em fila, a aba os mostra agrupados, e um destino
/// novo aparece nos dois sem ninguém lembrar de ir ao segundo.
Future<void> showAccountSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    // Rolável: com a fonte do sistema ampliada, meia dúzia de itens com legenda passa de
    // qualquer teto fixo.
    isScrollControlled: true,
    builder: (_) => const AccountSheet(),
  );
}

class AccountSheet extends ConsumerWidget {
  const AccountSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Falha ao ler os papéis esconde a revisão em vez de derrubar a folha.
    final canReview =
        ref.watch(reviewableKindsProvider).valueOrNull?.isNotEmpty ?? false;

    return SafeArea(
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Quando há escrita esperando rede o usuário precisa saber, e este é um dos dois
            // lugares do app que ele abre sem estar no meio de outra coisa.
            ...accountNotices(
              ref,
              padding: const EdgeInsets.fromLTRB(
                Space.gutter,
                0,
                Space.gutter,
                8,
              ),
            ),
            for (final destination in [
              ...accountDestinations,
              if (canReview) reviewDestination,
            ])
              ListTile(
                leading: Icon(destination.icon),
                title: Text(destination.title),
                subtitle: Text(destination.subtitle),
                onTap: () {
                  Navigator.of(context).pop();
                  context.push(destination.route);
                },
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
