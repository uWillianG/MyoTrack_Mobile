import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/design/blocks.dart';
import '../../core/design/format.dart';
import '../../core/design/tokens.dart';
import '../../core/design/typography.dart';
import '../../core/jobs/generation_controller.dart';
import '../../core/widgets/blocks.dart';
import '../home/today_controller.dart' show nowProvider;
import 'data/meal_models.dart';
import 'manual_meal_controller.dart';

/// Registrar uma refeição **sem foto**.
///
/// **Rota própria, e não folha modal.** Três coisas decidiram: a estimativa por IA é
/// assíncrona e leva dezenas de segundos — esperar isso numa folha que cobre metade da tela é
/// o mesmo erro que tirou a captura do rodapé da Analisar; a montagem tem teclado aberto quase
/// o tempo todo, e uma folha que sobe com o teclado e desce sem ele briga com o próprio
/// conteúdo; e o rascunho precisa sobreviver ao gesto de voltar do Android, que numa folha é
/// indistinguível de "descartar". Dentro do `ShellRoute` como as outras — o fechamento do dia,
/// que também é tarefa focada, mora lá.
///
/// **Os três caminhos convivem porque desembocam na mesma lista.** Digitar item por item,
/// deixar a IA estimar de uma frase e escolher no catálogo produzem exatamente o mesmo
/// [MealAnalysisItem]; o que a tela mostra é **uma** refeição sendo montada, com três portas
/// para acrescentar itens a ela. Um segmentado com três abas teria feito o contrário — três
/// telas coladas, cada uma com o seu botão de salvar, e a pergunta "então o que acontece com o
/// que eu digitei na outra aba?" sem resposta.
///
/// **O campo de descrever fica aberto no topo**, e não atrás de uma porta, porque é o caminho
/// principal do produto: escondê-lo ao lado dos outros dois o teria demovido a uma opção entre
/// três. Catálogo e digitação entram como dois botões no pé da lista, que é onde "acrescentar
/// mais um item" naturalmente se procura.
class ManualMealPage extends ConsumerStatefulWidget {
  const ManualMealPage({super.key, this.day});

  /// O dia do diário em que a refeição entra. Null = hoje.
  ///
  /// Vem de quem empilhou a rota — o herói do diário sabe qual página do carrossel foi tocada
  /// — em vez de sair do `diaryDateProvider` aqui: no meio do arrasto entre dois dias há duas
  /// páginas vivas, e "o dia aberto" pode já ser o vizinho quando o toque chegar.
  final DateTime? day;

  @override
  ConsumerState<ManualMealPage> createState() => _ManualMealPageState();
}

class _ManualMealPageState extends ConsumerState<ManualMealPage> {
  final TextEditingController _description = TextEditingController();
  bool _saving = false;

  late final DateTime _day = widget.day ?? ref.read(nowProvider)();

  @override
  void dispose() {
    _description.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Blocks.nutrition(Theme.of(context).brightness);
    final items = ref.watch(manualMealDraftProvider);
    final estimate = ref.watch(manualMealEstimateProvider);

    ref.listen(manualMealEstimateProvider, (previous, next) {
      if (next.error != null && next.error != previous?.error) {
        _snack(next.error!);
        ref.read(manualMealEstimateProvider.notifier).dismissError();
      }
    });

    return Scaffold(
      appBar: AppBar(title: Text(_title())),
      body: ListView(
        padding: EdgeInsets.fromLTRB(
          Space.gutter,
          4,
          Space.gutter,
          screenBottomInset(context),
        ),
        children: [
          _DraftHero(
            items: items,
            colors: colors,
            day: _day,
            saving: _saving,
            onSave: _save,
          ),
          const SizedBox(height: Space.sm),
          _DescribeSection(
            colors: colors,
            controller: _description,
            state: estimate,
            full: items.length >= ManualMealDraft.maxItems,
            started: items.isNotEmpty,
            onEstimate: _estimate,
            onCancel: _cancelEstimate,
          ),
          const SizedBox(height: Space.sm),
          _ItemsSection(
            items: items,
            colors: colors,
            onEdit: _editItem,
            onRemove: (index) =>
                ref.read(manualMealDraftProvider.notifier).removeAt(index),
            onAddTyped: _addTyped,
            onAddFromCatalog: _addFromCatalog,
          ),
        ],
      ),
    );
  }

  /// "Refeição de hoje", "Refeição de ontem", ou a data.
  ///
  /// O dia vai no título porque esta tela grava **no dia que o diário estava mostrando**, e não
  /// necessariamente hoje. Sem dizê-lo, quem abriu o diário em ontem e registrou o jantar
  /// procuraria a refeição no dia errado.
  String _title() {
    final now = ref.read(nowProvider)();
    return Fmt.sameDay(_day, now)
        ? 'Refeição de hoje'
        : 'Refeição de ${Fmt.dayLabel(_day, now).toLowerCase()}';
  }

  void _snack(String message) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _estimate() async {
    final text = _description.text.trim();
    if (text.isEmpty) {
      _snack('Descreva o que você comeu.');
      return;
    }

    // O teclado sai de cena: o que vem a seguir é uma espera de dezenas de segundos, e a
    // resposta aparece na lista abaixo — que o teclado estaria cobrindo.
    FocusScope.of(context).unfocus();
    final chegou = await ref
        .read(manualMealEstimateProvider.notifier)
        .estimate(text);

    // O campo esvazia só quando os itens chegaram: em qualquer outro desfecho — erro, prazo
    // estourado, desistência — a frase que a pessoa escreveu é exatamente o que ela precisa
    // para tentar de novo.
    if (chegou && mounted) {
      _description.clear();
    }
  }

  /// Desistir da espera.
  ///
  /// O job continua no servidor; o que acaba é a tela parada. Sem esta saída, uma fila que
  /// não anda prendia a seção inteira — o campo de descrever some enquanto a estimativa
  /// corre, e com ele o único jeito de mexer na frase ou de pedir de novo.
  void _cancelEstimate() =>
      ref.read(manualMealEstimateProvider.notifier).cancel();

  Future<void> _addTyped() async {
    final item = await _showItemSheet();
    if (item != null) {
      ref.read(manualMealDraftProvider.notifier).add(item);
    }
  }

  Future<void> _addFromCatalog() async {
    final food = await showModalBottomSheet<FoodItem>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const _FoodSearchSheet(),
    );
    if (food == null || !mounted) {
      return;
    }

    final item = await _showItemSheet(food: food);
    if (item != null) {
      ref.read(manualMealDraftProvider.notifier).add(item);
    }
  }

  Future<void> _editItem(int index) async {
    final item = await _showItemSheet(
      initial: ref.read(manualMealDraftProvider)[index],
    );
    if (item != null) {
      ref.read(manualMealDraftProvider.notifier).replaceAt(index, item);
    }
  }

  Future<MealAnalysisItem?> _showItemSheet({
    MealAnalysisItem? initial,
    FoodItem? food,
  }) => showModalBottomSheet<MealAnalysisItem>(
    context: context,
    isScrollControlled: true,
    builder: (_) => _ItemSheet(initial: initial, food: food),
  );

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await ref
          .read(manualMealDraftProvider.notifier)
          .save(day: _day, now: ref.read(nowProvider)());

      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (error) {
      if (mounted) {
        setState(() => _saving = false);
        _snack('$error');
      }
    }
  }
}

/// O herói: a refeição que está sendo montada.
///
/// **Muda de assunto conforme o trabalho**, como a Analisar faz entre o convite e o progresso.
/// Vazio, não há número — e nem toda manchete precisa de um: o assunto é o trabalho, e parado
/// o trabalho é um convite. Com itens, o número é a soma do que já entrou, e a ação de salvar
/// aparece com ele.
///
/// **A soma é uma prévia, e o texto não finge o contrário.** Quem soma o que vai para o diário
/// é o servidor: ele reconcilia a caloria com os macros e recalcula do catálogo o item que tem
/// vínculo. Refazer essa aritmética aqui manteria duas versões dela livres para divergir.
class _DraftHero extends StatelessWidget {
  const _DraftHero({
    required this.items,
    required this.colors,
    required this.day,
    required this.saving,
    required this.onSave,
  });

  final List<MealAnalysisItem> items;
  final BlockColors colors;
  final DateTime day;
  final bool saving;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (items.isEmpty) {
      return HeroBlock(
        colors: colors,
        label: 'Nova refeição',
        icon: Icons.edit_note,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Sem foto desta vez.', style: theme.textTheme.titleMedium),
            const SizedBox(height: Space.xxs),
            Text(
              'Descreva o que você comeu e a IA estima as porções — '
              'ou monte item por item, pelo catálogo ou à mão.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colors.onGlass.withValues(alpha: 0.75),
              ),
            ),
          ],
        ),
      );
    }

    final totals = MealDraftTotals.of(items);

    return HeroBlock(
      colors: colors,
      label: 'Nova refeição',
      icon: Icons.edit_note,
      action: HeroAction(
        label: saving ? 'Salvando…' : 'Salvar refeição',
        onPressed: saving ? null : onSave,
      ),
      child: HeroFigure(
        value: Fmt.integer(totals.kcal),
        unit: 'kcal',
        colors: colors,
        detail:
            'P ${Fmt.grams(totals.proteinG)} · '
            'C ${Fmt.grams(totals.carbsG)} · '
            'G ${Fmt.grams(totals.fatG)} · '
            'os totais são conferidos ao salvar',
      ),
    );
  }
}

/// O caminho principal: a frase que vira itens.
///
/// **Fica aberto e no topo.** Guardá-lo atrás de uma porta ao lado das outras duas o teria
/// demovido a uma opção entre três, quando é o caminho que o produto quer que as pessoas usem.
///
/// Enquanto o job corre, o campo e o botão saem e entram os passos escritos — os mesmos da
/// análise por foto, pelo mesmo [JobGenerationController].
///
/// **Com os passos escritos vem a saída.** Esta seção é a única porta para a frase enquanto a
/// estimativa corre: o campo sumiu, e com ele o jeito de corrigir o texto ou de pedir de novo.
/// Sem um "Cancelar" ao lado do rodopio, uma fila que não anda deixava a pessoa olhando —
/// primeiro por dezenas de segundos, que é o normal, depois pelo prazo inteiro do
/// acompanhamento, que não é.
class _DescribeSection extends StatelessWidget {
  const _DescribeSection({
    required this.colors,
    required this.controller,
    required this.state,
    required this.full,
    required this.started,
    required this.onEstimate,
    required this.onCancel,
  });

  final BlockColors colors;
  final TextEditingController controller;
  final GenerationState state;

  /// A lista chegou ao teto: não há para onde a estimativa mandar itens.
  final bool full;

  /// A refeição já tem pelo menos um item — ou seja, o trabalho começou.
  final bool started;

  final VoidCallback onEstimate;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlockSection(
      colors: colors,
      label: 'Descreva a refeição',
      icon: Icons.auto_awesome,
      child: state.running
          ? Row(
              children: [
                SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: colors.ink,
                  ),
                ),
                const SizedBox(width: Space.sm),
                Expanded(
                  child: Text(
                    state.step ?? 'Estimando…',
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
                // Botão de texto, e não cheio: desistir é a saída de emergência, não o que se
                // espera que a pessoa faça enquanto a estimativa está a caminho.
                TextButton(
                  onPressed: onCancel,
                  style: TextButton.styleFrom(foregroundColor: colors.ink),
                  child: const Text('Cancelar'),
                ),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: controller,
                  enabled: !full,
                  minLines: 2,
                  maxLines: 4,
                  maxLength: 500,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    hintText: '2 ovos fritos e um pão francês com manteiga',
                    // O contador só aparece perto do teto: a frase típica tem 40 caracteres,
                    // e "12/500" embaixo dela sugere que se espera um texto longo.
                    counterText: '',
                  ),
                ),
                const SizedBox(height: Space.xs),
                Text(
                  full
                      ? 'A refeição já tem ${ManualMealDraft.maxItems} itens.'
                      : 'Vale medida caseira: "duas colheres de arroz", "meio prato". '
                            'Você confere e corrige antes de salvar.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colors.onGlass.withValues(alpha: 0.75),
                  ),
                ),
                const SizedBox(height: Space.sm),
                // **Cheio enquanto a lista está vazia; lavado depois do primeiro item.**
                // Cor cheia é ação, e só uma por tela pode sê-la: com a refeição já começada,
                // o herói acende "Salvar refeição" logo acima, e dois botões de esmeralda
                // cheia na mesma rolagem deixam de dizer qual é a saída — a regra do sistema é
                // que, se a coisa mais berrante da tela não for o que se quer que a pessoa
                // faça, algo está trocado. Aqui o que se quer muda de um estado para o outro:
                // vazia, a tela existe para estimar; começada, existe para salvar. O botão não
                // sai nem encolhe — acrescentar o quarto item continua sendo o mesmo alvo, no
                // mesmo lugar; ele só devolve a saturação a quem passou a precisar dela.
                FilledButton.icon(
                  onPressed: full ? null : onEstimate,
                  icon: const Icon(Icons.auto_awesome, size: 18),
                  label: const Text('Estimar com IA'),
                  style: FilledButton.styleFrom(
                    backgroundColor: started
                        ? colors.ink.withValues(alpha: 0.14)
                        : colors.ink,
                    foregroundColor: started ? colors.ink : colors.wash,
                    minimumSize: const Size.fromHeight(46),
                  ),
                ),
              ],
            ),
    );
  }
}

/// A lista para onde os três caminhos convergem, e as duas outras portas no pé dela.
///
/// **Uma caixa só, linhas separadas por um fio** — a mesma forma da lista de refeições do
/// diário. Um cartão por item faria uma refeição de quatro itens parecer quatro assuntos.
class _ItemsSection extends StatelessWidget {
  const _ItemsSection({
    required this.items,
    required this.colors,
    required this.onEdit,
    required this.onRemove,
    required this.onAddTyped,
    required this.onAddFromCatalog,
  });

  final List<MealAnalysisItem> items;
  final BlockColors colors;
  final ValueChanged<int> onEdit;
  final ValueChanged<int> onRemove;
  final VoidCallback onAddTyped;
  final VoidCallback onAddFromCatalog;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final full = items.length >= ManualMealDraft.maxItems;

    return BlockSection(
      colors: colors,
      label: 'Itens',
      icon: Icons.restaurant,
      trailing: items.isEmpty
          ? null
          : '${items.length} de ${ManualMealDraft.maxItems}',
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (items.isEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                Space.md,
                0,
                Space.md,
                Space.sm,
              ),
              child: Text(
                'Nenhum item ainda.',
                style: theme.textTheme.bodySmall,
              ),
            )
          else
            for (var i = 0; i < items.length; i++) ...[
              if (i > 0)
                Divider(
                  height: 1,
                  indent: Space.md,
                  endIndent: Space.md,
                  color: colors.ink.withValues(alpha: 0.14),
                ),
              _DraftItemRow(
                item: items[i],
                colors: colors,
                onEdit: () => onEdit(i),
                onRemove: () => onRemove(i),
              ),
            ],

          const Divider(height: 1),
          // As duas portas secundárias. **Botões escritos e não ícones**, ao contrário da
          // fileira do herói do diário: lá as três levam ao mesmo trabalho e a diferença entre
          // elas cabe num ícone conhecido (câmera, galeria); aqui "buscar no catálogo" e
          // "digitar item" são trabalhos diferentes e nenhum tem ícone que dispense o nome.
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: Space.xs,
              vertical: Space.xxs,
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextButton.icon(
                    onPressed: full ? null : onAddFromCatalog,
                    icon: const Icon(Icons.search, size: 18),
                    label: const Text('Catálogo'),
                    style: TextButton.styleFrom(foregroundColor: colors.ink),
                  ),
                ),
                Expanded(
                  child: TextButton.icon(
                    onPressed: full ? null : onAddTyped,
                    icon: const Icon(Icons.keyboard, size: 18),
                    label: const Text('Digitar'),
                    style: TextButton.styleFrom(foregroundColor: colors.ink),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Uma linha do rascunho: o que é, quanto pesa, quanto tem — e como sair dela.
class _DraftItemRow extends StatelessWidget {
  const _DraftItemRow({
    required this.item,
    required this.colors,
    required this.onEdit,
    required this.onRemove,
  });

  final MealAnalysisItem item;
  final BlockColors colors;
  final VoidCallback onEdit;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Semantics(
      button: true,
      label:
          '${item.description}, ${Fmt.grams(item.quantityG)}, '
          '${Fmt.kcal(item.kcal)}',
      excludeSemantics: true,
      child: InkWell(
        onTap: onEdit,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            Space.md,
            Space.xs,
            Space.xxs,
            Space.xs,
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            item.description,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodyMedium,
                          ),
                        ),
                        // O vínculo com o catálogo é visível porque muda o que acontece ao
                        // salvar: nesses itens os macros são recalculados pelo servidor a
                        // partir da tabela, e não é o número da tela que vale.
                        if (item.foodItemId != null) ...[
                          const SizedBox(width: Space.xxs),
                          Icon(
                            Icons.verified_outlined,
                            size: 14,
                            color: colors.ink,
                          ),
                        ],
                      ],
                    ),
                    Text(
                      '${Fmt.grams(item.quantityG)} · ${Fmt.kcal(item.kcal)} · '
                      'P ${Fmt.grams(item.proteinG)} · '
                      'C ${Fmt.grams(item.carbsG)} · '
                      'G ${Fmt.grams(item.fatG)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: onRemove,
                icon: const Icon(Icons.close, size: 18),
                tooltip: 'Remover ${item.description}',
                visualDensity: VisualDensity.compact,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Busca no catálogo nutricional.
///
/// **Abre com a lista já cheia.** O `q` em branco devolve o começo do catálogo justamente para
/// isto: uma folha que abre vazia esperando a primeira tecla parece um catálogo vazio, e o
/// caminho morre antes de alguém digitar. Com a lista à vista, ela também ensina o que existe
/// lá dentro — "Pão francês", "Feijão carioca cozido" — e o formato dos nomes.
class _FoodSearchSheet extends ConsumerStatefulWidget {
  const _FoodSearchSheet();

  @override
  ConsumerState<_FoodSearchSheet> createState() => _FoodSearchSheetState();
}

class _FoodSearchSheetState extends ConsumerState<_FoodSearchSheet> {
  /// Espera entre a última tecla e a requisição.
  ///
  /// 300 ms é o intervalo que separa "ainda digitando" de "parou para ver": abaixo disso uma
  /// palavra de seis letras vira seis requisições, e acima a lista parece travada. A busca é
  /// no servidor porque o catálogo tem duas centenas de itens e ele já sabe casar "pao" com
  /// "Pão" — o que o aparelho não sabe fazer sem baixar o catálogo inteiro.
  static const Duration _debounce = Duration(milliseconds: 300);

  final TextEditingController _query = TextEditingController();
  Timer? _timer;

  /// O que está de fato sendo buscado — atrasado em relação ao que está digitado.
  String _searching = '';

  @override
  void dispose() {
    _timer?.cancel();
    _query.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    _timer?.cancel();
    _timer = Timer(_debounce, () {
      if (mounted) {
        setState(() => _searching = value.trim());
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final results = ref.watch(foodSearchProvider(_searching));

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SizedBox(
        // Altura fixa e generosa: uma folha que cresce e encolhe conforme o número de
        // resultados salta na tela a cada tecla digitada.
        height: MediaQuery.of(context).size.height * 0.72,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                Space.gutter,
                Space.gutter,
                Space.gutter,
                Space.sm,
              ),
              child: TextField(
                controller: _query,
                onChanged: _onChanged,
                autofocus: true,
                textInputAction: TextInputAction.search,
                decoration: const InputDecoration(
                  hintText: 'Buscar alimento',
                  prefixIcon: Icon(Icons.search),
                ),
              ),
            ),
            Expanded(
              child: results.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(Space.gutter),
                    child: Text(
                      'Não foi possível buscar no catálogo.\n$error',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
                ),
                data: (foods) => foods.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(Space.gutter),
                          child: Text(
                            'Nenhum alimento com esse nome.\n'
                            'Você ainda pode digitar o item à mão.',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodySmall,
                          ),
                        ),
                      )
                    : ListView.builder(
                        itemCount: foods.length,
                        itemBuilder: (context, index) {
                          final food = foods[index];
                          return ListTile(
                            title: Text(food.name),
                            // Por 100 g, que é como o catálogo guarda. A porção vem no passo
                            // seguinte, e é ela que multiplica isto.
                            subtitle: Text(
                              '${Fmt.kcal(food.kcalPer100g)} · '
                              'P ${Fmt.grams(food.proteinPer100g)} · '
                              'C ${Fmt.grams(food.carbsPer100g)} · '
                              'G ${Fmt.grams(food.fatPer100g)} '
                              '(por 100 g)',
                            ),
                            onTap: () => Navigator.of(context).pop(food),
                          );
                        },
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Digitar ou corrigir um item.
///
/// **Serve aos dois caminhos que não são a IA**, e a diferença entre eles é uma só: com um
/// alimento do catálogo, os macros deixam de ser digitáveis e passam a ser calculados da
/// tabela conforme a porção muda. Campos editáveis que o servidor vai sobrescrever seriam uma
/// mentira de interface — ele **recalcula** o item com vínculo, e o que fosse digitado ali
/// seria descartado sem aviso.
///
/// **Sem caloria obrigatória.** Deixada em branco, o servidor a deriva dos macros pelos fatores
/// de Atwater — a mesma conta que ele faz de qualquer jeito quando o número informado não bate
/// com eles. Repetir essa fórmula aqui criaria duas versões dela livres para divergir; o que a
/// tela faz é dizer que dá para deixar em branco.
class _ItemSheet extends StatefulWidget {
  const _ItemSheet({this.initial, this.food});

  /// O item sendo corrigido, quando é uma edição.
  final MealAnalysisItem? initial;

  /// O alimento escolhido no catálogo, quando veio de lá.
  final FoodItem? food;

  @override
  State<_ItemSheet> createState() => _ItemSheetState();
}

class _ItemSheetState extends State<_ItemSheet> {
  /// Os mesmos limites do servidor. São **faixas**, não fórmulas: o servidor prende a porção
  /// entre 1 g e 2 kg e corta a descrição em 120 caracteres, e faz isso em silêncio. Recusar
  /// antes é o que evita a pessoa digitar 3000 g e receber 2000 de volta sem entender por quê.
  static const num _minQuantity = 1;
  static const num _maxQuantity = 2000;
  static const int _maxDescription = 120;

  final _form = GlobalKey<FormState>();

  late final TextEditingController _description = TextEditingController(
    text: widget.initial?.description ?? widget.food?.name ?? '',
  );
  late final TextEditingController _quantity = TextEditingController(
    text: _initialNumber(widget.initial?.quantityG),
  );
  late final TextEditingController _kcal = TextEditingController(
    text: _initialNumber(widget.initial?.kcal),
  );
  late final TextEditingController _protein = TextEditingController(
    text: _initialNumber(widget.initial?.proteinG),
  );
  late final TextEditingController _carbs = TextEditingController(
    text: _initialNumber(widget.initial?.carbsG),
  );
  late final TextEditingController _fat = TextEditingController(
    text: _initialNumber(widget.initial?.fatG),
  );

  FoodItem? get _food => widget.food;

  bool get _fromCatalog => _food != null;

  static String _initialNumber(num? value) =>
      value == null || value == 0 ? '' : Fmt.integer(value).replaceAll('.', '');

  @override
  void dispose() {
    for (final controller in [
      _description,
      _quantity,
      _kcal,
      _protein,
      _carbs,
      _fat,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  static num? _parse(String raw) =>
      num.tryParse(raw.trim().replaceAll(',', '.'));

  num get _grams => _parse(_quantity.text) ?? 0;

  /// Os macros da porção escolhida, saídos do catálogo.
  MealDraftTotals get _fromTable {
    final food = _food!;
    final factor = _grams / 100;
    return MealDraftTotals(
      kcal: food.kcalPer100g * factor,
      proteinG: food.proteinPer100g * factor,
      carbsG: food.carbsPer100g * factor,
      fatG: food.fatPer100g * factor,
    );
  }

  void _submit() {
    if (!_form.currentState!.validate()) {
      return;
    }

    final grams = _grams;
    final macros = _fromCatalog
        ? _fromTable
        : MealDraftTotals(
            kcal: _parse(_kcal.text) ?? 0,
            proteinG: _parse(_protein.text) ?? 0,
            carbsG: _parse(_carbs.text) ?? 0,
            fatG: _parse(_fat.text) ?? 0,
          );

    Navigator.of(context).pop(
      MealAnalysisItem(
        description: _description.text.trim(),
        // O vínculo sobrevive à edição de um item que já o tinha: perdê-lo faria o servidor
        // parar de recalcular do catálogo e passar a acreditar nos números da tela.
        foodItemId: _food?.id ?? widget.initial?.foodItemId,
        quantityG: grams,
        kcal: macros.kcal,
        proteinG: macros.proteinG,
        carbsG: macros.carbsG,
        fatG: macros.fatG,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.fromLTRB(
        Space.gutter,
        Space.gutter,
        Space.gutter,
        MediaQuery.of(context).viewInsets.bottom + Space.gutter,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _form,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                widget.initial == null ? 'Novo item' : 'Corrigir item',
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: Space.md),

              TextFormField(
                controller: _description,
                maxLength: _maxDescription,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'O que é',
                  counterText: '',
                ),
                validator: (value) => (value ?? '').trim().isEmpty
                    // Sem descrição o servidor descarta o item — em silêncio, porque um item
                    // sem nome é um número que ninguém consegue conferir na tela.
                    ? 'Diga o que é este item.'
                    : null,
              ),
              const SizedBox(height: Space.sm),

              TextFormField(
                controller: _quantity,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                ],
                decoration: const InputDecoration(
                  labelText: 'Quantidade',
                  suffixText: 'g',
                ),
                onChanged: (_) {
                  // Só o item do catálogo redesenha a cada tecla: é ele que mostra os macros
                  // calculados, e eles mudam com a porção.
                  if (_fromCatalog) {
                    setState(() {});
                  }
                },
                validator: (value) {
                  final grams = _parse(value ?? '');
                  if (grams == null || grams < _minQuantity) {
                    return 'Informe a quantidade em gramas.';
                  }
                  if (grams > _maxQuantity) {
                    return 'No máximo ${Fmt.grams(_maxQuantity)} por item.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: Space.md),

              if (_fromCatalog) _tableMacros(theme) else ..._typedMacros(),

              const SizedBox(height: Space.lg),
              FilledButton(
                onPressed: _submit,
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(46),
                ),
                child: const Text('Adicionar à refeição'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// O que o catálogo diz que esta porção tem — texto, e não campo.
  Widget _tableMacros(ThemeData theme) {
    final macros = _fromTable;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          Fmt.kcal(macros.kcal),
          style: AppTypography.numeric(
            size: 28,
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: Space.xxs),
        Text(
          'P ${Fmt.grams(macros.proteinG)} · '
          'C ${Fmt.grams(macros.carbsG)} · '
          'G ${Fmt.grams(macros.fatG)}',
          style: theme.textTheme.bodyMedium,
        ),
        const SizedBox(height: Space.xxs),
        Text(
          'Calculado pela tabela do catálogo (${_food!.source ?? 'TACO'}).',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  List<Widget> _typedMacros() => [
    Row(
      children: [
        Expanded(child: _macroField(_protein, 'Proteína')),
        const SizedBox(width: Space.sm),
        Expanded(child: _macroField(_carbs, 'Carboidrato')),
        const SizedBox(width: Space.sm),
        Expanded(child: _macroField(_fat, 'Gordura')),
      ],
    ),
    const SizedBox(height: Space.sm),
    _macroField(_kcal, 'Calorias', suffix: 'kcal'),
    const SizedBox(height: Space.xxs),
    Builder(
      builder: (context) => Text(
        'Deixe as calorias em branco para o servidor calculá-las pelos macros.',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    ),
  ];

  Widget _macroField(
    TextEditingController controller,
    String label, {
    String suffix = 'g',
  }) => TextFormField(
    controller: controller,
    keyboardType: const TextInputType.numberWithOptions(decimal: true),
    inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
    decoration: InputDecoration(labelText: label, suffixText: suffix),
    validator: (value) {
      final raw = (value ?? '').trim();
      if (raw.isEmpty) {
        // Em branco é zero, e zero é uma resposta legítima: café preto não tem gordura.
        return null;
      }
      return _parse(raw) == null ? 'Número inválido.' : null;
    },
  );
}
