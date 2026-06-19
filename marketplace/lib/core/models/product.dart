import 'category.dart';
import 'enums.dart';
import 'json_utils.dart';

/// `ProductListItemDto` (spec §5) :
/// `{ id, name, slug, basePrice, compareAtPrice?, currency, primaryImageUrl?,
///    gender, inStock, isFeatured }`.
class ProductListItem {
  const ProductListItem({
    required this.id,
    required this.name,
    required this.slug,
    required this.basePrice,
    this.compareAtPrice,
    required this.currency,
    this.primaryImageUrl,
    required this.gender,
    required this.inStock,
    required this.isFeatured,
  });

  final String id;
  final String name;
  final String slug;
  final int basePrice;
  final int? compareAtPrice;
  final String currency;
  final String? primaryImageUrl;
  final Gender gender;
  final bool inStock;
  final bool isFeatured;

  /// Vrai si un prix barré supérieur au prix courant est défini (promo).
  bool get hasDiscount => compareAtPrice != null && compareAtPrice! > basePrice;

  factory ProductListItem.fromJson(Map<String, dynamic> json) =>
      ProductListItem(
        id: asString(json['id']),
        name: asString(json['name']),
        slug: asString(json['slug']),
        basePrice: asInt(json['basePrice']),
        compareAtPrice: asIntOrNull(json['compareAtPrice']),
        currency: asString(json['currency'], fallback: 'XOF'),
        primaryImageUrl: json['primaryImageUrl'] as String?,
        gender: Gender.fromWire(json['gender'] as String?),
        inStock: asBool(json['inStock'], fallback: true),
        isFeatured: asBool(json['isFeatured']),
      );
}

/// `ImageDto` (spec §5) :
/// `{ id, url, altText?, isPrimary, displayOrder }`.
class ProductImage {
  const ProductImage({
    required this.id,
    required this.url,
    this.altText,
    required this.isPrimary,
    required this.displayOrder,
  });

  final String id;
  final String url;
  final String? altText;
  final bool isPrimary;
  final int displayOrder;

  factory ProductImage.fromJson(Map<String, dynamic> json) => ProductImage(
    id: asString(json['id']),
    url: asString(json['url']),
    altText: json['altText'] as String?,
    isPrimary: asBool(json['isPrimary']),
    displayOrder: asInt(json['displayOrder']),
  );
}

/// `VariantDto` (spec §5) :
/// `{ id, sku, size, color, colorHex?, price, stockQuantity, inStock }`.
class ProductVariant {
  const ProductVariant({
    required this.id,
    required this.sku,
    required this.size,
    required this.color,
    this.colorHex,
    required this.price,
    required this.stockQuantity,
    required this.inStock,
  });

  final String id;
  final String sku;
  final String size;
  final String color;
  final String? colorHex;
  final int price;
  final int stockQuantity;
  final bool inStock;

  /// Stock faible (≤ 5) : affichage d'une mention "Plus que N en stock".
  bool get isLowStock => inStock && stockQuantity > 0 && stockQuantity <= 5;

  factory ProductVariant.fromJson(Map<String, dynamic> json) => ProductVariant(
    id: asString(json['id']),
    sku: asString(json['sku']),
    size: asString(json['size']),
    color: asString(json['color']),
    colorHex: json['colorHex'] as String?,
    price: asInt(json['price']),
    stockQuantity: asInt(json['stockQuantity']),
    inStock: asBool(json['inStock'], fallback: false),
  );
}

/// `ProductDetailDto` (spec §5) :
/// `{ id, name, slug, description, shortDescription?, basePrice, compareAtPrice?,
///    currency, gender, material?, careInstructions?, category: CategoryRefDto,
///    images: ImageDto[], variants: VariantDto[] }`.
class ProductDetail {
  const ProductDetail({
    required this.id,
    required this.name,
    required this.slug,
    required this.description,
    this.shortDescription,
    required this.basePrice,
    this.compareAtPrice,
    required this.currency,
    required this.gender,
    this.material,
    this.careInstructions,
    required this.category,
    required this.images,
    required this.variants,
  });

  final String id;
  final String name;
  final String slug;
  final String description;
  final String? shortDescription;
  final int basePrice;
  final int? compareAtPrice;
  final String currency;
  final Gender gender;
  final String? material;
  final String? careInstructions;
  final CategoryRef category;
  final List<ProductImage> images;
  final List<ProductVariant> variants;

  bool get hasDiscount => compareAtPrice != null && compareAtPrice! > basePrice;

  bool get inStock => variants.any((v) => v.inStock);

  /// Tailles distinctes disponibles, dans l'ordre d'apparition.
  List<String> get sizes {
    final seen = <String>{};
    final result = <String>[];
    for (final v in variants) {
      if (v.size.isNotEmpty && seen.add(v.size)) result.add(v.size);
    }
    return result;
  }

  /// Couleurs distinctes disponibles, dans l'ordre d'apparition.
  List<String> get colors {
    final seen = <String>{};
    final result = <String>[];
    for (final v in variants) {
      if (v.color.isNotEmpty && seen.add(v.color)) result.add(v.color);
    }
    return result;
  }

  /// Retourne la variante correspondant à la taille + couleur choisies.
  ProductVariant? variantFor({String? size, String? color}) {
    for (final v in variants) {
      final sizeMatch = size == null || v.size == size;
      final colorMatch = color == null || v.color == color;
      if (sizeMatch && colorMatch) return v;
    }
    return null;
  }

  /// URL de l'image principale (sinon première image disponible).
  String? get primaryImageUrl {
    for (final img in images) {
      if (img.isPrimary) return img.url;
    }
    return images.isNotEmpty ? images.first.url : null;
  }

  factory ProductDetail.fromJson(Map<String, dynamic> json) => ProductDetail(
    id: asString(json['id']),
    name: asString(json['name']),
    slug: asString(json['slug']),
    description: asString(json['description']),
    shortDescription: json['shortDescription'] as String?,
    basePrice: asInt(json['basePrice']),
    compareAtPrice: asIntOrNull(json['compareAtPrice']),
    currency: asString(json['currency'], fallback: 'XOF'),
    gender: Gender.fromWire(json['gender'] as String?),
    material: json['material'] as String?,
    careInstructions: json['careInstructions'] as String?,
    category: CategoryRef.fromJson(
      (json['category'] as Map?)?.cast<String, dynamic>() ?? const {},
    ),
    images: asList(json['images'], ProductImage.fromJson),
    variants: asList(json['variants'], ProductVariant.fromJson),
  );
}
