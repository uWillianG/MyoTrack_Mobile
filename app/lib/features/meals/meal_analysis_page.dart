import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/day_groups.dart';
import '../../core/design/blocks.dart';
import '../../core/design/format.dart';
import '../../core/design/tokens.dart';
import '../../core/widgets/blocks.dart';
import '../../core/widgets/glass_segmented.dart';
import '../../core/widgets/empty_state.dart';
// O relógio do app, injetável: sem ele o bloco "Hoje" do histórico mudaria de valor entre a
// captura da galeria e a execução do teste.
import '../home/today_controller.dart' show nowProvider;
import 'data/meal_models.dart';
import 'meal_analysis_controller.dart';

/// O histórico partido em dias. Ver [groupByDay], que é onde a regra mora.
List<DayGroup<MealAnalysis>> groupMealsByDay(
  List<MealAnalysis> meals,
  DateTime now,
) => groupByDay(meals, now, at: (meal) => meal.createdAt, undated: 'Refeições');

/// Como a refeição se chama numa lista — o alimento que mais pesa, e quantos vieram com ele.
///
/// A análise não tem nome: o servidor devolve itens, macros e uma foto. **O nome é o alimento
/// de maior caloria** porque é o que a pessoa lembra de ter comido; a ordem em que a IA
/// devolveu os itens não significa nada e usar o primeiro seria escolher ao acaso.
///
/// "e mais 2" em vez dos três nomes: dois alimentos por extenso já estouram a linha em 360 dp,
/// e uma lista de nomes cortados no meio identifica menos que um nome inteiro mais a contagem.
String mealName(MealAnalysis meal) {
  if (meal.items.isEmpty) {
    return 'Refeição';
  }
  final head = meal.items.reduce((a, b) => b.kcal > a.kcal ? b : a).description;
  final rest = meal.items.length - 1;
  return rest == 0 ? head : '$head e mais $rest';
}

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
          now: ref.read(nowProvider)(),
          // A análise que acabou de sair chega aberta. Fechada, ela seria indistinguível das
          // antigas justamente no momento em que a pessoa está esperando por ela — e o
          // resultado que ela foi buscar exigiria um toque a mais para aparecer.
          justAnalyzed: controller.result?.id,
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
    required this.now,
    required this.justAnalyzed,
    required this.illustrated,
    required this.onIllustrated,
    required this.onCapture,
  });

  final List<MealAnalysis> meals;
  final bool running;
  final String? step;
  final double progress;
  final DateTime now;

  /// Id da análise recém-concluída, que a lista mostra aberta. Null quando nada foi analisado
  /// nesta sessão da tela.
  final String? justAnalyzed;

  final bool illustrated;

  /// Nulo enquanto a análise corre: o modo vale para a próxima captura, e mudá-lo no meio de
  /// uma que já subiu com a decisão tomada não teria efeito nenhum.
  final ValueChanged<bool>? onIllustrated;

  final ValueChanged<ImageSource> onCapture;

  @override
  Widget build(BuildContext context) {
    final colors = Blocks.nutrition(Theme.of(context).brightness);

    return ListView(
      padding: EdgeInsets.fromLTRB(
        Space.gutter,
        4,
        Space.gutter,
        listBottomInset(context),
      ),
      children: [
        // O herói é o estado do trabalho: o convite enquanto nada corre, o progresso enquanto
        // a análise acontece. Mesma mecânica do modo treino — o que muda sozinho ocupa o bloco
        // durante o tempo em que está mudando, e devolve o lugar quando termina.
        if (running)
          _ProgressHero(step: step, progress: progress, colors: colors)
        else
          _CaptureHero(
            colors: colors,
            hasHistory: meals.isNotEmpty,
            onCapture: onCapture,
          ),
        // O interruptor vem logo abaixo do herói, encostado na ação que ele modifica.
        //
        // **Ele já morou no fim da lista**, com o argumento de que ajuste de comportamento
        // futuro fica depois do conteúdo presente — e o argumento valia enquanto cada refeição
        // era um cartão aberto de meia tela: ali, no topo, ele empurrava para baixo justamente
        // o que a pessoa veio ver. Com a lista fechada em linhas, esse custo acabou: o
        // histórico inteiro cabe na tela com o interruptor em cima dele. O que sobrou foi o
        // custo oposto — ligar o modo ilustrado exigia rolar até o fim e voltar ao topo para
        // fotografar.
        const SizedBox(height: Space.sm),
        _IllustratedSection(
          colors: colors,
          value: illustrated,
          onChanged: onIllustrated,
        ),
        for (final day in groupMealsByDay(meals, now)) ...[
          const SizedBox(height: Space.sm),
          _DaySection(day: day, colors: colors, justAnalyzed: justAnalyzed),
        ],
      ],
    );
  }
}

/// Um dia do histórico: um bloco, e dentro dele uma linha por refeição.
///
/// **O dia é o bloco, e não uma régua entre cartões.** Uma primeira versão pôs a data numa
/// régua e manteve um bloco por refeição; com cinco refeições num dia, saíam cinco molduras
/// lavadas repetindo a mesma forma. As refeições de um dia são facetas do mesmo assunto — o que
/// aquela pessoa comeu naquele dia —, e faceta é seção, não ladrilho (§1). Assim o rótulo do
/// bloco carrega a data, que é a dimensão pela qual o histórico é percorrido (§18).
class _DaySection extends StatelessWidget {
  const _DaySection({
    required this.day,
    required this.colors,
    required this.justAnalyzed,
  });

  final DayGroup<MealAnalysis> day;
  final BlockColors colors;
  final String? justAnalyzed;

  @override
  Widget build(BuildContext context) {
    final meals = day.items;

    return BlockSection(
      colors: colors,
      label: day.label,
      icon: Icons.restaurant,
      trailing: meals.length == 1 ? '1 refeição' : '${meals.length} refeições',
      // Zero porque o conteúdo é lista: o fio entre duas refeições precisa encostar nas bordas
      // do bloco, senão ele lê como sublinhado de uma delas em vez de divisa entre as duas.
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final meal in meals) ...[
            if (meal != meals.first)
              Divider(height: 1, color: colors.ink.withValues(alpha: 0.14)),
            // **A chave é o id, e não a posição.** Uma análise nova entra na frente e empurra
            // todas as outras; sem a chave, o estado de aberta/fechada e o rascunho de porções
            // ficariam onde estavam e passariam a valer para a refeição vizinha.
            _MealRow(
              key: ValueKey(meal.id),
              meal: meal,
              colors: colors,
              justAnalyzed: meal.id == justAnalyzed,
            ),
          ],
        ],
      ),
    );
  }
}

/// O convite — e o que a IA faz com a foto.
///
/// **Diz também o que ela não faz.** "A estimativa fica editável" é a dúvida de quem nunca usou
/// e o antídoto de quem confia demais: sem essa linha, um número errado vira motivo para
/// desinstalar em vez de motivo para tocar em "Ajustar". A frase só aparece na primeira vez —
/// quem já tem refeições no histórico descobriu isso na primeira, e repetir vira ruído.
///
/// **Com histórico, o bloco perde o número e fica só com a ação.** Ele contava quantas
/// refeições já tinham sido analisadas, e essa é exatamente a soma do que os blocos de dia
/// escrevem logo abaixo — "2 refeições", "1 refeição". Um herói existe para dizer o que mais
/// nenhum bloco diz (§16), e este dizia a mesma coisa em 118 dp, que saíam do resultado que a
/// pessoa abriu para conferir.
///
/// Nem toda manchete precisa de número: aqui o assunto é **o trabalho**, e parado o trabalho é
/// um convite. O bloco continua sendo o único em cor cheia e o único com ação — que é o que faz
/// dele o herói.
class _CaptureHero extends StatelessWidget {
  const _CaptureHero({
    required this.colors,
    required this.hasHistory,
    required this.onCapture,
  });

  final BlockColors colors;

  /// Se já há refeições no histórico. É só isso que o bloco precisa saber: a contagem em si
  /// não aparece mais nele.
  final bool hasHistory;

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
          if (!hasHistory) ...[
            Text(
              'Fotografe\nseu prato.',
              style: theme.textTheme.displaySmall?.copyWith(
                color: colors.onGlass,
              ),
            ),
            const SizedBox(height: Space.sm),
            Text(
              'A IA estima as calorias e os macros — e a estimativa fica editável, item por '
              'item, antes de contar no seu dia.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colors.onGlass.withValues(alpha: 0.85),
              ),
            ),
            const SizedBox(height: Space.xs),
          ],
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () => onCapture(ImageSource.gallery),
              // Sem o respiro padrão do botão: com ele o ícone começa 12 dp à direita de tudo
              // o mais do bloco, e um item fora da margem é o que faz uma coluna parecer
              // desalinhada sem que se saiba dizer onde.
              style: TextButton.styleFrom(
                foregroundColor: colors.onGlass,
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
      // `dense`, e a ressalva numa linha só: no fim da lista a altura dele não custava nada, no
      // topo ela sai do conteúdo. Os dois fatos continuam escritos — o que some é o respiro.
      child: SwitchListTile(
        value: value,
        onChanged: onChanged,
        dense: true,
        title: const Text('Marcar os alimentos na foto'),
        subtitle: const Text('Uma chamada a mais, e nem sempre disponível.'),
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
              color: colors.onGlass,
              backgroundColor: colors.onGlass.withValues(alpha: 0.25),
            ),
          ),
          const SizedBox(height: Space.sm),
          Text(
            'A estimativa fica editável no fim.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: colors.onGlass.withValues(alpha: 0.85),
            ),
          ),
        ],
      ),
    );
  }
}

/// Uma refeição no histórico: o nome sempre, e a análise quando se pede.
///
/// **A foto não aparece de cara.** Aberta de saída, cada refeição custava 160 dp de imagem e
/// uma requisição, e um histórico de dez almoços baixava dez fotos ao abrir a tela — o mesmo
/// gasto que a metade de vídeo já evitava com "o toque é o consentimento" (§16). O que se
/// percorre num histórico é o que se comeu e quanto deu; a foto e os itens são o que se
/// confere depois de achar a refeição certa.
///
/// **O rascunho sobrevive ao fechar.** As porções em edição moram aqui, e não dentro do que
/// aparece ao abrir: recolher a linha no meio de um ajuste jogaria fora os toques já dados,
/// sem avisar. Enquanto houver rascunho, a própria linha fechada diz "ajuste não salvo".
class _MealRow extends ConsumerStatefulWidget {
  const _MealRow({
    super.key,
    required this.meal,
    required this.colors,
    this.justAnalyzed = false,
  });

  final MealAnalysis meal;
  final BlockColors colors;

  /// Esta é a análise que acabou de sair do servidor. Ela nasce aberta.
  final bool justAnalyzed;

  @override
  ConsumerState<_MealRow> createState() => _MealRowState();
}

class _MealRowState extends ConsumerState<_MealRow> {
  /// Se a análise desta refeição está aberta.
  ///
  /// Cada linha guarda a sua, em vez de a lista guardar "qual está aberta": abrir uma refeição
  /// para comparar com outra é gesto legítimo, e um acordeão que fecha sozinho o que a pessoa
  /// acabou de abrir transforma a comparação em vaivém.
  late bool _open = widget.justAnalyzed;

  /// A recém-analisada abre também quando a linha já existia — é o caso de reanalisar a mesma
  /// refeição. Só na virada: depois disso, quem manda em `_open` é o toque, e um rebuild
  /// qualquer não reabre o que a pessoa fechou.
  @override
  void didUpdateWidget(covariant _MealRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.justAnalyzed && !oldWidget.justAnalyzed) {
      setState(() => _open = true);
    }
  }

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
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [_head(context), if (_open) _analysis(context)],
  );

  /// O que a lista mostra sempre: o nome, a hora, o total e o estado.
  ///
  /// `MergeSemantics` porque as duas linhas são uma coisa só para quem ouve — anunciadas
  /// separadamente, o nome e o "624 kcal" viram dois itens de lista que não se sabe se
  /// pertencem à mesma refeição. O `expanded` é o que diz se o toque abre ou fecha.
  Widget _head(BuildContext context) {
    final theme = Theme.of(context);
    final colors = widget.colors;

    return MergeSemantics(
      child: Semantics(
        button: true,
        expanded: _open,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => setState(() => _open = !_open),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: Space.md,
                vertical: Space.sm,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          mealName(widget.meal),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _summary(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: Space.sm),
                  Icon(
                    _open ? Icons.expand_less : Icons.expand_more,
                    size: 20,
                    color: colors.ink,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// O que abre no toque: a foto, os macros e as porções.
  ///
  /// **Sem o total em número grande.** Ele existia aqui e continua existindo — na linha logo
  /// acima, que fica visível o tempo todo e já acompanha o rascunho. Repeti-lo dois centímetros
  /// abaixo seria o mesmo dado duas vezes na mesma vista (§18).
  Widget _analysis(BuildContext context) {
    final theme = Theme.of(context);
    final colors = widget.colors;
    final meal = widget.meal;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _MealPhoto(meal: meal),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            Space.md,
            Space.sm,
            Space.md,
            Space.md,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
                  Divider(height: 1, color: colors.ink.withValues(alpha: 0.14)),
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
    );
  }

  /// A segunda linha do cabeçalho: hora, total e o que houver de estado.
  ///
  /// **A hora perdeu a data** quando a lista passou a ser agrupada: ela distinguia duas
  /// refeições das 12:30 em dias diferentes, e agora quem faz isso é o rótulo do bloco do dia.
  ///
  /// **O total é o do rascunho**, quando há um. É o número que anda enquanto se aperta o mais,
  /// e ele fica na linha que não sai da tela — por isso a análise aberta não o repete.
  ///
  /// **O estado vem por último e em caixa baixa**: aqui ele é o fim de uma frase que começou na
  /// hora, e não um rótulo solto. "ajuste não salvo" existe porque a linha fecha com o rascunho
  /// vivo, e um ajuste esquecido dentro de uma linha fechada é um ajuste perdido.
  String _summary() {
    final meal = widget.meal;
    final at = meal.createdAt == null
        ? null
        : DateTime.tryParse(meal.createdAt!)?.toLocal();

    return [
      if (at != null) Fmt.time(at),
      Fmt.kcal(_total((i) => i.kcal, meal.totalKcal)),
      if (meal.excludedFromDiary)
        'fora do diário'
      else if (_dirty)
        'ajuste não salvo'
      else if (meal.userAdjusted)
        'você ajustou',
    ].join(' · ');
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

/// A foto da refeição no cartão, e o toque que a abre inteira.
///
/// **A faixa de 160 dp não é a foto, é a lembrança dela.** Recortada em `cover`, ela serve para
/// reconhecer o prato enquanto se rola — e não para conferir nada. Quando a análise é
/// ilustrada, as etiquetas que a IA desenhou sobre a comida ("Arroz branco, 150 g") saem
/// ilegíveis nesse recorte, e são justamente elas que dizem se a porção precisa de ajuste.
///
/// O selo no canto existe porque **alvo de toque sem sinal não é alvo**: uma foto que abre e
/// uma foto que não abre são idênticas de olhar, e a diferença só se descobre tocando.
class _MealPhoto extends StatelessWidget {
  const _MealPhoto({required this.meal});

  final MealAnalysis meal;

  @override
  Widget build(BuildContext context) {
    // Quando há versão ilustrada, é ela que aparece: as anotações sobre a comida dizem mais
    // que a foto crua. A original continua no storage e agora tem como ser vista — o visor
    // alterna entre as duas.
    final photo = meal.illustratedPhotoUrl ?? meal.photoUrl;
    if (photo == null) {
      return const SizedBox.shrink();
    }

    return Stack(
      fit: StackFit.passthrough,
      children: [
        Image.network(
          photo,
          height: 160,
          fit: BoxFit.cover,
          // A URL é assinada e expira; falhar em carregar não pode quebrar o cartão, que
          // continua útil pelos macros. Com a imagem em nada, a pilha inteira colapsa com
          // ela — o selo e o alvo de toque vão junto, que é o certo: não há o que abrir.
          errorBuilder: (_, _, _) => const SizedBox.shrink(),
        ),
        // O respingo precisa de um `Material` próprio: pintado por baixo da imagem ele
        // aconteceria atrás dela, e o toque ficaria sem resposta nenhuma.
        //
        // O rótulo do leitor de tela mora aqui e não em volta da pilha: é este o alvo, e
        // `container` é o que lhe dá nó próprio em vez de deixar o texto se dissolver no nó
        // do bloco. Sem isso a foto é, para quem não a vê, uma região muda.
        Positioned.fill(
          child: Semantics(
            button: true,
            container: true,
            label: 'Ver a foto da refeição',
            child: Material(
              color: Colors.transparent,
              child: InkWell(onTap: () => _open(context)),
            ),
          ),
        ),
        Positioned(
          right: Space.sm,
          bottom: Space.sm,
          child: DecoratedBox(
            decoration: const BoxDecoration(
              // Preto e branco fixos, e não a família nem o tema: o que está atrás é uma
              // foto de comida, que pode ser clara ou escura em qualquer um dos dois temas.
              color: Color(0x8C000000),
              borderRadius: Radii.smAll,
            ),
            child: const Padding(
              padding: EdgeInsets.all(6),
              child: Icon(Icons.zoom_out_map, size: 16, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }

  void _open(BuildContext context) => Navigator.of(context).push(
    MaterialPageRoute<void>(
      fullscreenDialog: true,
      builder: (_) => _PhotoViewer(
        illustrated: meal.illustratedPhotoUrl,
        original: meal.photoUrl,
      ),
    ),
  );
}

/// A foto em tela cheia, com zoom.
///
/// Fundo preto e barra transparente: numa tela cujo assunto é uma imagem, toda superfície
/// pintada disputa com ela. É a única tela do app em que o preto não é a identidade do produto
/// e sim ausência de cor — o que se olha é a foto.
///
/// **O visor alterna entre a marcada e a original quando as duas existem.** No cartão só a
/// marcada aparece, e as etiquetas cobrem exatamente a comida que se quer conferir; sem o
/// alternador, a foto crua estaria no storage sem caminho nenhum até ela.
class _PhotoViewer extends StatefulWidget {
  const _PhotoViewer({required this.illustrated, required this.original});

  final String? illustrated;
  final String? original;

  @override
  State<_PhotoViewer> createState() => _PhotoViewerState();
}

class _PhotoViewerState extends State<_PhotoViewer> {
  /// Abre na mesma imagem que o cartão mostrava: quem tocou tocou naquela.
  bool _original = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final both = widget.illustrated != null && widget.original != null;
    final url = _original
        ? widget.original
        : widget.illustrated ?? widget.original;

    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.close),
          tooltip: 'Fechar',
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: InteractiveViewer(
                maxScale: 5,
                child: Center(
                  child: url == null
                      ? const SizedBox.shrink()
                      : Image.network(
                          url,
                          fit: BoxFit.contain,
                          loadingBuilder: (_, child, progress) =>
                              progress == null
                              ? child
                              : const CircularProgressIndicator(
                                  color: Colors.white,
                                ),
                          // A URL é assinada e expira. O recado diz o que houve e o que
                          // fazer — "não foi possível" sozinho deixaria a pessoa tocando de
                          // novo na mesma foto.
                          errorBuilder: (_, _, _) => Padding(
                            padding: const EdgeInsets.all(Space.gutter),
                            child: Text(
                              'Não foi possível abrir a foto. O link expira depois de um '
                              'tempo — volte e puxe a lista para atualizar.',
                              textAlign: TextAlign.center,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: Colors.white70,
                              ),
                            ),
                          ),
                        ),
                ),
              ),
            ),
            if (both)
              Padding(
                padding: const EdgeInsets.only(top: Space.sm, bottom: Space.md),
                // "Marcações" e não "ilustrada": é a mesma palavra do interruptor que liga o
                // modo ("Marcar os alimentos na foto"), e dois nomes para a mesma coisa fazem
                // parecer que são duas.
                // Sobre a foto, e não sobre a tela: o que está atrás é imprevisível, e a
                // paleta do tema desapareceria num prato claro sob luz dura.
                child: GlassSegmented<bool>(
                  surface: GlassSegmentedSurface.media,
                  segments: const [
                    GlassSegment(value: false, label: 'Com marcações'),
                    GlassSegment(value: true, label: 'Sem marcações'),
                  ],
                  value: _original,
                  onChanged: (next) => setState(() => _original = next),
                ),
              ),
          ],
        ),
      ),
    );
  }
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
