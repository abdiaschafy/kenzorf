import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/auth/auth_controller.dart';
import '../../../core/models/cart.dart';
import '../data/cart_repository.dart';

/// Contrôleur du panier serveur. Charge le panier quand l'utilisateur est
/// connecté, et expose des actions (ajout, mise à jour, suppression, vidage).
///
/// L'état est `AsyncValue<Cart>` : `loading` / `data` / `error` gérés par l'UI.
///
/// Robustesse — invariant clé :
/// les **mutations** (`addItem`, `updateQuantity`, `removeItem`, `clear`) ne
/// font **jamais** basculer l'état en `AsyncError` (ce qui viderait l'écran et
/// le badge). En cas d'échec, le panier courant reste affiché et une
/// [ApiException] localisable est **relevée** pour que l'appelant affiche un
/// toast. Aucune exception non typée ne s'échappe : l'UI ne voit jamais d'écran
/// d'erreur rouge sur un ajout au panier.
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

  /// Recharge le panier depuis le serveur (utilisé par le bouton "Réessayer").
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(_repo.getCart);
  }

  /// Dernière valeur connue du panier (sert de repli si l'état est en erreur).
  Cart get _currentOrEmpty => state.asData?.value ?? Cart.empty();

  /// Exécute une mutation du panier de façon sûre :
  /// - signale l'opération en cours via [cartMutationProvider] ;
  /// - applique le panier renvoyé en cas de succès ;
  /// - restaure le panier précédent et relève une [ApiException] en cas
  ///   d'échec (jamais d'`AsyncError`, jamais d'exception non typée).
  Future<void> _mutate(Future<Cart> Function() action) async {
    final previous = _currentOrEmpty;
    final mutation = ref.read(cartMutationProvider.notifier);
    mutation.begin();
    try {
      final cart = await action();
      state = AsyncValue.data(cart);
    } on ApiException {
      // Conserve le panier visible et propage l'erreur déjà localisable.
      state = AsyncValue.data(previous);
      rethrow;
    } catch (e) {
      // Toute autre erreur est normalisée pour rester traduisible côté UI.
      state = AsyncValue.data(previous);
      throw const ApiException(code: 'error.unknown', messageKey: 'error.unknown');
    } finally {
      mutation.end();
    }
  }

  /// Ajoute une variante au panier. Relève une [ApiException] localisable en
  /// cas d'échec (ex. `cart.quantity.max`) à présenter par l'appelant.
  Future<void> addItem({
    required String productVariantId,
    int quantity = 1,
  }) {
    return _mutate(
      () => _repo.addItem(
        productVariantId: productVariantId,
        quantity: quantity,
      ),
    );
  }

  /// Met à jour la quantité d'une ligne.
  Future<void> updateQuantity({
    required String itemId,
    required int quantity,
  }) {
    return _mutate(
      () => _repo.updateItem(itemId: itemId, quantity: quantity),
    );
  }

  /// Retire une ligne du panier.
  Future<void> removeItem(String itemId) {
    return _mutate(() => _repo.removeItem(itemId));
  }

  /// Vide le panier.
  Future<void> clear() {
    return _mutate(() async {
      await _repo.clear();
      return Cart.empty();
    });
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

/// Indique qu'une mutation du panier est en cours (ajout / mise à jour /
/// suppression). Permet à l'UI de désactiver les actions et d'afficher un
/// indicateur pendant l'appel réseau, sans masquer le panier courant.
class CartMutationNotifier extends Notifier<bool> {
  int _inFlight = 0;

  @override
  bool build() => false;

  void begin() {
    _inFlight++;
    state = _inFlight > 0;
  }

  void end() {
    if (_inFlight > 0) _inFlight--;
    state = _inFlight > 0;
  }
}

final cartMutationProvider = NotifierProvider<CartMutationNotifier, bool>(
  CartMutationNotifier.new,
);
