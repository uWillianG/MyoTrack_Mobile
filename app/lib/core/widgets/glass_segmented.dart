import 'package:flutter/material.dart';

import '../design/tokens.dart';

/// Uma opção do [GlassSegmented].
@immutable
class GlassSegment<T> {
  const GlassSegment({
    required this.value,
    required this.label,
    this.icon,
    this.color,
  });

  final T value;

  /// O nome escrito da opção.
  ///
  /// **Sempre obrigatório, mesmo na forma compacta**, em que ele não aparece na tela: ali ele
  /// vira o balão do toque longo e o que o leitor de tela anuncia. Um controle sem texto não é
  /// um controle sem nome — quem usa TalkBack ouviria "botão, botão" e teria de adivinhar pela
  /// ordem.
  final String label;

  /// O **assunto** da opção, não o instrumento. Ver a nota de [GlassSegmented].
  ///
  /// Obrigatório na forma compacta, que é só de ícone; ignorado na de texto, onde um ícone ao
  /// lado de cada palavra só apertaria a linha.
  final IconData? icon;

  /// A tinta da família quando esta opção está escolhida. Sem ela, a escolhida fica na cor de
  /// texto do tema — que é o certo para o que não pertence a família nenhuma, como um filtro
  /// de período.
  final Color? color;
}

/// Onde o segmentado está pousado, que é o que decide a paleta dele.
enum GlassSegmentedSurface {
  /// Sobre uma tela do app. O trilho é um rebaixo na superfície.
  page,

  /// Sobre mídia — a foto do prato, um vídeo. Aqui não existe "a cor do tema": o que está
  /// atrás é imprevisível, e a única paleta que funciona sobre qualquer quadro é branco com
  /// opacidade suficiente para não sumir num fundo claro.
  media,
}

/// Um segmentado de vidro: trilho rebaixado e uma pastilha que corre entre as opções.
///
/// **Por que não o `SegmentedButton` do Material.** Ele desenha as opções coladas com uma
/// emenda reta entre elas e um contorno em volta do conjunto — três arestas para dizer uma
/// coisa só, e a emenda faz o grupo ler como botões que por acaso se encostam. O tema do app
/// já invertia as cores dele para disfarçar isso; o que sobrava ainda era a forma.
///
/// Aqui a leitura é a de sempre no sistema: um trilho translúcido, e a escolha corrente é uma
/// pastilha mais clara **por cima** dele. Nenhuma borda, nenhuma divisória — o que separa as
/// opções é o espaço, e o que marca a escolhida é profundidade.
///
/// **A pastilha desliza, e isso não é enfeite.** Trocada por corte, ela pisca de um lado ao
/// outro e o olho perde o rastro de quantas opções existem e de onde a atual está no meio
/// delas. Deslizando, o controle se explica sozinho no primeiro uso. (É o contrário da barra
/// de abas do rodapé, que troca sem transição de propósito: aba é lugar, e ir a um lugar não
/// tem meio do caminho. Aqui não se muda de lugar — filtra-se o mesmo lugar.)
///
/// **Duas formas, e a escolha entre elas não é de gosto.** A de texto ocupa a largura toda,
/// porque o rótulo é o conteúdo e cortar palavra para caber num alvo estreito é pior que
/// qualquer economia de espaço. A [compact] é só de ícone e se encolhe ao próprio tamanho: um
/// trilho de largura cheia com dois ícones no meio é uma tira de nada com dois pontinhos.
///
/// **Na forma compacta o ícone é o assunto, não o instrumento.** As duas metades da análise
/// são fotografar um prato e filmar uma série: se o ícone fosse a ferramenta, seriam câmera e
/// câmera, e o controle não diria nada. Sendo garfo e halter, ele diz o que vai ser analisado
/// — e reusa a iconografia que as famílias do app já estabeleceram, que é o que permite
/// reconhecê-lo sem ter aprendido.
class GlassSegmented<T> extends StatelessWidget {
  const GlassSegmented({
    super.key,
    required this.segments,
    required this.value,
    required this.onChanged,
    this.compact = false,
    this.surface = GlassSegmentedSurface.page,
  });

  final List<GlassSegment<T>> segments;
  final T value;
  final ValueChanged<T> onChanged;

  /// Mostra só os ícones e encolhe o controle ao próprio tamanho.
  ///
  /// Exige [GlassSegment.icon] em todas as opções — sem ele não sobraria nada para tocar.
  final bool compact;

  final GlassSegmentedSurface surface;

  /// 44 e não os 36 do desenho. O desenho põe o segmentado em largura cheia, onde cada opção é
  /// um alvo de 170 dp; na forma compacta ele encolhe para 64, e aí a altura é a única
  /// dimensão que ainda pode sustentar o dedo.
  static const double _height = 44;
  static const double _compactSegment = 64;
  static const double _inset = 3;

  @override
  Widget build(BuildContext context) {
    assert(
      !compact || segments.every((s) => s.icon != null),
      'A forma compacta é só de ícone: toda opção precisa de um.',
    );

    final theme = Theme.of(context);
    final palette = _Palette.of(theme, surface);
    final index = segments.indexWhere((s) => s.value == value);

    final track = Container(
      height: _height,
      padding: const EdgeInsets.all(_inset),
      decoration: BoxDecoration(
        color: palette.track,
        borderRadius: BorderRadius.circular(Radii.sm),
      ),
      child: Stack(
        children: [
          if (index >= 0)
            AnimatedAlign(
              // Uma opção só não tem para onde correr, e a conta de interpolação dividiria
              // por zero.
              alignment: segments.length == 1
                  ? Alignment.center
                  : Alignment(-1 + 2 * index / (segments.length - 1), 0),
              duration: Motion.base,
              curve: Motion.enter,
              child: FractionallySizedBox(
                widthFactor: 1 / segments.length,
                heightFactor: 1,
                child: _Pill(palette: palette),
              ),
            ),
          Row(
            children: [
              for (final segment in segments)
                Expanded(
                  child: _Segment(
                    segment: segment,
                    selected: segment.value == value,
                    compact: compact,
                    palette: palette,
                    onTap: () => onChanged(segment.value),
                  ),
                ),
            ],
          ),
        ],
      ),
    );

    if (!compact) {
      return track;
    }

    return Center(
      child: SizedBox(
        width: _compactSegment * segments.length + _inset * 2,
        child: track,
      ),
    );
  }
}

/// As quatro cores que o controle usa, já resolvidas para a superfície em que ele pousou.
@immutable
class _Palette {
  const _Palette({
    required this.track,
    required this.pill,
    required this.selected,
    required this.unselected,
    required this.edge,
    required this.lift,
  });

  final Color track;
  final Color pill;
  final Color selected;
  final Color unselected;

  /// A aresta de cima da pastilha. Nula onde ela não faz sentido — no tema claro a pastilha é
  /// branca opaca, e uma linha branca por cima de branco não existe.
  final Color? edge;

  /// A sombra que levanta a pastilha. Só no claro, pela mesma física do resto do app.
  ///
  /// **Curta, e não a de cartão.** `Shadows.resting` foi desenhada para um bloco de 150 dp: no
  /// pastilha de 38 ela borra 14 px para fora do trilho, e o controle passa a parecer que
  /// vazou. Aqui a sombra só precisa dizer "isto está por cima", e dois pixels bastam.
  static const List<BoxShadow> _lift = [
    BoxShadow(color: Color(0x14101B14), blurRadius: 5, offset: Offset(0, 2)),
  ];

  final List<BoxShadow>? lift;

  static _Palette of(ThemeData theme, GlassSegmentedSurface surface) {
    final scheme = theme.colorScheme;

    if (surface == GlassSegmentedSurface.media) {
      // Sobre foto, tudo sobe de opacidade: o que está atrás pode ser um prato branco sob luz
      // dura, e um véu de 7% desapareceria nele.
      return const _Palette(
        track: Color(0x2EFFFFFF),
        pill: Color(0x4DFFFFFF),
        selected: Color(0xFFFFFFFF),
        unselected: Color(0xB3FFFFFF),
        edge: Color(0x59FFFFFF),
        lift: null,
      );
    }

    final isDark = theme.brightness == Brightness.dark;

    return _Palette(
      // O trilho é um rebaixo, não um cartão: ele é o buraco em que a pastilha corre, e por
      // isso escurece a superfície em vez de clareá-la.
      track: scheme.onSurface.withValues(alpha: isDark ? 0.07 : 0.05),
      // No escuro a pastilha é o mesmo véu de sempre, um degrau acima do trilho. No claro
      // precisa ser branco de verdade: um branco translúcido sobre um trilho cinza-claro daria
      // dois cinzas quase iguais, e a escolha some.
      pill: isDark
          ? scheme.onSurface.withValues(alpha: 0.13)
          : scheme.surfaceContainerLowest,
      selected: scheme.onSurface,
      unselected: scheme.onSurfaceVariant,
      edge: isDark ? scheme.onSurface.withValues(alpha: 0.16) : null,
      lift: isDark ? null : _lift,
    );
  }
}

/// A pastilha da escolha corrente.
class _Pill extends StatelessWidget {
  const _Pill({required this.palette});

  final _Palette palette;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: palette.pill,
        borderRadius: BorderRadius.circular(Radii.sm - GlassSegmented._inset),
        boxShadow: palette.lift,
        // A aresta de cima, como em todo vidro do app: é ela que faz a pastilha parecer
        // apoiada sobre o trilho em vez de recortada nele.
        border: palette.edge == null
            ? null
            : Border(top: BorderSide(color: palette.edge!)),
      ),
    );
  }
}

class _Segment<T> extends StatelessWidget {
  const _Segment({
    required this.segment,
    required this.selected,
    required this.compact,
    required this.palette,
    required this.onTap,
  });

  final GlassSegment<T> segment;
  final bool selected;
  final bool compact;
  final _Palette palette;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // **A escolhida veste a cor da família; a outra fica neutra.** Duas cores acesas ao mesmo
    // tempo não diriam qual está valendo — e é a cor da escolhida que antecipa a tela por
    // baixo do controle.
    final ink = selected
        ? (segment.color ?? palette.selected)
        : palette.unselected;

    final content = compact
        ? Icon(segment.icon, size: 21, color: ink)
        : Text(
            segment.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelMedium?.copyWith(
              color: ink,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            ),
          );

    return Semantics(
      button: true,
      selected: selected,
      label: segment.label,
      excludeSemantics: true,
      child: Tooltip(
        // Só onde o nome não está escrito. Um balão repetindo a palavra que já se lê é ruído.
        message: compact ? segment.label : '',
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            borderRadius: BorderRadius.circular(Radii.sm),
            onTap: onTap,
            child: Center(
              // A troca entra por transição e não por corte: a pastilha leva 220 ms para
              // chegar, e um rótulo que muda de cor no primeiro quadro chega antes dela.
              child: AnimatedDefaultTextStyle(
                duration: Motion.base,
                style: DefaultTextStyle.of(
                  context,
                ).style.merge(theme.textTheme.labelMedium).copyWith(color: ink),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: Space.xs),
                  child: content,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
