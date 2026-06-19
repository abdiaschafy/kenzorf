import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../../core/router/routes.dart';
import '../../../core/utils/error_localizer.dart';
import '../../../core/widgets/product_card.dart';
import '../../../core/widgets/state_views.dart';
import '../application/catalog_controller.dart';
import 'catalog_filters_sheet.dart';

/// Catalogue produits : recherche, filtres (catégorie/genre/tri), grille
/// paginée (scroll infini).
class CatalogScreen extends ConsumerStatefulWidget {
  const CatalogScreen({super.key});

  @override
  ConsumerState<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends ConsumerState<CatalogScreen> {
  final _scrollController = ScrollController();
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 300) {
      ref.read(catalogControllerProvider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final state = ref.watch(catalogControllerProvider);
    final controller = ref.read(catalogControllerProvider.notifier);

    final hasActiveFilters =
        state.query.categorySlug != null ||
        state.query.gender != null ||
        (state.query.sort != null);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.t('catalog.title')),
        actions: [
          IconButton(
            icon: Badge(
              isLabelVisible: hasActiveFilters,
              child: const Icon(Icons.tune),
            ),
            onPressed: () => _openFilters(context),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(64),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: TextField(
              controller: _searchController,
              textInputAction: TextInputAction.search,
              onSubmitted: (value) => controller.search(value.trim()),
              decoration: InputDecoration(
                hintText: l10n.t('catalog.searchHint'),
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          _searchController.clear();
                          controller.search(null);
                        },
                      ),
                isDense: true,
              ),
            ),
          ),
        ),
      ),
      body: _buildBody(context, state, controller, l10n),
    );
  }

  Future<void> _openFilters(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => const CatalogFiltersSheet(),
    );
  }

  Widget _buildBody(
    BuildContext context,
    CatalogState state,
    CatalogController controller,
    AppLocalizations l10n,
  ) {
    if (state.isLoading && state.items.isEmpty) {
      return const LoadingView();
    }
    if (state.isInitialError) {
      return ErrorView(
        message: l10n.describeError(state.error),
        onRetry: controller.load,
      );
    }
    if (state.isEmptyResult) {
      return EmptyView(
        icon: Icons.search_off,
        title: l10n.t('catalog.empty'),
        message: '',
        actionLabel: l10n.t('catalog.filter.reset'),
        onAction: () {
          _searchController.clear();
          controller.resetFilters();
        },
      );
    }

    return RefreshIndicator(
      onRefresh: controller.load,
      child: GridView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.56,
          crossAxisSpacing: 14,
          mainAxisSpacing: 18,
        ),
        itemCount: state.items.length + (state.isLoadingMore ? 2 : 0),
        itemBuilder: (context, i) {
          if (i >= state.items.length) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            );
          }
          final p = state.items[i];
          return ProductCard(
            product: p,
            onTap: () => context.push(AppRoutes.productPath(p.slug)),
          );
        },
      ),
    );
  }
}
