import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'tokens.dart';

/// O vidro: a superfície que substituiu o retângulo pintado.
///
/// **O que mudou e por quê.** Até aqui cada bloco tinha um fundo próprio na cor do assunto —
/// um lavado esmeralda para nutrição, um índigo para treino — e a tela era um mosaico de
/// retângulos coloridos. Funcionava para separar assunto, e era exatamente o que fazia o app
/// parecer um painel de instrumentos: sete cores de fundo competindo, nenhuma superfície.
///
/// A troca é de portador, não de paleta. **A cromia por assunto continua** — esmeralda para
/// nutrição, índigo para treino, âmbar para progresso, magenta para conquista —, só que agora
/// ela vive na *tinta* (o número, o ícone, o traço do anel, o botão de ação) e o fundo é
/// sempre o mesmo material translúcido. O olho passa a ler a tela por profundidade e escala em
/// vez de por área de cor, que é o que separa "superfície" de "painel".
///
/// **O material tem três camadas, e as três importam:**
///
/// 1. **O véu** — branco a 5,5% no escuro. Sobre o preto absoluto do fundo ele vira um cinza
///    de mais ou menos #0E0E0E: presente o bastante para o cartão existir, longe o bastante do
///    fundo para nada precisar de borda.
/// 2. **A aresta especular** — uma linha de 1 px que começa clara no topo e some na base, como
///    a luz bate na quina de uma placa de vidro. É a peça barata que mais faz o cartão parecer
///    um objeto em vez de uma área preenchida; sem ela o véu sozinho lê como retângulo cinza.
/// 3. **O borrão** — e este é opcional de propósito. `BackdropFilter` custa uma passada de
///    composição inteira, e borrar o que está atrás de um cartão que tem *fundo liso* atrás
///    dele é gastar essa passada para não mudar um pixel. Só a moldura do app pede borrão de
///    verdade — a barra de cima e a de baixo, por onde o conteúdo passa rolando.
///
/// **No claro é o mesmo material com a luz invertida.** O véu vira branco a 78% sobre a página
/// cinza-claro, a aresta continua branca (a luz vem de cima nos dois temas) e entra uma
/// hairline escura por fora, porque branco sobre quase-branco precisa de um limite escrito.
@immutable
class GlassSpec {
  const GlassSpec({
    required this.fill,
    required this.edge,
    required this.stroke,
    required this.blurSigma,
  });

  /// O véu translúcido do cartão.
  final Color fill;

  /// O topo da aresta especular. Ela desce em gradiente até sumir.
  final Color edge;

  /// Contorno externo. Transparente no escuro — lá o próprio véu já se afirma contra o preto,
  /// e uma borda por cima dele só endureceria a peça.
  final Color stroke;

  /// Desvio-padrão do borrão da moldura, em pixels lógicos.
  final double blurSigma;
}

/// As duas receitas do material, e os atalhos que o resto do app usa.
abstract final class Glass {
  static const GlassSpec _dark = GlassSpec(
    // 5,5% de branco. É o valor do desenho, e ele não é arbitrário: abaixo de 5% o cartão
    // some no preto de uma tela OLED com brilho baixo; acima de 7% ele começa a parecer um
    // retângulo cinza pintado, que é justamente o que saímos de fazer.
    fill: Color(0x0EFFFFFF),
    edge: Color(0x1CFFFFFF),
    stroke: Color(0x00000000),
    blurSigma: 24,
  );

  static const GlassSpec _light = GlassSpec(
    fill: Color(0xC7FFFFFF),
    edge: Color(0xFFFFFFFF),
    // Preto esverdeado a 8%: a mesma família da sombra do tema claro. Um cinza neutro aqui
    // apareceria azulado ao lado dela.
    stroke: Color(0x14101B12),
    blurSigma: 20,
  );

  static GlassSpec of(Brightness brightness) =>
      brightness == Brightness.dark ? _dark : _light;

  /// A moldura do app — a barra de cima quando o conteúdo passa por baixo, e a de baixo.
  ///
  /// Mais opaca que o cartão porque a função dela é outra: o cartão quer deixar o fundo
  /// aparecer, a moldura quer que o texto por cima dela continue legível com *qualquer* coisa
  /// passando atrás. 62% de um quase-preto é o ponto em que o conteúdo ainda se adivinha
  /// através dela e nada em cima dela perde contraste.
  static Color chrome(Brightness brightness) => brightness == Brightness.dark
      ? const Color(0x9E0C0E0D)
      : const Color(0xD6F7F8F8);
}

/// Um cartão de vidro.
///
/// Substitui o `Material` de fundo chapado que os blocos usavam. O contorno arredondado, o
/// véu, a aresta e o recorte vêm juntos porque errar um deles isolado é o que faz duas peças
/// do mesmo sistema parecerem de sistemas diferentes.
class GlassPanel extends StatelessWidget {
  const GlassPanel({
    super.key,
    required this.child,
    this.radius = Radii.xlAll,
    this.tint,
    this.blur = false,
    this.padding,
    this.onTap,
  });

  final Widget child;
  final BorderRadius radius;

  /// Um véu de cor por cima do véu branco, para o cartão que fala de um assunto só — a faixa
  /// de conquista, magenta a 10%. **Sempre fraco**: passando de uns 12% ele volta a ser um
  /// retângulo pintado, e o sistema inteiro perde o sentido.
  final Color? tint;

  /// Borra o que está atrás. Só vale a pena onde há conteúdo atrás de verdade: a moldura, e um
  /// cartão que se sobrepõe a outro. Num cartão com o fundo liso atrás é custo sem efeito.
  final bool blur;

  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final spec = Glass.of(theme.brightness);

    Widget content = padding == null
        ? child
        : Padding(padding: padding!, child: child);

    // `Material` por dentro e não por fora: o respingo do toque precisa acontecer *sobre* o
    // véu, senão ele pinta por baixo do vidro e sai apagado.
    content = Material(
      type: MaterialType.transparency,
      child: onTap == null ? content : InkWell(onTap: onTap, child: content),
    );

    Widget panel = DecoratedBox(
      decoration: BoxDecoration(
        color: spec.fill,
        borderRadius: radius,
        border: spec.stroke.a == 0
            ? null
            : Border.all(color: spec.stroke, width: 1),
      ),
      child: CustomPaint(
        painter: _GlassEdge(radius: radius, color: spec.edge),
        child: tint == null
            ? content
            : DecoratedBox(
                decoration: BoxDecoration(color: tint, borderRadius: radius),
                child: content,
              ),
      ),
    );

    panel = ClipRRect(borderRadius: radius, child: panel);

    if (blur) {
      panel = ClipRRect(
        borderRadius: radius,
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(
            sigmaX: spec.blurSigma,
            sigmaY: spec.blurSigma,
          ),
          child: panel,
        ),
      );
    }

    if (theme.brightness == Brightness.light) {
      // No claro o vidro ainda precisa de sombra: sem ela, branco a 78% sobre uma página
      // quase branca não flutua, só clareia um pedaço da tela.
      panel = DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: radius,
          boxShadow: Shadows.resting(Brightness.light),
        ),
        child: panel,
      );
    }

    return panel;
  }
}

/// A aresta especular: 1 px que nasce claro no topo e morre na base.
///
/// É um traço com gradiente, e não uma borda de cor sólida, porque uma borda uniforme em volta
/// de um cartão translúcido lê como contorno desenhado — a coisa que se quer evitar. A luz do
/// sistema vem de cima; o que ela acende é a quina de cima.
class _GlassEdge extends CustomPainter {
  const _GlassEdge({required this.radius, required this.color});

  final BorderRadius radius;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    // Meio pixel para dentro: um traço de 1 px centrado na borda do recorte perde metade da
    // largura no `ClipRRect` e sai com meia opacidade.
    final rect = Offset.zero & size;
    final rrect = radius.toRRect(rect).deflate(0.5);

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..shader = ui.Gradient.linear(
        rect.topCenter,
        rect.bottomCenter,
        [
          color,
          color.withValues(alpha: color.a * 0.35),
          color.withValues(alpha: 0),
        ],
        const [0, 0.28, 0.8],
      );

    canvas.drawRRect(rrect, paint);
  }

  @override
  bool shouldRepaint(_GlassEdge old) =>
      old.color != color || old.radius != radius;
}

/// Onde a moldura encosta no conteúdo.
enum GlassEdgeSide { none, top, bottom }

/// A moldura translúcida: a barra por onde o conteúdo passa rolando.
///
/// **O borrão é ao vivo, e é essa a graça.** Uma barra opaca esconde o que passa por baixo e a
/// tela vira duas superfícies empilhadas sem relação. Borrando, o conteúdo continua se
/// anunciando através dela — a pessoa vê que há mais coisa ali, e a barra vira uma camada de
/// vidro sobre a tela em vez de uma tampa.
///
/// [opacity] existe para o cabeçalho da Hoje, que **chega junto com a rolagem**: no topo da
/// lista não há nada por baixo para borrar, e uma barra já materializada ali só marcaria uma
/// divisão que não existe.
class GlassChrome extends StatelessWidget {
  const GlassChrome({
    super.key,
    required this.child,
    this.opacity = 1,
    this.edge = GlassEdgeSide.none,
  });

  final Widget child;

  /// 0 a 1. Multiplica o véu **e** o borrão: os dois precisam entrar juntos, senão o texto
  /// aparece nítido sobre um fundo ainda transparente e a barra pisca.
  final double opacity;

  /// De que lado fica a linha de 1 px que separa a moldura do conteúdo: embaixo na barra de
  /// cima, em cima na de baixo. Sem ela, com a lista rolando atrás, não dá para dizer onde a
  /// moldura começa.
  final GlassEdgeSide edge;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final spec = Glass.of(brightness);
    final t = opacity.clamp(0.0, 1.0);

    if (t == 0) {
      return child;
    }

    final fill = Glass.chrome(brightness);
    final line = spec.edge.withValues(alpha: spec.edge.a * t);

    return ClipRect(
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(
          sigmaX: spec.blurSigma * t,
          sigmaY: spec.blurSigma * t,
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: fill.withValues(alpha: fill.a * t),
            border: switch (edge) {
              GlassEdgeSide.none => null,
              GlassEdgeSide.top => Border(top: BorderSide(color: line)),
              GlassEdgeSide.bottom => Border(bottom: BorderSide(color: line)),
            },
          ),
          child: child,
        ),
      ),
    );
  }
}
