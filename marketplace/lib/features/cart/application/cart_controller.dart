import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/auth_controller.dart';
import '../../../core/models/cart.dart';
import '../data/cart_repository.dart';

/// Contrôleur du panier serveur. Charge le panier quand l'utilisateur est
/// connecté, et expose des actions (ajout, mise à jour, suppression, vidage).
///
/// L'état est `AsyncValue<Cart>` : `loading` / `data` / `error` gérés par l'UI.
class CartController extends AsyncNotifier<Cart> {
  CartRepository get _repo => ref.read(cartRepositoryProvider);

  @override
  Future<Cart> build() async {
    // Le panier dépend de l'authentification : un invité a un panier vide.
    final auth = ref.watch(authControllerProvider);
    if (!auth.isAuthenticated) {
      return Cart.empty();
    }
    return _repo.getCart();
  }

  /// Recharge le panier depuis le serveur.
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(_repo.getCart);
  }

  /// Ajoute une variante au panier. Lève une `ApiException` à gérer par
  /// l'appelant (ex. stock insuffisant).
  Future<void> addItem({
    required String productVariantId,
    int quantity = 1,
  }) async {
    final cart = await _repo.addItem(
      productVariantId: productVariantId,
      quantity: quantity,
    );
    state = AsyncValue.data(cart);
  }

  /// Met à jour la quantité d'une ligne.
  Future<void> updateQuantity({
    required String itemId,
    required int quantity,
  }) async {
    final cart = await _repo.updateItem(itemId: itemId, quantity: quantity);
    state = AsyncValue.data(cart);
  }

  /// Retire une ligne du panier.
  Future<void> removeItem(String itemId) async {
    final cart = await _repo.removeItem(itemId);
    state = AsyncValue.data(cart);
  }

  /// Vide le panier.
  Future<void> clear() async {
    await _repo.clear();
    state = AsyncValue.data(Cart.empty());
  }
}

/// Provider du panier.
final cartControllerProvider = AsyncNotifierProvider<CartController, Cart>(
  CartController.new,
);

/// Nombre total d'articles dans le panier (pour le badge de navigation).
final cartCountProvider = Provider<int>((ref) {
  final cart = ref.watch(cartControllerProvider);
  return cart.maybeWhen(data: (c) => c.totalQuantity, orElse: () => 0);
});
