import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router.dart';
import '../dashboard/dashboard_controller.dart';
import '../dashboard/dashboard_view.dart';
import '../reports/weekly_report_card.dart';
import '../reviews/review_controller.dart';

/// Tela inicial: o que aconteceu até agora, e como chegar ao resto.
///
/// Substitui a lista provisória que existia até o B10. Os números vêm primeiro porque são o
/// motivo de abrir o app fora da academia — a navegação continua logo abaixo, e não em um
/// menu escondido, porque durante o treino a pressa é chegar à tela, não ver gráfico.
class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(dashboardStatsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('MyoTrack')),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(dashboardStatsProvider);
          await ref.read(dashboardStatsProvider.future);
        },
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          children: [
            // O dashboard não pode bloquear a navegação: sem rede, ou com o histórico
            // falhando, as telas do app continuam alcançáveis logo abaixo.
            stats.when(
              loading: () => const SizedBox(
                height: 120,
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (error, _) => _DashboardUnavailable(
                onRetry: () => ref.invalidate(dashboardStatsProvider),
              ),
              data: (data) => data.isEmpty
                  ? const _FirstSteps()
                  : DashboardView(stats: data),
            ),
            // O card do relatório fica acima dos gráficos porque é leitura, não consulta:
            // ele já diz o que a semana foi, e os gráficos existem para quem quer conferir.
            // Some sozinho quando ainda não há relatório.
            const Padding(
              padding: EdgeInsets.only(top: 16),
              child: WeeklyReportCard(),
            ),
            const SizedBox(height: 24),
            const _Navigation(),
          ],
        ),
      ),
    );
  }
}

/// Quem ainda não registrou nada não tem gráfico para ver — e um gráfico vazio pareceria
/// defeito. Em vez disso, o próximo passo.
class _FirstSteps extends StatelessWidget {
  const _FirstSteps();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Comece por aqui', style: theme.textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(
              'Registre seu primeiro treino e seu peso. A partir daí esta tela mostra '
              'volume por semana, evolução do peso e seus recordes.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            FilledButton.tonal(
              onPressed: () => context.push(Routes.logSession),
              child: const Text('Registrar treino'),
            ),
          ],
        ),
      ),
    );
  }
}

class _DashboardUnavailable extends StatelessWidget {
  const _DashboardUnavailable({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.cloud_off_outlined, color: theme.colorScheme.outline),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Não foi possível carregar seus números agora.',
                style: theme.textTheme.bodyMedium,
              ),
            ),
            TextButton(onPressed: onRetry, child: const Text('Tentar')),
          ],
        ),
      ),
    );
  }
}

class _Navigation extends ConsumerWidget {
  const _Navigation();

  // Uma entrada por rota registrada no router. O modo treino (Routes.workoutMode) fica de
  // fora até o B4 entrar: listar um destino cuja rota não existe leva ao "Rota não
  // encontrada" em vez da tela.
  static const _destinations = <_Destination>[
    _Destination(
      icon: Icons.fitness_center_outlined,
      title: 'Meu treino',
      subtitle: 'Plano gerado a partir do seu perfil',
      route: Routes.workoutPlan,
    ),
    _Destination(
      icon: Icons.restaurant_outlined,
      title: 'Minha dieta',
      subtitle: 'Refeições e metas calculadas pelo seu peso',
      route: Routes.dietPlan,
    ),
    _Destination(
      icon: Icons.menu_book_outlined,
      title: 'Diário',
      subtitle: 'O que você comeu no dia, comparado às suas metas',
      route: Routes.diary,
    ),
    _Destination(
      icon: Icons.photo_camera_outlined,
      title: 'Analisar refeição',
      subtitle: 'Fotografe o prato e a IA estima calorias e macros',
      route: Routes.mealAnalysis,
    ),
    _Destination(
      icon: Icons.videocam_outlined,
      title: 'Analisar execução',
      subtitle: 'Grave uma série e veja onde a técnica sai do lugar',
      route: Routes.videoAnalysis,
    ),
    _Destination(
      icon: Icons.chat_bubble_outline,
      title: 'Coach',
      subtitle: 'Tire dúvidas com quem conhece seu treino e sua dieta',
      route: Routes.coach,
    ),
    _Destination(
      icon: Icons.edit_note_outlined,
      title: 'Registrar treino',
      subtitle: 'Séries, cargas e peso corporal — funciona offline',
      route: Routes.logSession,
    ),
    _Destination(
      icon: Icons.workspace_premium_outlined,
      title: 'Assinatura',
      subtitle: 'Seu plano e os limites diários de análise',
      route: Routes.billing,
    ),
    _Destination(
      icon: Icons.person_outline,
      title: 'Perfil',
      subtitle: 'Objetivo, experiência, equipamentos e lesões',
      route: Routes.profile,
    ),
    _Destination(
      icon: Icons.shield_outlined,
      title: 'Conta e privacidade',
      subtitle: 'Excluir sua conta e todos os seus dados',
      route: Routes.account,
    ),
  ];

  /// A revisão só aparece para quem pode revisar.
  ///
  /// Mostrar para todo mundo levaria o aluno a uma tela que o servidor recusa com 403 — e
  /// um item de menu que dá erro é pior que item nenhum.
  static const _reviewDestination = _Destination(
    icon: Icons.fact_check_outlined,
    title: 'Revisão',
    subtitle: 'Fila de planos aguardando sua aprovação',
    route: Routes.review,
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Falha ao ler os papéis esconde a revisão em vez de derrubar a navegação: as outras
    // telas continuam alcançáveis.
    final canReview =
        ref.watch(reviewableKindsProvider).valueOrNull?.isNotEmpty ?? false;

    return Column(
      children: [
        for (final destination in [
          ..._destinations,
          if (canReview) _reviewDestination,
        ])
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(destination.icon),
            title: Text(destination.title),
            subtitle: Text(destination.subtitle),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push(destination.route),
          ),
      ],
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
