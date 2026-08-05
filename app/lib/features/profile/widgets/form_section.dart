import 'package:flutter/material.dart';

import '../data/profile_models.dart';

/// Os dois controles de escolha do perfil.
///
/// Chips e não menu suspenso: as opções são poucas e curtas, e um menu esconderia atrás de um
/// toque justamente a informação que a pessoa precisa comparar para escolher.

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
