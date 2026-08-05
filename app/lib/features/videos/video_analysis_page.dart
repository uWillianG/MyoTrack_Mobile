import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';

import '../../core/design/blocks.dart';
import '../../core/design/format.dart';
import '../../core/design/tokens.dart';
import '../../core/design/typography.dart';
import '../../core/widgets/blocks.dart';
import '../../core/widgets/empty_state.dart';
// O relógio do app, injetável: sem ele o rótulo "Hoje" de uma análise mudaria de valor entre a
// captura da galeria e a execução do teste.
import '../home/today_controller.dart' show nowProvider;
import 'data/video_models.dart';
import 'video_analysis_controller.dart';

/// A média das notas do histórico e quantas entraram nela. Null se nenhuma entrou.
///
/// **É o número do herói, e existe justamente por não existir em nenhum cartão.** Promover a
/// nota da última execução ao bloco a mostraria duas vezes — ela continua no cartão dela, ao
/// lado do vídeo e dos pontos que a explicam. A média é o que só o conjunto sabe dizer, e é o
/// que responde "estou melhorando?", que é a pergunta pela qual se volta à tela.
///
/// **A contagem vem junto porque não é o tamanho da lista.** Notas nulas ficam de fora em vez
/// de contar como zero — "não deu para avaliar" é uma afirmação sobre o vídeo, não sobre a
/// execução —, e escrever "média de 2 execuções" quando só uma foi avaliada é uma média que o
/// usuário não consegue refazer de cabeça.
({int average, int count})? scoreAverage(List<VideoAnalysis> analyses) {
  final scores = [for (final analysis in analyses) ?analysis.score];
  if (scores.isEmpty) {
    return null;
  }
  return (
    average: (scores.reduce((a, b) => a + b) / scores.length).round(),
    count: scores.length,
  );
}

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

/// A análise de execução sem a barra de título.
///
/// **Índigo, a família do treino.** A outra metade da aba Analisar é esmeralda porque a foto do
/// prato vira caloria no diário; aqui o vídeo vira correção de execução, e quem manda na cor é
/// o destino do dado — não o segmentado que hospeda as duas.
///
/// **A captura saiu do rodapé e virou a ação do herói**, e com ela sumiu uma folha inteira: era
/// preciso escolher o exercício numa e a origem do vídeo noutra, duas decisões empilhadas antes
/// de a câmera abrir. Agora a origem é escolhida no bloco — gravar ou galeria — e só o
/// exercício, que o servidor exige, ainda pergunta.
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

    return RefreshIndicator(
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
          now: ref.read(nowProvider)(),
          onCapture: (source) => _start(context, ref, source),
        ),
      ),
    );
  }

  /// Escolhe o exercício antes do vídeo: a heurística de avaliação é por exercício, e sem ele
  /// o servidor não teria como analisar nada.
  Future<void> _start(
    BuildContext context,
    WidgetRef ref,
    ImageSource source,
  ) async {
    final exercise = await showModalBottomSheet<VideoExerciseOption>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => const _ExerciseSheet(),
    );
    if (exercise == null || !context.mounted) {
      return;
    }

    await ref
        .read(videoAnalysisProvider.notifier)
        .analyzeFrom(source, exercise.slug);
  }
}

class _Body extends StatelessWidget {
  const _Body({
    required this.analyses,
    required this.running,
    required this.step,
    required this.progress,
    required this.now,
    required this.onCapture,
  });

  final List<VideoAnalysis> analyses;
  final bool running;
  final String? step;
  final double progress;
  final DateTime now;
  final ValueChanged<ImageSource> onCapture;

  @override
  Widget build(BuildContext context) {
    final colors = Blocks.workout(Theme.of(context).brightness);

    return ListView(
      padding: const EdgeInsets.fromLTRB(Space.gutter, 4, Space.gutter, 32),
      children: [
        // A manchete é o estado do trabalho: o convite enquanto nada corre, o progresso
        // enquanto a análise acontece. Mesma mecânica da metade de refeição, e do modo treino
        // antes dela — o que muda sozinho ocupa o bloco durante o tempo em que está mudando.
        if (running)
          _ProgressHero(step: step, progress: progress, colors: colors)
        else
          _CaptureHero(
            colors: colors,
            analyses: analyses,
            onCapture: onCapture,
          ),
        for (final analysis in analyses) ...[
          const SizedBox(height: Space.sm),
          _AnalysisSection(analysis: analysis, colors: colors, now: now),
        ],
      ],
    );
  }
}

/// O convite — e o enquadramento, que é o que decide se vai dar para avaliar.
///
/// **Diz também o que a IA não faz.** Ela compara o movimento com o padrão do exercício a
/// partir do que o quadro mostra: não vê dor, não conhece a sua lesão e não substitui um
/// profissional. Sem essa linha, "nota 62" vira um veredito sobre o corpo da pessoa em vez de
/// uma leitura de um vídeo de sete segundos.
class _CaptureHero extends StatelessWidget {
  const _CaptureHero({
    required this.colors,
    required this.analyses,
    required this.onCapture,
  });

  final BlockColors colors;
  final List<VideoAnalysis> analyses;
  final ValueChanged<ImageSource> onCapture;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scored = scoreAverage(analyses);

    return HeroBlock(
      colors: colors,
      label: 'Execução',
      icon: Icons.videocam_outlined,
      action: HeroAction(
        label: 'Gravar série',
        onPressed: () => onCapture(ImageSource.camera),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (analyses.isEmpty) ...[
            Text(
              'Grave uma\nsérie.',
              style: theme.textTheme.displaySmall?.copyWith(
                color: colors.onTone,
              ),
            ),
            const SizedBox(height: Space.sm),
            Text(
              'A IA compara seu movimento com o padrão do exercício e aponta onde corrigir. '
              'Ela lê o que o quadro mostra — não substitui um profissional.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colors.onTone.withValues(alpha: 0.85),
              ),
            ),
          ] else if (scored != null)
            HeroFigure(
              value: '${scored.average}',
              unit: '/ 100',
              colors: colors,
              detail: scored.count == 1
                  ? 'nota da sua execução'
                  : 'média de ${scored.count} execuções',
            )
          else
            // Histórico só de vídeos que não deram para avaliar. Contar "0 de média" seria
            // afirmar que a execução é péssima quando o que houve foi enquadramento ruim.
            HeroFigure(
              value: '${analyses.length}',
              unit: analyses.length == 1 ? 'vídeo' : 'vídeos',
              colors: colors,
              detail: 'nenhum deu para avaliar ainda',
            ),
          const SizedBox(height: Space.sm),
          // O enquadramento fica no convite e não numa folha depois dele: é a instrução que
          // decide se o vídeo será avaliável, e ela precisa ser lida **antes** de a câmera
          // abrir. Escondida atrás de um toque, ela chegava tarde demais.
          _Framing(colors: colors),
          const SizedBox(height: Space.xs),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () => onCapture(ImageSource.gallery),
              style: TextButton.styleFrom(
                foregroundColor: colors.onTone,
                padding: EdgeInsets.zero,
                minimumSize: const Size(0, 44),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              icon: const Icon(Icons.video_library_outlined, size: 18),
              label: const Text('Escolher da galeria'),
            ),
          ),
        ],
      ),
    );
  }
}

/// As três condições do vídeo, como recado curto sobre o bloco.
class _Framing extends StatelessWidget {
  const _Framing({required this.colors});

  final BlockColors colors;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.onTone.withValues(alpha: 0.15),
        borderRadius: Radii.mdAll,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: Space.sm + 2,
          vertical: Space.sm,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.crop_free,
              size: 16,
              color: colors.onTone.withValues(alpha: 0.9),
            ),
            const SizedBox(width: Space.xs + 2),
            Expanded(
              child: Text(
                'De lado, corpo inteiro no quadro, '
                'até ${maxVideoDuration.inSeconds}s.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colors.onTone.withValues(alpha: 0.9),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Enquanto a análise corre, o herói é o trabalho em curso.
class _ProgressHero extends StatefulWidget {
  const _ProgressHero({
    required this.step,
    required this.progress,
    required this.colors,
  });

  final String? step;
  final double progress;
  final BlockColors colors;

  @override
  State<_ProgressHero> createState() => _ProgressHeroState();
}

class _ProgressHeroState extends State<_ProgressHero> {
  /// Segundos desde que a análise começou.
  ///
  /// Vídeo é analisado quadro a quadro e leva minutos. Depois do upload a barra fica
  /// indeterminada — o tempo passa a ser do servidor —, e uma barra que anda sem chegar a lugar
  /// nenhum é onde a pessoa desiste e sai da tela. O contador é o que diz que ainda está
  /// andando.
  int _seconds = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => setState(() => _seconds += 1),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = widget.colors;
    // O upload é a etapa cuja duração depende da rede do usuário, e vídeo é grande: mostrar a
    // fração já enviada é o que impede a impressão de travado. Depois disso o tempo é do
    // servidor, e aí a barra vira indeterminada em vez de fingir que sabe quanto falta.
    final uploading = widget.progress > 0 && widget.progress < 1;

    return HeroBlock(
      colors: colors,
      label: 'Analisando',
      icon: Icons.hourglass_top,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          HeroFigure(
            value: '$_seconds',
            unit: 's',
            colors: colors,
            detail: widget.step ?? 'Enviando o vídeo',
          ),
          const SizedBox(height: Space.md),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: uploading ? widget.progress : null,
              minHeight: 7,
              color: colors.onTone,
              backgroundColor: colors.onTone.withValues(alpha: 0.25),
            ),
          ),
          const SizedBox(height: Space.sm),
          Text(
            uploading
                ? 'Enviando — ${(widget.progress * 100).round()}%.'
                : 'Quadro a quadro leva alguns minutos. Pode sair da tela.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: colors.onTone.withValues(alpha: 0.85),
            ),
          ),
        ],
      ),
    );
  }
}

/// Uma execução analisada: o vídeo com o esqueleto, a nota, e o que fazer com ela.
class _AnalysisSection extends StatelessWidget {
  const _AnalysisSection({
    required this.analysis,
    required this.colors,
    required this.now,
  });

  final VideoAnalysis analysis;
  final BlockColors colors;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final result = analysis.result;
    final notEvaluable = result.notEvaluableReason;

    return BlockSection(
      colors: colors,
      label: analysis.analyzedExercise.isEmpty
          ? 'Execução'
          : analysis.analyzedExercise,
      icon: Icons.fitness_center,
      trailing: _when(analysis.createdAt, now),
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // O vídeo mostrado é o com esqueleto: ver onde o joelho passou da linha vale mais
          // que ler "profundidade insuficiente".
          if (analysis.overlayVideoUrl != null)
            _OverlayPlayer(
              url: analysis.overlayVideoUrl!,
              colors: colors,
              marks: [
                for (final issue in result.issues) ...issue.timestampsSec,
              ],
            ),
          Padding(
            padding: const EdgeInsets.all(Space.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Score(
                  score: analysis.score,
                  repCount: analysis.repCount,
                  colors: colors,
                ),
                if (notEvaluable != null && notEvaluable.isNotEmpty) ...[
                  const SizedBox(height: Space.md),
                  _Notice(message: notEvaluable, colors: colors),
                ],
                if (result.issues.isNotEmpty) ...[
                  const SizedBox(height: Space.md),
                  _PointGroup(
                    label: 'O que corrigir',
                    icon: Icons.error_outline,
                    // A única cor fora da família nesta tela, e ela não anda sozinha: o ícone
                    // tem forma própria e o grupo tem título escrito. Quem não distingue
                    // vermelho de índigo continua lendo "O que corrigir".
                    iconColor: theme.colorScheme.error,
                    colors: colors,
                    points: [
                      for (final issue in result.issues)
                        (message: issue.message, detail: _timestamps(issue)),
                    ],
                  ),
                ],
                if (result.correctPoints.isNotEmpty) ...[
                  const SizedBox(height: Space.md),
                  _PointGroup(
                    label: 'O que já está bom',
                    icon: Icons.check_circle_outline,
                    iconColor: colors.ink,
                    colors: colors,
                    points: [
                      for (final point in result.correctPoints)
                        (message: point.message, detail: null),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String? _when(String? createdAt, DateTime now) {
    final at = createdAt == null
        ? null
        : DateTime.tryParse(createdAt)?.toLocal();
    return at == null ? null : Fmt.dayTime(at, now);
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

/// A nota, como número e como barra.
///
/// **Era um chip que mudava de cor com o valor** — verde acima de 80, âmbar no meio, vermelho
/// abaixo de 60. Cor por estado é o que o sistema proíbe: a mesma família teria três
/// significados, e a nota já é um número que se lê. Quem dá o recado é o tamanho da barra.
class _Score extends StatelessWidget {
  const _Score({
    required this.score,
    required this.repCount,
    required this.colors,
  });

  final int? score;
  final int repCount;
  final BlockColors colors;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final reps = '$repCount ${repCount == 1 ? 'repetição' : 'repetições'}';

    // Null não é zero: zero seria uma execução péssima, e "não deu para avaliar" é outra
    // afirmação. Mostrar 0 faria a pessoa mudar como levanta peso por causa de um vídeo ruim.
    if (score == null) {
      return Row(
        children: [
          Expanded(
            child: Text('Não avaliado', style: theme.textTheme.titleMedium),
          ),
          Text(
            reps,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              '$score',
              style: AppTypography.numeric(size: 28, color: colors.ink),
            ),
            const SizedBox(width: Space.xs),
            Expanded(
              child: Text(
                '/ 100',
                style: theme.textTheme.titleSmall?.copyWith(color: colors.ink),
              ),
            ),
            Text(
              reps,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: score! / 100,
            minHeight: 7,
            color: colors.ink,
            backgroundColor: colors.ink.withValues(alpha: 0.18),
          ),
        ),
      ],
    );
  }
}

/// O aviso de "não deu para avaliar", com o motivo que o servidor deu.
class _Notice extends StatelessWidget {
  const _Notice({required this.message, required this.colors});

  final String message;
  final BlockColors colors;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.ink.withValues(alpha: 0.12),
        borderRadius: Radii.mdAll,
      ),
      child: Padding(
        padding: const EdgeInsets.all(Space.sm + 2),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.info_outline, size: 18, color: colors.ink),
            const SizedBox(width: Space.sm),
            Expanded(child: Text(message, style: theme.textTheme.bodySmall)),
          ],
        ),
      ),
    );
  }
}

/// Um grupo de pontos da avaliação, com título.
///
/// **Os dois grupos eram uma lista só, distinguida por cor de ícone.** Erros e acertos
/// misturados na mesma coluna leem como registro de log; separados e nomeados, viram duas
/// respostas — o que mudar na próxima série, e o que não mexer.
class _PointGroup extends StatelessWidget {
  const _PointGroup({
    required this.label,
    required this.icon,
    required this.iconColor,
    required this.colors,
    required this.points,
  });

  final String label;
  final IconData icon;
  final Color iconColor;
  final BlockColors colors;
  final List<({String message, String? detail})> points;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: colors.ink,
            letterSpacing: 0.1,
          ),
        ),
        for (final point in points)
          Padding(
            padding: const EdgeInsets.only(top: Space.sm),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, size: 18, color: iconColor),
                const SizedBox(width: Space.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(point.message, style: theme.textTheme.bodyMedium),
                      if (point.detail case final detail?)
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
      ],
    );
  }
}

/// Qual exercício está no vídeo.
///
/// Continua sendo uma pergunta e não uma adivinhação: a heurística de avaliação é por
/// exercício, e um agachamento avaliado como levantamento terra devolveria correções erradas —
/// que é pior do que não devolver nenhuma.
class _ExerciseSheet extends ConsumerWidget {
  const _ExerciseSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
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
                padding: const EdgeInsets.fromLTRB(
                  Space.gutter,
                  0,
                  Space.gutter,
                  Space.md,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Qual exercício está no vídeo?',
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: Space.xs),
                    Text(
                      'A avaliação muda com o exercício — o que é erro no agachamento é '
                      'correto no terra.',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              for (final option in options)
                ListTile(
                  title: Text(option.label),
                  trailing: const Icon(Icons.chevron_right, size: 20),
                  onTap: () => Navigator.of(context).pop(option),
                ),
            ],
          ),
        ),
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
  const _OverlayPlayer({
    required this.url,
    required this.colors,
    this.marks = const [],
  });

  final String url;
  final BlockColors colors;

  /// Momentos, em segundos, em que houve problema.
  final List<double> marks;

  @override
  State<_OverlayPlayer> createState() => _OverlayPlayerState();
}

class _OverlayPlayerState extends State<_OverlayPlayer> {
  VideoPlayerController? _controller;
  bool _failed = false;
  bool _loading = false;

  Future<void> _load() async {
    setState(() => _loading = true);
    final controller = VideoPlayerController.networkUrl(Uri.parse(widget.url));
    try {
      await controller.initialize();
      await controller.setLooping(true);
      await controller.play();
      if (mounted) {
        // A barra precisa acompanhar a reprodução: sem ouvir o controller ela ficaria
        // parada no zero enquanto o vídeo corre.
        controller.addListener(_onTick);
        setState(() {
          _controller = controller;
          _loading = false;
        });
      } else {
        await controller.dispose();
      }
    } catch (_) {
      // A URL é assinada e expira; falhar não pode derrubar o cartão, que ainda tem os
      // pontos de execução.
      await controller.dispose();
      if (mounted) {
        setState(() {
          _failed = true;
          _loading = false;
        });
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
      return _PlayerPlaceholder(
        colors: widget.colors,
        loading: _loading,
        onPlay: _load,
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
          colors: widget.colors,
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

/// O lugar do vídeo antes de ele ser baixado.
///
/// **Não carrega sozinho.** Cada vídeo do histórico são alguns MB, e uma lista que baixa todos
/// ao abrir gasta o pacote de dados de quem está na academia. O toque é o consentimento.
///
/// **É uma faixa, e não um 16:9.** Vazio, o retângulo do vídeo comia um terço da tela por
/// cartão e empurrava a nota e as correções para fora da vista — numa lista de execuções, o
/// que se percorre são as notas. A faixa diz que há vídeo ali e devolve o espaço; ao tocar, o
/// player abre na proporção verdadeira do arquivo.
class _PlayerPlaceholder extends StatelessWidget {
  const _PlayerPlaceholder({
    required this.colors,
    required this.loading,
    required this.onPlay,
  });

  final BlockColors colors;
  final bool loading;
  final VoidCallback onPlay;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SizedBox(
      height: 96,
      child: Material(
        color: colors.ink.withValues(alpha: 0.14),
        child: InkWell(
          onTap: loading ? null : onPlay,
          child: Center(
            child: loading
                ? SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: colors.ink,
                    ),
                  )
                // O rótulo encolhe: com o corpo de texto ampliado, "Ver com o esqueleto"
                // passa da largura da faixa, e uma linha cortada é melhor que a listra de
                // estouro por cima do convite.
                : Padding(
                    padding: const EdgeInsets.symmetric(horizontal: Space.md),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.play_circle_outline,
                          size: 30,
                          color: colors.ink,
                        ),
                        const SizedBox(width: Space.sm),
                        Flexible(
                          child: Text(
                            'Ver com o esqueleto',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.labelLarge?.copyWith(
                              color: colors.ink,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

/// Barra de progresso do vídeo, com as marcas das ocorrências.
class _Scrubber extends StatelessWidget {
  const _Scrubber({
    required this.position,
    required this.duration,
    required this.marks,
    required this.colors,
    required this.onSeek,
  });

  final Duration position;
  final Duration duration;
  final List<double> marks;
  final BlockColors colors;
  final ValueChanged<Duration> onSeek;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final total = duration.inMilliseconds;
    final ratio = total <= 0
        ? 0.0
        : (position.inMilliseconds / total).clamp(0.0, 1.0);

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        Space.md,
        Space.sm,
        Space.md,
        Space.xs,
      ),
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
                            color: colors.ink,
                            backgroundColor: colors.ink.withValues(alpha: 0.18),
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
