import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers.dart';
import '../../core/router.dart';
import '../reviews/review_controller.dart';

/// O que fica atrás do avatar da barra superior.
///
/// O protótipo tem quatro abas e um avatar; o app tem nove telas que não são Hoje, Nutrição,
/// Analisar nem Perfil — progresso, coach, assinatura, exclusão de conta, a fila de revisão.
/// Elas não cabem na barra inferior e não podem sumir: a exclusão de conta, em particular,
/// precisa ser fácil de achar ou a revisão das lojas recusa o app. O avatar é o lugar onde se
/// procura "o resto", e é a única gaveta que o protótipo desenhou.
Future<void> showAccountSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    // Rolável: com a fonte do sistema ampliada, nove itens passam de qualquer teto fixo.
    isScrollControlled: true,
    builder: (_) => const AccountSheet(),
  );
}

class AccountSheet extends ConsumerWidget {
  const AccountSheet({super.key});

  static const _destinations = <_Destination>[
    _Destination(
      icon: Icons.insights_outlined,
      title: 'Progresso',
      subtitle: 'Volume por semana, peso corporal e seus recordes',
      route: Routes.progress,
    ),
    _Destination(
      icon: Icons.fitness_center_outlined,
      title: 'Meu treino',
      subtitle: 'O plano inteiro, dia a dia',
      route: Routes.workoutPlan,
    ),
    _Destination(
      icon: Icons.edit_note_outlined,
      title: 'Registrar treino',
      subtitle: 'Séries, cargas e peso corporal — funciona offline',
      route: Routes.logSession,
    ),
    _Destination(
      icon: Icons.chat_bubble_outline,
      title: 'Coach',
      subtitle: 'Tire dúvidas com quem conhece seu treino e sua dieta',
      route: Routes.coach,
    ),
    _Destination(
      icon: Icons.workspace_premium_outlined,
      title: 'Assinatura',
      subtitle: 'Seu plano e os limites diários de análise',
      route: Routes.billing,
    ),
    _Destination(
      icon: Icons.shield_outlined,
      title: 'Conta e privacidade',
      subtitle: 'Excluir sua conta e todos os seus dados',
      route: Routes.account,
    ),
  ];

  /// A revisão só aparece para quem pode revisar: mostrar para o aluno o levaria a uma tela
  /// que o servidor recusa com 403, e item de menu que dá erro é pior que item nenhum.
  static const _reviewDestination = _Destination(
    icon: Icons.fact_check_outlined,
    title: 'Revisão',
    subtitle: 'Fila de planos aguardando sua aprovação',
    route: Routes.review,
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Falha ao ler os papéis esconde a revisão em vez de derrubar a folha.
    final canReview =
        ref.watch(reviewableKindsProvider).valueOrNull?.isNotEmpty ?? false;
    final pending = ref.watch(pendingWritesProvider).valueOrNull ?? 0;

    return SafeArea(
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Quando há escrita esperando rede o usuário precisa saber, e este é o único
            // lugar do app que ele abre sem estar no meio de outra coisa.
            if (pending > 0) _PendingWritesNotice(count: pending),
            for (final destination in [
              ..._destinations,
              if (canReview) _reviewDestination,
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
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Card(
        margin: EdgeInsets.zero,
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

class _Destination {
  const _Destination({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.route,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String route;
}
