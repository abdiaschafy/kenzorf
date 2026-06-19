import 'json_utils.dart';

/// `CartItemDto` (spec §5) :
/// `{ id, productVariantId, productId, productName, productSlug, size, color,
///    colorHex?, imageUrl?, unitPrice, quantity, lineTotal, stockQuantity }`.
class CartItem {
  const CartItem({
    required this.id,
    required this.productVariantId,
    required this.productId,
    required this.productName,
    required this.productSlug,
    required this.size,
    required this.color,
    this.colorHex,
    this.imageUrl,
    required this.unitPrice,
    required this.quantity,
    required this.lineTotal,
    required this.stockQuantity,
  });

  final String id;
  final String productVariantId;
  final String productId;
  final String productName;
  final String productSlug;
  final String size;
  final String color;
  final String? colorHex;
  final String? imageUrl;
  final int unitPrice;
  final int quantity;
  final int lineTotal;
  final int stockQuantity;

  /// Vrai si la quantité a atteint le stock disponible.
  bool get atMaxStock => quantity >= stockQuantity;

  /// Libellé combiné taille / couleur (`"M · Noir"`).
  String get variantLabel {
    final parts = [size, color].where((p) => p.isNotEmpty).toList();
    return parts.join(' · ');
  }

  factory CartItem.fromJson(Map<String, dynamic> json) => CartItem(
    id: asString(json['id']),
    productVariantId: asString(json['productVariantId']),
    productId: asString(json['productId']),
    productName: asString(json['productName']),
    productSlug: asString(json['productSlug']),
    size: asString(json['size']),
    color: asString(json['color']),
    colorHex: json['colorHex'] as String?,
    imageUrl: json['imageUrl'] as String?,
    unitPrice: asInt(json['unitPrice']),
    quantity: asInt(json['quantity']),
    lineTotal: asInt(json['lineTotal']),
    stockQuantity: asInt(json['stockQuantity']),
  );
}

/// `CartDto` (spec §5) :
/// `{ id, items: CartItemDto[], subtotal, totalQuantity, currency }`.
class Cart {
  const Cart({
    required this.id,
    required this.items,
    required this.subtotal,
    required this.totalQuantity,
    required this.currency,
  });

  final String id;
  final List<CartItem> items;
  final int subtotal;
  final int totalQuantity;
  final String currency;

  bool get isEmpty => items.isEmpty;

  factory Cart.fromJson(Map<String, dynamic> json) => Cart(
    id: asString(json['id']),
    items: asList(json['items'], CartItem.fromJson),
    subtotal: asInt(json['subtotal']),
    totalQuantity: asInt(json['totalQuantity']),
    currency: asString(json['currency'], fallback: 'XOF'),
  );

  /// Panier vide (état initial / après vidage).
  static Cart empty() => const Cart(
    id: '',
    items: [],
    subtotal: 0,
    totalQuantity: 0,
    currency: 'XOF',
  );
}
