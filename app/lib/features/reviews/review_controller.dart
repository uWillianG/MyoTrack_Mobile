import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../core/network/api_client.dart';
import '../../core/providers.dart';

part 'review_controller.freezed.dart';
part 'review_controller.g.dart';

/// Um plano esperando revisão — `GET /api/reviews/{workout,diet}-plans`.
///
/// Um modelo só para os dois tipos: a fila mostra os mesmos campos, e separar em duas
/// classes idênticas dobraria a tela sem dobrar a informação.
@freezed
abstract class ReviewQueueItem with _$ReviewQueueItem {
  const factory ReviewQueueItem({
    required String id,
    @Default('') String name,
    @Default(1) int version,
    String? createdAt,

    /// E-mail do aluno: é o que diz ao revisor de quem é o plano.
    String? student,

    /// Divisão do treino (`split`) — só nos treinos.
    String? split,
    String? goal,

    /// Meta calórica — só nas dietas.
    num? targetKcal,
    String? calorieGoal,
  }) = _ReviewQueueItem;

  factory ReviewQueueItem.fromJson(Map<String, dynamic> json) =>
      _$ReviewQueueItemFromJson(json);
}

/// Qual fila está aberta.
enum ReviewKind {
  workout('workout-plans', 'Treinos'),
  diet('diet-plans', 'Dietas');

  const ReviewKind(this.path, this.label);

  final String path;
  final String label;
}

class ReviewRepository {
  ReviewRepository(this._api);

  final ApiClient _api;

  Future<List<ReviewQueueItem>> pending(ReviewKind kind) async {
    final json = await _api.get<List<dynamic>>('/api/reviews/${kind.path}');
    return json
        .map((e) => ReviewQueueItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// O detalhe vem como árvore: treino e dieta têm formatos diferentes, e a tela lê os
  /// campos que precisa em vez de exigir dois modelos gerados.
  Future<Map<String, dynamic>> detail(ReviewKind kind, String id) =>
      _api.get<Map<String, dynamic>>('/api/reviews/${kind.path}/$id');

  /// Registra a decisão. `status` é `Approved` ou `ChangesRequested`.
  Future<void> decide(
    ReviewKind kind,
    String id, {
    required String status,
    String? note,
  }) => _api.post<void>(
    '/api/reviews/${kind.path}/$id',
    body: {'status': status, 'note': note},
  );
}

final reviewRepositoryProvider = Provider<ReviewRepository>(
  (ref) => ReviewRepository(ref.watch(apiClientProvider)),
);

/// Fila atualmente aberta.
final reviewKindProvider = StateProvider<ReviewKind>(
  (ref) => ReviewKind.workout,
);

final reviewQueueProvider = FutureProvider<List<ReviewQueueItem>>(
  (ref) => ref
      .watch(reviewRepositoryProvider)
      .pending(ref.watch(reviewKindProvider)),
);

/// Quais filas este usuário pode revisar, a partir dos papéis do token.
///
/// A tela usa isso para não oferecer uma aba que o servidor recusaria com 403 — a checagem
/// de verdade continua sendo dele.
final reviewableKindsProvider = FutureProvider<List<ReviewKind>>((ref) async {
  final roles = await ref.watch(userRolesProvider.future);

  return [
    if (roles.contains('Trainer') || roles.contains('Admin'))
      ReviewKind.workout,
    if (roles.contains('Nutritionist') || roles.contains('Admin'))
      ReviewKind.diet,
  ];
});
