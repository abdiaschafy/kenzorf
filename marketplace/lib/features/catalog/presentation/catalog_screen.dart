import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../../core/models/product.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/error_localizer.dart';
import '../../../core/widgets/product_card.dart';
import '../../../core/widgets/reveal.dart';
import '../../../core/widgets/state_views.dart';
import '../application/catalog_controller.dart';
import 'catalog_filters_sheet.dart';

/// Catalogue produits : recherche, filtres (catégorie/genre/tri), grille
/// éditoriale **asymétrique** à deux colonnes (scroll infini).
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
        _scrollController.position.maxScrollExtent - 400) {
      ref.read(catalogControllerProvider.notifier).loadMore();
    }
  }

  Future<void> _openFilters() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => const CatalogFiltersSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final state = ref.watch(catalogControllerProvider);
    final controller = ref.read(catalogControllerProvider.notifier);

    final hasActiveFilters =
        state.query.categorySlug != null ||
        state.query.gender != null ||
        state.query.sort != null;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _Header(
              l10n: l10n,
              searchController: _searchController,
              hasActiveFilters: hasActiveFilters,
              count: state.items.length,
              onSubmitSearch: (v) => controller.search(v.trim()),
              onClearSearch: () {
                _searchController.clear();
                controller.search(null);
              },
              onOpenFilters: _openFilters,
            ),
            Expanded(child: _buildBody(context, state, controller, l10n)),
          ],
        ),
      ),
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
      color: AppColors.gold,
      onRefresh: controller.load,
      child: SingleChildScrollView(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.sm,
          AppSpacing.md,
          AppSpacing.xl,
        ),
        child: Column(
          children: [
            _AsymmetricGrid(items: state.items),
            if (state.isLoadingMore)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
                child: SizedBox(
                  height: 26,
                  width: 26,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.gold,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.l10n,
    required this.searchController,
    required this.hasActiveFilters,
    required this.count,
    required this.onSubmitSearch,
    required this.onClearSearch,
    required this.onOpenFilters,
  });

  final AppLocalizations l10n;
  final TextEditingController searchController;
  final bool hasActiveFilters;
  final int count;
  final ValueChanged<String> onSubmitSearch;
  final VoidCallback onClearSearch;
  final VoidCallback onOpenFilters;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.t('catalog.title'),
                      style: theme.textTheme.displaySmall?.copyWith(
                        fontSize: 30,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l10n.t('catalog.resultCount', {'count': count}),
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: AppColors.taupe,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ),
              _FilterButton(
                active: hasActiveFilters,
                onTap: onOpenFilters,
                tooltip: l10n.t('catalog.filters'),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: searchController,
            textInputAction: TextInputAction.search,
            onSubmitted: onSubmitSearch,
            decoration: InputDecoration(
              hintText: l10n.t('catalog.searchHint'),
              prefixIcon: const Icon(Icons.search, size: 20),
              suffixIcon: ValueListenableBuilder<TextEditingValue>(
                valueListenable: searchController,
                builder: (context, value, _) => value.text.isEmpty
                    ? const SizedBox.shrink()
                    : IconButton(
                        icon: const Icon(Icons.close, size: 18),
                        onPressed: onClearSearch,
                      ),
              ),
              isDense: true,
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterButton extends StatelessWidget {
  const _FilterButton({
    required this.active,
    required this.onTap,
    required this.tooltip,
  });

  final bool active;
  final VoidCallback onTap;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Semantics(
        button: true,
        label: tooltip,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          child: Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: active ? AppColors.charcoal : AppColors.paper,
              border: Border.all(
                color: active ? AppColors.charcoal : AppColors.line,
              ),
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            ),
            child: Icon(
              Icons.tune,
              size: 20,
              color: active ? AppColors.goldLight : AppColors.ink,
            ),
          ),
        ),
      ),
    );
  }
}

/// Grille éditoriale asymétrique : deux colonnes décalées, ratios alternés.
/// La colonne de droite est décalée vers le bas pour casser la symétrie.
class _AsymmetricGrid extends StatelessWidget {
  const _AsymmetricGrid({required this.items});

  final List<ProductListItem> items;

  @override
  Widget build(BuildContext context) {
    final left = <Widget>[];
    final right = <Widget>[];

    for (var i = 0; i < items.length; i++) {
      // Ratios alternés pour un rythme magazine (portrait haut / plus carré).
      final tall = i.isEven;
      final card = Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.lg),
        child: Reveal(
          delay: AppMotion.stagger * (i % 6),
          child: ProductCard(
            product: items[i],
            heroPrefix: 'catalog',
            aspectRatio: tall ? 3 / 4 : 1,
            onTap: () =>
                context.push(AppRoutes.productPath(items[i].slug)),
          ),
        ),
      );
      (i.isEven ? left : right).add(card);
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(children: left),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          // Décalage vertical de la colonne droite : asymétrie éditoriale.
          child: Padding(
            padding: const EdgeInsets.only(top: AppSpacing.xl),
            child: Column(children: right),
          ),
        ),
      ],
    );
  }
}
