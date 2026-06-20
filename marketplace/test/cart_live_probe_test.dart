// Probe d'intégration RÉSEAU (manuel) — exerce le vrai chemin client
// (Dio + CartRepository + parsing des modèles + ApiException) contre l'API
// KENZORF locale, pour prouver que le flux panier fonctionne et que les erreurs
// sont traduisibles (jamais d'écran rouge).
//
// Nécessite l'API sur http://localhost:8098 et le seed démo. À lancer
// explicitement (exclu de la suite unitaire sans réseau) :
//
//   PUB_CACHE=/Users/abdiaschafanglontchi/kenzorf/.pub-cache-local \
//   flutter test test/cart_live_probe_test.dart
//
// Tag `live` : `flutter test` (sans cible) saute ce fichier via dart_test.yaml.
@Tags(['live'])
library;

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kenzorf_marketplace/core/api/api_exception.dart';
import 'package:kenzorf_marketplace/core/models/cart.dart';
import 'package:kenzorf_marketplace/core/models/product.dart';
import 'package:kenzorf_marketplace/features/cart/data/cart_repository.dart';

const _base = 'http://localhost:8098/api';
const _email = 'fatoumata@kenzorf.com';
const _password = 'Password123!';

void main() {
  test('flux panier complet contre l\'API durcie (add/update/remove/erreur)',
      () async {
    final dio = Dio(
      BaseOptions(
        baseUrl: _base,
        headers: {'Accept-Language': 'fr'},
        validateStatus: (s) => s != null && s < 400,
      ),
    );

    // 1. Login (récupère le JWT comme le ferait AuthRepository).
    final login = await dio.post<Map<String, dynamic>>(
      '/auth/login',
      data: {'email': _email, 'password': _password},
    );
    final token = login.data!['accessToken'] as String;
    dio.options.headers['Authorization'] = 'Bearer $token';

    final repo = CartRepository(dio);

    // 2. Récupère un produit + une variante en stock.
    final products = await dio.get<Map<String, dynamic>>(
      '/products',
      queryParameters: {'pageSize': 5},
    );
    final firstSlug = (products.data!['items'] as List).first['slug'] as String;
    final detailRes =
        await dio.get<Map<String, dynamic>>('/products/$firstSlug');
    final detail = ProductDetail.fromJson(detailRes.data!);
    final variant = detail.variants.firstWhere(
      (v) => v.inStock,
      orElse: () => detail.variants.first,
    );

    // 3. Repart d'un panier vide pour un test déterministe.
    await repo.clear();
    Cart cart = await repo.getCart();
    expect(cart.isEmpty, isTrue, reason: 'panier non vide après clear');

    // 4. AJOUT — 200 + panier cohérent (parsing FCFA float -> int OK).
    cart = await repo.addItem(productVariantId: variant.id, quantity: 1);
    expect(cart.totalQuantity, 1);
    expect(cart.items.length, 1);
    final line = cart.items.first;
    expect(line.unitPrice, greaterThan(0));
    expect(line.lineTotal, line.unitPrice);

    // 5. MAJ quantité → 2.
    cart = await repo.updateItem(itemId: line.id, quantity: 2);
    expect(cart.totalQuantity, 2);
    expect(cart.subtotal, line.unitPrice * 2);

    // 6. ERREUR contrôlée — quantité > stock : ApiException traduisible
    //    (cart.quantity.max), surtout pas un crash / écran rouge.
    Object? caught;
    try {
      await repo.addItem(
        productVariantId: variant.id,
        quantity: variant.stockQuantity + 9999,
      );
    } catch (e) {
      caught = e;
    }
    expect(caught, isA<ApiException>());
    expect((caught as ApiException).messageKey, 'cart.quantity.max');

    // 7. SUPPRESSION → panier vide ; nettoyage (ne touche pas au seed).
    cart = await repo.removeItem(line.id);
    await repo.clear();

    // Trace lisible dans la sortie de test.
    // ignore: avoid_print
    print('PROBE PANIER OK — produit "${detail.name}", variante '
        '${variant.size}/${variant.color}, prix ${line.unitPrice} XOF.');
  });
}
