import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';

import '../../core/widgets/empty_state.dart';
import 'data/video_models.dart';
import 'video_analysis_controller.dart';

/// Análise de execução por vídeo. Porte de `VideoAnalysisPage.tsx`.
class VideoAnalysisPage extends ConsumerWidget {
  const VideoAnalysisPage({super.key});

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

    return Scaffold(
      appBar: AppBar(title: const Text('Análise de execução')),
      body: RefreshIndicator(
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
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        child: FilledButton.icon(
          onPressed: state.running ? null : () => _start(context, ref),
          icon: const Icon(Icons.videocam_outlined),
          label: const Text('Analisar execução'),
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
        ),
      ),
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
            _OverlayPlayer(url: analysis.overlayVideoUrl!),

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

/// Reprodutor do vídeo com esqueleto.
///
/// Não toca sozinho: a lista pode ter várias análises, e vários vídeos iniciando juntos
/// gastariam dados e bateria sem ninguém pedir.
class _OverlayPlayer extends StatefulWidget {
  const _OverlayPlayer({required this.url});

  final String url;

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

  @override
  void dispose() {
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

    return AspectRatio(
      aspectRatio: controller.value.aspectRatio,
      child: GestureDetector(
        onTap: () => setState(() {
          controller.value.isPlaying ? controller.pause() : controller.play();
        }),
        child: VideoPlayer(controller),
      ),
    );
  }
}
