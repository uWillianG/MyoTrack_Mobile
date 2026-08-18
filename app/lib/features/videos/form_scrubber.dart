import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/design/blocks.dart';
import '../../core/design/materials.dart';
import '../../core/design/tokens.dart';

/// A cabeça de leitura do vídeo, compartilhada entre a barra e a lista de correções.
///
/// **Existe para ligar as duas.** A avaliação sempre teve as duas metades — o vídeo com o
/// esqueleto e a lista do que corrigir —, e elas eram dois blocos empilhados sem relação
/// nenhuma: a lista dizia "em 0:02" e cabia ao usuário achar 0:02 numa barra de sete segundos
/// com o polegar. Com uma cabeça de leitura só, arrastar a barra **acende a correção daquele
/// instante** e tocar na correção **leva o vídeo até ele**. É a mesma informação de antes,
/// ligada nos dois sentidos.
class Playhead extends ChangeNotifier {
  double _seconds = 0;
  double _duration = 0;

  /// Onde o vídeo está, em segundos.
  double get seconds => _seconds;

  /// Quanto o vídeo dura. Zero enquanto ele não abriu.
  double get duration => _duration;

  /// Ligado pelo player quando ele existe. Nulo antes disso — e é por isso que a lista de
  /// correções só vira botão depois de o vídeo abrir: prometer "toque para ir ao instante"
  /// sem ter para onde ir é pior que não prometer nada.
  void Function(double seconds)? onSeek;

  bool get canSeek => onSeek != null && _duration > 0;

  void report({required double seconds, required double duration}) {
    if (_seconds == seconds && _duration == duration) {
      return;
    }
    _seconds = seconds;
    _duration = duration;
    notifyListeners();
  }

  void seek(double seconds) {
    onSeek?.call(seconds.clamp(0, _duration));
  }

  /// A janela em que a cabeça de leitura conta como "em cima" de uma marca.
  ///
  /// Fixa em segundos, e não uma fração da duração: o erro de execução acontece num instante
  /// de duração própria — o quadril subindo antes da barra dura o que dura —, e não encolhe
  /// porque o vídeo é mais longo.
  static const double window = 0.45;

  /// Se algum dos instantes desta correção está debaixo da cabeça de leitura.
  bool isNear(List<double> marks) =>
      marks.any((mark) => (mark - _seconds).abs() < window);
}

/// A barra do vídeo: o botão, a trilha, os instantes marcados e o cursor.
///
/// Três coisas a separam de um `Slider`:
///
/// - **Ela responde no toque, não na soltura.** Encostar já busca o instante — esperar o dedo
///   sair para reagir é o que faz uma barra parecer um controle remoto com pilha fraca.
/// - **As marcas são conteúdo**, não decoração: cada traço é um instante em que a execução
///   saiu do padrão, e é o único índice que existe num vídeo de sete segundos.
/// - **O cursor cresce enquanto é arrastado.** Sob o polegar ele fica invisível; crescer é o
///   que confirma que o app está seguindo o dedo, e não adivinhando.
class FormScrubber extends StatefulWidget {
  const FormScrubber({
    super.key,
    required this.playhead,
    required this.marks,
    required this.colors,
    required this.playing,
    required this.onTogglePlay,
  });

  final Playhead playhead;

  /// Os instantes com problema, em segundos.
  final List<double> marks;

  final BlockColors colors;
  final bool playing;
  final VoidCallback onTogglePlay;

  /// A trilha arrastável, para os testes de gesto acharem o alvo.
  static const Key trackKey = ValueKey('form-scrubber-track');

  @override
  State<FormScrubber> createState() => _FormScrubberState();
}

class _FormScrubberState extends State<FormScrubber> {
  bool _dragging = false;

  /// Qual marca estava acesa no quadro anterior, para o toque háptico soar uma vez por
  /// passagem em vez de a cada quadro.
  int _lastNear = -1;

  void _seekAt(double dx, double width) {
    final duration = widget.playhead.duration;
    if (width <= 0 || duration <= 0) {
      return;
    }
    final seconds = (dx / width).clamp(0.0, 1.0) * duration;
    widget.playhead.seek(seconds);

    final near = widget.marks.indexWhere(
      (mark) => (mark - seconds).abs() < Playhead.window,
    );
    if (near != _lastNear) {
      if (near >= 0) {
        // Uma marca passando debaixo do dedo é a única coisa nesta barra que merece toque:
        // ela é onde a pessoa está tentando parar.
        HapticFeedback.selectionClick();
      }
      _lastNear = near;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        Space.md,
        Space.sm,
        Space.md,
        Space.xs,
      ),
      child: Row(
        children: [
          GlassPanel(
            radius: Radii.smAll,
            onTap: widget.onTogglePlay,
            child: SizedBox.square(
              dimension: 44,
              child: Semantics(
                button: true,
                label: widget.playing ? 'Pausar' : 'Reproduzir',
                child: Icon(
                  widget.playing ? Icons.pause : Icons.play_arrow,
                  size: 22,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ),
          ),
          const SizedBox(width: Space.sm),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth;
                return GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  // No toque, e não na soltura.
                  onTapDown: (details) {
                    setState(() => _dragging = true);
                    _seekAt(details.localPosition.dx, width);
                  },
                  onTapUp: (_) => setState(() => _dragging = false),
                  onTapCancel: () => setState(() => _dragging = false),
                  onHorizontalDragStart: (details) {
                    setState(() => _dragging = true);
                    _seekAt(details.localPosition.dx, width);
                  },
                  onHorizontalDragUpdate: (details) =>
                      _seekAt(details.localPosition.dx, width),
                  onHorizontalDragEnd: (_) => setState(() => _dragging = false),
                  child: SizedBox(
                    // Nomeada porque é o alvo do gesto e não tem nada mais que a identifique:
                    // por tipo, o primeiro `CustomPaint` da barra é a aresta de vidro do botão
                    // de play.
                    key: FormScrubber.trackKey,
                    // 44 dp de alvo para uma trilha de 5: o dedo não acerta 5 dp, e errar
                    // aqui significa buscar o instante errado.
                    height: 44,
                    child: AnimatedBuilder(
                      animation: widget.playhead,
                      builder: (context, _) => CustomPaint(
                        size: Size(width, 44),
                        painter: _TrackPainter(
                          progress: widget.playhead.duration <= 0
                              ? 0
                              : (widget.playhead.seconds /
                                        widget.playhead.duration)
                                    .clamp(0.0, 1.0),
                          marks: [
                            for (final mark in widget.marks)
                              if (widget.playhead.duration > 0 &&
                                  mark <= widget.playhead.duration)
                                mark / widget.playhead.duration,
                          ],
                          track: theme.colorScheme.onSurface.withValues(
                            alpha: 0.12,
                          ),
                          fill: widget.colors.ink,
                          mark: theme.colorScheme.error,
                          knob: theme.colorScheme.onSurface,
                          knobScale: _dragging ? 1.25 : 1,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(width: Space.sm),
          AnimatedBuilder(
            animation: widget.playhead,
            builder: (context, _) => Text(
              _clock(widget.playhead.seconds),
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
        ],
      ),
    );
  }

  static String _clock(double seconds) {
    final total = seconds.round();
    return '${total ~/ 60}:${(total % 60).toString().padLeft(2, '0')}';
  }
}

class _TrackPainter extends CustomPainter {
  const _TrackPainter({
    required this.progress,
    required this.marks,
    required this.track,
    required this.fill,
    required this.mark,
    required this.knob,
    required this.knobScale,
  });

  final double progress;

  /// Os instantes, já como fração da duração.
  final List<double> marks;

  final Color track;
  final Color fill;
  final Color mark;
  final Color knob;
  final double knobScale;

  @override
  void paint(Canvas canvas, Size size) {
    final middle = size.height / 2;
    final x = progress * size.width;

    canvas.drawRRect(
      RRect.fromLTRBR(
        0,
        middle - 2.5,
        size.width,
        middle + 2.5,
        const Radius.circular(3),
      ),
      Paint()..color = track,
    );
    if (x > 0) {
      canvas.drawRRect(
        RRect.fromLTRBR(
          0,
          middle - 2.5,
          x,
          middle + 2.5,
          const Radius.circular(3),
        ),
        Paint()..color = fill,
      );
    }

    for (final at in marks) {
      final mx = at * size.width;
      canvas.drawRRect(
        RRect.fromLTRBR(
          mx - 1.5,
          middle - 9.5,
          mx + 1.5,
          middle + 9.5,
          const Radius.circular(2),
        ),
        Paint()..color = mark,
      );
    }

    final radius = 11 * knobScale;
    canvas.drawCircle(
      Offset(x, middle),
      radius,
      Paint()
        ..color = const Color(0x80000000)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );
    canvas.drawCircle(Offset(x, middle), radius, Paint()..color = knob);
  }

  @override
  bool shouldRepaint(_TrackPainter old) =>
      old.progress != progress ||
      old.knobScale != knobScale ||
      old.marks.length != marks.length ||
      old.fill != fill;
}

/// Uma correção, ligada ao instante em que ela acontece.
///
/// **Acende sozinha quando o vídeo passa pelo erro dela**, e leva o vídeo até lá quando é
/// tocada. As duas direções importam: a primeira responde "o que foi isso que acabei de ver?",
/// a segunda, "onde foi que isso aconteceu?" — e antes o app deixava as duas com a pessoa.
class IssueRow extends StatelessWidget {
  const IssueRow({
    super.key,
    required this.playhead,
    required this.message,
    required this.marks,
    required this.colors,
  });

  final Playhead playhead;
  final String message;

  /// Os instantes desta correção, em segundos. Vazio quando o serviço não os devolveu — aí a
  /// linha continua existindo, apenas sem virar atalho.
  final List<double> marks;

  final BlockColors colors;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final error = theme.colorScheme.error;

    return AnimatedBuilder(
      animation: playhead,
      builder: (context, _) {
        // **Dentro do builder, e não fora.** A linha nasce antes do vídeo: quando ela é
        // construída, ninguém baixou arquivo nenhum e `canSeek` é falso. Lido uma vez lá
        // fora, esse falso ficaria congelado — o vídeo abriria e a correção continuaria sendo
        // um parágrafo, nunca um atalho.
        final seekable = marks.isNotEmpty && playhead.canSeek;
        final on = marks.isNotEmpty && playhead.isNear(marks);

        return Padding(
          padding: const EdgeInsets.only(top: Space.sm),
          child: AnimatedContainer(
            duration: Motion.fast,
            curve: Motion.enter,
            decoration: BoxDecoration(
              borderRadius: Radii.lgAll,
              color: on ? error.withValues(alpha: 0.13) : Colors.transparent,
              border: Border.all(
                color: on ? error.withValues(alpha: 0.55) : Colors.transparent,
                width: 1.5,
              ),
            ),
            child: Material(
              type: MaterialType.transparency,
              child: InkWell(
                borderRadius: Radii.lgAll,
                onTap: seekable
                    ? () {
                        playhead.seek(marks.first);
                        HapticFeedback.selectionClick();
                      }
                    : null,
                child: Padding(
                  padding: const EdgeInsets.all(Space.sm),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.error_outline, size: 18, color: error),
                      const SizedBox(width: Space.sm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(message, style: theme.textTheme.bodyMedium),
                            if (_detail(seekable) case final detail?)
                              Text(
                                detail,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  /// Os instantes em que o erro apareceu, e o convite ao toque quando há vídeo para onde ir.
  String? _detail(bool seekable) {
    if (marks.isEmpty) {
      return null;
    }
    final at = marks
        .map((s) {
          final total = s.round();
          return '${total ~/ 60}:${(total % 60).toString().padLeft(2, '0')}';
        })
        .join(', ');
    return seekable ? 'em $at — toque para ir ao instante' : 'em $at';
  }
}
