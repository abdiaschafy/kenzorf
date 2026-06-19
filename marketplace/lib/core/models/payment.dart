import 'enums.dart';
import 'json_utils.dart';

/// `PaymentDto` (spec §5) :
/// `{ reference, provider, status, amount, currency, paymentMethod?, checkoutUrl? }`.
class Payment {
  const Payment({
    required this.reference,
    required this.provider,
    required this.status,
    required this.amount,
    required this.currency,
    this.paymentMethod,
    this.checkoutUrl,
  });

  final String reference;
  final String provider;
  final PaymentStatus status;
  final int amount;
  final String currency;
  final PaymentMethod? paymentMethod;
  final String? checkoutUrl;

  factory Payment.fromJson(Map<String, dynamic> json) => Payment(
    reference: asString(json['reference']),
    provider: asString(json['provider']),
    status: PaymentStatus.fromWire(json['status'] as String?),
    amount: asInt(json['amount']),
    currency: asString(json['currency'], fallback: 'XOF'),
    paymentMethod: PaymentMethod.fromWire(json['paymentMethod'] as String?),
    checkoutUrl: json['checkoutUrl'] as String?,
  );
}

/// Réponse de `GET /api/payments/{reference}/status` (spec §4) :
/// `{ status, orderId, orderStatus }`.
class PaymentStatusResult {
  const PaymentStatusResult({
    required this.status,
    required this.orderId,
    required this.orderStatus,
  });

  final PaymentStatus status;
  final String orderId;
  final String orderStatus; // OrderStatus wire value

  factory PaymentStatusResult.fromJson(Map<String, dynamic> json) =>
      PaymentStatusResult(
        status: PaymentStatus.fromWire(json['status'] as String?),
        orderId: asString(json['orderId']),
        orderStatus: asString(json['orderStatus']),
      );
}
