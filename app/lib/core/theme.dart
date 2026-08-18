// `CupertinoPageTransitionsBuilder` mora no pacote cupertino, e não no material.
import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;
import 'package:flutter/material.dart';

import 'design/palette.dart';
import 'design/tokens.dart';
import 'design/typography.dart';

/// O tema do app.
///
/// A cor vem de [Palette], a tipografia de [AppTypography] e as medidas de `tokens.dart`.
/// O que mora aqui é a ligação entre eles e o ajuste de cada componente do Material — que é
/// onde o padrão do framework mais entrega a idade dele: botão de 40 dp com entreletra de
/// 2014, campo com borda dupla, barra inferior de 80 dp com rótulo minúsculo.
class AppTheme {
  const AppTheme._();

  /// A cor da marca, exposta aqui porque o resto do app já a importava deste arquivo.
  static const Color seed = Palette.brand;

  /// [fontFamily] fica nulo no app — cada plataforma usa a fonte dela. Quem preenche é a
  /// galeria visual de `test/design`, para que a captura não mude de máquina para máquina.
  static ThemeData light({String? fontFamily}) =>
      _base(Palette.light, fontFamily);
  static ThemeData dark({String? fontFamily}) =>
      _base(Palette.dark, fontFamily);

  static ThemeData _base(ColorScheme scheme, [String? fontFamily]) {
    final text = AppTypography.scale(scheme, family: fontFamily);
    final brightness = scheme.brightness;
    final isDark = brightness == Brightness.dark;

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      textTheme: text,
      fontFamily: fontFamily,
      scaffoldBackgroundColor: scheme.surface,
      // A sombra de tudo que o Material eleva por conta própria — botão flutuante, folha,
      // menu. Preto puro (o padrão) sai como um contorno duro em volta do objeto; um preto
      // esverdeado a 10% cai junto com a paleta e some nas bordas, que é como sombra se
      // comporta.
      shadowColor: const Color(0x1A0F1512),
      // O tingimento por elevação do Material 3 pinta cada superfície levantada com um véu
      // da cor primária. Com uma paleta autoral isso só suja os neutros: a hierarquia aqui
      // vem da própria cor da superfície e da sombra, que é o que o olho já sabe ler.
      splashFactory: InkSparkle.splashFactory,
      visualDensity: VisualDensity.standard,

      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleSpacing: Space.gutter,
        titleTextStyle: text.titleLarge,
        iconTheme: IconThemeData(color: scheme.onSurface, size: 24),
        actionsIconTheme: IconThemeData(color: scheme.onSurface, size: 24),
      ),

      // O cartão levanta de dois jeitos diferentes, porque as duas físicas são diferentes:
      // no claro, uma sombra curta e muito diluída (a luz vem de cima e o objeto está a
      // poucos milímetros da folha); no escuro, sombra nenhuma — preto sobre preto não é
      // profundidade, é sujeira — e quem separa é a superfície mais clara com uma borda de
      // um pixel. `surfaceTintColor` transparente nos dois: o véu de cor primária que o
      // Material 3 pinta sobre o que está elevado é exatamente o que dá o aspecto de tema
      // gerado por semente.
      cardTheme: CardThemeData(
        color: scheme.surfaceContainer,
        elevation: isDark ? 0 : 2,
        surfaceTintColor: Colors.transparent,
        shadowColor: isDark ? Colors.transparent : const Color(0x1A0F1512),
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: Radii.mdAll,
          side: isDark
              ? BorderSide(color: scheme.outlineVariant)
              : BorderSide.none,
        ),
      ),

      // 52 dp de altura e raio fechado. O alvo mínimo de toque é 48, mas este app é usado
      // com a mão suada no meio do treino, e o botão principal de uma tela não deveria ser
      // do tamanho mínimo aceitável.
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          padding: const EdgeInsets.symmetric(horizontal: Space.xl),
          shape: const RoundedRectangleBorder(borderRadius: Radii.smAll),
          textStyle: text.labelLarge,
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          padding: const EdgeInsets.symmetric(horizontal: Space.xl),
          shape: const RoundedRectangleBorder(borderRadius: Radii.smAll),
          textStyle: text.labelLarge,
          side: BorderSide(color: scheme.outlineVariant),
          foregroundColor: scheme.onSurface,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(0, 44),
          padding: const EdgeInsets.symmetric(horizontal: Space.md),
          shape: const RoundedRectangleBorder(borderRadius: Radii.smAll),
          textStyle: text.labelLarge,
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          minimumSize: const Size.square(44),
          foregroundColor: scheme.onSurfaceVariant,
        ),
      ),

      // Sem borda e preenchido: a borda dupla (contorno + fundo) do padrão do Material rouba
      // 2 dp de cada lado e faz o formulário parecer uma planilha. O foco aparece por um anel
      // da cor primária, que é o único estado que precisa gritar.
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark
            ? scheme.surfaceContainerHigh
            : scheme.surfaceContainerHigh,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: Space.md,
          vertical: Space.md,
        ),
        border: const OutlineInputBorder(
          borderRadius: Radii.smAll,
          borderSide: BorderSide.none,
        ),
        enabledBorder: const OutlineInputBorder(
          borderRadius: Radii.smAll,
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: Radii.smAll,
          borderSide: BorderSide(color: scheme.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: Radii.smAll,
          borderSide: BorderSide(color: scheme.error, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: Radii.smAll,
          borderSide: BorderSide(color: scheme.error, width: 2),
        ),
        labelStyle: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
        floatingLabelStyle: text.labelMedium?.copyWith(color: scheme.primary),
        hintStyle: text.bodyMedium?.copyWith(color: scheme.outline),
        helperStyle: text.bodySmall,
        errorStyle: text.bodySmall?.copyWith(color: scheme.error),
      ),

      // **Transparente, e sem a pastilha.** A barra inteira virou vidro — quem pinta o fundo
      // dela é o `GlassChrome` do shell, e o conteúdo do app passa rolando por baixo. Uma cor
      // de fundo aqui taparia o borrão e devolveria a tampa opaca.
      //
      // A pastilha do indicador saiu junto: ela existe para marcar o item corrente numa barra
      // opaca, onde só a cor do ícone não bastaria. Sobre vidro ela vira um retângulo claro
      // flutuando dentro de outro, e o que marca o item passa a ser o que já marcava melhor —
      // o ícone preenchido, na cor da marca, com o rótulo no mesmo tom.
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        elevation: 0,
        height: 60,
        indicatorColor: Colors.transparent,
        indicatorShape: const RoundedRectangleBorder(borderRadius: Radii.pill),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return text.labelSmall?.copyWith(
            fontSize: 11.5,
            letterSpacing: 0.2,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: selected ? scheme.primary : scheme.onSurfaceVariant,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            size: 24,
            color: selected ? scheme.primary : scheme.onSurfaceVariant,
          );
        }),
      ),

      // 54 dp de altura nos dois flutuantes da tira de baixo. O `extended` do Material nasce
      // com 48 e o `small` com 40, e os dois lado a lado — que é como a Hoje os usa — leem
      // como um botão e o irmão menor dele em vez de um par. Sombra longa mesmo no escuro:
      // eles são a única coisa do app que flutua *sobre* o conteúdo rolando, e sem ela o
      // `Registrar` esmeralda encosta no cartão que passa por trás.
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        elevation: isDark ? 6 : 3,
        focusElevation: isDark ? 6 : 3,
        hoverElevation: isDark ? 8 : 4,
        highlightElevation: isDark ? 10 : 6,
        extendedTextStyle: text.labelLarge?.copyWith(color: scheme.onPrimary),
        extendedSizeConstraints: const BoxConstraints.tightFor(height: 54),
        shape: const RoundedRectangleBorder(borderRadius: Radii.mdAll),
      ),

      // Flutuante e com margem: encostada na base, a barra de aviso cobre a navegação e
      // some junto com ela na troca de tela.
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: scheme.inverseSurface,
        contentTextStyle: text.bodyMedium?.copyWith(
          color: scheme.onInverseSurface,
        ),
        actionTextColor: scheme.inversePrimary,
        elevation: 6,
        insetPadding: const EdgeInsets.all(Space.md),
        shape: const RoundedRectangleBorder(borderRadius: Radii.smAll),
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: scheme.surfaceContainer,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: const RoundedRectangleBorder(borderRadius: Radii.lgAll),
        titleTextStyle: text.titleLarge,
        contentTextStyle: text.bodyMedium,
        insetPadding: const EdgeInsets.symmetric(
          horizontal: Space.xl,
          vertical: Space.xl,
        ),
      ),

      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: scheme.surfaceContainer,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        showDragHandle: true,
        dragHandleColor: scheme.outlineVariant,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(Radii.xl)),
        ),
      ),

      chipTheme: ChipThemeData(
        backgroundColor: scheme.surfaceContainerHigh,
        selectedColor: scheme.primaryContainer,
        side: BorderSide.none,
        labelStyle: text.labelMedium,
        secondaryLabelStyle: text.labelMedium,
        padding: const EdgeInsets.symmetric(
          horizontal: Space.sm,
          vertical: Space.xs,
        ),
        shape: const RoundedRectangleBorder(borderRadius: Radii.pill),
        showCheckmark: false,
      ),

      // Trilho e cursor, e não dois botões colados.
      //
      // O `SegmentedButton` do Material pinta o segmento escolhido com a cor primária e
      // deixa o outro cinza: o resultado são duas metades de cores diferentes com uma emenda
      // reta no meio, que lê como dois componentes e não como um. Invertendo — os segmentos
      // não escolhidos formam o trilho cinza, e o escolhido é uma pastilha clara por cima —
      // sai o controle que todo mundo já sabe operar, e a cor da marca fica livre para
      // significar ação em vez de "aba corrente".
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: SegmentedButton.styleFrom(
          backgroundColor: scheme.surfaceContainerHigh,
          selectedBackgroundColor: isDark
              ? scheme.surfaceContainerHighest
              : scheme.surfaceContainerLowest,
          selectedForegroundColor: scheme.onSurface,
          foregroundColor: scheme.onSurfaceVariant,
          side: BorderSide.none,
          textStyle: text.labelMedium,
          padding: const EdgeInsets.symmetric(vertical: Space.sm),
          shape: const RoundedRectangleBorder(borderRadius: Radii.pill),
        ),
      ),

      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? scheme.onPrimary
              : scheme.outline,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? scheme.primary
              : scheme.surfaceContainerHighest,
        ),
        trackOutlineColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? Colors.transparent
              : scheme.outlineVariant,
        ),
        thumbIcon: const WidgetStatePropertyAll(Icon(null)),
      ),

      checkboxTheme: CheckboxThemeData(
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(6)),
        ),
        side: BorderSide(color: scheme.outline, width: 1.5),
        fillColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? scheme.primary
              : Colors.transparent,
        ),
      ),

      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? scheme.primary
              : scheme.outline,
        ),
      ),

      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: Space.lg,
          vertical: Space.xxs,
        ),
        titleTextStyle: text.titleSmall,
        subtitleTextStyle: text.bodySmall,
        iconColor: scheme.onSurfaceVariant,
        minVerticalPadding: Space.sm,
        shape: const RoundedRectangleBorder(borderRadius: Radii.smAll),
      ),

      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant,
        thickness: 1,
        space: Space.xl,
      ),

      // Arredondado e com trilha visível: a barra reta de canto vivo do padrão é a peça mais
      // datada do Material, e aparece em quatro telas deste app.
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: scheme.primary,
        linearTrackColor: isDark
            ? scheme.surfaceContainerHighest
            : scheme.surfaceContainerHighest,
        linearMinHeight: 8,
        borderRadius: Radii.pill,
        circularTrackColor: Colors.transparent,
        strokeCap: StrokeCap.round,
      ),

      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: scheme.inverseSurface,
          borderRadius: Radii.smAll,
        ),
        textStyle: text.bodySmall?.copyWith(color: scheme.onInverseSurface),
      ),

      // Volta pelo gesto no Android desenha a tela saindo enquanto o dedo arrasta; no iOS, a
      // transição lateral que o sistema usa. As duas são o que o usuário já espera da
      // plataforma — e nada denuncia mais um app multiplataforma do que a transição errada.
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: PredictiveBackPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.windows: FadeForwardsPageTransitionsBuilder(),
        },
      ),
    );
  }
}
