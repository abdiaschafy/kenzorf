import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/order.dart';
import '../data/orders_repository.dart';

/// Liste des commandes du client (`GET /api/orders`).
final ordersListProvider = FutureProvider.autoDispose<List<OrderSummary>>((
  ref,
) async {
  final repo = ref.read(ordersRepositoryProvider);
  return repo.list();
});

/// Détail d'une commande (`GET /api/orders/{id}`).
final orderDetailProvider = FutureProvider.autoDispose.family<Order, String>((
  ref,
  id,
) async {
  final repo = ref.read(ordersRepositoryProvider);
  return repo.byId(id);
});
