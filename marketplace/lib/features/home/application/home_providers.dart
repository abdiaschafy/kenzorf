import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/category.dart';
import '../../../core/models/product.dart';
import '../../catalog/data/catalog_repository.dart';

/// Produits mis en avant pour la vitrine (`GET /api/products/featured`).
final featuredProductsProvider =
    FutureProvider.autoDispose<List<ProductListItem>>((ref) async {
      final repo = ref.read(catalogRepositoryProvider);
      return repo.featured();
    });

/// Catégories du catalogue (`GET /api/categories`).
/// Non auto-dispose : réutilisé par la vitrine et les filtres du catalogue.
final categoriesProvider = FutureProvider<List<Category>>((ref) async {
  final repo = ref.read(catalogRepositoryProvider);
  return repo.categories();
});
