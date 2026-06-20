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
import '../../../core/widgets/brand_monogram.dart';
import '../../../core/widgets/editorial.dart';
import '../../../core/widgets/product_card.dart';
import '../../../core/widgets/reveal.dart';
import '../../../core/widgets/state_views.dart';
import '../../catalog/application/catalog_controller.dart';
import '../application/home_providers.dart';

/// Vitrine KENZORF — éditorial : héros plein cadre, nouveautés, sélection,
/// rayons, bloc « histoire » signé du monogramme.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final featured = ref.watch(featuredProductsProvider);
    final categories = ref.watch(categoriesProvider);

    return Scaffold(
      body: RefreshIndicator(
        color: AppColors.gold,
        onRefresh: () async {
          ref.invalidate(featuredProductsProvider);
          ref.invalidate(categoriesProvider);
          try {
            await ref.read(featuredProductsProvider.future);
            await ref.read(categoriesProvider.future);
          } catch (_) {
            // L'UI affiche l'état d'erreur par section.
          }
        },
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _TopBar(l10n: l10n)),
            SliverToBoxAdapter(child: _Hero(l10n: l10n, featured: featured)),
            SliverToBoxAdapter(
              child: _FeaturedRail(state: featured, l10n: l10n),
            ),
            SliverToBoxAdapter(
              child: _Categories(state: categories, l10n: l10n),
            ),
            SliverToBoxAdapter(child: _EditorialBlock(l10n: l10n)),
            const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xxl)),
          ],
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.l10n});
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.md,
          AppSpacing.md,
          AppSpacing.sm,
        ),
        child: Row(
          children: [
            const BrandMonogram(size: 26),
            const SizedBox(width: 10),
            Text(
              l10n.t('app.name'),
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontFamily: null,
                letterSpacing: 4,
                fontWeight: FontWeight.w600,
                fontSize: 19,
              ),
            ),
            const Spacer(),
            IconButton(
              icon: const Icon(Icons.search),
              tooltip: l10n.t('common.search'),
              onPressed: () => context.go(AppRoutes.catalog),
            ),
          ],
        ),
      ),
    );
  }
}

/// Héros éditorial : grande image plein cadre (1ère pièce mise en avant),
/// overline doré, titre serif sur voile charbon, CTA.
class _Hero extends StatelessWidget {
  const _Hero({required this.l10n, required this.featured});
  final AppLocalizations l10n;
  final AsyncValue<List<ProductListItem>> featured;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final heroImage = featured.maybeWhen(
      data: (list) => list.isNotEmpty ? list.first.primaryImageUrl : null,
      orElse: () => null,
    );
    final heroProduct = featured.maybeWhen(
      data: (list) => list.isNotEmpty ? list.first : null,
      orElse: () => null,
    );

    return Reveal(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.sm,
          AppSpacing.lg,
          AppSpacing.sm,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          child: AspectRatio(
            aspectRatio: 0.82,
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (heroImage != null)
                  AppNetworkImage(url: heroImage)
                else
                  const ColoredBox(color: AppColors.charcoal),
                // Voile dégradé pour lisibilité du texte.
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color(0x22000000),
                        Color(0x00000000),
                        Color(0xCC15120E),
                      ],
                      stops: [0, 0.45, 1],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        l10n.t('home.hero.overline').toUpperCase(),
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: AppColors.goldLight,
                          letterSpacing: 3,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        l10n.t('home.hero.title'),
                        style: theme.textTheme.displaySmall?.copyWith(
                          color: AppColors.cream,
                          height: 1.05,
                          fontSize: 34,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        l10n.t('home.hero.subtitle'),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: AppColors.cream.withValues(alpha: 0.85),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      _HeroCta(
                        label: l10n.t('home.hero.cta'),
                        onTap: () {
                          if (heroProduct != null) {
                            context.push(
                              AppRoutes.productPath(heroProduct.slug),
                            );
                          } else {
                            context.go(AppRoutes.catalog);
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HeroCta extends StatelessWidget {
  const _HeroCta({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      onTap: onTap,
      semanticLabel: label,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.gold,
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: AppColors.charcoal,
                fontWeight: FontWeight.w600,
                fontSize: 14.5,
                letterSpacing: 0.3,
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.arrow_forward, size: 18, color: AppColors.charcoal),
          ],
        ),
      ),
    );
  }
}

/// Rail horizontal « La sélection » (produits mis en avant).
class _FeaturedRail extends StatelessWidget {
  const _FeaturedRail({required this.state, required this.l10n});
  final AsyncValue<List<ProductListItem>> state;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return state.when(
      loading: () => const SizedBox(height: 384, child: LoadingView()),
      error: (e, _) => Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
        child: ErrorView(message: l10n.describeError(e)),
      ),
      data: (products) {
        if (products.isEmpty) return const SizedBox.shrink();
        // Saute la 1ère pièce (déjà en héros) si la liste est assez longue.
        final list = products.length > 3 ? products.sublist(1) : products;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionHeader(
              overline: l10n.t('home.featured.overline'),
              title: l10n.t('home.featured'),
              action: l10n.t('common.seeAll'),
              onAction: () => context.go(AppRoutes.catalog),
            ),
            SizedBox(
              height: 384,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                itemCount: list.length,
                separatorBuilder: (_, _) => const SizedBox(width: 16),
                itemBuilder: (context, i) {
                  return Reveal(
                    delay: AppMotion.stagger * i,
                    child: SizedBox(
                      width: 210,
                      child: ProductCard(
                        product: list[i],
                        heroPrefix: 'home',
                        onTap: () => context.push(
                          AppRoutes.productPath(list[i].slug),
                        ),
                      ),
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

/// Rayons (catégories) en pastilles éditoriales.
class _Categories extends ConsumerWidget {
  const _Categories({required this.state, required this.l10n});
  final AsyncValue<List<Category>> state;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return state.when(
      loading: () => const SizedBox(height: 150),
      error: (e, _) => const SizedBox.shrink(),
      data: (categories) {
        if (categories.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionHeader(
              overline: l10n.t('home.categories.overline'),
              title: l10n.t('home.categories'),
            ),
            SizedBox(
              height: 150,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                itemCount: categories.length,
                separatorBuilder: (_, _) => const SizedBox(width: 14),
                itemBuilder: (context, i) {
                  final c = categories[i];
                  return _CategoryTile(
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

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({required this.category, required this.onTap});
  final Category category;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      onTap: onTap,
      semanticLabel: category.name,
      child: SizedBox(
        width: 124,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              child: SizedBox(
                height: 112,
                width: 124,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    AppNetworkImage(url: category.imageUrl),
                    const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Color(0x00000000), Color(0x99000000)],
                        ),
                      ),
                    ),
                    Positioned(
                      left: 10,
                      right: 8,
                      bottom: 8,
                      child: Text(
                        category.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.cream,
                          fontWeight: FontWeight.w600,
                          fontSize: 13.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Bloc éditorial « histoire » : monogramme filigrané, titre serif, texte,
/// renvoi vers le catalogue. Asymétrique, beaucoup de blanc.
class _EditorialBlock extends StatelessWidget {
  const _EditorialBlock({required this.l10n});
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Reveal(
      child: Container(
        margin: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.xl,
          AppSpacing.lg,
          0,
        ),
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.charcoal,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        ),
        child: Stack(
          children: [
            Positioned(
              right: -20,
              top: -10,
              child: MonogramWatermark(
                size: 160,
                opacity: 0.10,
                color: AppColors.gold,
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const GoldRule(width: 44),
                const SizedBox(height: AppSpacing.md),
                Text(
                  l10n.t('home.editorial.title'),
                  style: theme.textTheme.headlineMedium?.copyWith(
                    color: AppColors.cream,
                    height: 1.08,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  l10n.t('home.editorial.body'),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppColors.cream.withValues(alpha: 0.8),
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                TextButton(
                  onPressed: () => context.go(AppRoutes.catalog),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.goldLight,
                    padding: EdgeInsets.zero,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(l10n.t('home.story.cta')),
                      const SizedBox(width: 6),
                      const Icon(Icons.arrow_forward, size: 16),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
