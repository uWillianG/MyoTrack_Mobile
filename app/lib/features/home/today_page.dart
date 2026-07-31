import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/router.dart';
import '../dashboard/dashboard_controller.dart';
import '../diary/data/diary_models.dart';
import '../diary/diary_controller.dart';
import '../profile/data/profile_models.dart';
import '../profile/onboarding_controller.dart';
import '../progress/progress_controller.dart';
import 'today_controller.dart';

/// Hoje: o que o dia pede, em ordem de urgência.
///
/// Substitui a lista de destinos que era a home até aqui. A troca não é de estilo: a lista
/// exigia que a pessoa soubesse **o que** queria antes de abrir o app, e quem abre no meio da
/// tarde quer saber quanto ainda pode comer e se já treinou. Os destinos não sumiram — foram
/// para a folha do avatar, na barra superior.
///
/// Cada cartão só aparece quando tem o que dizer. Cartão com traço no lugar do número parece
/// defeito, e a tela inteira em esqueleto de carregamento faria o app parecer lento mesmo
/// quando só uma das chamadas demorou.
class TodayView extends ConsumerWidget {
  const TodayView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(diaryDayProvider);
        ref.invalidate(dashboardStatsProvider);
        ref.invalidate(nextWorkoutProvider);
        ref.invalidate(pendingReviewsProvider);
        await ref.read(diaryDayProvider.future);
      },
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
        children: const [
          _EnergyCard(),
          SizedBox(height: 16),
          _NextWorkoutCard(),
          _WeekCard(),
          SizedBox(height: 16),
          _CloseDayCard(),
          _ReviewQueueCard(),
        ],
      ),
    );
  }
}

/// Calorias e macros do dia: o anel diz quanto ainda cabe, as barras dizem de quê.
///
/// O número grande é o que **resta**, e não o que foi comido: às três da tarde a pergunta é
/// quanto ainda dá para comer, e transformar 1.476 em 624 é uma conta que ninguém deveria
/// fazer de cabeça na fila do restaurante.
class _EnergyCard extends ConsumerWidget {
  const _EnergyCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dayAsync = ref.watch(diaryDayProvider);

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: dayAsync.when(
          loading: () => const SizedBox(
            height: 104,
            child: Center(child: CircularProgressIndicator()),
          ),
          // Sem diário o hub não some: os outros cartões continuam, e este explica a falta
          // em uma linha em vez de virar um erro de tela cheia.
          error: (error, _) => _CardMessage(
            icon: Icons.cloud_off_outlined,
            message: 'Não foi possível carregar suas calorias de hoje.',
            onRetry: () => ref.invalidate(diaryDayProvider),
          ),
          data: (day) => _EnergyBody(day: day),
        ),
      ),
    );
  }
}

class _EnergyBody extends StatelessWidget {
  const _EnergyBody({required this.day});

  final DiaryDay day;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final targets = day.targets;
    final consumed = day.consumed;

    // Sem dieta gerada não há meta, e um anel contra meta zero ficaria sempre estourado. O
    // que sobra de verdadeiro é o consumido — e o caminho para ter meta.
    if (targets == null || targets.kcal <= 0) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                _integer(consumed.kcal),
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                'kcal hoje',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Gere sua dieta para o app saber quanto ainda cabe no dia.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      );
    }

    final left = math.max(0, (targets.kcal - consumed.kcal).round());
    final proteinLeft = math.max(
      0,
      (targets.proteinG - consumed.proteinG).round(),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _CalorieRing(
              consumed: consumed.kcal.toDouble(),
              target: targets.kcal.toDouble(),
              left: left,
            ),
            const SizedBox(width: 18),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        _integer(consumed.kcal),
                        style: theme.textTheme.titleMedium,
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          'de ${_integer(targets.kcal)} kcal',
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  _MiniBar(
                    label: 'P',
                    consumed: consumed.proteinG,
                    target: targets.proteinG,
                  ),
                  _MiniBar(
                    label: 'C',
                    consumed: consumed.carbsG,
                    target: targets.carbsG,
                  ),
                  _MiniBar(
                    label: 'G',
                    consumed: consumed.fatG,
                    target: targets.fatG,
                  ),
                ],
              ),
            ),
          ],
        ),
        // Uma frase só, e a que muda a próxima refeição. Proteína porque é o macro que a
        // pessoa erra por falta, e o único que a escolha do prato ainda corrige à noite.
        if (targets.proteinG > 0) ...[
          const Divider(height: 26),
          Row(
            children: [
              Icon(
                proteinLeft == 0 ? Icons.check_circle_outline : Icons.bolt,
                size: 18,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  proteinLeft == 0
                      ? 'Meta de proteína batida.'
                      : 'Faltam $proteinLeft g de proteína para bater a meta',
                  style: theme.textTheme.bodyMedium,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

/// Anel de calorias.
///
/// Satura em 100% em vez de dar a volta: passar da meta não é erro que mereça um anel
/// vermelho girando de novo, e o número no centro já conta o resto — ele zera.
class _CalorieRing extends StatelessWidget {
  const _CalorieRing({
    required this.consumed,
    required this.target,
    required this.left,
  });

  final double consumed;
  final double target;
  final int left;

  static const double _size = 104;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ratio = target <= 0 ? 0.0 : (consumed / target).clamp(0.0, 1.0);

    return SizedBox(
      width: _size,
      height: _size,
      child: Semantics(
        label: '$left quilocalorias restantes de ${target.round()}',
        child: CustomPaint(
          painter: _RingPainter(
            ratio: ratio.toDouble(),
            track: theme.colorScheme.surfaceContainerHighest,
            progress: theme.colorScheme.primary,
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // O número encolhe em vez de quebrar: com a fonte do sistema ampliada,
                // "1.476" partido em duas linhas perderia a leitura de relance.
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    NumberFormat.decimalPattern('pt_BR').format(left),
                    maxLines: 1,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Text(
                  'kcal restam',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  const _RingPainter({
    required this.ratio,
    required this.track,
    required this.progress,
  });

  final double ratio;
  final Color track;
  final Color progress;

  static const double _stroke = 10;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final center = rect.center;
    final radius = (size.shortestSide - _stroke) / 2;

    final base = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = _stroke
      ..color = track;

    canvas.drawCircle(center, radius, base);

    if (ratio <= 0) {
      return;
    }

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      // Começa no topo: é de onde qualquer pessoa espera que um mostrador circular parta.
      -math.pi / 2,
      2 * math.pi * ratio,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = _stroke
        ..strokeCap = StrokeCap.round
        ..color = progress,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.ratio != ratio || old.track != track || old.progress != progress;
}

/// Barra fina de macro, do tamanho que cabe ao lado do anel.
class _MiniBar extends StatelessWidget {
  const _MiniBar({
    required this.label,
    required this.consumed,
    required this.target,
  });

  final String label;
  final num consumed;
  final num target;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ratio = target <= 0
        ? 0.0
        : (consumed / target).clamp(0.0, 1.0).toDouble();
    final style = theme.textTheme.labelSmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(label, style: style)),
              Text('${consumed.round()} / ${target.round()} g', style: style),
            ],
          ),
          const SizedBox(height: 3),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(value: ratio, minHeight: 6),
          ),
        ],
      ),
    );
  }
}

/// O treino que a rotação sugere, e o caminho para começá-lo.
///
/// O botão leva à escolha do dia em `/treinar` em vez de já abrir o treino sugerido. A
/// diferença é de um toque, e ela existe porque a sugestão pode estar errada — quem trocou a
/// ordem da semana ou pulou um dia acharia o app teimoso se ele começasse sozinho o treino
/// errado, com as mãos já na barra.
class _NextWorkoutCard extends ConsumerWidget {
  const _NextWorkoutCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final nextAsync = ref.watch(nextWorkoutProvider);
    final next = nextAsync.valueOrNull;

    // Sem plano ativo (ou enquanto ele carrega) não há treino a oferecer, e um cartão
    // "Treinar agora" que leva a uma tela vazia é pior que cartão nenhum.
    if (next == null) {
      return const SizedBox.shrink();
    }

    final days = next.daysSince();

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.fitness_center_outlined,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(next.day.label, style: theme.textTheme.titleSmall),
                        const SizedBox(height: 2),
                        Text(
                          _workoutDetail(next.exerciseCount, next, days),
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              FilledButton.icon(
                onPressed: () => context.push(Routes.workoutMode),
                icon: const Icon(Icons.play_circle_outline),
                label: const Text('Treinar agora'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// "6 exercícios · cerca de 50 min · último há 4 dias".
  ///
  /// A recência só entra quando existe: "último há 0 dias" em quem nunca treinou este dia
  /// seria mentira, e a ausência da frase já diz que é a primeira vez.
  static String _workoutDetail(int exercises, NextWorkout next, int? days) {
    return [
      exercises == 1 ? '1 exercício' : '$exercises exercícios',
      'cerca de ${next.estimatedMinutes} min',
      if (days != null)
        switch (days) {
          0 => 'feito hoje',
          1 => 'último ontem',
          _ => 'último há $days dias',
        },
    ].join(' · ');
  }
}

/// A semana em duas leituras: quais dias tiveram treino, e como o volume vem se comportando.
///
/// As bolinhas respondem "estou mantendo o ritmo?" e as barras, "estou progredindo?". São
/// perguntas diferentes, e por isso as duas cabem no mesmo cartão sem competir. O gráfico
/// completo — peso, recordes, doze semanas — fica a um toque, em `/progresso`: aqui ele
/// gastaria meia tela para responder o que a silhueta já responde.
class _WeekCard extends ConsumerWidget {
  const _WeekCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final statsAsync = ref.watch(dashboardStatsProvider);
    final stats = statsAsync.valueOrNull;
    final streak = ref.watch(weekStreakProvider).valueOrNull;

    if (stats == null || stats.isEmpty) {
      return const SizedBox.shrink();
    }

    final weeks = stats.weeklyVolume.length <= _WeekCard._bars
        ? stats.weeklyVolume
        : stats.weeklyVolume.sublist(stats.weeklyVolume.length - _bars);
    final maxVolume = weeks.fold<double>(
      0,
      (max, w) => w.volumeKg > max ? w.volumeKg.toDouble() : max,
    );

    return Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => context.push(Routes.progress),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Expanded(
                    child: Text(
                      'Sua semana',
                      style: theme.textTheme.titleSmall,
                    ),
                  ),
                  // Contra a meta do perfil, e não solto: "3 treinos" não diz se a semana
                  // está indo bem; "3 de 4 treinos" diz. Sem perfil ainda não há meta com
                  // que comparar, e aí sobra a contagem.
                  Text(
                    _sessionsLabel(
                      stats.sessionsThisWeek,
                      ref.watch(userProfileProvider).valueOrNull,
                    ),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              if (streak != null) ...[
                const SizedBox(height: 14),
                _StreakRow(days: streak),
              ],
              if (maxVolume > 0) ...[
                const SizedBox(height: 16),
                _VolumeSparkline(weeks: weeks, max: maxVolume),
                const SizedBox(height: 6),
                Text(
                  'Volume por semana, últimas ${weeks.length} semanas — '
                  '${_formatTons(stats.volumeThisWeek)} nesta',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// Oito semanas: é o que cabe legível na largura de um celular pequeno. As doze do
  /// dashboard vivem em `/progresso`, onde o gráfico tem a tela inteira.
  static const int _bars = 8;

  /// "3 de 4 treinos", ou só "3 treinos" em quem ainda não tem perfil.
  static String _sessionsLabel(int done, UserProfile? profile) {
    final goal = profile?.trainingDaysPerWeek;
    if (goal == null || goal <= 0) {
      return done == 1 ? '1 treino' : '$done treinos';
    }
    return '$done de $goal ${goal == 1 ? 'treino' : 'treinos'}';
  }
}

class _StreakRow extends StatelessWidget {
  const _StreakRow({required this.days});

  /// Sete posições, do dia mais antigo para hoje.
  final List<bool> days;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final today = DateTime.now();

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        for (var i = 0; i < days.length; i++)
          () {
            final date = today.subtract(Duration(days: days.length - 1 - i));
            final done = days[i];
            return Column(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: done
                        ? theme.colorScheme.primary
                        : theme.colorScheme.surfaceContainerHighest,
                  ),
                  // A marca não é só cor: quem não distingue verde de cinza precisa do
                  // símbolo para saber em que dia treinou.
                  child: done
                      ? Icon(
                          Icons.check,
                          size: 16,
                          color: theme.colorScheme.onPrimary,
                        )
                      : null,
                ),
                const SizedBox(height: 6),
                Text(
                  // Sem locale explícito: o `Intl.defaultLocale` do `main` já é pt_BR, e
                  // fixá-lo aqui exigiria carregar os símbolos de data também nos testes.
                  DateFormat('E').format(date).substring(0, 1).toUpperCase(),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            );
          }(),
      ],
    );
  }
}

/// Silhueta do volume das últimas semanas.
///
/// Sem eixo, sem rótulo e sem toque: é forma, não leitura de valor. Quem quiser o número
/// abre `/progresso`, e é para lá que o cartão inteiro leva.
class _VolumeSparkline extends StatelessWidget {
  const _VolumeSparkline({required this.weeks, required this.max});

  final List<WeeklyVolume> weeks;
  final double max;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SizedBox(
      height: 64,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (var i = 0; i < weeks.length; i++) ...[
            if (i > 0) const SizedBox(width: 6),
            Expanded(
              child: Container(
                // Um mínimo de 2 dp para a semana sem treino continuar visível como
                // ausência, em vez de sumir e encurtar o gráfico.
                height: math.max(2, (weeks[i].volumeKg / max) * 64),
                decoration: BoxDecoration(
                  color: i == weeks.length - 1
                      ? theme.colorScheme.primary
                      : theme.colorScheme.primary.withValues(alpha: 0.35),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(4),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Convite para o fechamento do dia.
///
/// Fica destacado com a cor de container primária porque é a única ação da tela que o app
/// pede, e não a pessoa: tudo mais aqui responde a uma pergunta que ela já tinha.
class _CloseDayCard extends StatelessWidget {
  const _CloseDayCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: EdgeInsets.zero,
      color: theme.colorScheme.primaryContainer,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.bedtime_outlined,
                  size: 20,
                  color: theme.colorScheme.onPrimaryContainer,
                ),
                const SizedBox(width: 10),
                Text(
                  'Fechar o dia',
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Três perguntas: como o dia foi, seu peso e sua energia.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(height: 14),
            Align(
              alignment: Alignment.centerLeft,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  minimumSize: const Size(0, 40),
                  backgroundColor: theme.colorScheme.surface,
                  foregroundColor: theme.colorScheme.primary,
                ),
                onPressed: () => context.push(Routes.dayClose),
                child: const Text('Começar'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Fila de revisão. Só existe para quem revisa, e só quando há o que revisar.
class _ReviewQueueCard extends ConsumerWidget {
  const _ReviewQueueCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final pending =
        ref.watch(pendingReviewsProvider).valueOrNull ?? PendingReviews.empty;
    final total = pending.total;

    if (total == 0) {
      return const SizedBox.shrink();
    }

    final waiting = pending.daysWaiting();
    final breakdown = [
      for (final entry in pending.counts.entries)
        if (entry.value > 0) '${entry.value} ${entry.key.label.toLowerCase()}',
      // Quanto o mais antigo já esperou: quatro planos de hoje e quatro de duas semanas
      // atrás são a mesma contagem e urgências bem diferentes.
      if (waiting != null)
        switch (waiting) {
          0 => 'o mais antigo de hoje',
          1 => 'o mais antigo de ontem',
          _ => 'o mais antigo há $waiting dias',
        },
    ].join(' · ');

    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Card(
        margin: EdgeInsets.zero,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => context.push(Routes.review),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.fact_check_outlined,
                              size: 15,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Revisor',
                              style: theme.textTheme.labelMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        total == 1
                            ? '1 plano aguardando você'
                            : '$total planos aguardando você',
                        style: theme.textTheme.titleSmall,
                      ),
                      Text(
                        breakdown,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Falha de um cartão só, dentro dele mesmo.
class _CardMessage extends StatelessWidget {
  const _CardMessage({
    required this.icon,
    required this.message,
    required this.onRetry,
  });

  final IconData icon;
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Icon(icon, color: theme.colorScheme.outline),
        const SizedBox(width: 12),
        Expanded(child: Text(message, style: theme.textTheme.bodyMedium)),
        TextButton(onPressed: onRetry, child: const Text('Tentar')),
      ],
    );
  }
}

String _integer(num value) =>
    NumberFormat.decimalPattern('pt_BR').format(value.round());

/// Volume da semana em toneladas: "12,4 t".
///
/// Em kg o número da semana passa de cinco dígitos e deixa de ser lido de relance — que é a
/// única coisa que esta linha precisa fazer. Abaixo de uma tonelada continua em kg, porque
/// "0,4 t" não é como ninguém fala.
String _formatTons(double kg) => kg < 1000
    ? '${NumberFormat('#,##0', 'pt_BR').format(kg)} kg'
    : '${NumberFormat('#,##0.0', 'pt_BR').format(kg / 1000)} t';
