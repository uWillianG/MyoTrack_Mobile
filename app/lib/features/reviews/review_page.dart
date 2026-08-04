import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/design/tokens.dart';
import '../../core/widgets/empty_state.dart';
import 'review_controller.dart';

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

    return Column(
      children: [
        // Um único tipo revisável não precisa de seletor: a aba sozinha só ocuparia espaço.
        if (available.length > 1)
          Padding(
            padding: const EdgeInsets.fromLTRB(
              Space.gutter,
              8,
              Space.gutter,
              0,
            ),
            child: SegmentedButton<ReviewKind>(
              segments: [
                for (final k in available)
                  ButtonSegment(value: k, label: Text(k.label)),
              ],
              selected: {selected},
              onSelectionChanged: (s) =>
                  ref.read(reviewKindProvider.notifier).state = s.first,
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
              data: (items) => items.isEmpty
                  ? const EmptyState(
                      icon: Icons.check_circle_outline,
                      title: 'Nada pendente por aqui.',
                      detail: 'Todos os planos ativos já foram revisados.',
                    )
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(
                        Space.gutter,
                        8,
                        Space.gutter,
                        16,
                      ),
                      children: [
                        for (final item in items)
                          _QueueTile(item: item, kind: selected),
                      ],
                    ),
            ),
          ),
        ),
      ],
    );
  }
}

class _QueueTile extends ConsumerWidget {
  const _QueueTile({required this.item, required this.kind});

  final ReviewQueueItem item;
  final ReviewKind kind;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    final subtitle = kind == ReviewKind.workout
        ? [item.split, item.goal].whereType<String>().join('  ·  ')
        : [
            if (item.targetKcal != null) '${item.targetKcal!.round()} kcal',
            if (item.calorieGoal != null) item.calorieGoal!,
          ].join('  ·  ');

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        title: Text('${item.name}  ·  v${item.version}'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (subtitle.isNotEmpty)
              Text(subtitle, style: theme.textTheme.bodySmall),
            // O e-mail é o que identifica de quem é o plano — sem ele a fila seria uma
            // lista de planos anônimos.
            if (item.student != null)
              Text(
                item.student!,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
          ],
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => _open(context, ref),
      ),
    );
  }

  Future<void> _open(BuildContext context, WidgetRef ref) async {
    final decision = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _DecisionSheet(item: item, kind: kind),
    );

    if (decision == true) {
      ref.invalidate(reviewQueueProvider);
    }
  }
}

/// Detalhe do plano e a decisão.
class _DecisionSheet extends ConsumerStatefulWidget {
  const _DecisionSheet({required this.item, required this.kind});

  final ReviewQueueItem item;
  final ReviewKind kind;

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

    return Padding(
      padding: EdgeInsets.fromLTRB(
        16,
        16,
        16,
        MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.8,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(widget.item.name, style: theme.textTheme.titleMedium),
            if (widget.item.student != null)
              Text(
                widget.item.student!,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            const SizedBox(height: 12),

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
                  );
                },
              ),
            ),

            const SizedBox(height: 12),
            TextField(
              controller: _note,
              enabled: !_saving,
              maxLines: 3,
              minLines: 1,
              decoration: const InputDecoration(
                labelText: 'Observação',
                hintText: 'Obrigatória ao pedir mudanças',
                isDense: true,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _saving
                        ? null
                        : () => _decide('ChangesRequested'),
                    child: const Text('Pedir mudanças'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton(
                    onPressed: _saving ? null : () => _decide('Approved'),
                    child: _saving
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
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
class _PlanBody extends StatelessWidget {
  const _PlanBody({required this.detail, required this.kind});

  final Map<String, dynamic> detail;
  final ReviewKind kind;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final groups =
        (detail[kind == ReviewKind.workout ? 'days' : 'meals'] as List?)
            ?.cast<Map<String, dynamic>>() ??
        const [];

    return ListView(
      children: [
        if (kind == ReviewKind.diet) ...[
          Text(
            'Metas: ${_round(detail['targetKcal'])} kcal  ·  '
            'P ${_round(detail['targetProteinG'])} g  ·  '
            'C ${_round(detail['targetCarbsG'])} g  ·  '
            'G ${_round(detail['targetFatG'])} g',
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 12),
        ],
        for (final group in groups) ...[
          Text(
            '${group['label'] ?? group['name'] ?? ''}',
            style: theme.textTheme.titleSmall,
          ),
          const SizedBox(height: 4),
          for (final line in _linesOf(group))
            Padding(
              padding: const EdgeInsets.only(left: 8, bottom: 2),
              child: Text('• $line', style: theme.textTheme.bodySmall),
            ),
          const SizedBox(height: 12),
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
