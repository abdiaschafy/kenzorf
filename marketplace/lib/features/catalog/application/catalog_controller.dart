import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_config.dart';
import '../../../core/models/enums.dart';
import '../../../core/models/product.dart';
import '../data/catalog_repository.dart';

/// État du catalogue : produits paginés + filtres courants + indicateurs de
/// chargement (initial / page suivante) et erreur.
class CatalogState {
  const CatalogState({
    required this.query,
    this.items = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.hasMore = false,
    this.error,
    this.totalPages = 0,
  });

  final ProductQuery query;
  final List<ProductListItem> items;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final Object? error;
  final int totalPages;

  bool get isInitialError => error != null && items.isEmpty;
  bool get isEmptyResult => !isLoading && error == null && items.isEmpty;

  CatalogState copyWith({
    ProductQuery? query,
    List<ProductListItem>? items,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMore,
    Object? error,
    bool clearError = false,
    int? totalPages,
  }) => CatalogState(
    query: query ?? this.query,
    items: items ?? this.items,
    isLoading: isLoading ?? this.isLoading,
    isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    hasMore: hasMore ?? this.hasMore,
    error: clearError ? null : (error ?? this.error),
    totalPages: totalPages ?? this.totalPages,
  );
}

/// Contrôleur paginé du catalogue.
///
/// Recharge depuis la page 1 à chaque changement de filtre, et concatène les
/// pages suivantes via [loadMore].
class CatalogController extends Notifier<CatalogState> {
  @override
  CatalogState build() {
    // Premier chargement déclenché après l'init.
    Future.microtask(load);
    return const CatalogState(
      query: ProductQuery(pageSize: AppConfig.defaultPageSize),
      isLoading: true,
    );
  }

  CatalogRepository get _repo => ref.read(catalogRepositoryProvider);

  /// Charge la première page selon les filtres courants.
  Future<void> load() async {
    state = state.copyWith(isLoading: true, clearError: true);
    final query = state.query.copyWith(page: 1);
    try {
      final paged = await _repo.products(query);
      state = state.copyWith(
        query: query,
        items: paged.items,
        isLoading: false,
        hasMore: paged.hasMore,
        totalPages: paged.totalPages,
        clearError: true,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e);
    }
  }

  /// Charge la page suivante (pagination infinie).
  Future<void> loadMore() async {
    if (state.isLoadingMore || !state.hasMore || state.isLoading) return;
    final nextPage = state.query.page + 1;
    state = state.copyWith(isLoadingMore: true);
    try {
      final query = state.query.copyWith(page: nextPage);
      final paged = await _repo.products(query);
      state = state.copyWith(
        query: query,
        items: [...state.items, ...paged.items],
        isLoadingMore: false,
        hasMore: paged.hasMore,
      );
    } catch (e) {
      // En cas d'échec de page suivante, on conserve la liste et stoppe le
      // spinner ; l'erreur n'écrase pas les résultats déjà affichés.
      state = state.copyWith(isLoadingMore: false, error: e);
    }
  }

  /// Applique une recherche texte.
  Future<void> search(String? term) async {
    state = state.copyWith(
      query: state.query.copyWith(
        search: term,
        resetSearch: term == null || term.isEmpty,
        page: 1,
      ),
    );
    await load();
  }

  /// Filtre par catégorie (slug). `null` réinitialise.
  Future<void> setCategory(String? slug) async {
    state = state.copyWith(
      query: state.query.copyWith(
        categorySlug: slug,
        resetCategory: slug == null,
        page: 1,
      ),
    );
    await load();
  }

  /// Filtre par genre. `null` réinitialise.
  Future<void> setGender(Gender? gender) async {
    state = state.copyWith(
      query: state.query.copyWith(
        gender: gender,
        resetGender: gender == null,
        page: 1,
      ),
    );
    await load();
  }

  /// Change le tri (`newest` | `price_asc` | `price_desc`).
  Future<void> setSort(String? sort) async {
    state = state.copyWith(query: state.query.copyWith(sort: sort, page: 1));
    await load();
  }

  /// Applique en une seule passe catégorie + genre + tri (depuis la feuille de
  /// filtres) pour éviter des rechargements multiples.
  Future<void> applyFilters({
    required String? categorySlug,
    required Gender? gender,
    required String? sort,
  }) async {
    state = state.copyWith(
      query: ProductQuery(
        categorySlug: categorySlug,
        gender: gender,
        sort: sort,
        pageSize: state.query.pageSize,
      ),
    );
    await load();
  }

  /// Réinitialise tous les filtres.
  Future<void> resetFilters() async {
    state = state.copyWith(
      query: const ProductQuery(pageSize: AppConfig.defaultPageSize),
    );
    await load();
  }
}

/// Provider du catalogue. Auto-dispose pour repartir propre à chaque entrée.
final catalogControllerProvider =
    NotifierProvider<CatalogController, CatalogState>(CatalogController.new);
