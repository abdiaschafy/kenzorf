import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/address.dart';
import '../../../core/models/enums.dart';
import '../../../core/models/order.dart';
import '../../orders/data/orders_repository.dart';

/// Crée la commande à partir du panier et initie le paiement KPay.
///
/// Le résultat est un [Order] dont `payment.checkoutUrl` doit être ouvert en
/// WebView. Le passage à `Paid` ne dépend QUE du webhook serveur (vérifié via
/// le polling de statut), jamais du retour navigateur (spec §7).
class CheckoutController extends Notifier<AsyncValue<Order?>> {
  @override
  AsyncValue<Order?> build() => const AsyncValue.data(null);

  OrdersRepository get _repo => ref.read(ordersRepositoryProvider);

  /// Crée la commande. Retourne l'[Order] créé (avec `checkoutUrl`) ou `null`
  /// en cas d'échec ; l'erreur est exposée via l'état.
  Future<Order?> placeOrder({
    required AddressRequest shippingAddress,
    String? customerNote,
    PaymentMethod? paymentMethod,
  }) async {
    state = const AsyncValue.loading();
    try {
      final order = await _repo.create(
        CreateOrderRequest(
          shippingAddress: shippingAddress,
          customerNote: customerNote,
          paymentMethod: paymentMethod,
        ),
      );
      state = AsyncValue.data(order);
      return order;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }

  void reset() => state = const AsyncValue.data(null);
}

final checkoutControllerProvider =
    NotifierProvider<CheckoutController, AsyncValue<Order?>>(
      CheckoutController.new,
    );
