import 'package:flutter/material.dart';

/// Os valores que se repetem no app inteiro: espaço, raio, sombra e tempo.
///
/// Existem como constantes nomeadas, e não soltos em cada tela, porque a diferença entre um
/// app que parece caro e um que parece montado às pressas quase nunca está numa tela — está
/// em dezesseis telas usarem 14, 16 e 18 dp de respiro para a mesma coisa. Um número que só
/// aparece uma vez pode ser literal; um que aparece três, mora aqui.

/// Escala de espaçamento, em passos de 4 dp.
///
/// Quatro é o menor passo que o olho ainda distingue em tela de celular, e a escala para de
/// dobrar depois de 24 porque acima disso a diferença é de composição, não de ritmo.
abstract final class Space {
  static const double xxs = 4;
  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 20;
  static const double xl = 24;
  static const double xxl = 32;
  static const double huge = 48;

  /// Respiro no fim de uma lista que corre por baixo de um botão flutuante: 40 dp de botão
  /// pequeno mais a margem que o `Scaffold` já reserva. Sem ele o último cartão da tela para
  /// debaixo do botão e a rolagem acaba antes de tirá-lo de lá.
  static const double fabClearance = 56;

  /// Margem lateral das telas. Vale para todo conteúdo de leitura: o alinhamento entre um
  /// título de seção e a borda do cartão abaixo dele é o que dá a sensação de grade.
  static const double gutter = 20;
}

/// Quanto uma lista precisa reservar no fim para não terminar debaixo da moldura.
///
/// **Existe porque a barra de abas virou vidro.** Ela deixou de ocupar espaço no layout e
/// passou a flutuar por cima do conteúdo — que é o ponto: o que se vê borrado através dela é a
/// própria lista continuando. O preço é que a lista não termina mais onde a tela termina, e
/// sem este respiro o último cartão fica ilegível atrás do material.
///
/// O `Scaffold` com `extendBody` informa a altura da barra no `padding` do `MediaQuery`, então
/// esta conta serve igual nas abas e nas telas com rota própria — nestas o número é só o
/// recorte do sistema, que é o que elas precisam de qualquer jeito.
double listBottomInset(BuildContext context) =>
    Space.fabClearance + MediaQuery.paddingOf(context).bottom;

/// Raios de canto.
///
/// Três degraus e um pílula. O erro comum é usar o mesmo raio no cartão e no botão dentro
/// dele — o botão precisa ser mais fechado, senão os dois arcos brigam e o conjunto parece
/// borrado.
abstract final class Radii {
  static const double xs = 10;
  static const double sm = 14;
  static const double md = 18;
  static const double lg = 24;
  static const double xl = 28;

  static const BorderRadius smAll = BorderRadius.all(Radius.circular(sm));
  static const BorderRadius mdAll = BorderRadius.all(Radius.circular(md));
  static const BorderRadius lgAll = BorderRadius.all(Radius.circular(lg));
  static const BorderRadius xlAll = BorderRadius.all(Radius.circular(xl));

  /// Para chips, selos e o que for claramente um "comprimido".
  static const BorderRadius pill = BorderRadius.all(Radius.circular(999));
}

/// Durações de animação.
///
/// Curtas. O padrão do Material (300 ms) foi desenhado para telas grandes; num celular na
/// mão a mesma curva parece que o app está pensando.
abstract final class Motion {
  static const Duration fast = Duration(milliseconds: 140);
  static const Duration base = Duration(milliseconds: 220);
  static const Duration slow = Duration(milliseconds: 380);

  /// Desacelera até parar sem quicar. `easeOutCubic` em vez de `easeInOut` porque o começo
  /// de uma transição disparada por toque já aconteceu na cabeça do usuário — o que importa
  /// é como ela termina.
  static const Curve enter = Curves.easeOutCubic;
  static const Curve exit = Curves.easeInCubic;
}

/// Sombras.
///
/// Duas camadas em vez de uma: uma sombra curta e quase opaca que cola o objeto na
/// superfície, e uma longa e diluída que dá a altura. Uma camada só sempre parece adesivo.
/// No escuro elas somem — sombra preta sobre fundo preto não é elevação, é sujeira; lá a
/// altura vem da superfície mais clara.
abstract final class Shadows {
  static List<BoxShadow> resting(Brightness brightness) =>
      brightness == Brightness.dark
      ? const []
      : const [
          BoxShadow(
            color: Color(0x0A101B14),
            blurRadius: 2,
            offset: Offset(0, 1),
          ),
          BoxShadow(
            color: Color(0x0F101B14),
            blurRadius: 14,
            offset: Offset(0, 6),
          ),
        ];

  /// Para o que flutua de verdade: folhas, o botão de registrar, diálogos.
  static List<BoxShadow> lifted(Brightness brightness) =>
      brightness == Brightness.dark
      ? const [
          BoxShadow(
            color: Color(0x66000000),
            blurRadius: 24,
            offset: Offset(0, 10),
          ),
        ]
      : const [
          BoxShadow(
            color: Color(0x14101B14),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
          BoxShadow(
            color: Color(0x1F101B14),
            blurRadius: 28,
            offset: Offset(0, 12),
          ),
        ];
}
