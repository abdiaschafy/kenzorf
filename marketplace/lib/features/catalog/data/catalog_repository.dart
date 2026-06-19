import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_exception.dart';
import '../../../core/models/category.dart';
import '../../../core/models/enums.dart';
import '../../../core/models/paged.dart';
import '../../../core/models/product.dart';

/// Critères de filtrage du catalogue (spec §4 `GET /api/products`).
class ProductQuery {
  const ProductQuery({
    this.categorySlug,
    this.gender,
    this.search,
    this.minPrice,
    this.maxPrice,
    this.sort,
    this.page = 1,
    this.pageSize = 20,
  });

  final String? categorySlug;
  final Gender? gender;
  final String? search;
  final int? minPrice;
  final int? maxPrice;
  final String? sort; // newest | price_asc | price_desc
  final int page;
  final int pageSize;

  Map<String, dynamic> toQueryParameters() => {
    if (categorySlug != null && categorySlug!.isNotEmpty)
      'categorySlug': categorySlug,
    if (gender != null) 'gender': gender!.wire,
    if (search != null && search!.isNotEmpty) 'search': search,
    if (minPrice != null) 'minPrice': minPrice,
    if (maxPrice != null) 'maxPrice': maxPrice,
    if (sort != null) 'sort': sort,
    'page': page,
    'pageSize': pageSize,
  };

  ProductQuery copyWith({
    String? categorySlug,
    Gender? gender,
    String? search,
    String? sort,
    int? page,
    bool resetCategory = false,
    bool resetGender = false,
    bool resetSearch = false,
  }) => ProductQuery(
    categorySlug: resetCategory ? null : (categorySlug ?? this.categorySlug),
    gender: resetGender ? null : (gender ?? this.gender),
    search: resetSearch ? null : (search ?? this.search),
    minPrice: minPrice,
    maxPrice: maxPrice,
    sort: sort ?? this.sort,
    page: page ?? this.page,
    pageSize: pageSize,
  );
}

/// Accès réseau au catalogue public (catégories + produits).
class CatalogRepository {
  CatalogRepository(this._dio);

  final Dio _dio;

  /// `GET /api/categories` → `CategoryDto[]`.
  Future<List<Category>> categories() async {
    try {
      final res = await _dio.get<List<dynamic>>('/categories');
      return (res.data ?? [])
          .whereType<Map<String, dynamic>>()
          .map(Category.fromJson)
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// `GET /api/products` → `Paged<ProductListItemDto>`.
  Future<Paged<ProductListItem>> products(ProductQuery query) async {
    try {
      final res = await _dio.get<Map<String, dynamic>>(
        '/products',
        queryParameters: query.toQueryParameters(),
      );
      return Paged.fromJson(res.data!, ProductListItem.fromJson);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// `GET /api/products/featured` → `ProductListItemDto[]`.
  Future<List<ProductListItem>> featured() async {
    try {
      final res = await _dio.get<List<dynamic>>('/products/featured');
      return (res.data ?? [])
          .whereType<Map<String, dynamic>>()
          .map(ProductListItem.fromJson)
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// `GET /api/products/{slug}` → `ProductDetailDto`.
  Future<ProductDetail> productBySlug(String slug) async {
    try {
      final res = await _dio.get<Map<String, dynamic>>('/products/$slug');
      return ProductDetail.fromJson(res.data!);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}

final catalogRepositoryProvider = Provider<CatalogRepository>(
  (ref) => CatalogRepository(ref.read(dioProvider)),
);
