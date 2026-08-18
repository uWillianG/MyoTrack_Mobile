import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';

import '../../core/day_groups.dart';
import '../../core/design/blocks.dart';
import '../../core/design/format.dart';
import '../../core/design/tokens.dart';
import '../../core/widgets/blocks.dart';
import '../../core/widgets/empty_state.dart';
// O relógio do app, injetável: sem ele o bloco "Hoje" do histórico mudaria de valor entre a
// captura da galeria e a execução do teste.
import '../home/today_controller.dart' show nowProvider;
import 'data/video_models.dart';
import 'form_scrubber.dart';
import 'video_analysis_controller.dart';

/// O histórico partido em dias. Ver [groupByDay], que é onde a regra mora.
List<DayGroup<VideoAnalysis>> groupAnalysesByDay(
  List<VideoAnalysis> analyses,
  DateTime now,
) => groupByDay(
  analyses,
  now,
  at: (analysis) => analysis.createdAt,
  undated: 'Execuções',
);

/// Como a execução se chama numa lista: o exercício.
///
/// Aqui o nome **vem pronto** — o servidor exige o exercício antes de analisar, e é por ele que
/// a heurística de avaliação é escolhida. Diferente da refeição, que não tem nome e precisa
/// calcular um a partir dos alimentos.
String analysisName(VideoAnalysis analysis) =>
    analysis.analyzedExercise.isEmpty ? 'Execução' : analysis.analyzedExercise;

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
          // A análise que acabou de sair chega aberta: fechada, ela seria indistinguível das
          // antigas justamente no instante em que a pessoa está esperando por ela.
          justAnalyzed: controller.result?.id,
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
    required this.justAnalyzed,
    required this.onCapture,
  });

  final List<VideoAnalysis> analyses;
  final bool running;
  final String? step;
  final double progress;
  final DateTime now;

  /// Id da análise recém-concluída, que a lista mostra aberta.
  final String? justAnalyzed;

  final ValueChanged<ImageSource> onCapture;

  @override
  Widget build(BuildContext context) {
    final colors = Blocks.workout(Theme.of(context).brightness);

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        Space.gutter,
        4,
        Space.gutter,
        32 + Space.fabClearance,
      ),
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
        for (final day in groupAnalysesByDay(analyses, now)) ...[
          const SizedBox(height: Space.sm),
          _DaySection(day: day, colors: colors, justAnalyzed: justAnalyzed),
        ],
      ],
    );
  }
}

/// Um dia do histórico: um bloco, e dentro dele uma linha por execução.
///
/// Mesma forma da metade de refeição: as execuções de um dia são facetas do mesmo assunto — o
/// que aquela pessoa treinou naquele dia —, e faceta é seção, não ladrilho (§1). O rótulo do
/// bloco carrega a data, que é a dimensão pela qual o histórico é percorrido (§18).
class _DaySection extends StatelessWidget {
  const _DaySection({
    required this.day,
    required this.colors,
    required this.justAnalyzed,
  });

  final DayGroup<VideoAnalysis> day;
  final BlockColors colors;
  final String? justAnalyzed;

  @override
  Widget build(BuildContext context) {
    final analyses = day.items;

    return BlockSection(
      colors: colors,
      label: day.label,
      icon: Icons.fitness_center,
      trailing: analyses.length == 1
          ? '1 execução'
          : '${analyses.length} execuções',
      // Zero porque o conteúdo é lista: o fio entre duas execuções precisa encostar nas bordas
      // do bloco, senão lê como sublinhado de uma delas em vez de divisa entre as duas.
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final analysis in analyses) ...[
            if (analysis != analyses.first)
              Divider(height: 1, color: colors.ink.withValues(alpha: 0.14)),
            // A chave é o id: uma análise nova entra na frente e empurra as outras, e sem ela
            // o estado de aberta/fechada ficaria preso à posição.
            _AnalysisRow(
              key: ValueKey(analysis.id),
              analysis: analysis,
              colors: colors,
              justAnalyzed: analysis.id == justAnalyzed,
            ),
          ],
        ],
      ),
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
                color: colors.onGlass,
              ),
            ),
            const SizedBox(height: Space.sm),
            Text(
              'A IA compara seu movimento com o padrão do exercício e aponta onde corrigir. '
              'Ela lê o que o quadro mostra — não substitui um profissional.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colors.onGlass.withValues(alpha: 0.85),
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
                foregroundColor: colors.onGlass,
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
        color: colors.onGlass.withValues(alpha: 0.15),
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
              color: colors.onGlass.withValues(alpha: 0.9),
            ),
            const SizedBox(width: Space.xs + 2),
            Expanded(
              child: Text(
                'De lado, corpo inteiro no quadro, '
                'até ${maxVideoDuration.inSeconds}s.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colors.onGlass.withValues(alpha: 0.9),
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
              color: colors.onGlass,
              backgroundColor: colors.onGlass.withValues(alpha: 0.25),
            ),
          ),
          const SizedBox(height: Space.sm),
          Text(
            uploading
                ? 'Enviando — ${(widget.progress * 100).round()}%.'
                : 'Quadro a quadro leva alguns minutos. Pode sair da tela.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: colors.onGlass.withValues(alpha: 0.85),
            ),
          ),
        ],
      ),
    );
  }
}

/// Uma execução no histórico: o exercício sempre, e a avaliação quando se pede.
///
/// **O vídeo não aparece de cara.** Aberto de saída, cada cartão reservava o espaço do player e
/// mantinha na tela a nota, as correções e os acertos de execuções que a pessoa nem estava
/// procurando. O que se percorre num histórico é **o que foi treinado e quanto deu**; as
/// correções são o que se lê depois de achar a série certa.
///
/// É a mesma regra da metade de refeição, e ela reforça a que esta tela já tinha: o player só
/// baixa o arquivo no toque. Agora nem o lugar dele custa espaço antes disso.
class _AnalysisRow extends StatefulWidget {
  const _AnalysisRow({
    super.key,
    required this.analysis,
    required this.colors,
    this.justAnalyzed = false,
  });

  final VideoAnalysis analysis;
  final BlockColors colors;

  /// Esta é a análise que acabou de sair do servidor. Ela nasce aberta.
  final bool justAnalyzed;

  @override
  State<_AnalysisRow> createState() => _AnalysisRowState();
}

class _AnalysisRowState extends State<_AnalysisRow> {
  late bool _open = widget.justAnalyzed;

  /// A cabeça de leitura do vídeo desta execução.
  ///
  /// Mora aqui, e não dentro do player, porque ela é justamente o que liga as duas metades da
  /// avaliação: o player escreve nela, a lista de correções lê dela, e nenhuma das duas
  /// precisa conhecer a outra.
  final Playhead _playhead = Playhead();

  @override
  void dispose() {
    _playhead.dispose();
    super.dispose();
  }

  /// A recém-analisada abre também quando a linha já existia. Só na virada: depois disso quem
  /// manda é o toque, e um rebuild qualquer não reabre o que a pessoa fechou.
  @override
  void didUpdateWidget(covariant _AnalysisRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.justAnalyzed && !oldWidget.justAnalyzed) {
      setState(() => _open = true);
    }
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [_head(context), if (_open) _evaluation(context)],
  );

  /// O que a lista mostra sempre: o exercício, a hora, a nota e as repetições.
  ///
  /// `MergeSemantics` porque as duas linhas são uma coisa só para quem ouve — separadas, o
  /// exercício e o "82 / 100" viram dois itens de lista que não se sabe se são da mesma série.
  Widget _head(BuildContext context) {
    final theme = Theme.of(context);
    final colors = widget.colors;

    return MergeSemantics(
      child: Semantics(
        button: true,
        expanded: _open,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => setState(() => _open = !_open),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: Space.md,
                vertical: Space.sm,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          analysisName(widget.analysis),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _summary(),
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
                  Icon(
                    _open ? Icons.expand_less : Icons.expand_more,
                    size: 20,
                    color: colors.ink,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// A segunda linha do cabeçalho: hora, nota e repetições.
  ///
  /// **A nota entra como número e nunca como zero.** "não avaliado" é uma afirmação sobre o
  /// vídeo; zero seria uma afirmação sobre o corpo de quem gravou, e é a linha que a pessoa lê
  /// rolando o histórico — errar aqui é pior do que errar dentro da avaliação aberta.
  String _summary() {
    final analysis = widget.analysis;
    final at = analysis.createdAt == null
        ? null
        : DateTime.tryParse(analysis.createdAt!)?.toLocal();
    final reps = analysis.repCount;

    return [
      if (at != null) Fmt.time(at),
      if (analysis.score case final score?) '$score / 100' else 'não avaliado',
      if (reps > 0) '$reps ${reps == 1 ? 'repetição' : 'repetições'}',
    ].join(' · ');
  }

  /// O que abre no toque: o vídeo com o esqueleto, a barra da nota e os dois grupos de pontos.
  ///
  /// **Sem o número da nota.** Ele está na linha logo acima, que fica visível o tempo todo. O
  /// que fica aqui é a barra — a grandeza, que é o recado que o §16 pede que a nota dê — e as
  /// repetições subiram junto com a nota para o cabeçalho.
  Widget _evaluation(BuildContext context) {
    final theme = Theme.of(context);
    final colors = widget.colors;
    final analysis = widget.analysis;
    final result = analysis.result;
    final notEvaluable = result.notEvaluableReason;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // O vídeo mostrado é o com esqueleto: ver onde o joelho passou da linha vale mais
        // que ler "profundidade insuficiente".
        if (analysis.overlayVideoUrl != null)
          _OverlayPlayer(
            url: analysis.overlayVideoUrl!,
            colors: colors,
            playhead: _playhead,
            marks: [for (final issue in result.issues) ...issue.timestampsSec],
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            Space.md,
            Space.sm,
            Space.md,
            Space.md,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (analysis.score case final score?)
                _ScoreBar(score: score, colors: colors),
              if (notEvaluable != null && notEvaluable.isNotEmpty)
                BlockNotice(message: notEvaluable, colors: colors),
              if (result.issues.isNotEmpty) ...[
                const SizedBox(height: Space.md),
                Text(
                  'O que corrigir',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colors.ink,
                    letterSpacing: 0.1,
                  ),
                ),
                // Cada correção presa ao instante dela: acende sozinha quando o vídeo passa
                // por ali, e leva o vídeo até lá quando é tocada. Ver [IssueRow].
                //
                // A única cor fora da família nesta tela, e ela não anda sozinha: o ícone tem
                // forma própria e o grupo tem título escrito. Quem não distingue vermelho de
                // índigo continua lendo "O que corrigir".
                for (final issue in result.issues)
                  IssueRow(
                    playhead: _playhead,
                    message: issue.message,
                    marks: issue.timestampsSec,
                    colors: colors,
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
    );
  }
}

/// A nota como grandeza.
///
/// **Era um chip que mudava de cor com o valor** — verde acima de 80, âmbar no meio, vermelho
/// abaixo de 60. Cor por estado é o que o sistema proíbe: a mesma família teria três
/// significados, e a nota já é um número que se lê. Quem dá o recado é o tamanho da barra.
///
/// **E o número saiu daqui** quando a lista fechou: ele vive na linha do cabeçalho, que fica
/// visível o tempo todo. O que a barra acrescenta é o que o número sozinho não diz de relance —
/// quanto falta para o fim da régua.
///
/// Nota nula não desenha barra nenhuma. Zero seria uma execução péssima, e "não deu para
/// avaliar" é outra afirmação — quem a explica é o [BlockNotice] logo abaixo.
class _ScoreBar extends StatelessWidget {
  const _ScoreBar({required this.score, required this.colors});

  final int score;
  final BlockColors colors;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: Space.xs),
    child: Semantics(
      label: 'Nota $score de 100',
      child: ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: LinearProgressIndicator(
          value: score / 100,
          minHeight: 7,
          color: colors.ink,
          backgroundColor: colors.ink.withValues(alpha: 0.18),
        ),
      ),
    ),
  );
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
    required this.playhead,
    this.marks = const [],
  });

  final String url;
  final BlockColors colors;

  /// Onde o vídeo está. O player escreve nela; a lista de correções lê dela.
  final Playhead playhead;

  /// Momentos, em segundos, em que houve problema.
  final List<double> marks;

  @override
  State<_OverlayPlayer> createState() => _OverlayPlayerState();
}

class _OverlayPlayerState extends State<_OverlayPlayer> {
  VideoPlayerController? _controller;
  bool _failed = false;
  bool _loading = false;
  bool _playing = false;

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
        // A partir daqui a lista de correções tem para onde mandar o vídeo, e as linhas dela
        // viram atalhos.
        widget.playhead.onSeek = (seconds) =>
            controller.seekTo(Duration(milliseconds: (seconds * 1000).round()));
        setState(() {
          _controller = controller;
          _loading = false;
        });
      } else {
        await controller.dispose();
      }
    } catch (_) {
      // A URL é assinada e expira; falhar não pode derrubar a avaliação, que ainda tem os
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
    final controller = _controller;
    if (!mounted || controller == null) {
      return;
    }
    final value = controller.value;
    widget.playhead.report(
      seconds: value.position.inMilliseconds / 1000,
      duration: value.duration.inMilliseconds / 1000,
    );
    // Só o botão de play depende de `setState`: a posição já viaja pela cabeça de leitura, e
    // reconstruir a avaliação inteira a cada quadro de vídeo seria o jeito mais caro possível
    // de mover um cursor.
    if (_playing != value.isPlaying) {
      setState(() => _playing = value.isPlaying);
    }
  }

  @override
  void dispose() {
    widget.playhead.onSeek = null;
    _controller?.removeListener(_onTick);
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // **Falhar em silêncio custou caro.** Sumindo, o vídeo que não abre fica idêntico ao vídeo
    // que o servidor não gerou — e a pergunta "não gerou ou não dá para ver?" não tem como ser
    // respondida de dentro do app. O recado separa as duas: se ele aparece, o arquivo existe e
    // o que falhou foi a reprodução.
    if (_failed) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(Space.md, Space.md, Space.md, 0),
        child: BlockNotice(
          message:
              'O vídeo com o esqueleto não abriu. O link expira depois de '
              'um tempo — puxe a lista para atualizar e tente de novo.',
          colors: widget.colors,
        ),
      );
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
        ClipRRect(
          borderRadius: Radii.xlAll,
          child: AspectRatio(
            aspectRatio: value.aspectRatio,
            child: Stack(
              alignment: Alignment.center,
              children: [
                GestureDetector(
                  onTap: _togglePlay,
                  child: VideoPlayer(controller),
                ),
                // O quadro pisca quando a cabeça de leitura entra num instante marcado: é o
                // que amarra a correção acesa lá embaixo ao que está acontecendo aqui em
                // cima, sem escrever nada por cima do corpo de quem gravou.
                _IssueFlash(playhead: widget.playhead, marks: widget.marks),
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
        ),
        FormScrubber(
          playhead: widget.playhead,
          marks: widget.marks,
          colors: widget.colors,
          playing: _playing,
          onTogglePlay: _togglePlay,
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

/// O piscar do quadro quando a cabeça de leitura entra num instante marcado.
///
/// **É a metade visual do que a lista de correções faz em texto.** A correção acende lá
/// embaixo; aqui em cima o quadro ganha uma moldura da cor do erro. Sem isso, arrastar a barra
/// até uma marca acende um cartão fora do campo de visão de quem está olhando o vídeo — e a
/// ligação entre as duas metades, que é o ponto inteiro, não se vê.
///
/// Uma moldura e um véu fraco, e nada desenhado por cima do corpo: marcar a articulação errada
/// exigiria saber qual é, e o serviço devolve o instante, não a coordenada.
class _IssueFlash extends StatelessWidget {
  const _IssueFlash({required this.playhead, required this.marks});

  final Playhead playhead;
  final List<double> marks;

  @override
  Widget build(BuildContext context) {
    final error = Theme.of(context).colorScheme.error;

    return IgnorePointer(
      child: AnimatedBuilder(
        animation: playhead,
        builder: (context, _) => AnimatedOpacity(
          opacity: marks.isNotEmpty && playhead.isNear(marks) ? 1 : 0,
          duration: Motion.fast,
          curve: Motion.enter,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: error.withValues(alpha: 0.12),
              border: Border.all(color: error.withValues(alpha: 0.5), width: 2),
              borderRadius: Radii.xlAll,
            ),
            child: const SizedBox.expand(),
          ),
        ),
      ),
    );
  }
}
