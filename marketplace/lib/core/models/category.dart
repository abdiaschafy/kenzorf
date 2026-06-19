import 'json_utils.dart';

/// `CategoryDto` (spec §5) :
/// `{ id, name, slug, description?, imageUrl?, productCount }`.
class Category {
  const Category({
    required this.id,
    required this.name,
    required this.slug,
    this.description,
    this.imageUrl,
    required this.productCount,
  });

  final String id;
  final String name;
  final String slug;
  final String? description;
  final String? imageUrl;
  final int productCount;

  factory Category.fromJson(Map<String, dynamic> json) => Category(
    id: asString(json['id']),
    name: asString(json['name']),
    slug: asString(json['slug']),
    description: json['description'] as String?,
    imageUrl: json['imageUrl'] as String?,
    productCount: asInt(json['productCount']),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'slug': slug,
    'description': description,
    'imageUrl': imageUrl,
    'productCount': productCount,
  };
}

/// `CategoryRefDto` (référence légère utilisée dans `ProductDetailDto`).
/// Le contrat §5 expose `category: CategoryRefDto` sans en détailler les
/// champs ; on suppose `{ id, name, slug }`.
// À vérifier dans Swagger : forme exacte de CategoryRefDto.
class CategoryRef {
  const CategoryRef({required this.id, required this.name, required this.slug});

  final String id;
  final String name;
  final String slug;

  factory CategoryRef.fromJson(Map<String, dynamic> json) => CategoryRef(
    id: asString(json['id']),
    name: asString(json['name']),
    slug: asString(json['slug']),
  );
}
