import 'package:flutter/material.dart';

/// As duas paletas do app, escritas à mão.
///
/// **Por que não `ColorScheme.fromSeed`.** O gerador do Material parte de uma cor e tinge
/// *tudo* com ela, inclusive os neutros. Com um verde de semente, o fundo do app saía num
/// menta pálido, o cartão saía num menta um pouco menos pálido, e os dois ficavam a menos de
/// 2% de luminância um do outro: nada flutuava, e a tela inteira tinha a mesma cor de fundo
/// de um formulário de convênio. É o carimbo de "Material 3 com uma seed" — dá para
/// reconhecer de longe, e é o oposto de parecer um produto.
///
/// Aqui os neutros são neutros (com um traço de verde no preto, o suficiente para o conjunto
/// não parecer montado com duas famílias de cor diferentes) e o esmeralda aparece só onde
/// significa alguma coisa: ação primária, progresso, estado ativo, número que melhorou.
///
/// O esmeralda continua sendo o da marca — `#059669` é a cor dos botões dos e-mails
/// transacionais e do frontend React. No claro ele escurece um degrau (`#047857`) porque
/// sobre branco o original não alcança 4.5:1 com texto branco em corpo de texto; no escuro
/// clareia (`#34D399`), que é o mesmo salto que qualquer sistema faz ao inverter.
abstract final class Palette {
  /// A cor da marca, como ela aparece fora do app.
  static const Color brand = Color(0xFF059669);

  static const ColorScheme light = ColorScheme(
    brightness: Brightness.light,

    primary: Color(0xFF047857),
    onPrimary: Color(0xFFFFFFFF),
    primaryContainer: Color(0xFFD7F2E5),
    onPrimaryContainer: Color(0xFF033D2C),

    // Sálvia dessaturada: é o que carrega chip, aba inativa e cartão de apoio sem competir
    // com o esmeralda. Um segundo verde saturado transformaria toda tela em semáforo.
    secondary: Color(0xFF4B635A),
    onSecondary: Color(0xFFFFFFFF),
    secondaryContainer: Color(0xFFE7EEEA),
    onSecondaryContainer: Color(0xFF334740),

    // Âmbar. A paleta precisa de uma segunda voz para "atenção" e "espera" — sem ela, aviso
    // e sucesso saem da mesma cor e o usuário para de distinguir os dois.
    tertiary: Color(0xFF9A5B0B),
    onTertiary: Color(0xFFFFFFFF),
    tertiaryContainer: Color(0xFFFCEBD2),
    onTertiaryContainer: Color(0xFF5C3403),

    error: Color(0xFFB3261E),
    onError: Color(0xFFFFFFFF),
    errorContainer: Color(0xFFFBE9E7),
    onErrorContainer: Color(0xFF76160F),

    // O fundo é levemente mais escuro que o cartão, e não o contrário: é o que faz o cartão
    // branco parecer apoiado sobre a tela em vez de recortado nela.
    surface: Color(0xFFF7F8F8),
    onSurface: Color(0xFF0F1512),
    surfaceDim: Color(0xFFE4E8E6),
    surfaceBright: Color(0xFFFFFFFF),
    surfaceContainerLowest: Color(0xFFFFFFFF),
    surfaceContainerLow: Color(0xFFFFFFFF),
    surfaceContainer: Color(0xFFFFFFFF),
    surfaceContainerHigh: Color(0xFFF0F2F1),
    surfaceContainerHighest: Color(0xFFE8ECEA),
    onSurfaceVariant: Color(0xFF5B665F),

    outline: Color(0xFF8E9993),
    outlineVariant: Color(0xFFE2E7E4),

    shadow: Color(0xFF000000),
    scrim: Color(0xFF000000),
    inverseSurface: Color(0xFF1C221F),
    onInverseSurface: Color(0xFFF0F3F1),
    inversePrimary: Color(0xFF6EE7B7),
  );

  static const ColorScheme dark = ColorScheme(
    brightness: Brightness.dark,

    primary: Color(0xFF34D399),
    onPrimary: Color(0xFF00281B),
    primaryContainer: Color(0xFF0B4634),
    onPrimaryContainer: Color(0xFFA7F3D0),

    secondary: Color(0xFFA8C4B8),
    onSecondary: Color(0xFF13332A),
    secondaryContainer: Color(0xFF22332C),
    onSecondaryContainer: Color(0xFFC6E3D7),

    tertiary: Color(0xFFF0B357),
    onTertiary: Color(0xFF3B2400),
    tertiaryContainer: Color(0xFF553609),
    onTertiaryContainer: Color(0xFFFFDFB0),

    error: Color(0xFFFFB4AB),
    onError: Color(0xFF690005),
    errorContainer: Color(0xFF8C1D18),
    onErrorContainer: Color(0xFFFFDAD6),

    // **Preto puro.** Era um quase-preto (#0A0D0C), e o argumento contra o #000 continua
    // válido em geral: em OLED, texto claro sobre preto absoluto "vibra" na rolagem, e um
    // cartão escuro sobre um fundo já no fim da escala não tem para onde escurecer.
    //
    // Duas coisas resolvem os dois problemas neste app, e é por isso que a troca cabe aqui:
    //
    // - **O texto não é branco puro.** `onSurface` é #E6EBE8; o halo que faz a letra vibrar
    //   vem do par #FFFFFF sobre #000000, e três degraus abaixo do branco ele some.
    // - **Nada precisa escurecer.** O sistema de blocos empilha para **cima** — ladrilho
    //   lavado e herói em cor cheia, sempre mais claros que o fundo. A escada de containers
    //   abaixo existe para diálogo, folha e campo, e todos eles sobem.
    //
    // O que se ganha: em tela OLED o pixel preto está desligado, então o fundo desaparece de
    // verdade e os blocos coloridos ficam suspensos no escuro. É o que faz o mosaico ler como
    // objeto iluminado em vez de retângulo pintado.
    surface: Color(0xFF000000),
    onSurface: Color(0xFFE6EBE8),
    surfaceDim: Color(0xFF000000),
    surfaceBright: Color(0xFF2A302E),
    surfaceContainerLowest: Color(0xFF000000),
    surfaceContainerLow: Color(0xFF0B0F0D),
    surfaceContainer: Color(0xFF111614),
    surfaceContainerHigh: Color(0xFF1A201D),
    surfaceContainerHighest: Color(0xFF262D2A),
    onSurfaceVariant: Color(0xFF9BA7A1),

    outline: Color(0xFF67726C),
    outlineVariant: Color(0xFF232A27),

    shadow: Color(0xFF000000),
    scrim: Color(0xFF000000),
    inverseSurface: Color(0xFFE6EBE8),
    onInverseSurface: Color(0xFF19201D),
    inversePrimary: Color(0xFF047857),
  );
}
