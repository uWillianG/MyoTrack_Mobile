import 'package:flutter/material.dart';

/// A escala tipográfica do app.
///
/// **A fonte é a Manrope, empacotada no APK** (ver `pubspec.yaml`). O projeto usou a fonte de
/// cada plataforma por muito tempo, com o argumento de que fonte que chega pela rede às vezes
/// não chega. O argumento continua verdadeiro e não se aplica a uma fonte que viaja dentro do
/// binário: 165 KB, disponível no primeiro frame, offline.
///
/// A troca é a peça isolada que mais muda a cara do app. A fonte do sistema é o carimbo mais
/// visível de "aplicativo Flutter recém-criado", e nenhum arranjo de layout o remove — foi a
/// lição de duas rodadas de redesenho que mexeram só em espaço e cor.
///
/// **Por que a Manrope.** Grotesca geométrica de altura-x muito alta, que é o que mantém 12 px
/// legível numa tela suada; bojo de lado reto, que dá à palavra um contorno que a Roboto não
/// tem; e algarismos largos e confiantes, que é o que este app mais desenha grande. Não é
/// Inter, Poppins nem Montserrat — as três que aparecem em qualquer template.
///
/// O ajuste fino em cima dela é o que separa "texto" de "tipografia":
///
/// - **Entreletra negativa nos tamanhos grandes.** O espaçamento pensado para 14 px vira
///   frouxidão a 28 ou 32. Quanto maior o tamanho, mais fecha — a mesma lógica de tamanho
///   óptico das fontes com eixo variável.
/// - **Corpo em 15, não 14.** O `bodyMedium` do Material nasceu em 14 px, medida de tela de
///   desktop de 2014. Em celular, 15/22 é o que se lê sem aproximar o aparelho.
/// - **Peso 600 nos títulos.** O 500 do padrão desaparece contra um número grande ao lado.
///
/// [numeric] é o desvio deliberado: os números deste app são o produto (calorias restantes,
/// carga, peso), e merecem um estilo próprio em vez de herdar o do título.
abstract final class AppTypography {
  /// A família de todo o app.
  ///
  /// O arquivo é variável e cobre 200–800 num binário só; o Flutter interpola o eixo `wght` a
  /// partir do `fontWeight` do `TextStyle`. Quem confere se isso está funcionando é a galeria
  /// visual — um peso que não pega sai como texto todo do mesmo tom, e é invisível no código.
  static const String family = 'Manrope';

  /// [family] é sobrescrevível só para permitir uma comparação lado a lado na galeria. No
  /// app ele é sempre a Manrope: uma tela com outra fonte é uma tela de outro produto.
  static TextTheme scale(ColorScheme scheme, {String? family}) {
    final ink = scheme.onSurface;
    final muted = scheme.onSurfaceVariant;

    return _withFamily(family ?? AppTypography.family, _build(ink, muted));
  }

  static TextTheme _withFamily(String? family, TextTheme scale) =>
      family == null ? scale : scale.apply(fontFamily: family);

  static TextTheme _build(Color ink, Color muted) {
    return TextTheme(
      displayLarge: TextStyle(
        fontSize: 52,
        height: 1.08,
        fontWeight: FontWeight.w700,
        letterSpacing: -1.6,
        color: ink,
      ),
      displayMedium: TextStyle(
        fontSize: 42,
        height: 1.10,
        fontWeight: FontWeight.w700,
        letterSpacing: -1.2,
        color: ink,
      ),
      displaySmall: TextStyle(
        fontSize: 34,
        height: 1.14,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.8,
        color: ink,
      ),

      headlineLarge: TextStyle(
        fontSize: 30,
        height: 1.18,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.7,
        color: ink,
      ),
      headlineMedium: TextStyle(
        fontSize: 26,
        height: 1.20,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
        color: ink,
      ),
      // O tamanho dos enunciados das perguntas e dos títulos de tela.
      headlineSmall: TextStyle(
        fontSize: 22,
        height: 1.25,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.35,
        color: ink,
      ),

      titleLarge: TextStyle(
        fontSize: 20,
        height: 1.28,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.3,
        color: ink,
      ),
      titleMedium: TextStyle(
        fontSize: 17,
        height: 1.35,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.15,
        color: ink,
      ),
      titleSmall: TextStyle(
        fontSize: 15,
        height: 1.40,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.05,
        color: ink,
      ),

      bodyLarge: TextStyle(
        fontSize: 16,
        height: 1.50,
        fontWeight: FontWeight.w400,
        letterSpacing: 0,
        color: ink,
      ),
      bodyMedium: TextStyle(
        fontSize: 15,
        height: 1.47,
        fontWeight: FontWeight.w400,
        letterSpacing: 0,
        color: ink,
      ),
      bodySmall: TextStyle(
        fontSize: 13.5,
        height: 1.42,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.05,
        color: muted,
      ),

      labelLarge: TextStyle(
        fontSize: 15,
        height: 1.20,
        fontWeight: FontWeight.w600,
        letterSpacing: 0,
        color: ink,
      ),
      labelMedium: TextStyle(
        fontSize: 13,
        height: 1.25,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.1,
        color: ink,
      ),
      // Rótulo de eixo, legenda de gráfico, texto sob o ícone da barra. A entreletra positiva
      // é o que mantém a legibilidade quando o tamanho cai abaixo de 12.
      labelSmall: TextStyle(
        fontSize: 11.5,
        height: 1.25,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.35,
        color: muted,
      ),
    );
  }

  /// O estilo do número que é o assunto da tela.
  ///
  /// `FontFeature.tabularFigures` para que 1.476 e 624 ocupem a mesma largura por dígito: sem
  /// isso o número dança horizontalmente a cada atualização, e num anel de calorias que muda
  /// a cada refeição isso é visível. A entreletra fecha mais que a do texto porque dígito não
  /// tem ascendente nem descendente — o mesmo espaçamento parece maior entre números.
  static TextStyle numeric({
    required double size,
    required Color color,
    FontWeight weight = FontWeight.w800,
    String? family,
  }) => TextStyle(
    fontFamily: family ?? AppTypography.family,
    fontSize: size,
    height: 1.05,
    fontWeight: weight,
    letterSpacing: size >= 32 ? -1.4 : -0.6,
    color: color,
    fontFeatures: const [FontFeature.tabularFigures()],
  );
}
