import 'json_utils.dart';

/// Enveloppe de pagination (spec §3) :
/// `{ items, page, pageSize, total, totalPages }`.
class Paged<T> {
  const Paged({
    required this.items,
    required this.page,
    required this.pageSize,
    required this.total,
    required this.totalPages,
  });

  final List<T> items;
  final int page;
  final int pageSize;
  final int total;
  final int totalPages;

  /// Vrai s'il existe une page suivante à charger.
  bool get hasMore => page < totalPages;

  factory Paged.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) itemFromJson,
  ) => Paged<T>(
    items: asList(json['items'], itemFromJson),
    page: asInt(json['page'], fallback: 1),
    pageSize: asInt(json['pageSize'], fallback: 20),
    total: asInt(json['total']),
    totalPages: asInt(json['totalPages'], fallback: 1),
  );

  /// Page vide (état initial).
  static Paged<T> empty<T>() =>
      Paged<T>(items: const [], page: 1, pageSize: 20, total: 0, totalPages: 0);

  Paged<T> copyWithMore(List<T> more, {required int page}) => Paged<T>(
    items: [...items, ...more],
    page: page,
    pageSize: pageSize,
    total: total,
    totalPages: totalPages,
  );
}
