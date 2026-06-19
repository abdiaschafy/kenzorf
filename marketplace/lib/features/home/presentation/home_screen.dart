import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../../core/models/category.dart';
import '../../../core/models/product.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/error_localizer.dart';
import '../../../core/widgets/app_network_image.dart';
import '../../../core/widgets/product_card.dart';
import '../../../core/widgets/state_views.dart';
import '../../catalog/application/catalog_controller.dart';
import '../application/home_providers.dart';

/// Vitrine KENZORF : bannière, catégories, sélection mise en avant.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final featured = ref.watch(featuredProductsProvider);
    final categories = ref.watch(categoriesProvider);

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(featuredProductsProvider);
            ref.invalidate(categoriesProvider);
            // On attend le rechargement ; les erreurs sont déjà rendues par
            // les sections (AsyncValue.error), inutile de les propager ici.
            try {
              await ref.read(featuredProductsProvider.future);
              await ref.read(categoriesProvider.future);
            } catch (_) {
              // Ignoré : l'UI affiche l'état d'erreur par section.
            }
          },
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(child: _Header(l10n: l10n)),
              SliverToBoxAdapter(
                child: _Hero(l10n: l10n, ref: ref),
              ),
              SliverToBoxAdapter(
                child: _CategoriesSection(state: categories, l10n: l10n),
              ),
              SliverToBoxAdapter(
                child: _FeaturedSection(state: featured, l10n: l10n),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 24)),
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.l10n});
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            l10n.t('app.name'),
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: 2,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => context.go(AppRoutes.catalog),
          ),
        ],
      ),
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero({required this.l10n, required this.ref});
  final AppLocalizations l10n;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.ink,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.t('home.hero.title'),
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: AppColors.paper,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.t('home.hero.subtitle'),
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.line),
            ),
            const SizedBox(height: 18),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: AppColors.paper,
                minimumSize: const Size(160, 46),
              ),
              onPressed: () => context.go(AppRoutes.catalog),
              child: Text(l10n.t('home.hero.cta')),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoriesSection extends ConsumerWidget {
  const _CategoriesSection({required this.state, required this.l10n});
  final AsyncValue<List<Category>> state;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return state.when(
      loading: () => const SizedBox(
        height: 120,
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      ),
      error: (e, _) => const SizedBox.shrink(),
      data: (categories) {
        if (categories.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SectionTitle(title: l10n.t('home.categories')),
            SizedBox(
              height: 112,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: categories.length,
                separatorBuilder: (_, _) => const SizedBox(width: 12),
                itemBuilder: (context, i) {
                  final c = categories[i];
                  return _CategoryChip(
                    category: c,
                    onTap: () {
                      ref
                          .read(catalogControllerProvider.notifier)
                          .setCategory(c.slug);
                      context.go(AppRoutes.catalog);
                    },
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({required this.category, required this.onTap});
  final Category category;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        width: 88,
        child: Column(
          children: [
            AppNetworkImage(
              url: category.imageUrl,
              width: 72,
              height: 72,
              borderRadius: BorderRadius.circular(36),
            ),
            const SizedBox(height: 8),
            Text(
              category.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _FeaturedSection extends StatelessWidget {
  const _FeaturedSection({required this.state, required this.l10n});
  final AsyncValue<List<ProductListItem>> state;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return state.when(
      loading: () => const SizedBox(height: 260, child: LoadingView()),
      error: (e, _) => SizedBox(
        height: 200,
        child: ErrorView(message: l10n.describeError(e)),
      ),
      data: (products) {
        if (products.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SectionTitle(title: l10n.t('home.featured')),
            SizedBox(
              height: 300,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: products.length,
                separatorBuilder: (_, _) => const SizedBox(width: 14),
                itemBuilder: (context, i) {
                  final p = products[i];
                  return SizedBox(
                    width: 180,
                    child: ProductCard(
                      product: p,
                      onTap: () => context.push(AppRoutes.productPath(p.slug)),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 14),
      child: Text(
        title,
        style: Theme.of(
          context,
        ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
      ),
    );
  }
}
