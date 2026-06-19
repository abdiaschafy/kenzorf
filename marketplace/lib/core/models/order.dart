import 'address.dart';
import 'enums.dart';
import 'json_utils.dart';
import 'payment.dart';

/// `OrderItemDto` (spec §5) :
/// `{ id, productName, variantLabel, sku, imageUrl?, unitPrice, quantity, lineTotal }`.
class OrderItem {
  const OrderItem({
    required this.id,
    required this.productName,
    required this.variantLabel,
    required this.sku,
    this.imageUrl,
    required this.unitPrice,
    required this.quantity,
    required this.lineTotal,
  });

  final String id;
  final String productName;
  final String variantLabel;
  final String sku;
  final String? imageUrl;
  final int unitPrice;
  final int quantity;
  final int lineTotal;

  factory OrderItem.fromJson(Map<String, dynamic> json) => OrderItem(
    id: asString(json['id']),
    productName: asString(json['productName']),
    variantLabel: asString(json['variantLabel']),
    sku: asString(json['sku']),
    imageUrl: json['imageUrl'] as String?,
    unitPrice: asInt(json['unitPrice']),
    quantity: asInt(json['quantity']),
    lineTotal: asInt(json['lineTotal']),
  );
}

/// `OrderDto` (spec §5) :
/// `{ id, orderNumber, status, subtotal, shippingFee, discount, total, currency,
///    items: OrderItemDto[], shippingAddress: {...}, customerNote?,
///    payment: PaymentDto?, placedAt, paidAt? }`.
class Order {
  const Order({
    required this.id,
    required this.orderNumber,
    required this.status,
    required this.subtotal,
    required this.shippingFee,
    required this.discount,
    required this.total,
    required this.currency,
    required this.items,
    this.shippingAddress,
    this.customerNote,
    this.payment,
    this.placedAt,
    this.paidAt,
  });

  final String id;
  final String orderNumber;
  final OrderStatus status;
  final int subtotal;
  final int shippingFee;
  final int discount;
  final int total;
  final String currency;
  final List<OrderItem> items;

  /// `shippingAddress` est un objet inline dans le DTO ; on le mappe sur le
  /// modèle [Address] (mêmes champs ; `isDefault` peut être absent).
  final Address? shippingAddress;
  final String? customerNote;
  final Payment? payment;
  final DateTime? placedAt;
  final DateTime? paidAt;

  factory Order.fromJson(Map<String, dynamic> json) => Order(
    id: asString(json['id']),
    orderNumber: asString(json['orderNumber']),
    status: OrderStatus.fromWire(json['status'] as String?),
    subtotal: asInt(json['subtotal']),
    shippingFee: asInt(json['shippingFee']),
    discount: asInt(json['discount']),
    total: asInt(json['total']),
    currency: asString(json['currency'], fallback: 'XOF'),
    items: asList(json['items'], OrderItem.fromJson),
    shippingAddress: json['shippingAddress'] is Map
        ? Address.fromJson(
            (json['shippingAddress'] as Map).cast<String, dynamic>(),
          )
        : null,
    customerNote: json['customerNote'] as String?,
    payment: json['payment'] is Map
        ? Payment.fromJson((json['payment'] as Map).cast<String, dynamic>())
        : null,
    placedAt: asDate(json['placedAt']),
    paidAt: asDate(json['paidAt']),
  );
}

/// `OrderSummaryDto` (spec §5) :
/// `{ id, orderNumber, status, total, currency, itemCount, placedAt }`.
class OrderSummary {
  const OrderSummary({
    required this.id,
    required this.orderNumber,
    required this.status,
    required this.total,
    required this.currency,
    required this.itemCount,
    this.placedAt,
  });

  final String id;
  final String orderNumber;
  final OrderStatus status;
  final int total;
  final String currency;
  final int itemCount;
  final DateTime? placedAt;

  factory OrderSummary.fromJson(Map<String, dynamic> json) => OrderSummary(
    id: asString(json['id']),
    orderNumber: asString(json['orderNumber']),
    status: OrderStatus.fromWire(json['status'] as String?),
    total: asInt(json['total']),
    currency: asString(json['currency'], fallback: 'XOF'),
    itemCount: asInt(json['itemCount']),
    placedAt: asDate(json['placedAt']),
  );
}

/// `CreateOrderRequest` (spec §5) :
/// `{ shippingAddress: AddressRequest, customerNote?, paymentMethod? }`.
class CreateOrderRequest {
  const CreateOrderRequest({
    required this.shippingAddress,
    this.customerNote,
    this.paymentMethod,
  });

  final AddressRequest shippingAddress;
  final String? customerNote;
  final PaymentMethod? paymentMethod;

  Map<String, dynamic> toJson() => {
    'shippingAddress': shippingAddress.toJson(),
    if (customerNote != null && customerNote!.isNotEmpty)
      'customerNote': customerNote,
    if (paymentMethod != null) 'paymentMethod': paymentMethod!.wire,
  };
}
