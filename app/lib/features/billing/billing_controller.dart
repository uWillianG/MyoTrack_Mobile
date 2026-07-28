import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import '../../core/network/api_exception.dart';
import '../../core/providers.dart';
import 'data/billing_models.dart';
import 'data/billing_repository.dart';

/// Id do produto nas duas lojas. Precisa bater com o `PRO_PRODUCT_ID` do `BillingController`
/// do backend e com o cadastrado nos consoles da Apple e do Google.
const String proProductId = 'myotrack.pro.monthly';

final inAppPurchaseProvider = Provider<InAppPurchase>(
  (ref) => InAppPurchase.instance,
);

final billingRepositoryProvider = Provider<BillingRepository>(
  (ref) => BillingRepository(ref.watch(apiClientProvider)),
);

/// Plano atual, sempre vindo do servidor.
final subscriptionStatusProvider = FutureProvider<SubscriptionStatus>(
  (ref) => ref.watch(billingRepositoryProvider).status(),
);

/// Estado da tela de assinatura.
class BillingState {
  const BillingState({
    this.loadingStore = true,
    this.purchasing = false,
    this.storeAvailable = false,
    this.product,
    this.message,
    this.error,
  });

  /// Ainda consultando a loja pelo preço.
  final bool loadingStore;

  /// Compra em andamento — da abertura do diálogo até o servidor confirmar.
  final bool purchasing;

  /// A loja respondeu e o produto existe. Falso em emulador sem Play Services, em conta sem
  /// o produto liberado, ou quando o cadastro ainda não saiu da revisão.
  final bool storeAvailable;

  /// Preço já formatado pela loja, na moeda do usuário. Nunca montado pelo app: a loja
  /// aplica imposto e conversão regionais que o app não tem como reproduzir.
  final ProductDetails? product;

  final String? message;
  final String? error;

  BillingState copyWith({
    bool? loadingStore,
    bool? purchasing,
    bool? storeAvailable,
    ProductDetails? product,
    String? message,
    String? error,
  }) => BillingState(
    loadingStore: loadingStore ?? this.loadingStore,
    purchasing: purchasing ?? this.purchasing,
    storeAvailable: storeAvailable ?? this.storeAvailable,
    product: product ?? this.product,
    message: message,
    error: error,
  );
}

/// Conduz a compra da assinatura.
///
/// A regra que organiza tudo aqui: **a loja confirma o pagamento, o servidor concede o
/// benefício**. O app nunca vira Pro por conta própria — ele pega o recibo, manda para o
/// backend validar contra a loja e só então recarrega o plano. Confiar no retorno local
/// deixaria o Pro a um recibo forjado de distância.
class BillingController extends Notifier<BillingState> {
  StreamSubscription<List<PurchaseDetails>>? _purchases;

  InAppPurchase get _store => ref.read(inAppPurchaseProvider);

  @override
  BillingState build() {
    _purchases = _store.purchaseStream.listen(
      _onPurchases,
      onError: (Object error) =>
          state = state.copyWith(purchasing: false, error: '$error'),
    );
    ref.onDispose(() => _purchases?.cancel());

    unawaited(_loadProduct());
    return const BillingState();
  }

  Future<void> _loadProduct() async {
    try {
      if (!await _store.isAvailable()) {
        state = state.copyWith(loadingStore: false, storeAvailable: false);
        return;
      }

      final response = await _store.queryProductDetails({proProductId});
      final product = response.productDetails
          .where((p) => p.id == proProductId)
          .firstOrNull;

      state = state.copyWith(
        loadingStore: false,
        storeAvailable: product != null,
        product: product,
      );
    } catch (error) {
      state = state.copyWith(
        loadingStore: false,
        storeAvailable: false,
        error: 'Não foi possível falar com a loja: $error',
      );
    }
  }

  Future<void> buy() async {
    final product = state.product;
    if (product == null || state.purchasing) {
      return;
    }

    state = state.copyWith(purchasing: true, error: null, message: null);
    try {
      // Assinatura é "non consumable" nesta API: consumível é para item que se compra de
      // novo, e comprar o Pro duas vezes não faz sentido.
      await _store.buyNonConsumable(
        purchaseParam: PurchaseParam(productDetails: product),
      );
    } catch (error) {
      state = state.copyWith(purchasing: false, error: '$error');
    }
  }

  /// Recupera uma assinatura já comprada — troca de aparelho, reinstalação.
  ///
  /// As duas lojas exigem este botão em app com compra não consumível.
  Future<void> restore() async {
    state = state.copyWith(purchasing: true, error: null, message: null);
    try {
      await _store.restorePurchases();
      // O resultado chega pelo purchaseStream como `restored`; se não vier nada, a mensagem
      // abaixo é substituída lá.
      state = state.copyWith(
        purchasing: false,
        message: 'Procurando compras anteriores…',
      );
    } catch (error) {
      state = state.copyWith(purchasing: false, error: '$error');
    }
  }

  Future<void> _onPurchases(List<PurchaseDetails> purchases) async {
    for (final purchase in purchases) {
      switch (purchase.status) {
        case PurchaseStatus.pending:
          state = state.copyWith(purchasing: true);

        case PurchaseStatus.canceled:
          // Desistir não é erro: volta ao repouso, sem mensagem vermelha.
          state = state.copyWith(purchasing: false);
          await _complete(purchase);

        case PurchaseStatus.error:
          state = state.copyWith(
            purchasing: false,
            error: purchase.error?.message ?? 'A compra não foi concluída.',
          );
          await _complete(purchase);

        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          await _verify(purchase);
      }
    }
  }

  Future<void> _verify(PurchaseDetails purchase) async {
    try {
      final status = await ref
          .read(billingRepositoryProvider)
          .verifyReceipt(
            store: Platform.isIOS ? 'apple' : 'google',
            receipt: purchase.verificationData.serverVerificationData,
            productId: purchase.productID,
          );

      // A tela só muda depois da palavra do servidor.
      ref.invalidate(subscriptionStatusProvider);
      state = state.copyWith(
        purchasing: false,
        message: status.isPro
            ? 'Pro ativado. Bom treino!'
            : 'Compra registrada.',
      );
      await _complete(purchase);
    } on ApiException catch (e) {
      state = state.copyWith(purchasing: false, error: e.message);

      // Falha de rede ou servidor fora do ar: NÃO finaliza a compra. Deixá-la pendente faz a
      // loja reentregá-la na próxima abertura, e aí a validação acontece. Finalizar agora
      // perderia uma compra já paga.
      if (!e.isRetryable) {
        // Recusa definitiva (recibo inválido, produto errado): insistir só reentregaria o
        // mesmo recibo para sempre.
        await _complete(purchase);
      }
    }
  }

  /// Finalizar é obrigatório: pendência não finalizada é reentregue a cada abertura do app,
  /// e no iOS a loja continua cobrando a fila até alguém confirmar o recebimento.
  Future<void> _complete(PurchaseDetails purchase) async {
    if (purchase.pendingCompletePurchase) {
      await _store.completePurchase(purchase);
    }
  }

  void dismissMessages() => state = state.copyWith(error: null, message: null);
}

final billingControllerProvider =
    NotifierProvider<BillingController, BillingState>(BillingController.new);
