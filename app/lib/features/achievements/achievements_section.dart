import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/design/blocks.dart';
import '../../core/design/tokens.dart';
import '../../core/widgets/blocks.dart';
import 'achievement.dart';
import 'achievements_controller.dart';
import 'data/rewards_repository.dart';

/// Conquistas: o que a evolução já rendeu, e o que está a um passo.
///
/// **Era uma tela própria e virou parte do Progresso.** As duas respondiam a mesma pergunta —
/// "estou evoluindo?" — e obrigavam a pessoa a escolher entre conferir o número e ver o que
/// ele rendeu.
///
/// A fusão criou um risco que a tela própria não tinha, e ele mandou no desenho: **abrir o
/// Progresso marca as conquistas como vistas**, e quem foi lá só olhar o peso gastaria a
/// comemoração sem ver nada. Por isso são duas peças e não uma:
///
/// - [AchievementsHighlight] mora **logo abaixo da manchete**, acima da dobra, e é ele quem
///   comemora e quem grava o "já vi". Só existe quando há novidade.
/// - [AchievementsSection] é a lista inteira, no fim da tela, onde inventário deve ficar.
///
/// Não há pop-up de parabéns pousando por cima de outra tarefa — quem está registrando uma
/// série no meio do treino não quer confete.

/// A comemoração, acima da dobra. Some quando não há nada novo.
class AchievementsHighlight extends ConsumerStatefulWidget {
  const AchievementsHighlight({super.key});

  @override
  ConsumerState<AchievementsHighlight> createState() =>
      _AchievementsHighlightState();
}

class _AchievementsHighlightState extends ConsumerState<AchievementsHighlight> {
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
    final theme = Theme.of(context);
    final colors = Blocks.award(theme.brightness);
    final state = ref.watch(achievementsProvider).valueOrNull;

    if (state == null) {
      return const SizedBox.shrink();
    }

    _celebrate(state);
    final celebrating = _celebrating ?? const <String>{};
    final grant = ref.watch(rewardStatusProvider).valueOrNull?.activeGrant;

    if (celebrating.isEmpty && grant == null) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // O Pro valendo agora vem antes de tudo: é a única coisa aqui que expira.
        if (grant != null) ...[
          _ActiveGrant(grant: grant, colors: colors),
          const SizedBox(height: Space.sm),
        ],
        if (celebrating.isNotEmpty)
          BlockSection(
            colors: colors,
            label: celebrating.length == 1
                ? 'Você desbloqueou uma conquista'
                : 'Você desbloqueou ${celebrating.length} conquistas',
            icon: Icons.celebration,
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                for (final achievement in state.earned)
                  if (celebrating.contains(achievement.id))
                    _AchievementRow(
                      achievement: achievement,
                      isNew: true,
                      colors: colors,
                    ),
              ],
            ),
          ),
      ],
    );
  }
}

/// A lista inteira, no fim da tela.
///
/// **As trancadas vêm ordenadas pela proximidade**, e não pela dificuldade. Isso é a seção
/// inteira: a primeira linha de "a caminho" é o conselho da semana — "faltam dois dias para a
/// semana cheia" faz alguém treinar hoje; um mural de cadeados não faz.
class AchievementsSection extends ConsumerWidget {
  const AchievementsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Blocks.award(Theme.of(context).brightness);

    // Falha aqui não derruba o Progresso: as conquistas são derivadas do histórico, e o resto
    // da tela continua respondendo sem elas.
    final state = ref.watch(achievementsProvider).valueOrNull;
    if (state == null || state.all.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        BlockSection(
          colors: colors,
          label: 'Conquistas',
          icon: Icons.emoji_events,
          trailing: '${state.earned.length} de ${state.all.length}',
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              if (state.locked.isNotEmpty) ...[
                _GroupLabel(
                  text: 'A caminho',
                  hint: 'da mais perto de fechar',
                  colors: colors,
                ),
                for (final achievement in state.locked)
                  _AchievementRow(
                    achievement: achievement,
                    isNew: false,
                    colors: colors,
                  ),
              ],
              if (state.earned.isNotEmpty) ...[
                _GroupLabel(text: 'Conquistadas', colors: colors),
                // Sem o selo "Novo" aqui: quem acabou de ganhar já apareceu lá em cima, e
                // repetir a marca faria a mesma conquista parecer duas.
                for (final achievement in state.earned)
                  _AchievementRow(
                    achievement: achievement,
                    isNew: false,
                    colors: colors,
                  ),
              ],
            ],
          ),
        ),
        const SizedBox(height: Space.sm),
        const _Footnote(),
      ],
    );
  }
}

/// O Pro que a constância rendeu, com o prazo à vista.
///
/// O prazo é o ponto. Um selo "você tem Pro" sem data faria a volta ao plano gratuito parecer
/// defeito — a pessoa perderia as análises de vídeo de um dia para o outro sem entender por
/// quê. Dizer quantos dias restam transforma o fim em algo previsto, e é a única forma honesta
/// de dar um prêmio que acaba.
class _ActiveGrant extends StatelessWidget {
  const _ActiveGrant({required this.grant, required this.colors});

  final ActiveGrant grant;
  final BlockColors colors;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final days = grant.daysLeft(DateTime.now());

    return Material(
      color: colors.tone,
      borderRadius: Radii.lgAll,
      child: Padding(
        padding: const EdgeInsets.all(Space.md),
        child: Row(
          children: [
            Icon(Icons.workspace_premium, color: colors.onTone),
            const SizedBox(width: Space.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Pro ativo pela sua constância',
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: colors.onTone,
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
                      color: colors.onTone.withValues(alpha: 0.85),
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

class _GroupLabel extends StatelessWidget {
  const _GroupLabel({required this.text, required this.colors, this.hint});

  final String text;
  final String? hint;
  final BlockColors colors;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        Space.md,
        Space.md,
        Space.md,
        Space.xs,
      ),
      child: Row(
        children: [
          Text(
            text,
            style: theme.textTheme.titleSmall?.copyWith(color: colors.ink),
          ),
          if (hint case final hint?) ...[
            const SizedBox(width: Space.xs),
            Expanded(
              child: Text(
                hint,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Uma conquista na lista.
///
/// A trancada mostra a barra e o "3 de 4"; a ganha troca a barra pelo visto. Nas duas o ícone
/// é o mesmo — o que muda é a cor, e não o desenho: trocar o ícone por um cadeado apagaria a
/// única pista visual do que a conquista é.
class _AchievementRow extends StatelessWidget {
  const _AchievementRow({
    required this.achievement,
    required this.isNew,
    required this.colors,
  });

  final Achievement achievement;
  final bool isNew;
  final BlockColors colors;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final earned = achievement.earned;

    return Semantics(
      label: earned
          ? '${achievement.title}, conquistada'
          : '${achievement.title}, '
                '${achievement.progressLabel(_unit) ?? 'ainda não conquistada'}',
      excludeSemantics: true,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          Space.md,
          Space.sm,
          Space.md,
          Space.sm,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: earned
                    ? colors.ink.withValues(alpha: 0.18)
                    : theme.colorScheme.surfaceContainerHigh,
                shape: BoxShape.circle,
              ),
              child: Icon(
                achievement.icon,
                size: 19,
                color: earned ? colors.ink : theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(width: Space.sm),
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
                        _Tag(
                          text: 'NOVO',
                          background: colors.ink,
                          foreground: colors.wash,
                        ),
                      ],
                      // O prêmio só é anunciado enquanto pode ser ganho: depois de concedido
                      // (uma vez por marca, para sempre) o selo sairia como promessa de algo
                      // que não vem de novo.
                      if (!earned && achievement.grantsPro) ...[
                        const SizedBox(width: Space.xs),
                        _Tag(
                          text: achievement.proDays == 30
                              ? '1 MÊS DE PRO'
                              : '${achievement.proDays} DIAS DE PRO',
                          background: theme.colorScheme.tertiaryContainer,
                          foreground: theme.colorScheme.onTertiaryContainer,
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(achievement.caption, style: theme.textTheme.bodySmall),
                  if (!earned) ...[
                    const SizedBox(height: Space.xs),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: LinearProgressIndicator(
                        value: achievement.ratio,
                        minHeight: 6,
                        color: colors.ink,
                        backgroundColor: colors.ink.withValues(alpha: 0.18),
                      ),
                    ),
                    if (achievement.progressLabel(_unit) case final label?) ...[
                      const SizedBox(height: 4),
                      Text(label, style: theme.textTheme.labelSmall),
                    ],
                  ],
                ],
              ),
            ),
          ],
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

class _Tag extends StatelessWidget {
  const _Tag({
    required this.text,
    required this.background,
    required this.foreground,
  });

  final String text;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: Space.xs, vertical: 2),
      decoration: BoxDecoration(color: background, borderRadius: Radii.pill),
      child: Text(
        text,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: foreground,
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
  Widget build(BuildContext context) => Text(
    'As conquistas são calculadas a partir do seu histórico de treino, peso e diário — elas '
    'acompanham o que está registrado. O aviso de conquista nova é deste aparelho.',
    style: Theme.of(context).textTheme.bodySmall,
  );
}
