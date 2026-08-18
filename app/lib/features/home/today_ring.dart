import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../core/design/blocks.dart';
import '../../core/design/format.dart';
import '../../core/design/materials.dart';
import '../../core/design/springs.dart';
import '../../core/design/tokens.dart';
import '../../core/design/typography.dart';
import '../diary/data/diary_models.dart';

/// O anel de calorias.
///
/// Desenha a fração **consumida** da meta, e não a que resta, ainda que o número no meio dele
/// seja o que resta. Não é contradição: o arco é o dia enchendo — ele cresce conforme se come,
/// que é a direção que a pessoa sente — e o número responde a pergunta prática, "quanto ainda
/// cabe". Um anel que *esvazia* ao longo do dia leria como bateria descarregando, e comer
/// deixaria de parecer progresso.
///
/// Serve nos dois tamanhos: 186 dp no herói e 22 dp na barra, quando o herói já saiu de cena.
/// É a mesma peça em duas escalas, de propósito — é o que faz o número da barra ser
/// reconhecido como "aquele anel lá de cima" sem nenhuma transição desenhando isso.
class CalorieRing extends StatelessWidget {
  const CalorieRing({
    super.key,
    required this.progress,
    required this.colors,
    required this.diameter,
    required this.stroke,
  });

  /// 0 a 1. Acima de 1 o anel satura: uma segunda volta por cima da primeira não diz nada que
  /// o número já não diga, e some com a referência de onde a meta ficava.
  final double progress;

  final BlockColors colors;
  final double diameter;
  final double stroke;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: diameter,
      child: CustomPaint(
        painter: _RingPainter(
          progress: progress.clamp(0.0, 1.0),
          // A trilha é a própria família a 16%, e não um cinza neutro: o cinza faria o anel
          // parecer um medidor genérico colado por cima da tela, e o esmeralda fraco já é a
          // sombra do arco cheio.
          track: colors.ink.withValues(alpha: 0.16),
          ink: colors.ink,
          stroke: stroke,
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  const _RingPainter({
    required this.progress,
    required this.track,
    required this.ink,
    required this.stroke,
  });

  final double progress;
  final Color track;
  final Color ink;
  final double stroke;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = (size.shortestSide - stroke) / 2;

    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..color = track,
    );

    if (progress <= 0) {
      return;
    }

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      // Do topo, no sentido do relógio: é de onde todo mostrador parte.
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round
        ..color = ink,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.progress != progress ||
      old.ink != ink ||
      old.track != track ||
      old.stroke != stroke;
}

/// O herói da Hoje: a data, o anel, e o dia inteiro a um puxão dele.
///
/// **O anel é um objeto, não uma figura.** Puxá-lo para baixo abre a linha do tempo do dia — as
/// refeições lançadas, na ordem em que aconteceram. É a informação que antes exigia trocar de
/// aba e que ninguém trocava de aba para ver; aqui ela mora atrás do próprio número que a
/// resume, que é o lugar onde faz sentido procurá-la.
///
/// As três decisões que fazem o gesto parecer físico, e não uma animação disparada por toque:
///
/// - **O conteúdo segue o dedo 1:1** enquanto se arrasta, do primeiro pixel ao último. Painel
///   que só se move quando o dedo solta é um botão disfarçado.
/// - **Quem decide o destino é a velocidade, não a distância** — ver [momentumProjection]. Um
///   peteleco de três milímetros abre o painel inteiro; um arrasto lento até a metade volta.
/// - **O limite resiste em vez de travar** — ver [rubberBand]. Travar não diz se o app entendeu
///   o gesto ou se congelou.
///
/// **Para cima com o painel fechado é rolagem.** O anel ocupa quase um terço da tela; um
/// objeto desse tamanho que engole o gesto de rolar faz o app parecer preso. Nesse caso o
/// herói devolve o arrasto para a lista, com a projeção de momento fazendo o papel do impulso.
class TodayRingHero extends StatefulWidget {
  const TodayRingHero({
    super.key,
    required this.day,
    required this.colors,
    required this.scrollController,
  });

  final DiaryDay day;

  final BlockColors colors;

  /// A rolagem da Hoje, para onde vai o arrasto que não é do anel.
  final ScrollController scrollController;

  @override
  State<TodayRingHero> createState() => _TodayRingHeroState();
}

class _TodayRingHeroState extends State<TodayRingHero>
    with SingleTickerProviderStateMixin {
  /// 0 fechado, 1 aberto. Sem limites porque o elástico do fim de curso passa dos dois.
  late final AnimationController _reveal = AnimationController.unbounded(
    vsync: this,
    value: 0,
  );

  /// Quanto o arrasto corrente já entregou para a rolagem em vez de para o painel.
  ///
  /// Guardado porque o desfecho do gesto depende dele: um arrasto que virou rolagem termina
  /// com um impulso na lista, e não com a mola do painel.
  bool _scrolling = false;

  double get _distance => _timelineHeight(_entries.length);

  List<DiaryEntry> get _entries => [
    for (final entry in widget.day.entries)
      if (!entry.excludedFromDiary) entry,
  ];

  @override
  void dispose() {
    _reveal.dispose();
    super.dispose();
  }

  void _onDragStart(DragStartDetails details) {
    _reveal.stop();
    _scrolling = false;
  }

  void _onDragUpdate(DragUpdateDetails details) {
    final dy = details.delta.dy;

    // Para cima com o painel fechado o anel não é o alvo: quem devia estar se mexendo é a
    // lista. `jumpTo` e não uma animação — o dedo está encostado, e o que ele pede é
    // deslocamento, não transição.
    if (_reveal.value <= 0 && dy < 0 || _scrolling && _reveal.value <= 0) {
      _scrolling = true;
      final position = widget.scrollController.position;
      widget.scrollController.jumpTo(
        (position.pixels - dy).clamp(
          position.minScrollExtent,
          position.maxScrollExtent,
        ),
      );
      return;
    }

    _scrolling = false;
    var next = _reveal.value + dy / _distance;
    // Fim de curso dos dois lados: passa, mas cada vez menos.
    if (next > 1) {
      next = 1 + rubberBand((next - 1) * _distance, _distance) / _distance;
    } else if (next < 0) {
      next = -rubberBand(-next * _distance, _distance) / _distance;
    }
    _reveal.value = next;
  }

  void _onDragEnd(DragEndDetails details) {
    final velocity = details.velocity.pixelsPerSecond.dy;

    if (_scrolling) {
      _scrolling = false;
      _flingScroll(velocity);
      return;
    }

    _settle(velocity);
  }

  /// Continua a rolagem que o anel emprestou à lista.
  ///
  /// A lista não viu o gesto — ele foi consumido aqui — então ela também não ganharia o
  /// impulso do fim dele, e a rolagem pararia seca no instante em que o dedo sai. A mesma
  /// projeção de momento que decide o destino do painel diz onde ela deveria parar.
  void _flingScroll(double velocity) {
    if (velocity.abs() < 50) {
      return;
    }
    final position = widget.scrollController.position;
    final target = (position.pixels - momentumProjection(velocity)).clamp(
      position.minScrollExtent,
      position.maxScrollExtent,
    );
    widget.scrollController.animateTo(
      target,
      duration: const Duration(milliseconds: 480),
      curve: Curves.easeOutCubic,
    );
  }

  /// Leva o painel ao aberto ou ao fechado, a partir de onde ele está e com a velocidade que
  /// o dedo deixou.
  void _settle(double velocity) {
    final projected =
        _reveal.value + momentumProjection(velocity) / math.max(1, _distance);
    final target = projected > 0.5 ? 1.0 : 0.0;

    if ((target == 1) != (_reveal.value > 0.5)) {
      // O toque háptico marca a virada, não a soltura: ele confirma que o app entendeu para
      // onde o gesto ia, no instante em que isso é decidido.
      HapticFeedback.selectionClick();
    }

    _reveal.animateWith(
      SpringSimulation(
        Springs.settle(velocity: velocity),
        _reveal.value,
        target,
        velocity / math.max(1, _distance),
      ),
    );
  }

  void _toggle() {
    // Um toque não tem velocidade própria, então empresta-se uma: é o que mantém a abertura
    // por toque e a por arremesso com a mesma cara.
    _settle(_reveal.value > 0.5 ? -320 : 320);
  }

  @override
  Widget build(BuildContext context) {
    final targets = widget.day.targets!;
    final consumed = widget.day.consumed;
    final left = math.max(0, (targets.kcal - consumed.kcal).round());
    final progress = targets.kcal <= 0 ? 0.0 : consumed.kcal / targets.kcal;
    final entries = _entries;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GestureDetector(
          // O alvo é a faixa inteira do anel, e não o disco: mirar um círculo de 186 dp com o
          // polegar em movimento erra a borda com frequência.
          behavior: HitTestBehavior.opaque,
          onVerticalDragStart: _onDragStart,
          onVerticalDragUpdate: _onDragUpdate,
          onVerticalDragEnd: _onDragEnd,
          onTap: _toggle,
          child: AnimatedBuilder(
            animation: _reveal,
            builder: (context, _) {
              final t = _reveal.value.clamp(0.0, 1.0);
              return Column(
                children: [
                  // O anel recua e encolhe um pouco enquanto o painel sai de trás dele. É o
                  // que dá a impressão de que a linha do tempo estava embaixo o tempo todo, em
                  // vez de ter sido criada agora.
                  Transform.translate(
                    offset: Offset(0, -8 * t),
                    child: Transform.scale(
                      scale: 1 - 0.07 * t,
                      child: _RingFigure(
                        progress: progress,
                        left: left,
                        consumed: consumed.kcal,
                        target: targets.kcal,
                        colors: widget.colors,
                      ),
                    ),
                  ),
                  Opacity(
                    opacity: (1 - t * 1.6).clamp(0.0, 1.0),
                    child: _GrabHint(open: t > 0.5),
                  ),
                ],
              );
            },
          ),
        ),
        AnimatedBuilder(
          animation: _reveal,
          builder: (context, child) {
            final t = _reveal.value.clamp(0.0, 1.0);
            // Uma folga, e não `== 0`: a mola assenta dentro de uma tolerância, não num zero
            // exato. Sem ela o painel fica na árvore para sempre depois da primeira abertura —
            // invisível na tela, presente para o leitor de tela e para o toque.
            if (t < 0.001) {
              return const SizedBox.shrink();
            }
            return ClipRect(
              child: Align(
                alignment: Alignment.topCenter,
                heightFactor: t,
                child: Opacity(
                  opacity: t,
                  // Sobe 16 dp durante a abertura: o painel *emerge* de trás do anel em vez
                  // de simplesmente aparecer no lugar dele.
                  child: Transform.translate(
                    offset: Offset(0, -16 + 16 * t),
                    child: Transform.scale(
                      scale: 0.965 + 0.035 * t,
                      child: child,
                    ),
                  ),
                ),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.only(top: Space.sm),
            child: SizedBox(
              height: _distance - Space.sm,
              child: _DayTimeline(entries: entries, colors: widget.colors),
            ),
          ),
        ),
      ],
    );
  }
}

/// A altura que a linha do tempo ocupa aberta — e, por ser a mesma, a distância do arrasto.
///
/// **Os dois números têm de ser um só.** Se o painel abre 172 dp enquanto o dedo percorre 196,
/// o conteúdo anda mais devagar que a mão, e é exatamente essa defasagem que faz uma interface
/// parecer que está *respondendo* ao gesto em vez de estar *sendo movida* por ele.
double _timelineHeight(int rows) =>
    Space.sm + 30 + math.max(1, math.min(rows, _maxRows)) * 32 + 30;

/// Quantas refeições cabem antes de o painel virar uma segunda tela.
///
/// Cinco: quem lança mais que isso num dia está no diário, não no anel da Hoje.
const int _maxRows = 5;

/// O número, o anel e o que sustenta os dois.
class _RingFigure extends StatelessWidget {
  const _RingFigure({
    required this.progress,
    required this.left,
    required this.consumed,
    required this.target,
    required this.colors,
  });

  final double progress;
  final int left;
  final num consumed;
  final num target;
  final BlockColors colors;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SizedBox(
      height: 190,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CalorieRing(
            progress: progress,
            colors: colors,
            diameter: 186,
            stroke: 12,
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // O maior número do app, e é o único que precisa ser lido de longe: ele é
              // consultado com o celular na mesa e o prato na frente.
              Text(
                Fmt.integer(left),
                maxLines: 1,
                style: AppTypography.numeric(
                  size: 64,
                  color: theme.colorScheme.onSurface,
                  weight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'kcal restam',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: colors.ink,
                  letterSpacing: 0.2,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${Fmt.integer(consumed)} de ${Fmt.integer(target)}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// O convite ao gesto.
///
/// **Um gesto sem sinal é um gesto que não existe.** A seta e a frase são a única coisa que
/// separa "dá para puxar o anel" de "descobri por acidente", e elas somem assim que o painel
/// começa a abrir — cumprida a função, ficar seria ruído permanente.
class _GrabHint extends StatelessWidget {
  const _GrabHint({required this.open});

  final bool open;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.75);

    return SizedBox(
      height: 22,
      child: Semantics(
        button: true,
        label: open ? 'Fechar o dia até agora' : 'Ver o dia até agora',
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.keyboard_arrow_down, size: 16, color: muted),
            const SizedBox(width: 5),
            Text(
              'arraste para ver o dia',
              style: theme.textTheme.bodySmall?.copyWith(color: muted),
            ),
          ],
        ),
      ),
    );
  }
}

/// O dia até agora: cada refeição lançada, na hora em que foi.
class _DayTimeline extends StatelessWidget {
  const _DayTimeline({required this.entries, required this.colors});

  final List<DiaryEntry> entries;
  final BlockColors colors;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final shown = entries.take(_maxRows).toList();

    return GlassPanel(
      radius: Radii.xlAll,
      // **Este é o único cartão da Hoje que borra de verdade**, e é o único que precisa: ele
      // desliza por cima do anel e dos cartões, e é o que passa por trás dele que faz o vidro
      // parecer vidro em vez de um cinza mais claro.
      blur: true,
      padding: const EdgeInsets.fromLTRB(
        Space.lg,
        Space.md,
        Space.lg,
        Space.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'O DIA ATÉ AGORA',
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: Space.xs),
          if (shown.isEmpty)
            SizedBox(
              height: 32,
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Nada lançado ainda hoje.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            )
          else
            for (final entry in shown)
              _TimelineRow(entry: entry, colors: colors),
        ],
      ),
    );
  }
}

class _TimelineRow extends StatelessWidget {
  const _TimelineRow({required this.entry, required this.colors});

  final DiaryEntry entry;
  final BlockColors colors;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final at = DateTime.tryParse(entry.createdAt ?? '')?.toLocal();

    return SizedBox(
      height: 32,
      child: Row(
        children: [
          SizedBox(
            width: 44,
            child: Text(
              at == null ? '—' : DateFormat('HH:mm').format(at),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: colors.ink,
            ),
          ),
          const SizedBox(width: Space.sm),
          Expanded(
            child: Text(
              mealSlotName(at),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium,
            ),
          ),
          Text(
            Fmt.integer(entry.totalKcal),
            style: theme.textTheme.titleSmall?.copyWith(color: colors.ink),
          ),
        ],
      ),
    );
  }
}

/// Como a refeição se chama na linha do tempo.
///
/// **É a faixa do dia, e não uma afirmação sobre o prato.** O app não guarda nome de refeição —
/// a análise devolve calorias e macros de uma foto, não "almoço" —, e a hora é a única coisa
/// que ele sabe. Chamar de "Almoço" o que foi lançado ao meio-dia é a convenção que qualquer
/// pessoa usa ao contar o próprio dia, e é honesta enquanto for lida como horário: a linha
/// mostra a hora ao lado, e é ela que manda.
///
/// Sem hora nenhuma o nome não é chutado — "Refeição" é o que se pode dizer.
String mealSlotName(DateTime? at) {
  if (at == null) {
    return 'Refeição';
  }
  return switch (at.hour) {
    < 5 => 'Ceia',
    < 11 => 'Café da manhã',
    < 15 => 'Almoço',
    < 18 => 'Lanche',
    < 23 => 'Jantar',
    _ => 'Ceia',
  };
}
