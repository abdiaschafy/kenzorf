import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_exception.dart';
import '../../../core/models/cart.dart';

/// Accès réseau au panier `/api/cart` (Auth, Customer — spec §4).
class CartRepository {
  CartRepository(this._dio);

  final Dio _dio;

  /// `GET /api/cart` → `CartDto`.
  Future<Cart> getCart() async {
    try {
      final res = await _dio.get<Map<String, dynamic>>('/cart');
      return Cart.fromJson(res.data!);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// `POST /api/cart/items` `{ productVariantId, quantity }` → `CartDto`.
  Future<Cart> addItem({
    required String productVariantId,
    required int quantity,
  }) async {
    try {
      final res = await _dio.post<Map<String, dynamic>>(
        '/cart/items',
        data: {'productVariantId': productVariantId, 'quantity': quantity},
      );
      return Cart.fromJson(res.data!);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// `PUT /api/cart/items/{itemId}` `{ quantity }` → `CartDto`.
  Future<Cart> updateItem({
    required String itemId,
    required int quantity,
  }) async {
    try {
      final res = await _dio.put<Map<String, dynamic>>(
        '/cart/items/$itemId',
        data: {'quantity': quantity},
      );
      return Cart.fromJson(res.data!);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// `DELETE /api/cart/items/{itemId}` → `CartDto`.
  Future<Cart> removeItem(String itemId) async {
    try {
      final res = await _dio.delete<Map<String, dynamic>>(
        '/cart/items/$itemId',
      );
      return Cart.fromJson(res.data!);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// `DELETE /api/cart` → 204 (vide le panier).
  Future<void> clear() async {
    try {
      await _dio.delete<void>('/cart');
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}

final cartRepositoryProvider = Provider<CartRepository>(
  (ref) => CartRepository(ref.read(dioProvider)),
);
