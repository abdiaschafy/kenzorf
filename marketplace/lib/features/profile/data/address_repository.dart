import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_exception.dart';
import '../../../core/models/address.dart';

/// Accès réseau aux adresses `/api/addresses` (Auth, Customer — spec §4).
class AddressRepository {
  AddressRepository(this._dio);

  final Dio _dio;

  /// `GET /api/addresses` → `AddressDto[]`.
  Future<List<Address>> list() async {
    try {
      final res = await _dio.get<List<dynamic>>('/addresses');
      return (res.data ?? [])
          .whereType<Map<String, dynamic>>()
          .map(Address.fromJson)
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// `POST /api/addresses` `AddressRequest` → `AddressDto`.
  Future<Address> create(AddressRequest request) async {
    try {
      final res = await _dio.post<Map<String, dynamic>>(
        '/addresses',
        data: request.toJson(),
      );
      return Address.fromJson(res.data!);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// `PUT /api/addresses/{id}` `AddressRequest` → `AddressDto`.
  Future<Address> update(String id, AddressRequest request) async {
    try {
      final res = await _dio.put<Map<String, dynamic>>(
        '/addresses/$id',
        data: request.toJson(),
      );
      return Address.fromJson(res.data!);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// `DELETE /api/addresses/{id}`.
  Future<void> delete(String id) async {
    try {
      await _dio.delete<void>('/addresses/$id');
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}

final addressRepositoryProvider = Provider<AddressRepository>(
  (ref) => AddressRepository(ref.read(dioProvider)),
);
