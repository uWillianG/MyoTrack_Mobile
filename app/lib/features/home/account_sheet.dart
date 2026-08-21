import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/db/local_database.dart';
import '../../core/design/materials.dart';
import '../../core/design/tokens.dart';
import '../../core/providers.dart';
import '../../core/sync/discarded_write_summary.dart';
import '../reviews/review_controller.dart';
import 'account_destinations.dart';

/// O que fica atrás do avatar da barra superior.
///
/// O protótipo tem quatro abas e um avatar; o app tem uma dezena de telas que não são Hoje,
/// Nutrição, Analisar nem Perfil — treino, coach, assinatura, conta e privacidade, a fila de
/// revisão. Elas não cabem na barra inferior e não podem sumir: a exclusão de conta, em
/// particular, precisa ser fácil de achar ou a revisão das lojas recusa o app. O avatar é o
/// lugar onde se procura "o resto", e é a única gaveta que o protótipo desenhou.
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
    final pending = ref.watch(pendingWritesProvider).valueOrNull ?? 0;
    final discarded =
        ref.watch(discardedWritesProvider).valueOrNull ?? const [];

    return SafeArea(
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // O que foi recusado vem antes do que está só esperando: um está perdido e exige
            // ação, o outro se resolve sozinho quando a rede voltar.
            if (discarded.isNotEmpty) _DiscardedWritesNotice(writes: discarded),
            // Quando há escrita esperando rede o usuário precisa saber, e este é o único
            // lugar do app que ele abre sem estar no meio de outra coisa.
            if (pending > 0) _PendingWritesNotice(count: pending),
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

class _PendingWritesNotice extends StatelessWidget {
  const _PendingWritesNotice({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(Space.gutter, 0, Space.gutter, 8),
      child: GlassPanel(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(
                Icons.cloud_upload_outlined,
                color: theme.colorScheme.outline,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  count == 1
                      ? '1 registro ainda não subiu. Ele sobe sozinho quando houver rede.'
                      : '$count registros ainda não subiram. Eles sobem sozinhos quando '
                            'houver rede.',
                  style: theme.textTheme.bodyMedium,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// O aviso do que não subiu e não vai subir.
///
/// **Usa a cor de erro, e o de pendentes não.** Escrita pendente é um estado normal do app
/// offline-first e um cartão vermelho a cada treino no subsolo ensinaria a ignorar a cor.
/// Escrita recusada é perda de dado: aconteceu, não tem volta automática, e a única saída é a
/// pessoa refazer o registro à mão — que é justamente o que o texto de cada linha permite.
class _DiscardedWritesNotice extends ConsumerWidget {
  const _DiscardedWritesNotice({required this.writes});

  final List<DiscardedWrite> writes;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final summaries = [
      for (final write in writes) DiscardedWriteSummary.of(write),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(Space.gutter, 0, Space.gutter, 8),
      child: GlassPanel(
        // Tingido de erro, e não pintado dele: escrita recusada é perda de dado e precisa se
        // distinguir do aviso de pendente logo acima — mas um retângulo vermelho cheio no meio
        // de uma folha de vidro grita mais alto que o conteúdo dele.
        tint: theme.colorScheme.error.withValues(alpha: 0.14),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.cloud_off_outlined,
                    color: theme.colorScheme.onErrorContainer,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      summaries.length == 1
                          ? 'Um registro foi recusado pelo servidor e não subiu.'
                          : '${summaries.length} registros foram recusados pelo '
                                'servidor e não subiram.',
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: theme.colorScheme.onErrorContainer,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              for (final summary in summaries)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        summary.what,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onErrorContainer,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        summary.reason,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onErrorContainer,
                        ),
                      ),
                    ],
                  ),
                ),
              Text(
                'Registre de novo pelo app para não perder o histórico.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onErrorContainer,
                ),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  // Só depois de ler: o aviso não some sozinho com o tempo, porque o custo de
                  // ele ficar um dia a mais é zero e o de sumir antes de ser visto é o
                  // registro perdido em silêncio de novo.
                  onPressed: () async {
                    await ref.read(syncQueueProvider).clearDiscarded();
                    ref.invalidate(discardedWritesProvider);
                  },
                  child: const Text('Entendi, dispensar'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
