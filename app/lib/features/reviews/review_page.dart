import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/design/blocks.dart';
import '../../core/design/format.dart';
import '../../core/design/tokens.dart';
import '../../core/widgets/blocks.dart';
import '../../core/widgets/glass_segmented.dart';
import '../../core/widgets/empty_state.dart';
// O relógio do app, injetável: a idade de cada plano na fila é o número que mais muda de
// significado com o tempo, e é justamente o que a galeria e os testes precisam fixar.
import '../home/today_controller.dart' show nowProvider;
import 'review_controller.dart';

/// O plano que está esperando há mais tempo, ou null se a fila está vazia.
///
/// **É o que a manchete promove.** Uma fila não se revisa por gosto — se revisa pela ponta, e a
/// ponta é a que está esperando há mais tempo. Sem isto o revisor abre o primeiro da lista, que
/// é o mesmo que a ordem do servidor lhe entregou, e o plano esquecido continua esquecido.
///
/// Item sem `createdAt` fica de fora da comparação em vez de contar como antiquíssimo: data
/// ausente é falta de informação, não urgência.
ReviewQueueItem? oldestPending(List<ReviewQueueItem> items) {
  ReviewQueueItem? oldest;
  DateTime? oldestAt;

  for (final item in items) {
    final at = _at(item);
    if (at == null) {
      continue;
    }
    if (oldestAt == null || at.isBefore(oldestAt)) {
      oldest = item;
      oldestAt = at;
    }
  }
  // Fila inteira sem data: a ponta passa a ser simplesmente o primeiro.
  return oldest ?? (items.isEmpty ? null : items.first);
}

DateTime? _at(ReviewQueueItem item) => item.createdAt == null
    ? null
    : DateTime.tryParse(item.createdAt!)?.toLocal();

/// A cor da fila é a do assunto que ela alimenta.
///
/// Treino revisado vira plano de treino (índigo); dieta revisada vira plano alimentar
/// (esmeralda). O segmentado troca de assunto, não de estado — é o mesmo caso da aba Analisar,
/// e não o do diário e do plano, que são as duas metades de **um** assunto.
BlockColors _colorsOf(ReviewKind kind, Brightness brightness) =>
    kind == ReviewKind.workout
    ? Blocks.workout(brightness)
    : Blocks.nutrition(brightness);

/// Fila de revisão. Só para treinador, nutricionista e admin.
class ReviewPage extends ConsumerWidget {
  const ReviewPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final kinds = ref.watch(reviewableKindsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Revisão')),
      body: kinds.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => EmptyState(
          icon: Icons.cloud_off_outlined,
          title: 'Não foi possível verificar suas permissões.',
          detail: '$error',
        ),
        // Sem papel de revisor não há fila. A tela diz isso em vez de mostrar uma lista
        // vazia, que pareceria "nada pendente" quando na verdade é "não é para você".
        data: (available) => available.isEmpty
            ? const EmptyState(
                icon: Icons.lock_outline,
                title: 'Esta área é para revisores.',
                detail:
                    'Treinadores revisam treinos e nutricionistas revisam dietas. '
                    'Fale com o suporte se você deveria ter acesso.',
              )
            : _Queue(available: available),
      ),
    );
  }
}

class _Queue extends ConsumerWidget {
  const _Queue({required this.available});

  final List<ReviewKind> available;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final kind = ref.watch(reviewKindProvider);
    final queue = ref.watch(reviewQueueProvider);

    // Quem só revisa dieta não deve cair na fila de treino, que é o padrão do provider.
    final selected = available.contains(kind) ? kind : available.first;
    if (selected != kind) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(reviewKindProvider.notifier).state = selected;
      });
    }

    final colors = _colorsOf(selected, Theme.of(context).brightness);

    return Column(
      children: [
        // Um único tipo revisável não precisa de seletor: a aba sozinha só ocuparia espaço.
        if (available.length > 1)
          Padding(
            padding: const EdgeInsets.fromLTRB(
              Space.gutter,
              Space.xs,
              Space.gutter,
              0,
            ),
            child: GlassSegmented<ReviewKind>(
              segments: [
                for (final k in available)
                  GlassSegment(value: k, label: k.label),
              ],
              value: selected,
              onChanged: (next) =>
                  ref.read(reviewKindProvider.notifier).state = next,
            ),
          ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(reviewQueueProvider);
              await ref.read(reviewQueueProvider.future);
            },
            child: queue.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => EmptyState(
                icon: Icons.cloud_off_outlined,
                title: 'Não foi possível carregar a fila.',
                detail: '$error',
                action: FilledButton.tonal(
                  onPressed: () => ref.invalidate(reviewQueueProvider),
                  child: const Text('Tentar de novo'),
                ),
              ),
              data: (items) => _QueueBody(
                items: items,
                kind: selected,
                colors: colors,
                now: ref.read(nowProvider)(),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _QueueBody extends ConsumerWidget {
  const _QueueBody({
    required this.items,
    required this.kind,
    required this.colors,
    required this.now,
  });

  final List<ReviewQueueItem> items;
  final ReviewKind kind;
  final BlockColors colors;
  final DateTime now;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final oldest = oldestPending(items);

    return ListView(
      padding: const EdgeInsets.fromLTRB(Space.gutter, 4, Space.gutter, 32),
      children: [
        HeroBlock(
          colors: colors,
          label: kind == ReviewKind.workout ? 'Treinos' : 'Dietas',
          icon: Icons.fact_check_outlined,
          action: oldest == null
              ? null
              : HeroAction(
                  label: 'Revisar o mais antigo',
                  onPressed: () => _open(context, ref, oldest),
                ),
          child: items.isEmpty
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Nada pendente.',
                      style: theme.textTheme.displaySmall?.copyWith(
                        color: colors.onGlass,
                      ),
                    ),
                    const SizedBox(height: Space.sm),
                    Text(
                      'Todos os planos ativos já foram revisados.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colors.onGlass.withValues(alpha: 0.85),
                      ),
                    ),
                  ],
                )
              // A idade da ponta, e não o total do dia: numa fila o que cobra não é o
              // tamanho, é o tempo que o primeiro está esperando.
              : HeroFigure(
                  value: '${items.length}',
                  unit: items.length == 1 ? 'plano' : 'planos',
                  colors: colors,
                  detail: _oldestDetail(oldest),
                ),
        ),
        for (final item in items) ...[
          const SizedBox(height: Space.sm),
          _QueueSection(
            item: item,
            kind: kind,
            colors: colors,
            now: now,
            onOpen: () => _open(context, ref, item),
          ),
        ],
      ],
    );
  }

  String _oldestDetail(ReviewQueueItem? oldest) {
    final at = oldest == null ? null : _at(oldest);
    return at == null
        ? 'esperando revisão'
        : 'esperando — o mais antigo, ${Fmt.ago(at, now)}';
  }

  Future<void> _open(
    BuildContext context,
    WidgetRef ref,
    ReviewQueueItem item,
  ) async {
    final decision = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _DecisionSheet(item: item, kind: kind, colors: colors),
    );

    if (decision == true) {
      ref.invalidate(reviewQueueProvider);
    }
  }
}

/// Um plano na fila.
///
/// **O rótulo colorido é a idade**, e não o aluno. Numa fila, a espera é a dimensão pela qual
/// se decide o que abrir primeiro — é o que o rótulo do bloco existe para carregar. O e-mail
/// desce para o corpo e ganha a largura toda: em `marina.alves@exemplo.com`, disputar espaço
/// com um `trailing` cortava justamente o domínio.
///
/// **O nome do plano não entra.** O servidor gera "Gerado em 2 de agosto · versão 2", que é a
/// data e a versão escritas por extenso — os dois campos que a linha já mostra. Repeti-lo era
/// a mesma informação três vezes na mesma seção.
class _QueueSection extends StatelessWidget {
  const _QueueSection({
    required this.item,
    required this.kind,
    required this.colors,
    required this.now,
    required this.onOpen,
  });

  final ReviewQueueItem item;
  final ReviewKind kind;
  final BlockColors colors;
  final DateTime now;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final at = _at(item);

    final facts = kind == ReviewKind.workout
        ? [item.split, item.goal].whereType<String>().toList()
        : [
            if (item.targetKcal != null) Fmt.kcal(item.targetKcal!),
            if (item.calorieGoal != null) item.calorieGoal!,
          ];

    return BlockSection(
      colors: colors,
      label: at == null ? 'Na fila' : 'Esperando ${Fmt.ago(at, now)}',
      icon: Icons.schedule,
      trailing: 'versão ${item.version}',
      onEdit: onOpen,
      // Nem todo toque é edição: aqui a seção **abre** o plano para uma decisão, e um lápis
      // prometeria que o revisor pode reescrever a dieta de outra pessoa.
      actionIcon: Icons.chevron_right,
      actionVerb: 'Revisar',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            item.student ?? 'Aluno sem e-mail',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleSmall,
          ),
          const SizedBox(height: 2),
          Text(
            [
              ...facts,
              if (at != null) 'gerado em ${Fmt.dayMonth(at)}',
            ].join('  ·  '),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

/// Detalhe do plano e a decisão.
class _DecisionSheet extends ConsumerStatefulWidget {
  const _DecisionSheet({
    required this.item,
    required this.kind,
    required this.colors,
  });

  final ReviewQueueItem item;
  final ReviewKind kind;
  final BlockColors colors;

  @override
  ConsumerState<_DecisionSheet> createState() => _DecisionSheetState();
}

class _DecisionSheetState extends ConsumerState<_DecisionSheet> {
  final _note = TextEditingController();
  late Future<Map<String, dynamic>> _detail;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _detail = ref
        .read(reviewRepositoryProvider)
        .detail(widget.kind, widget.item.id);
  }

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> _decide(String status) async {
    // Pedir mudanças sem dizer o quê deixa o aluno sem ação possível — e o plano volta
    // igual na próxima geração.
    if (status == 'ChangesRequested' && _note.text.trim().isEmpty) {
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(
          const SnackBar(
            content: Text('Diga o que precisa mudar antes de recusar.'),
          ),
        );
      return;
    }

    setState(() => _saving = true);
    try {
      await ref
          .read(reviewRepositoryProvider)
          .decide(
            widget.kind,
            widget.item.id,
            status: status,
            note: _note.text.trim().isEmpty ? null : _note.text.trim(),
          );
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (error) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context)
          ..clearSnackBars()
          ..showSnackBar(SnackBar(content: Text('$error')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = widget.colors;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        Space.gutter,
        0,
        Space.gutter,
        MediaQuery.of(context).viewInsets.bottom + Space.md,
      ),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.8,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.item.student ?? 'Aluno sem e-mail',
              style: theme.textTheme.titleMedium,
            ),
            Text(
              '${widget.item.name.isEmpty ? 'Plano sem nome' : widget.item.name}'
              '  ·  versão ${widget.item.version}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: Space.sm),

            Expanded(
              child: FutureBuilder<Map<String, dynamic>>(
                future: _detail,
                builder: (context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return EmptyState(
                      icon: Icons.cloud_off_outlined,
                      title: 'Não foi possível abrir o plano.',
                      detail: '${snapshot.error}',
                    );
                  }
                  return _PlanBody(
                    detail: snapshot.data ?? const {},
                    kind: widget.kind,
                    colors: colors,
                  );
                },
              ),
            ),

            const SizedBox(height: Space.sm),
            TextField(
              controller: _note,
              enabled: !_saving,
              maxLines: 3,
              minLines: 1,
              decoration: const InputDecoration(
                labelText: 'Observação',
                // `helperText` e não `hintText`: a dica some no primeiro caractere digitado, e
                // esta condição precisa continuar visível justamente enquanto se escreve.
                helperText: 'Obrigatória para pedir mudanças',
                isDense: true,
              ),
            ),
            const SizedBox(height: Space.sm),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _saving
                        ? null
                        : () => _decide('ChangesRequested'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: theme.colorScheme.onSurface,
                      minimumSize: const Size.fromHeight(46),
                    ),
                    child: const Text('Pedir mudanças'),
                  ),
                ),
                const SizedBox(width: Space.xs),
                Expanded(
                  child: FilledButton(
                    onPressed: _saving ? null : () => _decide('Approved'),
                    style: FilledButton.styleFrom(
                      backgroundColor: colors.ink,
                      foregroundColor: colors.wash,
                      minimumSize: const Size.fromHeight(46),
                    ),
                    child: _saving
                        ? SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: colors.wash,
                            ),
                          )
                        : const Text('Aprovar'),
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

/// Conteúdo do plano, lido da árvore que o servidor devolveu.
///
/// **O revisor vê o plano como o aluno vê**: os mesmos blocos por dia ou por refeição, e não uma
/// lista de marcadores. Aprovar algo que se lê de outro jeito é aprovar outra coisa.
class _PlanBody extends StatelessWidget {
  const _PlanBody({
    required this.detail,
    required this.kind,
    required this.colors,
  });

  final Map<String, dynamic> detail;
  final ReviewKind kind;
  final BlockColors colors;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final groups =
        (detail[kind == ReviewKind.workout ? 'days' : 'meals'] as List?)
            ?.cast<Map<String, dynamic>>() ??
        const [];

    return ListView(
      children: [
        if (kind == ReviewKind.diet)
          BlockSection(
            colors: colors,
            label: 'Metas do plano',
            icon: Icons.pie_chart_outline,
            trailing: '${_round(detail['targetKcal'])} kcal',
            child: Text(
              'P ${_round(detail['targetProteinG'])} g  ·  '
              'C ${_round(detail['targetCarbsG'])} g  ·  '
              'G ${_round(detail['targetFatG'])} g',
              style: theme.textTheme.bodyMedium,
            ),
          ),
        for (final group in groups) ...[
          const SizedBox(height: Space.sm),
          BlockSection(
            colors: colors,
            label: '${group['label'] ?? group['name'] ?? ''}',
            icon: kind == ReviewKind.workout
                ? Icons.fitness_center
                : Icons.lunch_dining,
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                for (final line in _linesOf(group))
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      Space.md,
                      0,
                      Space.md,
                      6,
                    ),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(line, style: theme.textTheme.bodySmall),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  List<String> _linesOf(Map<String, dynamic> group) {
    if (kind == ReviewKind.workout) {
      final exercises =
          (group['exercises'] as List?)?.cast<Map<String, dynamic>>() ??
          const [];
      return exercises
          .map(
            (e) =>
                '${e['exerciseName']} — ${e['sets']} × ${e['repsMin']}–${e['repsMax']}'
                '  ·  ${e['restSeconds']}s',
          )
          .toList();
    }

    final items =
        (group['items'] as List?)?.cast<Map<String, dynamic>>() ?? const [];
    return items
        .map((i) => '${i['foodName']} — ${_round(i['quantityG'])} g')
        .toList();
  }

  static String _round(Object? value) =>
      value is num ? value.round().toString() : '—';
}
