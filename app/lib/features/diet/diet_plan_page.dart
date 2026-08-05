import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/design/blocks.dart';
import '../../core/design/format.dart';
import '../../core/design/tokens.dart';
import '../../core/jobs/generation_controller.dart';
import '../../core/router.dart';
import '../../core/widgets/blocks.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/review_badge.dart';
import 'data/diet_models.dart';
import 'diet_plan_controller.dart';

/// Plano alimentar ativo.
///
/// Rota própria (`/dieta`); o conteúdo mora em [DietPlanView] para a aba Nutrição do hub poder
/// mostrá-lo sob a barra de título dela.
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

/// A dieta sem a barra de título.
///
/// **Pergunta: o que eu deveria comer? Ação: gerar (ou regerar) o plano.**
///
/// Mesma família do diário — as duas metades da nutrição são o mesmo assunto, e trocar de cor
/// entre elas faria o segmentado parecer levar a outro lugar do app.
///
/// **O botão de gerar saiu do rodapé e virou a ação do herói.** Preso embaixo, ele competia com
/// a barra de navegação e aparecia mesmo enquanto o plano carregava, quando não havia nada para
/// regerar. No herói ele está ao lado do número que descreve o plano, que é o contexto que faz
/// alguém decidir refazê-lo.
class DietPlanView extends ConsumerWidget {
  const DietPlanView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final planAsync = ref.watch(activeDietPlanProvider);
    final generation = ref.watch(dietGenerationProvider);
    final colors = Blocks.nutrition(Theme.of(context).brightness);

    ref.listen(dietGenerationProvider, (previous, next) {
      if (next.error != null && next.error != previous?.error) {
        ScaffoldMessenger.of(context)
          ..clearSnackBars()
          ..showSnackBar(SnackBar(content: Text(next.error!)));
        ref.read(dietGenerationProvider.notifier).dismissError();
      }
    });

    return RefreshIndicator(
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
        data: (plan) =>
            _PlanBody(plan: plan, generation: generation, colors: colors),
      ),
    );
  }
}

class _PlanBody extends ConsumerWidget {
  const _PlanBody({
    required this.plan,
    required this.generation,
    required this.colors,
  });

  final DietPlan? plan;
  final GenerationState generation;
  final BlockColors colors;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    final action = HeroAction(
      label: generation.running
          ? (generation.step ?? 'Gerando…')
          : plan == null
          ? 'Gerar dieta'
          : 'Regenerar dieta',
      onPressed: generation.running
          ? null
          : () => ref.read(dietGenerationProvider.notifier).start(),
    );

    return ListView(
      padding: const EdgeInsets.fromLTRB(Space.gutter, 4, Space.gutter, 24),
      children: [
        if (plan == null)
          _NoPlanHero(generation: generation, colors: colors, action: action)
        else ...[
          _PlanHero(plan: plan!, colors: colors, action: action),
          const SizedBox(height: Space.sm),
          _TargetsSection(plan: plan!, colors: colors),
          for (final meal in plan!.meals) ...[
            const SizedBox(height: Space.sm),
            _MealSection(meal: meal, colors: colors),
          ],
          const SizedBox(height: Space.md),
          Text(
            'Plano gerado automaticamente com base no seu perfil. Valores nutricionais são '
            'estimativas (base TACO). Consulte um nutricionista para acompanhamento '
            'profissional.',
            style: theme.textTheme.bodySmall,
          ),
        ],
      ],
    );
  }
}

/// O herói do plano: a meta calórica e o nome do que a gerou.
class _PlanHero extends StatelessWidget {
  const _PlanHero({
    required this.plan,
    required this.colors,
    required this.action,
  });

  final DietPlan plan;
  final BlockColors colors;
  final HeroAction action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return HeroBlock(
      colors: colors,
      label: 'Sua dieta',
      icon: Icons.restaurant_menu,
      action: action,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          HeroFigure(
            value: Fmt.integer(plan.targets.kcal),
            unit: 'kcal por dia',
            colors: colors,
            detail: DietLabels.calorieGoal(plan.calorieGoal),
          ),
          const SizedBox(height: Space.md),
          Text(
            plan.name,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colors.onTone.withValues(alpha: 0.85),
            ),
          ),
          // O selo da revisão fica no herói e não perdido no meio da lista: ele diz se este
          // plano já passou por um humano, e é a primeira coisa que muda a confiança de quem
          // vai seguir a dieta.
          const SizedBox(height: Space.sm),
          Align(
            alignment: Alignment.centerLeft,
            child: ReviewBadge(
              reviewStatus: plan.reviewStatus,
              reviewNote: plan.reviewNote,
              onTone: colors.onTone,
            ),
          ),
        ],
      ),
    );
  }
}

/// Sem plano, o herói é o convite.
class _NoPlanHero extends StatelessWidget {
  const _NoPlanHero({
    required this.generation,
    required this.colors,
    required this.action,
  });

  final GenerationState generation;
  final BlockColors colors;
  final HeroAction action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        HeroBlock(
          colors: colors,
          label: 'Sua dieta',
          icon: Icons.restaurant_menu,
          action: action,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Você ainda não\ntem uma dieta.',
                style: theme.textTheme.displaySmall?.copyWith(
                  color: colors.onTone,
                ),
              ),
              const SizedBox(height: Space.sm),
              Text(
                generation.running
                    ? 'Isso pode levar até um minuto.'
                    // O peso é o que define a meta calórica: sem ele o backend recusa a
                    // geração.
                    : 'Complete o perfil e registre seu peso — é o peso que define a meta '
                          'de calorias.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colors.onTone.withValues(alpha: 0.85),
                ),
              ),
            ],
          ),
        ),
        if (!generation.running) ...[
          const SizedBox(height: Space.sm),
          TextButton(
            onPressed: () => context.push(Routes.profile),
            child: const Text('Ir para o perfil'),
          ),
        ],
      ],
    );
  }
}

/// Os três macros do plano: o que ele soma contra o que ele mira.
///
/// As calorias ficam de fora — elas são o número do herói, e repeti-las aqui seria a mesma
/// duplicação que a Hoje evita ao tirar do mosaico o assunto promovido.
class _TargetsSection extends StatelessWidget {
  const _TargetsSection({required this.plan, required this.colors});

  final DietPlan plan;
  final BlockColors colors;

  @override
  Widget build(BuildContext context) {
    final targets = plan.targets;
    final totals = plan.totals;

    return BlockSection(
      colors: colors,
      label: 'Macros do plano',
      icon: Icons.pie_chart_outline,
      trailing: '${Fmt.integer(totals.kcal)} kcal somadas',
      child: Column(
        children: [
          for (final macro in [
            ('Proteína', totals.proteinG, targets.proteinG),
            ('Carboidrato', totals.carbsG, targets.carbsG),
            ('Gordura', totals.fatG, targets.fatG),
          ]) ...[
            if (macro.$1 != 'Proteína') const SizedBox(height: Space.sm),
            BlockMeter(
              colors: colors,
              label: macro.$1,
              value: '${Fmt.integer(macro.$2)} / ${Fmt.grams(macro.$3)}',
              ratio: macro.$3 <= 0 ? 0 : macro.$2 / macro.$3,
            ),
          ],
        ],
      ),
    );
  }
}

/// Uma refeição do plano e os alimentos dela.
///
/// Era um cartão com cabeçalho tingido por dentro — uma caixa dentro de outra. Aqui é uma
/// seção só: o nome e o total no rótulo, os itens como linhas separadas por um fio.
class _MealSection extends StatelessWidget {
  const _MealSection({required this.meal, required this.colors});

  final DietMeal meal;
  final BlockColors colors;

  @override
  Widget build(BuildContext context) {
    final kcal = meal.items.fold<num>(0, (sum, item) => sum + item.kcal);

    return BlockSection(
      colors: colors,
      label: meal.name,
      icon: Icons.lunch_dining,
      trailing: Fmt.kcal(kcal),
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          for (var i = 0; i < meal.items.length; i++) ...[
            if (i > 0)
              Divider(
                height: 1,
                indent: Space.md,
                endIndent: Space.md,
                color: colors.ink.withValues(alpha: 0.14),
              ),
            _ItemRow(item: meal.items[i]),
          ],
        ],
      ),
    );
  }
}

class _ItemRow extends StatelessWidget {
  const _ItemRow({required this.item});

  final DietMealItem item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: Space.md,
        vertical: Space.sm,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.foodName, style: theme.textTheme.titleSmall),
                const SizedBox(height: 1),
                Text(
                  'P ${Fmt.grams(item.proteinG)} · '
                  'C ${Fmt.grams(item.carbsG)} · '
                  'G ${Fmt.grams(item.fatG)}',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
          const SizedBox(width: Space.xs),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${_grams(item.quantityG)} g',
                style: theme.textTheme.titleSmall,
              ),
              Text(Fmt.kcal(item.kcal), style: theme.textTheme.bodySmall),
            ],
          ),
        ],
      ),
    );
  }

  /// As quantidades vêm em múltiplos de 5 g; mostrar "150" em vez de "150.0" é o que alguém
  /// leria numa receita.
  static String _grams(num value) =>
      value == value.roundToDouble() ? '${value.round()}' : '$value';
}
