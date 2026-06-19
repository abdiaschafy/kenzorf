import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_exception.dart';
import '../../../core/models/payment.dart';

/// Accès réseau au statut de paiement KPay (spec §4).
///
/// Le webhook `POST /api/payments/webhook` est appelé **par KPay**, pas par
/// l'app : seul le polling du statut nous concerne ici.
class PaymentRepository {
  PaymentRepository(this._dio);

  final Dio _dio;

  /// `GET /api/payments/{reference}/status` →
  /// `{ status, orderId, orderStatus }` (polling).
  Future<PaymentStatusResult> status(String reference) async {
    try {
      final res = await _dio.get<Map<String, dynamic>>(
        '/payments/$reference/status',
      );
      return PaymentStatusResult.fromJson(res.data!);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}

final paymentRepositoryProvider = Provider<PaymentRepository>(
  (ref) => PaymentRepository(ref.read(dioProvider)),
);
