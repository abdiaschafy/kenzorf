import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_exception.dart';
import '../../../core/models/order.dart';

/// Accès réseau aux commandes `/api/orders` (Auth, Customer — spec §4).
class OrdersRepository {
  OrdersRepository(this._dio);

  final Dio _dio;

  /// `POST /api/orders` `CreateOrderRequest` → `OrderDto`.
  /// Crée la commande `Pending` à partir du panier ET initie le paiement KPay
  /// (la réponse porte `payment.checkoutUrl`).
  Future<Order> create(CreateOrderRequest request) async {
    try {
      final res = await _dio.post<Map<String, dynamic>>(
        '/orders',
        data: request.toJson(),
      );
      return Order.fromJson(res.data!);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// `GET /api/orders` → `OrderSummaryDto[]` (les miennes).
  Future<List<OrderSummary>> list() async {
    try {
      final res = await _dio.get<List<dynamic>>('/orders');
      return (res.data ?? [])
          .whereType<Map<String, dynamic>>()
          .map(OrderSummary.fromJson)
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// `GET /api/orders/{id}` → `OrderDto` (la mienne).
  Future<Order> byId(String id) async {
    try {
      final res = await _dio.get<Map<String, dynamic>>('/orders/$id');
      return Order.fromJson(res.data!);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// `POST /api/orders/{id}/cancel` → `OrderDto` (si `Pending`).
  Future<Order> cancel(String id) async {
    try {
      final res = await _dio.post<Map<String, dynamic>>('/orders/$id/cancel');
      return Order.fromJson(res.data!);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}

final ordersRepositoryProvider = Provider<OrdersRepository>(
  (ref) => OrdersRepository(ref.read(dioProvider)),
);
