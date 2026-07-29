import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/widgets/empty_state.dart';
import 'data/meal_models.dart';
import 'meal_analysis_controller.dart';

/// Análise de refeição por foto. Porte de `MealAnalysisPage.tsx`.
class MealAnalysisPage extends ConsumerStatefulWidget {
  const MealAnalysisPage({super.key});

  @override
  ConsumerState<MealAnalysisPage> createState() => _MealAnalysisPageState();
}

class _MealAnalysisPageState extends ConsumerState<MealAnalysisPage> {
  /// Modo ilustrado: a IA anota os itens e os macros na própria foto.
  ///
  /// Fica desligado por padrão porque custa uma chamada a mais e nem sempre está
  /// disponível — quando o modelo de imagem não tem cota, o servidor cai para um
  /// desenho local, e o resultado é mais simples do que a pessoa esperaria.
  bool _illustrated = false;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(mealAnalysisProvider);
    final controller = ref.read(mealAnalysisProvider.notifier);
    final history = ref.watch(mealHistoryProvider);

    ref.listen(mealAnalysisProvider, (previous, next) {
      if (next.error != null && next.error != previous?.error) {
        ScaffoldMessenger.of(context)
          ..clearSnackBars()
          ..showSnackBar(SnackBar(content: Text(next.error!)));
        ref.read(mealAnalysisProvider.notifier).dismissError();
      }
    });

    return Scaffold(
      appBar: AppBar(title: const Text('Refeições')),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(mealHistoryProvider);
          await ref.read(mealHistoryProvider.future);
        },
        child: history.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => EmptyState(
            icon: Icons.cloud_off_outlined,
            title: 'Não foi possível carregar suas refeições.',
            detail: '$error',
            action: FilledButton.tonal(
              onPressed: () => ref.invalidate(mealHistoryProvider),
              child: const Text('Tentar de novo'),
            ),
          ),
          data: (meals) => _Body(
            meals: meals,
            running: state.running,
            step: state.step,
            progress: controller.uploadProgress,
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              dense: true,
              value: _illustrated,
              onChanged: state.running
                  ? null
                  : (v) => setState(() => _illustrated = v),
              title: const Text('Análise ilustrada'),
              subtitle: const Text(
                'Marca os alimentos e os macros na própria foto',
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: state.running
                        ? null
                        : () => controller.analyzeFrom(
                            ImageSource.camera,
                            illustrated: _illustrated,
                          ),
                    icon: const Icon(Icons.photo_camera_outlined),
                    label: const Text('Fotografar'),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: state.running
                      ? null
                      : () => controller.analyzeFrom(
                          ImageSource.gallery,
                          illustrated: _illustrated,
                        ),
                  icon: const Icon(Icons.photo_library_outlined),
                  label: const Text('Galeria'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({
    required this.meals,
    required this.running,
    required this.step,
    required this.progress,
  });

  final List<MealAnalysis> meals;
  final bool running;
  final String? step;
  final double progress;

  @override
  Widget build(BuildContext context) {
    if (meals.isEmpty && !running) {
      return const EmptyState(
        icon: Icons.restaurant_outlined,
        title: 'Nenhuma refeição analisada ainda.',
        detail: 'Fotografe seu prato e a IA estima as calorias e os macros.',
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      children: [
        if (running) _ProgressCard(step: step, progress: progress),
        for (final meal in meals) _MealCard(meal: meal),
      ],
    );
  }
}

class _ProgressCard extends StatelessWidget {
  const _ProgressCard({required this.step, required this.progress});

  final String? step;
  final double progress;

  @override
  Widget build(BuildContext context) {
    // Enquanto a foto sobe, a barra mostra o quanto já foi — é a única etapa cuja duração
    // depende da rede do usuário. Depois disso o tempo é do servidor, e aí a barra vira
    // indeterminada em vez de fingir que sabe quanto falta.
    final uploading = progress > 0 && progress < 1;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              step ?? 'Analisando…',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(value: uploading ? progress : null),
          ],
        ),
      ),
    );
  }
}

class _MealCard extends ConsumerWidget {
  const _MealCard({required this.meal});

  final MealAnalysis meal;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Quando há versão ilustrada, é ela que aparece: as anotações sobre a comida
          // dizem mais que a foto crua, e a original continua no storage.
          if ((meal.illustratedPhotoUrl ?? meal.photoUrl) != null)
            Image.network(
              meal.illustratedPhotoUrl ?? meal.photoUrl!,
              height: 160,
              fit: BoxFit.cover,
              // A URL é assinada e expira; falhar em carregar não pode quebrar o cartão,
              // que continua útil pelos macros.
              errorBuilder: (_, _, _) => const SizedBox.shrink(),
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${_round(meal.totalKcal)} kcal',
                        style: theme.textTheme.titleLarge,
                      ),
                    ),
                    if (meal.userAdjusted)
                      Padding(
                        padding: const EdgeInsets.only(right: 4),
                        child: Tooltip(
                          message: 'Você ajustou esta estimativa',
                          child: Icon(
                            Icons.edit_outlined,
                            size: 16,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    if (meal.excludedFromDiary)
                      Chip(
                        label: const Text('Fora do diário'),
                        visualDensity: VisualDensity.compact,
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'P ${_round(meal.totalProteinG)} g  ·  '
                  'C ${_round(meal.totalCarbsG)} g  ·  '
                  'G ${_round(meal.totalFatG)} g',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 12),

                for (final item in meal.items)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.description,
                            style: theme.textTheme.bodyMedium,
                          ),
                        ),
                        Text(
                          '${_round(item.quantityG)} g  ·  ${_round(item.kcal)} kcal',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 8),
                Row(
                  children: [
                    TextButton.icon(
                      onPressed: () => _editQuantities(context, ref),
                      icon: const Icon(Icons.tune, size: 18),
                      label: const Text('Ajustar'),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: () => _toggleDiary(context, ref),
                      child: Text(
                        meal.excludedFromDiary
                            ? 'Voltar ao diário'
                            : 'Tirar do diário',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleDiary(BuildContext context, WidgetRef ref) async {
    try {
      await ref
          .read(mealAnalysisProvider.notifier)
          .adjust(
            meal.id,
            MealAdjustRequest(excludedFromDiary: !meal.excludedFromDiary),
          );
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
          ..clearSnackBars()
          ..showSnackBar(SnackBar(content: Text('$error')));
      }
    }
  }

  Future<void> _editQuantities(BuildContext context, WidgetRef ref) async {
    final items = await showModalBottomSheet<List<MealAnalysisItem>>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _QuantitySheet(meal: meal),
    );
    if (items == null || !context.mounted) {
      return;
    }

    try {
      await ref
          .read(mealAnalysisProvider.notifier)
          .adjust(meal.id, MealAdjustRequest(items: items));
      if (context.mounted) {
        ScaffoldMessenger.of(context)
          ..clearSnackBars()
          ..showSnackBar(const SnackBar(content: Text('Estimativa ajustada.')));
      }
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
          ..clearSnackBars()
          ..showSnackBar(SnackBar(content: Text('$error')));
      }
    }
  }

  static String _round(num value) => value.round().toString();
}

/// Ajuste das porções.
///
/// Só a quantidade é editável: os macros são reescalados proporcionalmente antes do envio, e
/// quem soma tudo de novo é o servidor. Deixar o usuário digitar caloria à mão abriria a porta
/// para um total que não corresponde a nenhum item.
class _QuantitySheet extends StatefulWidget {
  const _QuantitySheet({required this.meal});

  final MealAnalysis meal;

  @override
  State<_QuantitySheet> createState() => _QuantitySheetState();
}

class _QuantitySheetState extends State<_QuantitySheet> {
  late final List<TextEditingController> _quantities;
  late final List<bool> _keep;

  @override
  void initState() {
    super.initState();
    _quantities = widget.meal.items
        .map(
          (item) =>
              TextEditingController(text: item.quantityG.round().toString()),
        )
        .toList();
    _keep = List.filled(widget.meal.items.length, true);
  }

  @override
  void dispose() {
    for (final controller in _quantities) {
      controller.dispose();
    }
    super.dispose();
  }

  void _submit() {
    final adjusted = <MealAnalysisItem>[];

    for (var i = 0; i < widget.meal.items.length; i++) {
      if (!_keep[i]) {
        continue;
      }
      final original = widget.meal.items[i];
      final grams = double.tryParse(
        _quantities[i].text.trim().replaceAll(',', '.'),
      );

      if (grams == null || grams <= 0) {
        continue;
      }
      // Regra de três sobre a estimativa original: dobrar a porção dobra os macros.
      final factor = original.quantityG == 0
          ? 1.0
          : grams / original.quantityG.toDouble();

      adjusted.add(
        original.copyWith(
          quantityG: grams,
          kcal: original.kcal * factor,
          proteinG: original.proteinG * factor,
          carbsG: original.carbsG * factor,
          fatG: original.fatG * factor,
        ),
      );
    }

    if (adjusted.isEmpty) {
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(
          const SnackBar(
            content: Text(
              'Deixe pelo menos um item. Para descartar a refeição, '
              'tire-a do diário.',
            ),
          ),
        );
      return;
    }

    Navigator.of(context).pop(adjusted);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        16,
        16,
        16,
        MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Ajustar porções',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            Text(
              'A IA estima pelo tamanho aparente. Corrija o que estiver longe.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 16),

            for (var i = 0; i < widget.meal.items.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Checkbox(
                      value: _keep[i],
                      onChanged: (value) =>
                          setState(() => _keep[i] = value ?? true),
                    ),
                    Expanded(
                      child: Text(
                        widget.meal.items[i].description,
                        style: TextStyle(
                          decoration: _keep[i]
                              ? null
                              : TextDecoration.lineThrough,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 90,
                      child: TextField(
                        controller: _quantities[i],
                        enabled: _keep[i],
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.end,
                        decoration: const InputDecoration(
                          suffixText: 'g',
                          isDense: true,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 16),
            FilledButton(
              onPressed: _submit,
              child: const Text('Salvar ajuste'),
            ),
          ],
        ),
      ),
    );
  }
}
