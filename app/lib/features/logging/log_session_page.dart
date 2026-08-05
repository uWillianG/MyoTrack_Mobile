import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/design/blocks.dart';
import '../../core/design/tokens.dart';
import '../../core/providers.dart';
import '../../core/widgets/blocks.dart';
import '../../core/widgets/empty_state.dart';
import 'data/logging_models.dart';
import 'log_session_controller.dart';

/// Registro manual de treino.
///
/// **Pergunta: o que eu fiz? Ação: salvar as séries.**
///
/// Funciona sem rede: a lista de exercícios vem do cache local e as séries entram na fila de
/// sincronização. É o requisito que define a tela — quase todo treino é registrado na academia,
/// onde o sinal costuma faltar.
///
/// Separada de `/treinar` de propósito, e a diferença é de postura: lá a pessoa está de pé com
/// o cronômetro correndo e lança uma série por vez; aqui ela está sentada lançando o que já fez,
/// e precisa ver a sessão inteira de uma vez para conferir.
class LogSessionPage extends ConsumerWidget {
  const LogSessionPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final form = ref.watch(logSessionProvider);
    final catalog = ref.watch(exerciseCatalogProvider);
    final pending = ref.watch(pendingWritesProvider).valueOrNull ?? 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Registrar treino'),
        bottom: pending == 0
            ? null
            : PreferredSize(
                preferredSize: const Size.fromHeight(28),
                child: _PendingBanner(count: pending),
              ),
      ),
      body: catalog.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => EmptyState(
          icon: Icons.cloud_off_outlined,
          title: 'Não foi possível carregar os exercícios.',
          detail: '$error',
          action: FilledButton.tonal(
            onPressed: () => ref.invalidate(exerciseCatalogProvider),
            child: const Text('Tentar de novo'),
          ),
        ),
        data: (exercises) => exercises.isEmpty
            ? EmptyState(
                icon: Icons.wifi_off_outlined,
                // Sem catálogo em cache não há como registrar offline: é preciso abrir a
                // tela uma vez com rede antes.
                title: 'Catálogo de exercícios indisponível.',
                detail:
                    'Conecte-se à internet uma vez para baixá-lo. Depois disso o '
                    'registro funciona offline.',
                action: FilledButton.tonal(
                  onPressed: () => ref.invalidate(exerciseCatalogProvider),
                  child: const Text('Tentar de novo'),
                ),
              )
            : _Form(form: form, exercises: exercises),
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(Space.gutter, 0, Space.gutter, 12),
        child: FilledButton.icon(
          onPressed: form.canSubmit ? () => _submit(context, ref) : null,
          icon: const Icon(Icons.check),
          label: Text(
            form.canSubmit
                ? 'Salvar ${form.completeSets.length} série(s)'
                : 'Preencha ao menos uma série',
          ),
        ),
      ),
    );
  }

  Future<void> _submit(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    final result = await ref.read(logSessionProvider.notifier).submit();

    final message = switch (result) {
      SubmitSent() => 'Treino registrado.',
      // Dizer que "salvou" sem mais nada faria o usuário estranhar não ver o treino no
      // dashboard; dizer que falhou seria mentira, porque o dado está guardado.
      SubmitQueued() => 'Sem conexão: salvo no aparelho e será enviado depois.',
      SubmitFailed(:final message) => message,
    };

    messenger
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}

class _PendingBanner extends ConsumerWidget {
  const _PendingBanner({required this.count});

  final int count;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;

    return Material(
      color: scheme.tertiaryContainer,
      child: InkWell(
        onTap: () async {
          final messenger = ScaffoldMessenger.of(context);
          final sent = await ref.read(syncQueueProvider).flush();
          messenger.showSnackBar(
            SnackBar(
              content: Text(
                sent == 0
                    ? 'Ainda sem conexão com o servidor.'
                    : '$sent registro(s) enviados.',
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Row(
            children: [
              Icon(
                Icons.cloud_upload_outlined,
                size: 16,
                color: scheme.onTertiaryContainer,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '$count registro(s) aguardando envio · toque para tentar agora',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: scheme.onTertiaryContainer,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Form extends ConsumerWidget {
  const _Form({required this.form, required this.exercises});

  final LogSessionForm form;
  final List<ExerciseOption> exercises;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(logSessionProvider.notifier);

    final theme = Theme.of(context);
    final colors = Blocks.workout(theme.brightness);

    return ListView(
      padding: const EdgeInsets.fromLTRB(Space.gutter, 4, Space.gutter, 32),
      children: [
        HeroBlock(
          colors: colors,
          label: 'Registrar treino',
          icon: Icons.edit_note,
          child: HeroFigure(
            value: '${form.completeSets.length}',
            unit: form.completeSets.length == 1
                ? 'série pronta'
                : 'séries prontas',
            colors: colors,
            // O que falta para poder salvar, em vez de um botão morto sem explicação: uma
            // série só conta quando tem exercício, repetições e carga.
            detail: form.canSubmit
                ? 'De ${form.sets.length} lançadas'
                : 'Uma série conta quando tem exercício, reps e carga',
          ),
        ),
        const SizedBox(height: Space.md),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: form.date,
                    // Registro retroativo é comum (lembrar do treino de ontem); registro
                    // futuro não faz sentido.
                    firstDate: DateTime.now().subtract(
                      const Duration(days: 365),
                    ),
                    lastDate: DateTime.now(),
                  );
                  if (picked != null) {
                    controller.setDate(picked);
                  }
                },
                icon: const Icon(Icons.calendar_today_outlined, size: 18),
                label: Text(_formatDate(form.date)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                initialValue: form.bodyWeightKg,
                onChanged: controller.setBodyWeight,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Peso (kg)',
                  hintText: 'opcional',
                  isDense: true,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        for (var i = 0; i < form.sets.length; i++)
          _SetRow(
            key: ValueKey(i),
            index: i,
            entry: form.sets[i],
            exercises: exercises,
            canRemove: form.sets.length > 1,
          ),
        const SizedBox(height: 4),
        OutlinedButton.icon(
          onPressed: controller.addSet,
          icon: const Icon(Icons.add),
          label: const Text('Adicionar série'),
        ),
        const SizedBox(height: 16),
        TextFormField(
          initialValue: form.notes,
          onChanged: controller.setNotes,
          maxLines: 2,
          decoration: const InputDecoration(
            labelText: 'Observações',
            hintText: 'Como foi o treino?',
          ),
        ),
      ],
    );
  }

  static String _formatDate(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}/'
      '${date.month.toString().padLeft(2, '0')}/${date.year}';
}

class _SetRow extends ConsumerWidget {
  const _SetRow({
    super.key,
    required this.index,
    required this.entry,
    required this.exercises,
    required this.canRemove,
  });

  final int index;
  final SetEntry entry;
  final List<ExerciseOption> exercises;
  final bool canRemove;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(logSessionProvider.notifier);

    final colors = Blocks.workout(Theme.of(context).brightness);

    return Padding(
      padding: const EdgeInsets.only(bottom: Space.sm),
      child: BlockSection(
        colors: colors,
        label: 'Série ${index + 1}',
        icon: Icons.repeat,
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<int>(
                    initialValue: entry.exerciseId,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'Exercício'),
                    items: exercises
                        .map(
                          (e) => DropdownMenuItem(
                            value: e.id,
                            child: Text(
                              e.name,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (id) => controller.updateSet(
                      index,
                      entry.copyWith(exerciseId: id),
                    ),
                  ),
                ),
                IconButton(
                  onPressed: canRemove
                      ? () => controller.removeSet(index)
                      : null,
                  icon: const Icon(Icons.close),
                  tooltip: 'Remover série ${index + 1}',
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _NumberField(
                    label: 'Reps',
                    value: entry.reps,
                    // Repetição é sempre inteira: teclado numérico puro evita o "12."
                    // que o backend recusaria.
                    decimal: false,
                    onChanged: (value) => controller.updateSet(
                      index,
                      entry.copyWith(reps: value),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _NumberField(
                    label: 'Carga (kg)',
                    value: entry.loadKg,
                    decimal: true,
                    onChanged: (value) => controller.updateSet(
                      index,
                      entry.copyWith(loadKg: value),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButtonFormField<int?>(
                    initialValue: entry.rpe,
                    decoration: const InputDecoration(labelText: 'RPE'),
                    items: [
                      const DropdownMenuItem<int?>(
                        value: null,
                        child: Text('—'),
                      ),
                      for (var rpe = 6; rpe <= 10; rpe++)
                        DropdownMenuItem<int?>(value: rpe, child: Text('$rpe')),
                    ],
                    onChanged: (value) => controller.updateSet(
                      index,
                      value == null
                          ? entry.copyWith(clearRpe: true)
                          : entry.copyWith(rpe: value),
                    ),
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

class _NumberField extends StatelessWidget {
  const _NumberField({
    required this.label,
    required this.value,
    required this.decimal,
    required this.onChanged,
  });

  final String label;
  final String value;
  final bool decimal;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      initialValue: value,
      onChanged: onChanged,
      keyboardType: TextInputType.numberWithOptions(decimal: decimal),
      inputFormatters: [
        // Aceita vírgula e ponto: o teclado em pt-BR mostra vírgula, mas o usuário pode
        // ter um teclado físico ou outro layout.
        FilteringTextInputFormatter.allow(
          decimal ? RegExp(r'[0-9.,]') : RegExp(r'[0-9]'),
        ),
      ],
      decoration: InputDecoration(labelText: label),
    );
  }
}
