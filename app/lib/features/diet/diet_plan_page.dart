import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/design/tokens.dart';
import '../../core/jobs/generation_controller.dart';
import '../../core/router.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/review_badge.dart';
import 'data/diet_models.dart';
import 'diet_plan_controller.dart';

/// Plano alimentar ativo. Porte de `frontend/src/pages/DietPlanPage.tsx`.
///
/// Rota própria (`/dieta`); o conteúdo mora em [DietPlanView] para a aba Nutrição do hub
/// diário poder mostrá-lo sob a barra de título dela.
class DietPlanPage extends ConsumerWidget {
  const DietPlanPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final planAsync = ref.watch(activeDietPlanProvider);

    return Scaffold(
      appBar: AppBar(title: Text(planAsync.valueOrNull?.name ?? 'Sua dieta')),
      body: const DietPlanView(),
    );
  }
}

/// A dieta sem a barra de título, com o botão de gerar preso embaixo.
///
/// O botão vem no fim de uma `Column` em vez de num `bottomNavigationBar` porque esta view
/// também roda dentro da aba Nutrição, onde o rodapé do `Scaffold` já é a barra de
/// navegação do app.
class DietPlanView extends ConsumerWidget {
  const DietPlanView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final planAsync = ref.watch(activeDietPlanProvider);
    final generation = ref.watch(dietGenerationProvider);

    ref.listen(dietGenerationProvider, (previous, next) {
      if (next.error != null && next.error != previous?.error) {
        ScaffoldMessenger.of(context)
          ..clearSnackBars()
          ..showSnackBar(SnackBar(content: Text(next.error!)));
        ref.read(dietGenerationProvider.notifier).dismissError();
      }
    });

    return Column(
      children: [
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(activeDietPlanProvider);
              await ref.read(activeDietPlanProvider.future);
            },
            child: planAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => EmptyState(
                icon: Icons.cloud_off_outlined,
                title: 'Não foi possível carregar sua dieta.',
                detail: '$error',
                action: FilledButton.tonal(
                  onPressed: () => ref.invalidate(activeDietPlanProvider),
                  child: const Text('Tentar de novo'),
                ),
              ),
              data: (plan) => _PlanBody(plan: plan, generation: generation),
            ),
          ),
        ),
        SafeArea(
          top: false,
          minimum: const EdgeInsets.fromLTRB(Space.gutter, 0, Space.gutter, 12),
          child: FilledButton.icon(
            onPressed: generation.running
                ? null
                : () => ref.read(dietGenerationProvider.notifier).start(),
            icon: generation.running
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.auto_awesome),
            label: Text(
              generation.running
                  ? (generation.step ?? 'Gerando…')
                  : planAsync.valueOrNull == null
                  ? 'Gerar dieta'
                  : 'Regenerar dieta',
            ),
          ),
        ),
      ],
    );
  }
}

class _PlanBody extends StatelessWidget {
  const _PlanBody({required this.plan, required this.generation});

  final DietPlan? plan;
  final GenerationState generation;

  @override
  Widget build(BuildContext context) {
    if (plan == null) {
      return EmptyState(
        icon: Icons.restaurant_outlined,
        title: 'Você ainda não tem uma dieta ativa.',
        detail: generation.running
            ? 'Isso pode levar até um minuto.'
            // O peso é o que define a meta calórica: sem ele o backend recusa a geração.
            : 'Complete o perfil, registre seu peso e toque em "Gerar dieta".',
        action: generation.running
            ? null
            : TextButton(
                onPressed: () => context.push(Routes.profile),
                child: const Text('Ir para o perfil'),
              ),
      );
    }

    final diet = plan!;
    return ListView(
      padding: const EdgeInsets.fromLTRB(Space.gutter, 8, Space.gutter, 16),
      children: [
        Row(
          children: [
            Expanded(
              child: ReviewBadge(
                reviewStatus: diet.reviewStatus,
                reviewNote: diet.reviewNote,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              DietLabels.calorieGoal(diet.calorieGoal),
              style: Theme.of(context).textTheme.labelMedium,
            ),
          ],
        ),
        const SizedBox(height: 12),
        _MacroSummary(targets: diet.targets, totals: diet.totals),
        const SizedBox(height: 12),
        for (final meal in diet.meals) _MealCard(meal: meal),
        const SizedBox(height: 8),
        Text(
          'Plano gerado automaticamente com base no seu perfil. Valores nutricionais são '
          'estimativas (base TACO). Consulte um nutricionista para acompanhamento profissional.',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

/// Realizado vs. meta dos quatro números que importam.
class _MacroSummary extends StatelessWidget {
  const _MacroSummary({required this.targets, required this.totals});

  final Macros targets;
  final Macros totals;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      // Cartões baixos e largos: o conteúdo é um número e um rótulo.
      childAspectRatio: 2.4,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      children: [
        _MacroCard(
          label: 'Calorias',
          value: totals.kcal,
          target: targets.kcal,
          unit: 'kcal',
        ),
        _MacroCard(
          label: 'Proteína',
          value: totals.proteinG,
          target: targets.proteinG,
          unit: 'g',
        ),
        _MacroCard(
          label: 'Carboidrato',
          value: totals.carbsG,
          target: targets.carbsG,
          unit: 'g',
        ),
        _MacroCard(
          label: 'Gordura',
          value: totals.fatG,
          target: targets.fatG,
          unit: 'g',
        ),
      ],
    );
  }
}

class _MacroCard extends StatelessWidget {
  const _MacroCard({
    required this.label,
    required this.value,
    required this.target,
    required this.unit,
  });

  final String label;
  final num value;
  final num target;
  final String unit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 2),
            Text.rich(
              TextSpan(
                text: '${value.round()}',
                style: theme.textTheme.titleLarge,
                children: [
                  TextSpan(
                    text: ' / ${target.round()} $unit',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _MealCard extends StatelessWidget {
  const _MealCard({required this.meal});

  final DietMeal meal;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final kcal = meal.items.fold<num>(0, (sum, item) => sum + item.kcal);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            color: theme.colorScheme.surfaceContainerHighest,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Expanded(
                  child: Text(meal.name, style: theme.textTheme.titleMedium),
                ),
                Text(
                  '${kcal.round()} kcal',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          for (final item in meal.items)
            _ItemTile(item: item, isLast: item == meal.items.last),
        ],
      ),
    );
  }
}

class _ItemTile extends StatelessWidget {
  const _ItemTile({required this.item, required this.isLast});

  final DietMealItem item;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: isLast
          ? null
          : BoxDecoration(
              border: Border(
                bottom: BorderSide(color: theme.colorScheme.outlineVariant),
              ),
            ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${item.foodName} — ${_grams(item.quantityG)} g',
            style: theme.textTheme.bodyLarge,
          ),
          const SizedBox(height: 2),
          Text(
            'P ${item.proteinG}g · C ${item.carbsG}g · G ${item.fatG}g · '
            '${item.kcal.round()} kcal',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  /// As quantidades vêm em múltiplos de 5 g; mostrar "150" em vez de "150.0" é o que
  /// alguém leria numa receita.
  static String _grams(num value) =>
      value == value.roundToDouble() ? '${value.round()}' : '$value';
}
