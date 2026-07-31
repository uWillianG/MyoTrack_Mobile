import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';

import '../../core/widgets/empty_state.dart';
import 'data/video_models.dart';
import 'video_analysis_controller.dart';

/// Análise de execução por vídeo. Porte de `VideoAnalysisPage.tsx`.
///
/// Rota própria (`/videos`), que é para onde aponta a notificação de análise pronta; o
/// conteúdo mora em [VideoAnalysisView] para a aba Analisar do hub diário poder mostrá-lo
/// sob a barra de título dela.
class VideoAnalysisPage extends StatelessWidget {
  const VideoAnalysisPage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Análise de execução')),
    body: const VideoAnalysisView(),
  );
}

/// A análise de execução sem a barra de título, com o botão de gravar preso embaixo.
///
/// O botão vem no fim de uma `Column` e não num `bottomNavigationBar`: dentro da aba
/// Analisar o rodapé do `Scaffold` já é a barra de navegação do app.
class VideoAnalysisView extends ConsumerWidget {
  const VideoAnalysisView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(videoAnalysisProvider);
    final controller = ref.read(videoAnalysisProvider.notifier);
    final history = ref.watch(videoHistoryProvider);

    ref.listen(videoAnalysisProvider, (previous, next) {
      if (next.error != null && next.error != previous?.error) {
        ScaffoldMessenger.of(context)
          ..clearSnackBars()
          ..showSnackBar(SnackBar(content: Text(next.error!)));
        ref.read(videoAnalysisProvider.notifier).dismissError();
      }
    });

    return Column(
      children: [
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(videoHistoryProvider);
              await ref.read(videoHistoryProvider.future);
            },
            child: history.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => EmptyState(
                icon: Icons.cloud_off_outlined,
                title: 'Não foi possível carregar suas análises.',
                detail: '$error',
                action: FilledButton.tonal(
                  onPressed: () => ref.invalidate(videoHistoryProvider),
                  child: const Text('Tentar de novo'),
                ),
              ),
              data: (analyses) => _Body(
                analyses: analyses,
                running: state.running,
                step: state.step,
                progress: controller.uploadProgress,
              ),
            ),
          ),
        ),
        SafeArea(
          top: false,
          minimum: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: FilledButton.icon(
            onPressed: state.running ? null : () => _start(context, ref),
            icon: const Icon(Icons.videocam_outlined),
            label: const Text('Analisar execução'),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
            ),
          ),
        ),
      ],
    );
  }

  /// Escolhe o exercício antes do vídeo: a heurística de avaliação é por exercício, e sem ele
  /// o servidor não teria como analisar nada.
  Future<void> _start(BuildContext context, WidgetRef ref) async {
    final exercise = await showModalBottomSheet<VideoExerciseOption>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const _ExerciseSheet(),
    );
    if (exercise == null || !context.mounted) {
      return;
    }

    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.videocam_outlined),
              title: const Text('Gravar agora'),
              subtitle: Text(
                'Até ${maxVideoDuration.inSeconds}s, de lado e com o corpo inteiro no quadro',
              ),
              onTap: () => Navigator.of(sheetContext).pop(ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.video_library_outlined),
              title: const Text('Escolher da galeria'),
              onTap: () => Navigator.of(sheetContext).pop(ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source == null) {
      return;
    }

    await ref
        .read(videoAnalysisProvider.notifier)
        .analyzeFrom(source, exercise.slug);
  }
}

class _ExerciseSheet extends ConsumerWidget {
  const _ExerciseSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final exercises = ref.watch(videoExercisesProvider);

    return SafeArea(
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.6,
        child: exercises.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => EmptyState(
            icon: Icons.cloud_off_outlined,
            title: 'Não foi possível carregar os exercícios.',
            detail: '$error',
          ),
          data: (options) => ListView(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Text(
                  'Qual exercício está no vídeo?',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              for (final option in options)
                ListTile(
                  title: Text(option.label),
                  onTap: () => Navigator.of(context).pop(option),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({
    required this.analyses,
    required this.running,
    required this.step,
    required this.progress,
  });

  final List<VideoAnalysis> analyses;
  final bool running;
  final String? step;
  final double progress;

  @override
  Widget build(BuildContext context) {
    if (analyses.isEmpty && !running) {
      return const EmptyState(
        icon: Icons.videocam_outlined,
        title: 'Nenhuma execução analisada ainda.',
        detail:
            'Grave uma série de lado, com o corpo inteiro no enquadramento.',
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      children: [
        if (running) _ProgressCard(step: step, progress: progress),
        for (final analysis in analyses) _AnalysisCard(analysis: analysis),
      ],
    );
  }
}

class _ProgressCard extends StatelessWidget {
  const _ProgressCard({required this.step, required this.progress});

  final String? step;
  final double progress;

  @override
  Widget build(BuildContext context) {
    // O upload é a etapa cuja duração depende da rede do usuário, e vídeo é grande: mostrar a
    // fração já enviada é o que impede a impressão de travado. Depois disso o tempo é do
    // servidor, e a barra fica indeterminada.
    final uploading = progress > 0 && progress < 1;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              step ?? 'Analisando…',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(value: uploading ? progress : null),
          ],
        ),
      ),
    );
  }
}

class _AnalysisCard extends StatelessWidget {
  const _AnalysisCard({required this.analysis});

  final VideoAnalysis analysis;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final notEvaluable = analysis.result.notEvaluableReason;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // O vídeo mostrado é o com esqueleto: ver onde o joelho passou da linha vale mais
          // que ler "profundidade insuficiente".
          if (analysis.overlayVideoUrl != null)
            _OverlayPlayer(
              url: analysis.overlayVideoUrl!,
              marks: [
                for (final issue in analysis.result.issues)
                  ...issue.timestampsSec,
              ],
            ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        analysis.analyzedExercise,
                        style: theme.textTheme.titleMedium,
                      ),
                    ),
                    _ScoreBadge(score: analysis.score),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${analysis.repCount} '
                  '${analysis.repCount == 1 ? 'repetição' : 'repetições'}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),

                if (notEvaluable != null && notEvaluable.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.info_outline, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            notEvaluable,
                            style: theme.textTheme.bodySmall,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                for (final issue in analysis.result.issues)
                  _Point(
                    icon: Icons.error_outline,
                    color: theme.colorScheme.error,
                    message: issue.message,
                    detail: _timestamps(issue),
                  ),
                for (final point in analysis.result.correctPoints)
                  _Point(
                    icon: Icons.check_circle_outline,
                    color: theme.colorScheme.primary,
                    message: point.message,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Os instantes em que o erro apareceu — é o que permite achar o trecho no vídeo.
  static String? _timestamps(VideoIssue issue) {
    if (issue.timestampsSec.isEmpty) {
      return null;
    }
    final marks = issue.timestampsSec.map((s) {
      final total = s.round();
      return '${total ~/ 60}:${(total % 60).toString().padLeft(2, '0')}';
    });
    return 'em ${marks.join(', ')}';
  }
}

class _ScoreBadge extends StatelessWidget {
  const _ScoreBadge({required this.score});

  final int? score;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Null não é zero: zero seria uma execução péssima, e "não deu para avaliar" é outra
    // afirmação. Mostrar 0 faria a pessoa mudar como levanta peso por causa de um vídeo ruim.
    if (score == null) {
      return Chip(
        label: const Text('Não avaliado'),
        visualDensity: VisualDensity.compact,
      );
    }

    final color = score! >= 80
        ? theme.colorScheme.primary
        : score! >= 60
        ? theme.colorScheme.tertiary
        : theme.colorScheme.error;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '$score / 100',
        style: theme.textTheme.titleMedium?.copyWith(
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _Point extends StatelessWidget {
  const _Point({
    required this.icon,
    required this.color,
    required this.message,
    this.detail,
  });

  final IconData icon;
  final Color color;
  final String message;
  final String? detail;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(message, style: theme.textTheme.bodyMedium),
                if (detail != null)
                  Text(
                    detail!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// O vídeo com o esqueleto, mais a barra que marca onde a técnica saiu do lugar.
///
/// As marcas vermelhas são os `timestampsSec` das ocorrências, e tocar numa delas leva o
/// vídeo até ali. Sem isso a lista de problemas dizia "em 0:02, 0:05" e deixava a pessoa
/// caçar o instante arrastando o vídeo — que é justamente o que ela não consegue fazer com o
/// dedo numa barra de sete segundos.
class _OverlayPlayer extends StatefulWidget {
  const _OverlayPlayer({required this.url, this.marks = const []});

  final String url;

  /// Momentos, em segundos, em que houve problema.
  final List<double> marks;

  @override
  State<_OverlayPlayer> createState() => _OverlayPlayerState();
}

class _OverlayPlayerState extends State<_OverlayPlayer> {
  VideoPlayerController? _controller;
  bool _failed = false;

  Future<void> _load() async {
    final controller = VideoPlayerController.networkUrl(Uri.parse(widget.url));
    try {
      await controller.initialize();
      await controller.setLooping(true);
      await controller.play();
      if (mounted) {
        // A barra precisa acompanhar a reprodução: sem ouvir o controller ela ficaria
        // parada no zero enquanto o vídeo corre.
        controller.addListener(_onTick);
        setState(() => _controller = controller);
      } else {
        await controller.dispose();
      }
    } catch (_) {
      // A URL é assinada e expira; falhar não pode derrubar o cartão, que ainda tem os
      // pontos de execução.
      await controller.dispose();
      if (mounted) {
        setState(() => _failed = true);
      }
    }
  }

  void _onTick() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _controller?.removeListener(_onTick);
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_failed) {
      return const SizedBox.shrink();
    }

    final controller = _controller;
    if (controller == null) {
      return AspectRatio(
        aspectRatio: 16 / 9,
        child: ColoredBox(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          child: Center(
            child: IconButton.filled(
              onPressed: _load,
              icon: const Icon(Icons.play_arrow),
              tooltip: 'Ver o vídeo com o esqueleto',
            ),
          ),
        ),
      );
    }

    final value = controller.value;

    return Column(
      children: [
        AspectRatio(
          aspectRatio: value.aspectRatio,
          child: Stack(
            alignment: Alignment.center,
            children: [
              GestureDetector(
                onTap: _togglePlay,
                child: VideoPlayer(controller),
              ),
              // O botão só aparece com o vídeo parado: em cima da execução ele taparia
              // justamente o quadril e o joelho, que é onde se olha.
              if (!value.isPlaying)
                IconButton.filled(
                  onPressed: _togglePlay,
                  icon: const Icon(Icons.play_arrow),
                  tooltip: 'Reproduzir',
                ),
            ],
          ),
        ),
        _Scrubber(
          position: value.position,
          duration: value.duration,
          marks: widget.marks,
          onSeek: (position) => controller.seekTo(position),
        ),
      ],
    );
  }

  void _togglePlay() {
    final controller = _controller;
    if (controller == null) {
      return;
    }
    controller.value.isPlaying ? controller.pause() : controller.play();
  }
}

/// Barra de progresso do vídeo, com as marcas das ocorrências.
class _Scrubber extends StatelessWidget {
  const _Scrubber({
    required this.position,
    required this.duration,
    required this.marks,
    required this.onSeek,
  });

  final Duration position;
  final Duration duration;
  final List<double> marks;
  final ValueChanged<Duration> onSeek;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final total = duration.inMilliseconds;
    final ratio = total <= 0
        ? 0.0
        : (position.inMilliseconds / total).clamp(0.0, 1.0);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Column(
        children: [
          LayoutBuilder(
            builder: (context, constraints) => SizedBox(
              height: 24,
              child: Stack(
                alignment: Alignment.centerLeft,
                children: [
                  // Arrastar em qualquer ponto da faixa busca o instante: um alvo de 24 dp
                  // de altura para uma trilha de 4, porque o dedo não acerta 4 dp.
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTapDown: (details) =>
                        _seekTo(details.localPosition.dx, constraints.maxWidth),
                    onHorizontalDragUpdate: (details) =>
                        _seekTo(details.localPosition.dx, constraints.maxWidth),
                    child: SizedBox(
                      height: 24,
                      width: constraints.maxWidth,
                      child: Center(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(2),
                          child: LinearProgressIndicator(
                            value: ratio,
                            minHeight: 4,
                          ),
                        ),
                      ),
                    ),
                  ),
                  for (final mark in marks)
                    if (total > 0 && mark * 1000 <= total)
                      Positioned(
                        left: (mark * 1000 / total) * constraints.maxWidth - 5,
                        child: _IssueMark(
                          seconds: mark,
                          onTap: () => onSeek(
                            Duration(milliseconds: (mark * 1000).round()),
                          ),
                        ),
                      ),
                ],
              ),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _clock(position),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              Text(
                _clock(duration),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _seekTo(double dx, double width) {
    if (width <= 0 || duration.inMilliseconds <= 0) {
      return;
    }
    final ratio = (dx / width).clamp(0.0, 1.0);
    onSeek(Duration(milliseconds: (duration.inMilliseconds * ratio).round()));
  }

  static String _clock(Duration duration) {
    final seconds = duration.inSeconds;
    return '${seconds ~/ 60}:${(seconds % 60).toString().padLeft(2, '0')}';
  }
}

class _IssueMark extends StatelessWidget {
  const _IssueMark({required this.seconds, required this.onTap});

  final double seconds;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Semantics(
      button: true,
      label: 'Ir para ${seconds.toStringAsFixed(1)} segundos',
      child: GestureDetector(
        onTap: onTap,
        // O alvo tocável é maior que o ponto desenhado: 10 dp de bolinha não se acerta com
        // o polegar, e errar aqui significa buscar o instante errado.
        child: SizedBox(
          width: 24,
          height: 24,
          child: Center(
            child: Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: theme.colorScheme.error,
                border: Border.all(color: theme.colorScheme.surface, width: 2),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
