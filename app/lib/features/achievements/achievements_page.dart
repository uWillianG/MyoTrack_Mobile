import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/design/tokens.dart';
import '../../core/design/typography.dart';
import '../../core/widgets/empty_state.dart';
import '../dashboard/dashboard_controller.dart';
import '../diary/diary_controller.dart';
import 'achievement.dart';
import 'achievements_controller.dart';
import 'data/rewards_repository.dart';

/// Conquistas: o que a evolução já rendeu, e o que está a um passo.
///
/// **A lista das trancadas vem ordenada pela proximidade**, e não pela dificuldade. Isso é a
/// tela inteira: a primeira linha de "a caminho" é o conselho da semana — "faltam dois dias
/// para a semana cheia" faz alguém treinar hoje; um mural de cadeados não faz.
///
/// Abrir esta tela **é** a comemoração: o que estava novo deixa de estar quando ela fecha.
/// Não há pop-up de parabéns pousando por cima de outra tarefa — quem está registrando uma
/// série no meio do treino não quer confete.
class AchievementsPage extends ConsumerStatefulWidget {
  const AchievementsPage({super.key});

  @override
  ConsumerState<AchievementsPage> createState() => _AchievementsPageState();
}

class _AchievementsPageState extends ConsumerState<AchievementsPage> {
  /// O que estava por comemorar quando a tela abriu.
  ///
  /// Congelado no primeiro quadro de propósito: marcar como visto logo em seguida faz o
  /// provider reemitir sem nada novo, e sem esta cópia os selos "Novo" sumiriam na frente do
  /// usuário — que é justamente a comemoração que ele veio ver.
  Set<String>? _celebrating;

  void _celebrate(AchievementsState state) {
    if (_celebrating != null) {
      return;
    }
    _celebrating = state.unseen;
    if (state.unseen.isEmpty) {
      return;
    }
    // O notifier é lido agora, com o widget vivo, e usado depois: ele mora no container do
    // `ProviderScope` e a gravação sobrevive a fechar a tela no mesmo quadro em que ela
    // abriu. Um `ref.read` dentro do callback lançaria se isso acontecesse.
    final seen = ref.read(seenAchievementsProvider.notifier);
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => seen.markSeen(state.unseen),
    );
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(achievementsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Conquistas')),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => EmptyState(
          icon: Icons.cloud_off_outlined,
          title: 'Não foi possível carregar suas conquistas.',
          detail: 'Elas são calculadas a partir do seu histórico de treino.',
          action: FilledButton.tonal(
            onPressed: () => ref.invalidate(dashboardStatsProvider),
            child: const Text('Tentar de novo'),
          ),
        ),
        data: (state) {
          _celebrate(state);
          return _Body(state: state, celebrating: _celebrating ?? const {});
        },
      ),
    );
  }
}

class _Body extends ConsumerWidget {
  const _Body({required this.state, required this.celebrating});

  final AchievementsState state;
  final Set<String> celebrating;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final earned = state.earned;
    final locked = state.locked;

    return RefreshIndicator(
      // Invalida a origem, e não o provider de conquistas: elas são derivadas, então puxar
      // aqui tem de refazer as chamadas de progresso e de diário — recalcular sobre os
      // mesmos números não mudaria uma vírgula.
      onRefresh: () async {
        ref.invalidate(dashboardStatsProvider);
        ref.invalidate(diaryDayProvider);
        await ref.read(achievementsProvider.future);
      },
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
          Space.gutter,
          Space.md,
          Space.gutter,
          Space.xxl,
        ),
        children: [
          _Score(earned: earned.length, total: state.all.length),
          // O Pro valendo agora vem antes de tudo: é a única coisa nesta tela que expira.
          if (ref.watch(rewardStatusProvider).valueOrNull?.activeGrant
              case final grant?) ...[
            const SizedBox(height: Space.md),
            _ActiveGrantCard(grant: grant),
          ],
          // A novidade vem logo abaixo do placar, e com os próprios selos junto: sem isso o
          // que a pessoa acabou de ganhar ficava depois de dez itens trancados, e a
          // comemoração exigia rolar até achá-la.
          if (celebrating.isNotEmpty) ...[
            const SizedBox(height: Space.md),
            _NewBanner(count: celebrating.length),
            const SizedBox(height: Space.sm),
            for (final achievement in earned)
              if (celebrating.contains(achievement.id)) ...[
                _AchievementTile(achievement: achievement, isNew: true),
                const SizedBox(height: Space.xs),
              ],
          ],
          if (locked.isNotEmpty) ...[
            const SizedBox(height: Space.xl),
            const _SectionTitle('A caminho'),
            const SizedBox(height: Space.sm),
            for (final achievement in locked) ...[
              _AchievementTile(achievement: achievement, isNew: false),
              const SizedBox(height: Space.xs),
            ],
          ],
          if (earned.isNotEmpty) ...[
            const SizedBox(height: Space.xl),
            const _SectionTitle('Conquistadas'),
            const SizedBox(height: Space.sm),
            // Sem o selo "Novo" aqui: quem acabou de ganhar já apareceu lá em cima, e
            // repetir a marca faria a mesma conquista parecer duas.
            for (final achievement in earned) ...[
              _AchievementTile(achievement: achievement, isNew: false),
              const SizedBox(height: Space.xs),
            ],
          ],
          const SizedBox(height: Space.lg),
          const _Footnote(),
        ],
      ),
    );
  }
}

/// Quantas de quantas, com o anel de sempre.
class _Score extends StatelessWidget {
  const _Score({required this.earned, required this.total});

  final int earned;
  final int total;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(Space.lg),
        child: Row(
          children: [
            Text(
              '$earned',
              style: AppTypography.numeric(
                size: 40,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(width: Space.xs),
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                'de $total',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            const SizedBox(width: Space.md),
            Expanded(
              child: Text(
                earned == 0
                    ? 'Registre um treino para começar.'
                    : 'O que seu histórico já mostra.',
                textAlign: TextAlign.end,
                style: theme.textTheme.bodySmall,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// O Pro que a constância rendeu, com o prazo à vista.
///
/// O prazo é o ponto. Um selo "você tem Pro" sem data faria a volta ao plano gratuito parecer
/// defeito — a pessoa perderia as análises de vídeo de um dia para o outro sem entender por
/// quê. Dizer quantos dias restam transforma o fim em algo previsto, e é a única forma honesta
/// de dar um prêmio que acaba.
class _ActiveGrantCard extends StatelessWidget {
  const _ActiveGrantCard({required this.grant});

  final ActiveGrant grant;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final days = grant.daysLeft(DateTime.now());

    return Card(
      color: theme.colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(Space.lg),
        child: Row(
          children: [
            Icon(
              Icons.workspace_premium_outlined,
              color: theme.colorScheme.onPrimaryContainer,
            ),
            const SizedBox(width: Space.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Pro ativo pela sua constância',
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    switch (days) {
                      0 => 'Termina hoje. Análises e coach ampliados até lá.',
                      1 => 'Falta 1 dia. Análises e coach ampliados até lá.',
                      _ =>
                        'Faltam $days dias. Análises e coach ampliados até lá.',
                    },
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Selo do prêmio numa conquista que ainda não foi alcançada.
class _ProTag extends StatelessWidget {
  const _ProTag({required this.days});

  final int days;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: Space.xs, vertical: 2),
      decoration: BoxDecoration(
        color: theme.colorScheme.tertiaryContainer,
        borderRadius: Radii.pill,
      ),
      child: Text(
        days == 30 ? '1 MÊS DE PRO' : '$days DIAS DE PRO',
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.onTertiaryContainer,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.6,
        ),
      ),
    );
  }
}

class _NewBanner extends StatelessWidget {
  const _NewBanner({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      color: theme.colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(Space.lg),
        child: Row(
          children: [
            Icon(
              Icons.celebration_outlined,
              color: theme.colorScheme.onPrimaryContainer,
            ),
            const SizedBox(width: Space.sm),
            Expanded(
              child: Text(
                count == 1
                    ? 'Você desbloqueou uma conquista.'
                    : 'Você desbloqueou $count conquistas.',
                style: theme.textTheme.titleSmall?.copyWith(
                  color: theme.colorScheme.onPrimaryContainer,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Text(
      text.toUpperCase(),
      style: theme.textTheme.labelSmall?.copyWith(
        letterSpacing: 0.8,
        color: theme.colorScheme.onSurfaceVariant,
      ),
    );
  }
}

/// Uma conquista na lista.
///
/// A trancada mostra a barra e o "3 de 4"; a ganha troca a barra pela família a que pertence.
/// Nas duas o ícone é o mesmo — o que muda é a cor, e não o desenho: trocar o ícone por um
/// cadeado apagaria a única pista visual do que a conquista é.
class _AchievementTile extends StatelessWidget {
  const _AchievementTile({required this.achievement, required this.isNew});

  final Achievement achievement;
  final bool isNew;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final earned = achievement.earned;

    final iconBackground = earned
        ? theme.colorScheme.primaryContainer
        : theme.colorScheme.surfaceContainerHigh;
    final iconColor = earned
        ? theme.colorScheme.onPrimaryContainer
        : theme.colorScheme.onSurfaceVariant;

    return Semantics(
      label: earned
          ? '${achievement.title}, conquistada'
          : '${achievement.title}, ${achievement.progressLabel(_unit) ?? 'ainda não conquistada'}',
      excludeSemantics: true,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(Space.md),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: iconBackground,
                  shape: BoxShape.circle,
                ),
                child: Icon(achievement.icon, size: 22, color: iconColor),
              ),
              const SizedBox(width: Space.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            achievement.title,
                            style: theme.textTheme.titleSmall,
                          ),
                        ),
                        if (isNew) ...[
                          const SizedBox(width: Space.xs),
                          const _NewTag(),
                        ],
                        // O prêmio só é anunciado enquanto pode ser ganho: depois de
                        // concedido (uma vez por marca, para sempre) o selo sairia como
                        // promessa de algo que não vem de novo.
                        if (!achievement.earned && achievement.grantsPro) ...[
                          const SizedBox(width: Space.xs),
                          _ProTag(days: achievement.proDays),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(achievement.caption, style: theme.textTheme.bodySmall),
                    if (!earned) ...[
                      const SizedBox(height: Space.sm),
                      LinearProgressIndicator(
                        value: achievement.ratio,
                        minHeight: 6,
                      ),
                      if (achievement.progressLabel(_unit)
                          case final label?) ...[
                        const SizedBox(height: 6),
                        Text(label, style: theme.textTheme.labelSmall),
                      ],
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// A unidade de contagem da conquista. Vem do id porque é o que cada uma conta de fato —
  /// semanas, treinos, exercícios ou dias —, e "3 de 4 unidades" não diria nada.
  String get _unit => switch (achievement.id) {
    'semana-cheia' => 'treinos',
    'quatro-semanas' || 'doze-semanas' => 'semanas',
    'cinco-recordes' || 'quinze-recordes' => 'exercícios',
    'dez-pesagens' => 'pesagens',
    _ => 'dias',
  };
}

class _NewTag extends StatelessWidget {
  const _NewTag();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: Space.xs, vertical: 2),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary,
        borderRadius: Radii.pill,
      ),
      child: Text(
        'NOVO',
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.onPrimary,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.6,
        ),
      ),
    );
  }
}

/// De onde os números saem — e o que isso implica.
///
/// A nota é curta e explícita pelo mesmo motivo da nota do fechamento do dia: o app diz em
/// outros lugares quando algo é derivado e não guardado, e esconder isso faria alguém achar
/// que perdeu uma conquista por defeito quando o que houve foi uma sessão apagada.
class _Footnote extends StatelessWidget {
  const _Footnote();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Text(
      'As conquistas são calculadas a partir do seu histórico de treino, peso e diário — '
      'elas acompanham o que está registrado. O aviso de conquista nova é deste aparelho.',
      style: theme.textTheme.bodySmall?.copyWith(
        color: theme.colorScheme.onSurfaceVariant,
      ),
    );
  }
}
