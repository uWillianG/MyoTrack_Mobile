import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../dashboard/dashboard_controller.dart';
import '../diary/data/diary_models.dart';
import '../diary/diary_controller.dart';
import '../profile/data/profile_models.dart';
import '../profile/onboarding_controller.dart';
import 'achievement.dart';
import 'data/rewards_repository.dart';

/// O que a tela de conquistas mostra.
class AchievementsState {
  const AchievementsState({required this.all, required this.unseen});

  final List<Achievement> all;

  /// Conquistadas que o aparelho ainda não comemorou. É o que vira o cartão na Hoje e o
  /// selo "Novo" na lista.
  final Set<String> unseen;

  List<Achievement> get earned => [
    for (final a in all)
      if (a.earned) a,
  ];

  /// As trancadas, da mais perto de fechar para a mais longe. A ordem é o conselho: a
  /// primeira da lista é a que vale perseguir esta semana.
  List<Achievement> get locked => [
    for (final a in all)
      if (!a.earned) a,
  ]..sort((a, b) => b.ratio.compareTo(a.ratio));

  static const empty = AchievementsState(all: [], unseen: {});
}

/// Quais conquistas já foram comemoradas neste aparelho.
///
/// Um notifier, e não um `StreamProvider` sobre o `watch()` do drift. O stream funcionaria —
/// e foi a primeira versão —, mas ele só teria uma escritora (esta classe) e, em troca,
/// deixava uma assinatura viva que o drift fecha com um timer de duração zero: em teste de
/// widget isso vira "Pending timers" no fim de cada caso. Ler uma vez e atualizar o estado
/// na própria escrita entrega a mesma reatividade sem a assinatura.
class SeenAchievements extends AsyncNotifier<Set<String>> {
  @override
  Future<Set<String>> build() =>
      ref.read(localDatabaseProvider).seenAchievementIds();

  Future<void> markSeen(Iterable<String> ids) async {
    if (ids.isEmpty) {
      return;
    }
    await ref.read(localDatabaseProvider).markAchievementsSeen(ids);
    state = AsyncData({...?state.valueOrNull, ...ids});
  }
}

final seenAchievementsProvider =
    AsyncNotifierProvider<SeenAchievements, Set<String>>(SeenAchievements.new);

/// Os dados agregados que a avaliação consome, montados a partir do que as telas já pedem.
///
/// Reusa `dashboardStatsProvider` e `diaryDayProvider` de propósito: são as mesmas chamadas
/// que a Hoje e a Nutrição fazem, então abrir as conquistas não custa uma rodada de rede
/// nova — o Riverpod entrega o valor já em cache.
final achievementInputProvider = FutureProvider<AchievementInput>((ref) async {
  final stats = await ref.watch(dashboardStatsProvider.future);

  // A sequência e o prêmio vêm do servidor, que é quem paga por eles. Falha aqui devolve o
  // estado vazio (o provider já engole o erro): as conquistas de sequência ficam sem número,
  // as outras dez continuam de pé.
  final rewards = await ref.watch(rewardStatusProvider.future);

  // Diário e perfil são acessórios: sem eles as conquistas de nutrição e de semana cheia
  // ficam sem alvo, mas as de treino continuam válidas. Derrubar a tela inteira porque o
  // diário não respondeu seria desproporcional.
  DiaryDay? day;
  try {
    day = await ref.watch(diaryDayProvider.future);
  } catch (_) {
    day = null;
  }

  UserProfile? profile;
  try {
    profile = await ref.watch(userProfileProvider.future);
  } catch (_) {
    profile = null;
  }

  return AchievementInput(
    weeklySessions: [for (final w in stats.weeklyVolume) w.sessions],
    weeklyVolumeKg: [for (final w in stats.weeklyVolume) w.volumeKg],
    streakWeeks: rewards.streakWeeks,
    proDaysByMilestone: {for (final m in rewards.milestones) m.id: m.proDays},
    alreadyGranted: rewards.granted,
    records: stats.records.length,
    weighIns: stats.weightSeries.length,
    trainingDaysGoal: profile?.trainingDaysPerWeek,
    diaryWeekKcal: [
      for (final d in day?.week ?? const <DiaryDayTotal>[]) d.kcal,
    ],
    kcalTarget: day?.targets?.kcal,
  );
});

final achievementsProvider = FutureProvider<AchievementsState>((ref) async {
  final input = await ref.watch(achievementInputProvider.future);
  final seen = await ref.watch(seenAchievementsProvider.future);
  final all = evaluateAchievements(input);

  return AchievementsState(
    all: all,
    unseen: {
      for (final a in all)
        if (a.earned && !seen.contains(a.id)) a.id,
    },
  );
});

/// Quantas conquistas novas esperam ser vistas — é o que o cartão da Hoje observa.
///
/// Devolve zero em qualquer falha: o hub não pode deixar de carregar porque a contagem de
/// conquistas não veio.
final unseenAchievementsProvider = Provider<int>(
  (ref) => ref.watch(achievementsProvider).valueOrNull?.unseen.length ?? 0,
);
