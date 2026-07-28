import 'package:flutter/material.dart';

/// Selo de supervisão humana: diz se um profissional já revisou o plano gerado por IA.
///
/// Porte de `frontend/src/components/ReviewBadge.tsx`. Não é enfeite — é o que separa
/// "sugestão de um modelo" de "aprovado por alguém habilitado", e por isso o estado padrão
/// afirma explicitamente que a revisão ainda não aconteceu.
class ReviewBadge extends StatelessWidget {
  const ReviewBadge({super.key, required this.reviewStatus, this.reviewNote});

  final String reviewStatus;
  final String? reviewNote;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

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

    return Tooltip(
      message: reviewNote ?? '',
      // Sem nota não há o que explicar, e um tooltip vazio só atrapalha o leitor de tela.
      excludeFromSemantics: reviewNote == null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: style.background,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(style.icon, size: 15, color: style.foreground),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                style.label,
                style: Theme.of(
                  context,
                ).textTheme.labelMedium?.copyWith(color: style.foreground),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
