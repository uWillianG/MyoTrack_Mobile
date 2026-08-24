import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:myotrack/core/auth/token_store.dart';
import 'package:myotrack/core/providers.dart';
import 'package:myotrack/features/billing/billing_controller.dart';

/// A compra precisa dizer **de quem** ela é.
///
/// A loja devolve esse identificador ao servidor dentro da transação assinada e das
/// notificações de renovação. Sem ele, uma compra cuja validação nunca chegou ao backend fica
/// sem dono: a notificação diz qual assinatura mudou, e nada sobre quem a assinou.
///
/// O outro lado do teste é a recusa: a Apple exige um UUID no `appAccountToken` e rejeita a
/// compra inteira quando recebe outra coisa. Perder uma venda por causa de um identificador de
/// diagnóstico seria a pior troca possível, então fora do formato ele não vai.
void main() {
  const userId = '3f2504e0-4f89-41d3-9a0c-0305e82c3301';

  ProviderContainer container(_FakeStore store, {String? id = userId}) {
    final result = ProviderContainer(
      overrides: [
        inAppPurchaseProvider.overrideWithValue(store),
        tokenStoreProvider.overrideWithValue(_FakeTokenStore(id)),
      ],
    );
    addTearDown(result.dispose);
    return result;
  }

  /// Deixa o `_loadProduct` do `build()` terminar — sem isso não há produto para comprar.
  Future<BillingController> controller(ProviderContainer ref) async {
    final notifier = ref.read(billingControllerProvider.notifier);
    await pumpEventQueue();
    return notifier;
  }

  test('a compra leva o id da conta para a loja', () async {
    final store = _FakeStore();
    await (await controller(container(store))).buy();

    expect(store.boughtWith?.applicationUserName, userId);
    // E é o produto certo: o id da conta não pode ter passado por cima de nada.
    expect(store.boughtWith?.productDetails.id, proProductId);
  });

  test(
    'restaurar leva o mesmo id — é a mesma conta em outro aparelho',
    () async {
      final store = _FakeStore();
      await (await controller(container(store))).restore();

      expect(store.restoredWith, userId);
    },
  );

  test('id fora do formato de UUID não vai: a Apple recusaria a compra', () async {
    final store = _FakeStore();
    await (await controller(container(store, id: 'ana@exemplo.com'))).buy();

    expect(store.boughtWith?.applicationUserName, isNull);
    // A compra acontece assim mesmo. Vender sem o identificador é pior que não vender? Não:
    // a assinatura ainda é validada pelo recibo, e é só o socorro da notificação que se perde.
    expect(store.boughtWith, isNotNull);
  });

  test('sem sessão, a compra segue sem identificador', () async {
    final store = _FakeStore();
    await (await controller(container(store, id: null))).buy();

    expect(store.boughtWith?.applicationUserName, isNull);
  });
}

/// Só o que o controller usa; o resto explode se alguém encostar.
class _FakeStore implements InAppPurchase {
  final StreamController<List<PurchaseDetails>> _purchases =
      StreamController<List<PurchaseDetails>>.broadcast();

  PurchaseParam? boughtWith;
  String? restoredWith;

  @override
  Stream<List<PurchaseDetails>> get purchaseStream => _purchases.stream;

  @override
  Future<bool> isAvailable() async => true;

  @override
  Future<ProductDetailsResponse> queryProductDetails(
    Set<String> identifiers,
  ) async => ProductDetailsResponse(
    productDetails: [
      ProductDetails(
        id: proProductId,
        title: 'MyoTrack Pro',
        description: 'Assinatura mensal',
        price: 'R\$ 24,90',
        rawPrice: 24.9,
        currencyCode: 'BRL',
      ),
    ],
    notFoundIDs: const [],
  );

  @override
  Future<bool> buyNonConsumable({required PurchaseParam purchaseParam}) async {
    boughtWith = purchaseParam;
    return true;
  }

  @override
  Future<void> restorePurchases({String? applicationUserName}) async {
    restoredWith = applicationUserName;
  }

  @override
  Future<void> completePurchase(PurchaseDetails purchase) async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeTokenStore extends TokenStore {
  _FakeTokenStore(this._userId);

  final String? _userId;

  @override
  Future<String?> userId() async => _userId;
}
