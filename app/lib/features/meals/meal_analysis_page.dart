import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/design/blocks.dart';
import '../../core/design/format.dart';
import '../../core/design/tokens.dart';
import '../../core/design/typography.dart';
import '../../core/widgets/blocks.dart';
import '../../core/widgets/empty_state.dart';
// O relógio do app, injetável: sem ele o rótulo "Hoje" de uma refeição mudaria de valor entre
// a captura da galeria e a execução do teste.
import '../home/today_controller.dart' show nowProvider;
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

/// A análise de refeição sem a barra de título.
///
/// **Esmeralda, a família da nutrição.** A aba Analisar hospeda duas telas que alimentam
/// assuntos diferentes — a foto do prato vira caloria no diário, o vídeo vira correção de
/// execução no treino —, e cada metade usa a cor do que alimenta. Quem manda na cor é o destino
/// do dado, não o segmentado que hospeda as duas.
///
/// **A captura saiu do rodapé e virou a ação do herói.** Presa embaixo, ela competia com a barra
/// de navegação do app e ficava tão longe do resultado que a tela vazia não parecia ter começo.
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

    return RefreshIndicator(
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
          illustrated: _illustrated,
          onIllustrated: state.running
              ? null
              : (v) => setState(() => _illustrated = v),
          onCapture: (source) =>
              controller.analyzeFrom(source, illustrated: _illustrated),
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
    required this.illustrated,
    required this.onIllustrated,
    required this.onCapture,
  });

  final List<MealAnalysis> meals;
  final bool running;
  final String? step;
  final double progress;
  final bool illustrated;

  /// Nulo enquanto a análise corre: o modo vale para a próxima captura, e mudá-lo no meio de
  /// uma que já subiu com a decisão tomada não teria efeito nenhum.
  final ValueChanged<bool>? onIllustrated;

  final ValueChanged<ImageSource> onCapture;

  @override
  Widget build(BuildContext context) {
    final colors = Blocks.nutrition(Theme.of(context).brightness);

    return ListView(
      padding: const EdgeInsets.fromLTRB(Space.gutter, 4, Space.gutter, 32),
      children: [
        // O herói é o estado do trabalho: o convite enquanto nada corre, o progresso enquanto
        // a análise acontece. Mesma mecânica do modo treino — o que muda sozinho ocupa o bloco
        // durante o tempo em que está mudando, e devolve o lugar quando termina.
        if (running)
          _ProgressHero(step: step, progress: progress, colors: colors)
        else
          _CaptureHero(
            colors: colors,
            analyzed: meals.length,
            onCapture: onCapture,
          ),
        for (final meal in meals) ...[
          const SizedBox(height: Space.sm),
          _MealCard(meal: meal, colors: colors),
        ],
        // O interruptor fecha a lista em vez de abri-la: é ajuste da próxima captura, e entre
        // o herói e as refeições ele empurrava para baixo justamente o que a pessoa veio ver.
        const SizedBox(height: Space.sm),
        _IllustratedSection(
          colors: colors,
          value: illustrated,
          onChanged: onIllustrated,
        ),
      ],
    );
  }
}

/// O convite — e o que a IA faz com a foto.
///
/// **Diz também o que ela não faz.** "A estimativa fica editável" é a dúvida de quem nunca usou
/// e o antídoto de quem confia demais: sem essa linha, um número errado vira motivo para
/// desinstalar em vez de motivo para tocar em "Ajustar". A frase só aparece na primeira vez —
/// quem já tem refeições no histórico descobriu isso na primeira, e repetir vira ruído.
class _CaptureHero extends StatelessWidget {
  const _CaptureHero({
    required this.colors,
    required this.analyzed,
    required this.onCapture,
  });

  final BlockColors colors;
  final int analyzed;
  final ValueChanged<ImageSource> onCapture;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return HeroBlock(
      colors: colors,
      label: 'Refeição',
      icon: Icons.photo_camera_outlined,
      action: HeroAction(
        label: 'Fotografar prato',
        onPressed: () => onCapture(ImageSource.camera),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (analyzed == 0) ...[
            Text(
              'Fotografe\nseu prato.',
              style: theme.textTheme.displaySmall?.copyWith(
                color: colors.onTone,
              ),
            ),
            const SizedBox(height: Space.sm),
            Text(
              'A IA estima as calorias e os macros — e a estimativa fica editável, item por '
              'item, antes de contar no seu dia.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colors.onTone.withValues(alpha: 0.85),
              ),
            ),
          ] else
            HeroFigure(
              value: '$analyzed',
              unit: analyzed == 1 ? 'refeição' : 'refeições',
              colors: colors,
              detail: 'analisadas por foto',
            ),
          const SizedBox(height: Space.xs),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () => onCapture(ImageSource.gallery),
              // Sem o respiro padrão do botão: com ele o ícone começa 12 dp à direita de tudo
              // o mais do bloco, e um item fora da margem é o que faz uma coluna parecer
              // desalinhada sem que se saiba dizer onde.
              style: TextButton.styleFrom(
                foregroundColor: colors.onTone,
                padding: EdgeInsets.zero,
                minimumSize: const Size(0, 44),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              icon: const Icon(Icons.photo_library_outlined, size: 18),
              label: const Text('Escolher da galeria'),
            ),
          ),
        ],
      ),
    );
  }
}

/// O modo ilustrado, fora do herói.
///
/// É uma preferência da próxima captura, não parte do convite: dentro do bloco ele competiria
/// com a ação, e um interruptor sobre cor cheia é o controle que menos se lê de relance.
class _IllustratedSection extends StatelessWidget {
  const _IllustratedSection({
    required this.colors,
    required this.value,
    required this.onChanged,
  });

  final BlockColors colors;
  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    return BlockSection(
      colors: colors,
      label: 'Análise ilustrada',
      icon: Icons.auto_fix_high_outlined,
      padding: EdgeInsets.zero,
      child: SwitchListTile(
        value: value,
        onChanged: onChanged,
        title: const Text('Marcar os alimentos na foto'),
        subtitle: const Text(
          'Custa uma chamada a mais e nem sempre está disponível.',
        ),
      ),
    );
  }
}

/// Enquanto a análise corre, o herói é o trabalho em curso.
class _ProgressHero extends StatefulWidget {
  const _ProgressHero({
    required this.step,
    required this.progress,
    required this.colors,
  });

  final String? step;
  final double progress;
  final BlockColors colors;

  @override
  State<_ProgressHero> createState() => _ProgressHeroState();
}

class _ProgressHeroState extends State<_ProgressHero> {
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
    final colors = widget.colors;
    // Enquanto a foto sobe, a barra mostra o quanto já foi — é a única etapa cuja duração
    // depende da rede do usuário. Depois disso o tempo é do servidor, e aí a barra vira
    // indeterminada em vez de fingir que sabe quanto falta.
    final uploading = widget.progress > 0 && widget.progress < 1;

    return HeroBlock(
      colors: colors,
      label: 'Analisando',
      icon: Icons.hourglass_top,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // O contador é o número grande porque é o único que anda. A etapa vem embaixo, como
          // detalhe: ela muda três ou quatro vezes na análise inteira, e um texto que troca
          // sozinho no lugar do número faria o bloco piscar de tamanho a cada passo.
          HeroFigure(
            value: '$_seconds',
            unit: 's',
            colors: colors,
            detail: widget.step ?? 'Enviando a foto',
          ),
          const SizedBox(height: Space.md),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: uploading ? widget.progress : null,
              minHeight: 7,
              color: colors.onTone,
              backgroundColor: colors.onTone.withValues(alpha: 0.25),
            ),
          ),
          const SizedBox(height: Space.sm),
          Text(
            'A estimativa fica editável no fim.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: colors.onTone.withValues(alpha: 0.85),
            ),
          ),
        ],
      ),
    );
  }
}

/// Uma refeição analisada: a foto, o que a IA contou, e as porções em aberto.
///
/// É uma seção e não um ladrilho: as refeições do histórico são o mesmo assunto visto muitas
/// vezes, e picotá-las em cartões coloridos sugeriria uma independência que elas não têm.
class _MealCard extends ConsumerStatefulWidget {
  const _MealCard({required this.meal, required this.colors});

  final MealAnalysis meal;
  final BlockColors colors;

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
    final colors = widget.colors;
    final meal = widget.meal;
    final photo = meal.illustratedPhotoUrl ?? meal.photoUrl;

    return BlockSection(
      colors: colors,
      label: _label(meal.createdAt, ref.read(nowProvider)()),
      icon: Icons.restaurant,
      // Os dois estados da refeição viram texto no rótulo. Eram um chip e um lápis ao lado do
      // número: o chip repetia a moldura de um bloco que já é uma moldura, e o lápis de 16 dp
      // dependia de um tooltip que ninguém abre no celular para dizer o que significava.
      trailing: meal.excludedFromDiary
          ? 'Fora do diário'
          : meal.userAdjusted && !_dirty
          ? 'Você ajustou'
          : null,
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Quando há versão ilustrada, é ela que aparece: as anotações sobre a comida
          // dizem mais que a foto crua, e a original continua no storage.
          if (photo != null)
            Image.network(
              photo,
              height: 160,
              fit: BoxFit.cover,
              // A URL é assinada e expira; falhar em carregar não pode quebrar o cartão,
              // que continua útil pelos macros.
              errorBuilder: (_, _, _) => const SizedBox.shrink(),
            ),
          Padding(
            padding: const EdgeInsets.all(Space.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      _round(_total((i) => i.kcal, meal.totalKcal)),
                      style: AppTypography.numeric(size: 28, color: colors.ink),
                    ),
                    const SizedBox(width: Space.xs),
                    Text(
                      'kcal',
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: colors.ink,
                      ),
                    ),
                  ],
                ),
                Text(
                  'P ${_round(_total((i) => i.proteinG, meal.totalProteinG))} g  ·  '
                  'C ${_round(_total((i) => i.carbsG, meal.totalCarbsG))} g  ·  '
                  'G ${_round(_total((i) => i.fatG, meal.totalFatG))} g',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: Space.sm),

                for (var i = 0; i < _items.length; i++) ...[
                  if (i > 0)
                    Divider(
                      height: 1,
                      color: colors.ink.withValues(alpha: 0.14),
                    ),
                  _ItemRow(
                    item: _items[i],
                    colors: colors,
                    enabled: !_saving,
                    onDecrease: () => _bump(i, -10),
                    onIncrease: () => _bump(i, 10),
                  ),
                ],

                const SizedBox(height: Space.xs),
                // `Flexible` nos dois lados, e não um `Spacer` no meio: com o corpo do texto
                // ampliado pela acessibilidade, "Tirar do diário" sozinho passa da largura da
                // tela — e um `Spacer` empurra o estouro para fora da vista em vez de deixar o
                // botão encolher.
                if (_dirty)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: TextButton(
                          onPressed: _saving
                              ? null
                              : () => setState(() => _draft = null),
                          style: TextButton.styleFrom(
                            foregroundColor: theme.colorScheme.onSurfaceVariant,
                          ),
                          child: const Text('Descartar'),
                        ),
                      ),
                      Flexible(
                        child: FilledButton(
                          onPressed: _saving ? null : _save,
                          style: FilledButton.styleFrom(
                            backgroundColor: colors.ink,
                            foregroundColor: colors.wash,
                            minimumSize: const Size(0, 40),
                          ),
                          child: _saving
                              ? SizedBox(
                                  height: 18,
                                  width: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: colors.wash,
                                  ),
                                )
                              : const Text('Salvar ajuste'),
                        ),
                      ),
                    ],
                  )
                else
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: TextButton.icon(
                          onPressed: _editQuantities,
                          style: TextButton.styleFrom(
                            foregroundColor: colors.ink,
                          ),
                          icon: const Icon(Icons.tune, size: 18),
                          label: const Text('Ajustar'),
                        ),
                      ),
                      // Tirar do diário é o que desfaz o efeito da refeição no dia, e não é o
                      // que se faz com a maioria delas: fica em texto neutro, longe da cor da
                      // família, para não disputar com "Ajustar".
                      Flexible(
                        child: TextButton(
                          onPressed: _toggleDiary,
                          style: TextButton.styleFrom(
                            foregroundColor: theme.colorScheme.onSurfaceVariant,
                          ),
                          child: Text(
                            meal.excludedFromDiary
                                ? 'Voltar ao diário'
                                : 'Tirar do diário',
                          ),
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

  /// O rótulo da refeição: a hora, e a data quando não é de hoje.
  ///
  /// O histórico atravessa dias. Sem a data, duas refeições das 12:30 em dias diferentes ficam
  /// idênticas na lista — e a de ontem passa a parecer um lançamento duplicado de hoje.
  static String _label(String? createdAt, DateTime now) {
    final at = createdAt == null
        ? null
        : DateTime.tryParse(createdAt)?.toLocal();
    if (at == null) {
      return 'Refeição';
    }

    final hora = Fmt.time(at);
    final mesmoDia =
        at.year == now.year && at.month == now.month && at.day == now.day;
    return mesmoDia ? 'Hoje, $hora' : '${Fmt.dayMonth(at)}, $hora';
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
    required this.colors,
    required this.enabled,
    required this.onDecrease,
    required this.onIncrease,
  });

  final MealAnalysisItem item;
  final BlockColors colors;
  final bool enabled;
  final VoidCallback onDecrease;
  final VoidCallback onIncrease;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Sobre um fundo já tingido, o contorno do tema entra como um cinza de outra paleta: os
    // botões usam a própria cor da família, rebaixada.
    final buttons = IconButton.styleFrom(
      foregroundColor: colors.ink,
      side: BorderSide(color: colors.ink.withValues(alpha: 0.4)),
      disabledForegroundColor: colors.ink.withValues(alpha: 0.4),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
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
            style: buttons,
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
            style: buttons,
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
        Space.gutter,
        Space.gutter,
        Space.gutter,
        MediaQuery.of(context).viewInsets.bottom + Space.gutter,
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
            const SizedBox(height: Space.xs),
            Text(
              'A IA estima pelo tamanho aparente. Corrija o que estiver longe.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: Space.md),

            for (var i = 0; i < widget.meal.items.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: Space.sm),
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
                    const SizedBox(width: Space.sm),
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

            const SizedBox(height: Space.md),
            FilledButton(
              onPressed: _submit,
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(46),
              ),
              child: const Text('Salvar ajuste'),
            ),
          ],
        ),
      ),
    );
  }
}
