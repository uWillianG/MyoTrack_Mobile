import '../../../core/network/api_client.dart';
import 'billing_models.dart';

/// Fala com `/api/billing`.
class BillingRepository {
  BillingRepository(this._api);

  final ApiClient _api;

  Future<SubscriptionStatus> status() async {
    final json = await _api.get<Map<String, dynamic>>('/api/billing');
    return SubscriptionStatus.fromJson(json);
  }

  /// Manda o recibo da loja para o servidor validar. Devolve o status já atualizado.
  ///
  /// [store] é `apple` ou `google`. O servidor recusa com 400 o recibo que a loja não
  /// reconhece e com 503 quando o ambiente não tem verificador configurado — nos dois casos
  /// **sem** liberar o Pro, que é o ponto: o benefício nunca vem da palavra do cliente.
  Future<SubscriptionStatus> verifyReceipt({
    required String store,
    required String receipt,
    String? productId,
  }) async {
    final json = await _api.post<Map<String, dynamic>>(
      '/api/billing/$store/verify',
      body: {'receipt': receipt, 'productId': productId},
    );
    return SubscriptionStatus.fromJson(json);
  }
}
