import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/product.dart';
import '../../catalog/data/catalog_repository.dart';

/// Détail d'un produit par slug (`GET /api/products/{slug}`).
final productDetailProvider = FutureProvider.autoDispose
    .family<ProductDetail, String>((ref, slug) async {
      final repo = ref.read(catalogRepositoryProvider);
      return repo.productBySlug(slug);
    });
