import 'package:flutter/material.dart';

import '../data/profile_models.dart';

/// Bloco do formulário com título e, quando útil, uma explicação de por que se pergunta.
class FormSection extends StatelessWidget {
  const FormSection({
    required this.title,
    required this.children,
    this.description,
    super.key,
  });

  final String title;
  final String? description;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            if (description != null) ...[
              const SizedBox(height: 4),
              Text(
                description!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }
}

/// Múltipla escolha em forma de chips — cabe muito mais opção na tela que uma lista.
class OptionChips extends StatelessWidget {
  const OptionChips({
    required this.options,
    required this.selected,
    required this.onToggle,
    super.key,
  });

  final List<Option> options;
  final List<String> selected;
  final ValueChanged<String> onToggle;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final option in options)
          FilterChip(
            label: Text(option.label),
            selected: selected.contains(option.value),
            onSelected: (_) => onToggle(option.value),
          ),
      ],
    );
  }
}

/// Escolha única em chips. Usado onde um dropdown esconderia as opções sem necessidade.
class SingleChoiceChips extends StatelessWidget {
  const SingleChoiceChips({
    required this.options,
    required this.value,
    required this.onSelected,
    super.key,
  });

  final List<Option> options;
  final String? value;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final option in options)
          ChoiceChip(
            label: Text(option.label),
            selected: value == option.value,
            onSelected: (_) => onSelected(option.value),
          ),
      ],
    );
  }
}
