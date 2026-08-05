import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../design/blocks.dart';
import '../design/tokens.dart';
import '../design/typography.dart';

/// As formas do sistema: um herói, ladrilhos e seções.
///
/// O herói é o assunto do momento — cor cheia, número grande, uma ação. **Um por tela**, e o
/// assunto promovido a herói sai do resto: repeti-lo nos dois lugares é a duplicação que faz
/// uma tela parecer cheia sem dizer nada a mais.
///
/// Abaixo dele, a escolha entre [Tile] e [BlockSection] não é de tamanho, é de natureza:
///
/// - **[Tile] é para assuntos diferentes.** Na Hoje, treino, semana e peso são coisas
///   distintas, cada uma com a própria cor, e o valor de cada ladrilho responde a uma pergunta
///   que não é a das outras. Por isso a grade de dois em dois funciona: são peças autônomas.
/// - **[BlockSection] é para facetas do mesmo assunto.** No diário, calorias, macros, semana e
///   refeições são o mesmo assunto visto de quatro ângulos. Picotá-los em ladrilhos coloridos
///   sugeriria uma independência que eles não têm — e a tela voltaria a parecer um painel de
///   instrumentos.
///
/// A regra prática: se dois blocos vizinhos levam ao mesmo lugar e falam do mesmo número, eles
/// são seções da mesma coisa, não ladrilhos.

/// O bloco grande do topo.
class HeroBlock extends StatelessWidget {
  const HeroBlock({
    super.key,
    required this.colors,
    required this.label,
    required this.icon,
    required this.child,
    this.action,
    this.onTap,
  });

  final BlockColors colors;

  /// O assunto, em caixa normal: "Nutrição", "Treino". Nomear o bloco é o que permite à cor
  /// significar alguma coisa — sozinha ela seria um enfeite que o usuário decora com o tempo,
  /// ou não decora.
  final String label;

  final IconData icon;

  /// O miolo: o número grande e o que o acompanha.
  final Widget child;

  /// O botão do rodapé. Fundo claro sobre a cor cheia — a cor da marca sobre a cor da marca
  /// não teria contraste.
  final HeroAction? action;

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final content = Padding(
      // 20 e não 24: o herói ocupava metade da tela e sobrava pouco para o mosaico. Quatro
      // pixels em cada lado, mais a redução do número e do botão, tiram quase 60 dp de altura
      // sem que nada dentro dele aperte.
      padding: const EdgeInsets.all(Space.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: colors.onTone.withValues(alpha: 0.8)),
              const SizedBox(width: Space.xs),
              // `Expanded` e não largura natural: o rótulo do herói é conteúdo, não constante
              // — no diário ele é a data do dia aberto, e "quinta, 31 de julho" estoura a
              // linha num celular de 360 dp.
              Expanded(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: colors.onTone.withValues(alpha: 0.8),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: Space.sm),
          child,
          if (action case final action?) ...[
            const SizedBox(height: Space.md),
            action.build(context, colors),
          ],
        ],
      ),
    );

    return Material(
      color: colors.tone,
      borderRadius: Radii.xlAll,
      clipBehavior: Clip.antiAlias,
      child: onTap == null ? content : InkWell(onTap: onTap, child: content),
    );
  }
}

/// O botão do herói. Existe como dado e não como widget solto porque a cor dele sai do bloco.
///
/// [onPressed] aceita nulo: é como o botão fica enquanto a ação já está em andamento — a
/// geração de uma dieta leva até um minuto, e um botão vivo nesse intervalo convida a disparar
/// o trabalho duas vezes. O rótulo é quem conta o que está acontecendo ("Gerando…").
class HeroAction {
  const HeroAction({required this.label, required this.onPressed});

  final String label;
  final VoidCallback? onPressed;

  Widget build(BuildContext context, BlockColors colors) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton(
        style: FilledButton.styleFrom(
          backgroundColor: colors.onTone,
          foregroundColor: colors.tone,
          // O desabilitado do tema é um cinza pensado para fundo claro; sobre a cor cheia do
          // herói ele sairia como uma mancha de outra paleta.
          disabledBackgroundColor: colors.onTone.withValues(alpha: 0.35),
          disabledForegroundColor: colors.tone.withValues(alpha: 0.75),
          minimumSize: const Size.fromHeight(46),
        ),
        onPressed: onPressed,
        child: Text(label),
      ),
    );
  }
}

/// O número grande do herói, com a unidade colada nele.
class HeroFigure extends StatelessWidget {
  const HeroFigure({
    super.key,
    required this.value,
    required this.unit,
    required this.colors,
    this.detail,
  });

  final String value;

  /// Vai ao lado do número e não abaixo: "55 min", "624 kcal". Separar unidade de grandeza em
  /// duas linhas obriga a juntá-las de novo na leitura.
  final String unit;

  final String? detail;
  final BlockColors colors;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  value,
                  maxLines: 1,
                  // 48 e não 56: continua sendo, com folga, a maior coisa da tela — o próximo
                  // número é o do ladrilho, a 28 —, e oito pixels a menos aqui são oito
                  // pixels que o mosaico ganha.
                  style: AppTypography.numeric(size: 48, color: colors.onTone),
                ),
              ),
            ),
            const SizedBox(width: Space.xs),
            // `Flexible` também na unidade: ela deixou de ser uma constante curta quando o
            // Progresso passou a escrever "de 12 semanas" ali. Sem isto a linha estoura, e o
            // estouro aparece como faixa listrada em cima do número.
            Flexible(
              child: Padding(
                // Desce a unidade uns pixels: alinhada pela linha de base, ela fica alta
                // demais ao lado de um número deste tamanho.
                padding: const EdgeInsets.only(bottom: 3),
                child: Text(
                  unit,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: colors.onTone.withValues(alpha: 0.85),
                  ),
                ),
              ),
            ),
          ],
        ),
        if (detail case final detail?) ...[
          const SizedBox(height: Space.xs),
          Text(
            detail,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colors.onTone.withValues(alpha: 0.85),
            ),
          ),
        ],
      ],
    );
  }
}

/// Um ladrilho do mosaico.
///
/// Altura fixa para que a grade case sem `IntrinsicHeight`: dois ladrilhos lado a lado com
/// alturas diferentes são o detalhe que faz uma grade parecer montada às pressas.
class Tile extends StatelessWidget {
  const Tile({
    super.key,
    required this.colors,
    required this.label,
    required this.icon,
    required this.value,
    this.detail,
    this.footer,
    this.onTap,
    this.wide = false,
  });

  final BlockColors colors;
  final String label;
  final IconData icon;

  /// O valor, na cor cheia da família. É o que se lê de relance.
  final String value;

  final String? detail;

  /// Uma faixa no pé do ladrilho — os pontos da semana, por exemplo.
  final Widget? footer;

  final VoidCallback? onTap;

  /// O ímpar que sobra na grade, ocupando a largura toda.
  ///
  /// **Não é o mesmo ladrilho esticado.** Com a mesma altura e o mesmo empilhamento, a versão
  /// larga fica com o número num canto e um vazio do tamanho de meia tela ao lado. Aqui o
  /// conteúdo deita: rótulo e detalhe à esquerda, número à direita, e a altura cai para
  /// pouco mais da metade.
  final bool wide;

  static const double height = 146;
  static const double wideHeight = 84;

  /// O mesmo ladrilho, deitado. Quem chama é a [TileGrid], ao sobrar um ímpar no fim.
  Tile asWide() => Tile(
    key: key,
    colors: colors,
    label: label,
    icon: icon,
    value: value,
    detail: detail,
    footer: footer,
    onTap: onTap,
    wide: true,
  );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final content = wide ? _wide(theme) : _tall(theme);

    return SizedBox(
      height: wide ? wideHeight : height,
      child: Material(
        color: colors.wash,
        borderRadius: Radii.lgAll,
        clipBehavior: Clip.antiAlias,
        child: onTap == null ? content : InkWell(onTap: onTap, child: content),
      ),
    );
  }

  Widget _wide(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: Space.md,
        vertical: Space.sm,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  children: [
                    Icon(icon, size: 15, color: colors.ink),
                    const SizedBox(width: 5),
                    Flexible(
                      child: Text(
                        label,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: colors.ink,
                          letterSpacing: 0.1,
                        ),
                      ),
                    ),
                  ],
                ),
                if (detail case final detail?)
                  Text(
                    detail,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: Space.sm),
          Text(
            value,
            maxLines: 1,
            style: AppTypography.numeric(size: 28, color: colors.ink),
          ),
          if (footer case final footer?) ...[
            const SizedBox(width: Space.sm),
            footer,
          ],
        ],
      ),
    );
  }

  Widget _tall(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(Space.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 15, color: colors.ink),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colors.ink,
                    letterSpacing: 0.1,
                  ),
                ),
              ),
            ],
          ),
          const Spacer(),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              maxLines: 1,
              style: AppTypography.numeric(size: 28, color: colors.ink),
            ),
          ),
          if (detail case final detail?)
            Text(
              detail,
              // Duas linhas: "Treino B · Peito e tríceps" não cabe em meia largura de tela, e
              // cortado no meio da palavra ele não diz nem qual treino é.
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.25,
              ),
            ),
          if (footer case final footer?) ...[
            const SizedBox(height: Space.xs),
            footer,
          ],
        ],
      ),
    );
  }
}

/// A grade de ladrilhos: duas colunas, e o ímpar sobrando ocupa a largura toda.
///
/// Um ladrilho solto com metade da largura e metade vazia ao lado é o buraco que denuncia uma
/// grade que não foi pensada para número ímpar de itens.
class TileGrid extends StatelessWidget {
  const TileGrid({super.key, required this.tiles});

  final List<Tile> tiles;

  @override
  Widget build(BuildContext context) {
    if (tiles.isEmpty) {
      return const SizedBox.shrink();
    }

    final rows = <Widget>[];
    // Um item sobrando fica para o fim, em largura cheia; os demais vão em pares.
    final pairs = tiles.length - (tiles.length.isOdd ? 1 : 0);

    for (var i = 0; i < pairs; i += 2) {
      rows.add(
        // Sem `CrossAxisAlignment.stretch`: dentro de uma lista rolável a altura é ilimitada,
        // e esticar pede infinito. Quem garante que os dois ladrilhos casam é a altura fixa
        // do próprio `Tile`.
        Row(
          children: [
            Expanded(child: tiles[i]),
            const SizedBox(width: Space.sm),
            Expanded(child: tiles[i + 1]),
          ],
        ),
      );
    }
    if (tiles.length.isOdd) {
      rows.add(tiles.last.asWide());
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < rows.length; i++) ...[
          if (i > 0) const SizedBox(height: Space.sm),
          rows[i],
        ],
      ],
    );
  }
}

/// Uma faixa lavada com um rótulo e conteúdo livre.
///
/// É o recipiente do que não cabe num ladrilho: um gráfico, uma lista de refeições, três
/// medidores empilhados. Mesma cor de fundo e mesmo raio do ladrilho, para que a tela leia como
/// um sistema só — o que muda é que aqui o conteúdo manda no tamanho.
///
/// [padding] fica exposto porque lista quer encostar nas bordas e gráfico não: uma lista com
/// respiro dos dois lados perde o fio que separa uma linha da seguinte.
class BlockSection extends StatelessWidget {
  const BlockSection({
    super.key,
    required this.colors,
    required this.label,
    required this.icon,
    required this.child,
    this.trailing,
    this.padding = const EdgeInsets.all(Space.md),
    this.onEdit,
    this.actionIcon = Icons.edit_outlined,
    this.actionVerb = 'Editar',
  });

  final BlockColors colors;
  final String label;
  final IconData icon;
  final Widget child;

  /// À direita do rótulo: uma contagem, um total. Sempre em `labelSmall`.
  final String? trailing;

  final EdgeInsets padding;

  /// Torna a seção inteira tocável e põe um lápis no canto do rótulo.
  ///
  /// **A seção toda, e não só o lápis.** Um alvo de 24 dp num canto obriga a mira; a seção
  /// tem a largura da tela e a pessoa já está olhando para o conteúdo que quer mudar. O lápis
  /// fica como sinal de que dá para tocar, não como o alvo.
  final VoidCallback? onEdit;

  /// O sinal no canto do rótulo, e o verbo que o leitor de tela anuncia.
  ///
  /// Existem porque o toque nem sempre é edição: na fila de revisão a seção **abre** um plano
  /// para decidir sobre ele, e um lápis ali prometeria que o revisor pode reescrever a dieta de
  /// outra pessoa — que é justamente o que ele não pode.
  final IconData actionIcon;
  final String actionVerb;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            Space.md,
            Space.md,
            Space.md,
            Space.sm,
          ),
          child: Row(
            children: [
              Icon(icon, size: 15, color: colors.ink),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colors.ink,
                    letterSpacing: 0.1,
                  ),
                ),
              ),
              // `Flexible` também no trailing: ele é conteúdo — "maior carga por exercício",
              // "média 1.904 kcal" — e não uma contagem curta. Sem isto o rótulo do bloco
              // estoura em 360 dp e a faixa listrada aparece por cima do texto.
              if (trailing case final trailing?)
                Flexible(
                  child: Text(
                    trailing,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.end,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              if (onEdit != null) Icon(actionIcon, size: 16, color: colors.ink),
            ],
          ),
        ),
        Padding(padding: padding.copyWith(top: 0), child: child),
      ],
    );

    // `Material` e não `Container`: um fundo pintado por `BoxDecoration` fica **acima** do
    // Material mais próximo, e todo respingo de toque dos filhos desaparece atrás dele. O
    // Flutter chega a avisar quando um `ListTile` cai nessa armadilha — foi assim que apareceu.
    return Material(
      color: colors.wash,
      borderRadius: Radii.lgAll,
      clipBehavior: Clip.antiAlias,
      child: onEdit == null
          ? content
          : InkWell(
              onTap: onEdit,
              child: Semantics(
                button: true,
                label: '$actionVerb $label',
                child: content,
              ),
            ),
    );
  }
}

/// Um medidor: rótulo, valor contra a meta, e a barra.
///
/// **Passar da meta não é pintado de vermelho.** Comer acima do alvo num dia não é erro, e o
/// app não deveria repreender: a barra satura em 100% e o número ao lado conta o que houve.
class BlockMeter extends StatelessWidget {
  const BlockMeter({
    super.key,
    required this.colors,
    required this.label,
    required this.value,
    required this.ratio,
  });

  final BlockColors colors;
  final String label;

  /// "110 / 172 g", já formatado pelo `Fmt`.
  final String value;

  final double ratio;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Semantics(
      label: '$label, $value',
      excludeSemantics: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(label, style: theme.textTheme.titleSmall)),
              Text(
                value,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: ratio.clamp(0.0, 1.0),
              minHeight: 7,
              color: colors.ink,
              // Sobre um fundo já tingido, a trilha precisa ser a própria cor rebaixada — o
              // cinza do tema apareceria como uma terceira cor no meio do bloco.
              backgroundColor: colors.ink.withValues(alpha: 0.18),
            ),
          ),
        ],
      ),
    );
  }
}

/// **A barra de refeições** — a assinatura da nutrição, na Hoje e no diário.
///
/// Não é um medidor: é o registro do dia. Cada refeição lançada vira um segmento próprio, na
/// ordem em que foi comida, separada da seguinte por uma fresta. Ao longo do dia a barra se
/// preenche por pedaços — e num relance responde duas perguntas de uma vez, "quanto ainda
/// cabe" e "quantas vezes eu já comi", que é a diferença entre um gráfico e um diário.
///
/// Satura em 100% em vez de continuar: passar da meta não merece uma segunda barra, e o número
/// acima já conta o resto.
class MealBar extends StatelessWidget {
  const MealBar({
    super.key,
    required this.slices,
    required this.colors,
    this.onTone = true,
  });

  /// Uma fração da meta por refeição, na ordem do dia. Monte com [slicesOf].
  final List<double> slices;

  final BlockColors colors;

  /// Verdadeiro sobre o herói (cor cheia), falso sobre um fundo lavado.
  final bool onTone;

  static const double _height = 10;
  static const double _gap = 3;

  @override
  Widget build(BuildContext context) {
    final filled = slices.fold<double>(0, (sum, s) => sum + s).clamp(0.0, 1.0);
    final fill = onTone ? colors.onTone : colors.ink;

    return Semantics(
      label:
          '${(filled * 100).round()} por cento da meta, '
          'em ${slices.length} ${slices.length == 1 ? 'refeição' : 'refeições'}',
      child: SizedBox(
        height: _height,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            return Stack(
              children: [
                // A trilha inteira, sob os segmentos: o que ainda cabe no dia.
                Container(
                  decoration: BoxDecoration(
                    color: fill.withValues(alpha: 0.22),
                    borderRadius: BorderRadius.circular(_height / 2),
                  ),
                ),
                Row(
                  children: [
                    for (var i = 0; i < slices.length; i++) ...[
                      if (i > 0) const SizedBox(width: _gap),
                      Container(
                        // A fresta sai da largura do próprio segmento; um lanche pequeno
                        // ainda precisa deixar um traço visível, daí o piso de 6 dp.
                        width: math.max(
                          6,
                          slices[i] * width - (i > 0 ? _gap : 0),
                        ),
                        decoration: BoxDecoration(
                          color: fill,
                          borderRadius: BorderRadius.circular(_height / 2),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  /// A fatia de cada refeição, em fração da meta.
  ///
  /// **Sem lançamentos, mas com consumo, sai uma fatia só.** É o caso de quem tem consumo
  /// vindo de outro caminho que não a análise de foto: o total é verdadeiro e precisa
  /// aparecer, ainda que o app não saiba reparti-lo. Melhor uma barra cheia sem divisões do
  /// que uma barra vazia contradizendo o número acima dela.
  static List<double> slicesOf({
    required Iterable<num> mealKcal,
    required num consumed,
    required num target,
  }) {
    if (target <= 0) {
      return const [];
    }

    final counted = [
      for (final kcal in mealKcal)
        if (kcal > 0) kcal.toDouble(),
    ];
    final values = counted.isEmpty
        ? (consumed > 0 ? [consumed.toDouble()] : const <double>[])
        : counted;

    // Satura no total: a soma nunca passa de uma barra cheia.
    var remaining = 1.0;
    final slices = <double>[];
    for (final value in values) {
      if (remaining <= 0) {
        break;
      }
      final slice = math.min(value / target, remaining);
      slices.add(slice);
      remaining -= slice;
    }
    return slices;
  }
}
