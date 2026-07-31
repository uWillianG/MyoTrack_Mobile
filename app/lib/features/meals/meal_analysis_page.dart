import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/widgets/empty_state.dart';
import 'data/meal_models.dart';
import 'meal_analysis_controller.dart';

/// Análise de refeição por foto. Porte de `MealAnalysisPage.tsx`.
///
/// Rota própria (`/refeicoes`); o conteúdo mora em [MealAnalysisView] para a aba Analisar do
/// hub diário poder mostrá-lo sob a barra de título dela.
class MealAnalysisPage extends StatelessWidget {
  const MealAnalysisPage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Refeições')),
    body: const MealAnalysisView(),
  );
}

/// A análise de refeição sem a barra de título, com os botões de captura presos embaixo.
///
/// Os botões vêm no fim de uma `Column` e não num `bottomNavigationBar`: dentro da aba
/// Analisar o rodapé do `Scaffold` já é a barra de navegação do app.
class MealAnalysisView extends ConsumerStatefulWidget {
  const MealAnalysisView({super.key});

  @override
  ConsumerState<MealAnalysisView> createState() => _MealAnalysisViewState();
}

class _MealAnalysisViewState extends ConsumerState<MealAnalysisView> {
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

    return Column(
      children: [
        Expanded(
          child: RefreshIndicator(
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
        ),
        SafeArea(
          top: false,
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
                    // Altura mínima, largura pelo conteúdo. `Size.fromHeight` põe largura
                    // infinita no mínimo, e dentro de uma `Row` — que não limita o eixo
                    // principal dos filhos sem flex — isso estoura o layout.
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 48),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
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
      return ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        children: const [_PhotoPlaceholder()],
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

/// O lugar da foto, antes de existir foto.
///
/// Um retângulo tracejado no formato do resultado diz o que vai aparecer ali e onde — a
/// mensagem centralizada de estado vazio que estava aqui explicava com palavras o que a
/// forma explica sozinha, e deixava a tela parecendo um erro em vez de um começo.
class _PhotoPlaceholder extends StatelessWidget {
  const _PhotoPlaceholder();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        CustomPaint(
          painter: _DashedBorderPainter(color: theme.colorScheme.outline),
          child: SizedBox(
            height: 200,
            width: double.infinity,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.restaurant_outlined,
                  size: 40,
                  color: theme.colorScheme.outline,
                ),
                const SizedBox(height: 8),
                Text(
                  'foto do prato',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.outline,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Fotografe seu prato e a IA estima as calorias e os macros. A estimativa fica '
          'editável no fim.',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  const _DashedBorderPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = RRect.fromRectAndRadius(
      Offset.zero & size,
      const Radius.circular(16),
    );
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = color;

    // Traço de 6 dp com 6 de intervalo, percorrendo o contorno arredondado. Desenhado à mão
    // porque o Flutter não tem borda tracejada — e um `Container` com borda sólida não diria
    // "aqui ainda não tem nada".
    for (final metric in (Path()..addRRect(rect)).computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final end = math.min(distance + 6, metric.length);
        canvas.drawPath(metric.extractPath(distance, end), paint);
        distance = end + 6;
      }
    }
  }

  @override
  bool shouldRepaint(_DashedBorderPainter old) => old.color != color;
}

class _ProgressCard extends StatefulWidget {
  const _ProgressCard({required this.step, required this.progress});

  final String? step;
  final double progress;

  @override
  State<_ProgressCard> createState() => _ProgressCardState();
}

class _ProgressCardState extends State<_ProgressCard> {
  /// Segundos desde que a análise começou.
  ///
  /// A barra fica indeterminada depois do upload — o tempo passa a ser do servidor —, e uma
  /// barra que anda sem chegar a lugar nenhum é onde a pessoa desiste e sai da tela. O
  /// contador é o que diz que ainda está andando, e a frase ao lado é o que faz esperar
  /// valer: a estimativa não é definitiva.
  int _seconds = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => setState(() => _seconds += 1),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Enquanto a foto sobe, a barra mostra o quanto já foi — é a única etapa cuja duração
    // depende da rede do usuário. Depois disso o tempo é do servidor, e aí a barra vira
    // indeterminada em vez de fingir que sabe quanto falta.
    final uploading = widget.progress > 0 && widget.progress < 1;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.step ?? 'Analisando…',
              style: theme.textTheme.titleSmall,
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(value: uploading ? widget.progress : null),
            const SizedBox(height: 8),
            Text(
              '${_seconds}s — a estimativa fica editável no fim',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MealCard extends ConsumerStatefulWidget {
  const _MealCard({required this.meal});

  final MealAnalysis meal;

  @override
  ConsumerState<_MealCard> createState() => _MealCardState();
}

class _MealCardState extends ConsumerState<_MealCard> {
  /// Porções em edição. Null enquanto o usuário não mexeu em nada.
  ///
  /// O ajuste fica local até ele confirmar, em vez de um PUT por toque no "+": o gesto certo
  /// é apertar o mais três ou quatro vezes seguidas, e cada toque virando requisição faria a
  /// estimativa pular no meio da edição — além de gastar a rede da academia.
  List<MealAnalysisItem>? _draft;
  bool _saving = false;

  List<MealAnalysisItem> get _items => _draft ?? widget.meal.items;

  bool get _dirty => _draft != null;

  /// Total de um macro: somado do rascunho enquanto há edição, e o que veio do servidor
  /// quando não há. Recalcular sempre faria o cartão mostrar um número levemente diferente
  /// do salvo, por arredondamento.
  num _total(num Function(MealAnalysisItem) of, num saved) =>
      _dirty ? _items.fold<num>(0, (sum, item) => sum + of(item)) : saved;

  /// Muda a porção de um item em [delta] gramas, reescalando os macros na mesma proporção.
  ///
  /// Piso de 10 g: abaixo disso a regra de três amplifica o erro da estimativa original mais
  /// do que informa, e zerar um item é trabalho de "Ajustar", que sabe removê-lo.
  void _bump(int index, int delta) {
    final items = [..._items];
    final original = widget.meal.items[index];
    final grams = math.max(10, items[index].quantityG.round() + delta);
    final factor = original.quantityG == 0
        ? 1.0
        : grams / original.quantityG.toDouble();

    items[index] = original.copyWith(
      quantityG: grams,
      kcal: original.kcal * factor,
      proteinG: original.proteinG * factor,
      carbsG: original.carbsG * factor,
      fatG: original.fatG * factor,
    );
    setState(() => _draft = items);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final meal = widget.meal;

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
                        '${_round(_total((i) => i.kcal, meal.totalKcal))} kcal',
                        style: theme.textTheme.titleLarge,
                      ),
                    ),
                    if (meal.userAdjusted && !_dirty)
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
                  'P ${_round(_total((i) => i.proteinG, meal.totalProteinG))} g  ·  '
                  'C ${_round(_total((i) => i.carbsG, meal.totalCarbsG))} g  ·  '
                  'G ${_round(_total((i) => i.fatG, meal.totalFatG))} g',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 12),

                for (var i = 0; i < _items.length; i++)
                  _ItemRow(
                    item: _items[i],
                    enabled: !_saving,
                    onDecrease: () => _bump(i, -10),
                    onIncrease: () => _bump(i, 10),
                  ),

                const SizedBox(height: 8),
                if (_dirty)
                  Row(
                    children: [
                      TextButton(
                        onPressed: _saving
                            ? null
                            : () => setState(() => _draft = null),
                        child: const Text('Descartar'),
                      ),
                      const Spacer(),
                      FilledButton(
                        onPressed: _saving ? null : _save,
                        style: FilledButton.styleFrom(
                          minimumSize: const Size(0, 40),
                        ),
                        child: _saving
                            ? const SizedBox(
                                height: 18,
                                width: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text('Salvar ajuste'),
                      ),
                    ],
                  )
                else
                  Row(
                    children: [
                      TextButton.icon(
                        onPressed: _editQuantities,
                        icon: const Icon(Icons.tune, size: 18),
                        label: const Text('Ajustar'),
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: _toggleDiary,
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

  Future<void> _save() async {
    final items = _draft;
    if (items == null) {
      return;
    }

    setState(() => _saving = true);
    try {
      await ref
          .read(mealAnalysisProvider.notifier)
          .adjust(widget.meal.id, MealAdjustRequest(items: items));
      if (mounted) {
        setState(() {
          _draft = null;
          _saving = false;
        });
        ScaffoldMessenger.of(context)
          ..clearSnackBars()
          ..showSnackBar(const SnackBar(content: Text('Estimativa ajustada.')));
      }
    } catch (error) {
      if (mounted) {
        // O rascunho fica: perder o ajuste por uma falha de rede obrigaria a refazer os
        // toques um a um.
        setState(() => _saving = false);
        ScaffoldMessenger.of(context)
          ..clearSnackBars()
          ..showSnackBar(SnackBar(content: Text('$error')));
      }
    }
  }

  Future<void> _toggleDiary() async {
    try {
      await ref
          .read(mealAnalysisProvider.notifier)
          .adjust(
            widget.meal.id,
            MealAdjustRequest(
              excludedFromDiary: !widget.meal.excludedFromDiary,
            ),
          );
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..clearSnackBars()
          ..showSnackBar(SnackBar(content: Text('$error')));
      }
    }
  }

  /// A folha continua existindo para o que os botões não fazem: digitar um valor exato e
  /// remover um item que a IA viu e não estava no prato.
  Future<void> _editQuantities() async {
    final items = await showModalBottomSheet<List<MealAnalysisItem>>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _QuantitySheet(meal: widget.meal),
    );
    if (items == null || !mounted) {
      return;
    }

    setState(() => _draft = items);
    await _save();
  }

  static String _round(num value) => value.round().toString();
}

/// Uma linha de item, com os botões de porção.
///
/// Passos de 10 g porque é a granularidade que a estimativa comporta: a IA erra a porção em
/// dezenas de gramas, e um passo de 1 g sugeriria uma precisão que o número não tem.
class _ItemRow extends StatelessWidget {
  const _ItemRow({
    required this.item,
    required this.enabled,
    required this.onDecrease,
    required this.onIncrease,
  });

  final MealAnalysisItem item;
  final bool enabled;
  final VoidCallback onDecrease;
  final VoidCallback onIncrease;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.description, style: theme.textTheme.bodyMedium),
                Text(
                  '${item.kcal.round()} kcal',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          IconButton.outlined(
            onPressed: enabled ? onDecrease : null,
            icon: const Icon(Icons.remove, size: 16),
            visualDensity: VisualDensity.compact,
            tooltip: 'Menos 10 g de ${item.description}',
          ),
          SizedBox(
            width: 56,
            child: Text(
              '${item.quantityG.round()} g',
              textAlign: TextAlign.center,
              style: theme.textTheme.labelLarge,
            ),
          ),
          IconButton.outlined(
            onPressed: enabled ? onIncrease : null,
            icon: const Icon(Icons.add, size: 16),
            visualDensity: VisualDensity.compact,
            tooltip: 'Mais 10 g de ${item.description}',
          ),
        ],
      ),
    );
  }
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
