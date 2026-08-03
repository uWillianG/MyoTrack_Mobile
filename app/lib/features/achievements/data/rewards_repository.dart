import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/providers.dart';

/// O Pro que está valendo agora por constância.
class ActiveGrant {
  const ActiveGrant({required this.milestone, required this.expiresAt});

  /// O id da marca — o mesmo do catálogo de conquistas do app.
  final String milestone;

  final DateTime expiresAt;

  /// Quantos dias inteiros ainda restam. Zero no último dia.
  int daysLeft(DateTime now) {
    final left = expiresAt.difference(now).inHours;
    return left <= 0 ? 0 : (left / 24).floor();
  }

  static ActiveGrant? fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return null;
    }
    final expires = DateTime.tryParse('${json['expiresAt']}');
    if (expires == null) {
      return null;
    }
    return ActiveGrant(
      milestone: '${json['milestone']}',
      expiresAt: expires.toLocal(),
    );
  }
}

/// Uma marca de constância que rende Pro.
class RewardMilestone {
  const RewardMilestone({
    required this.id,
    required this.requiredWeeks,
    required this.proDays,
  });

  final String id;
  final int requiredWeeks;
  final int proDays;

  factory RewardMilestone.fromJson(Map<String, dynamic> json) =>
      RewardMilestone(
        id: '${json['id']}',
        requiredWeeks: (json['requiredWeeks'] as num?)?.toInt() ?? 0,
        proDays: (json['proDays'] as num?)?.toInt() ?? 0,
      );
}

/// A resposta de `GET /api/rewards`.
class RewardStatus {
  const RewardStatus({
    this.streakWeeks = 0,
    this.activeGrant,
    this.granted = const {},
    this.milestones = const [],
  });

  /// Semanas seguidas com treino. **Vem do servidor, e o app não a recalcula** — desde que
  /// ela concede plano pago, quem a conta precisa ser quem paga por ela.
  final int streakWeeks;

  final ActiveGrant? activeGrant;

  /// Marcas já concedidas alguma vez, mesmo as vencidas. É o que impede a tela de prometer de
  /// novo um prêmio que não vem: a concessão é uma por marca, para sempre.
  final Set<String> granted;

  final List<RewardMilestone> milestones;

  int proDaysOf(String milestoneId) {
    for (final m in milestones) {
      if (m.id == milestoneId) {
        return m.proDays;
      }
    }
    return 0;
  }

  static const empty = RewardStatus();

  factory RewardStatus.fromJson(Map<String, dynamic> json) => RewardStatus(
    streakWeeks: (json['streakWeeks'] as num?)?.toInt() ?? 0,
    activeGrant: ActiveGrant.fromJson(
      json['activeGrant'] as Map<String, dynamic>?,
    ),
    granted: {for (final id in (json['granted'] as List? ?? const [])) '$id'},
    milestones: [
      for (final m in (json['milestones'] as List? ?? const []))
        RewardMilestone.fromJson(m as Map<String, dynamic>),
    ],
  );
}

/// Consulta a recompensa por constância.
///
/// Só leitura. **Não existe "reivindicar conquista"** — o servidor reconta a sequência a partir
/// das sessões que ele guardou e concede o que for devido. Um endpoint de reivindicação seria
/// um endpoint em que o cliente afirma ter treinado doze semanas, e essa afirmação vale um mês
/// de plano pago.
class RewardsRepository {
  const RewardsRepository(this._api);

  final ApiClient _api;

  Future<RewardStatus> status() async {
    final json = await _api.get<Map<String, dynamic>>('/api/rewards');
    return RewardStatus.fromJson(json);
  }
}

final rewardsRepositoryProvider = Provider<RewardsRepository>(
  (ref) => RewardsRepository(ref.watch(apiClientProvider)),
);

/// A recompensa, ou o estado vazio quando a rede falha.
///
/// Falhar aqui não derruba as conquistas: as outras dez são derivadas do que já está em cache,
/// e só as duas de sequência ficam sem número. Uma tela de erro inteira porque o prêmio não
/// respondeu seria desproporcional — e o prêmio, quando existe, já está valendo no servidor
/// independentemente de esta chamada ter voltado.
final rewardStatusProvider = FutureProvider<RewardStatus>((ref) async {
  try {
    return await ref.watch(rewardsRepositoryProvider).status();
  } catch (_) {
    return RewardStatus.empty;
  }
});
