import 'package:flutter/material.dart';

/// Tema do app, alinhado ao visual da SPA: verde esmeralda sobre fundo claro
/// (`#059669` é a cor dos botões nos e-mails transacionais e no frontend React).
class AppTheme {
  const AppTheme._();

  static const Color seed = Color(0xFF059669);

  static ThemeData light() => _base(Brightness.light);
  static ThemeData dark() => _base(Brightness.dark);

  static ThemeData _base(Brightness brightness) {
    final scheme = ColorScheme.fromSeed(
      seedColor: seed,
      brightness: brightness,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      // Campos com borda visível: boa parte do app é formulário (onboarding,
      // registro de série, medidas) e borda fraca prejudica em tela pequena.
      inputDecorationTheme: const InputDecorationTheme(
        border: OutlineInputBorder(),
        filled: true,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          // 48 dp é o alvo mínimo de toque recomendado nas duas plataformas —
          // e este app é usado com a mão suada, no meio do treino.
          minimumSize: const Size.fromHeight(48),
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: scheme.outlineVariant),
        ),
      ),
    );
  }
}
