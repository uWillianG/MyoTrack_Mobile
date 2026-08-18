import 'package:flutter/material.dart';

import '../design/tokens.dart';

/// Selo de supervisão humana: diz se um profissional já revisou o plano gerado por IA.
///
/// Porte de `frontend/src/components/ReviewBadge.tsx`. Não é enfeite — é o que separa
/// "sugestão de um modelo" de "aprovado por alguém habilitado", e por isso o estado padrão
/// afirma explicitamente que a revisão ainda não aconteceu.
class ReviewBadge extends StatelessWidget {
  const ReviewBadge({
    super.key,
    required this.reviewStatus,
    this.reviewNote,
    this.onGlass,
  });

  final String reviewStatus;
  final String? reviewNote;

  /// A cor do texto quando o selo vive **dentro de um bloco de vidro de alguma família**.
  ///
  /// Sem isto o selo aprovado saía esmeralda dentro do herói índigo do treino — uma cor de
  /// outra família no meio do bloco, que é exatamente o que o sistema proíbe. Passando a cor
  /// do bloco, o selo vira um véu translúcido sobre ele e continua sendo a mesma peça.
  final Color? onGlass;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    // Dentro de um bloco de família o selo não muda de matiz por status: quem dá o recado é o
    // ícone e o texto, e três cores de fundo diferentes ali dentro brigariam com o bloco.
    if (onGlass case final onGlass?) {
      return _Pill(
        background: onGlass.withValues(alpha: 0.18),
        foreground: onGlass,
        icon: _iconOf(reviewStatus),
        label: _labelOf(reviewStatus, reviewNote),
        note: reviewNote,
      );
    }

    final ({Color background, Color foreground, IconData icon, String label})
    style = switch (reviewStatus) {
      'Approved' => (
        background: scheme.primaryContainer,
        foreground: scheme.onPrimaryContainer,
        icon: Icons.verified_outlined,
        label: 'Revisado por profissional',
      ),
      'ChangesRequested' => (
        background: scheme.tertiaryContainer,
        foreground: scheme.onTertiaryContainer,
        icon: Icons.warning_amber_outlined,
        label: reviewNote == null || reviewNote!.isEmpty
            ? 'Ajustes sugeridos'
            : 'Ajustes sugeridos: $reviewNote',
      ),
      _ => (
        background: scheme.surfaceContainerHighest,
        foreground: scheme.onSurfaceVariant,
        icon: Icons.smart_toy_outlined,
        label: 'Gerado por IA — aguardando revisão',
      ),
    };

    return _Pill(
      background: style.background,
      foreground: style.foreground,
      icon: style.icon,
      label: style.label,
      note: reviewNote,
    );
  }

  static IconData _iconOf(String status) => switch (status) {
    'Approved' => Icons.verified_outlined,
    'ChangesRequested' => Icons.warning_amber_outlined,
    _ => Icons.smart_toy_outlined,
  };

  static String _labelOf(String status, String? note) => switch (status) {
    'Approved' => 'Revisado por profissional',
    'ChangesRequested' =>
      note == null || note.isEmpty
          ? 'Ajustes sugeridos'
          : 'Ajustes sugeridos: $note',
    _ => 'Gerado por IA — aguardando revisão',
  };
}

class _Pill extends StatelessWidget {
  const _Pill({
    required this.background,
    required this.foreground,
    required this.icon,
    required this.label,
    required this.note,
  });

  final Color background;
  final Color foreground;
  final IconData icon;
  final String label;
  final String? note;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: note ?? '',
      // Sem nota não há o que explicar, e um tooltip vazio só atrapalha o leitor de tela.
      excludeFromSemantics: note == null,
      child: Container(
        padding: const EdgeInsets.fromLTRB(Space.sm, 6, Space.sm + 2, 6),
        decoration: BoxDecoration(color: background, borderRadius: Radii.pill),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: foreground),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                style: Theme.of(
                  context,
                ).textTheme.labelMedium?.copyWith(color: foreground),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
