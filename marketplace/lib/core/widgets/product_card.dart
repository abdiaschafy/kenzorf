import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/product.dart';
import '../theme/app_theme.dart';
import 'app_network_image.dart';
import 'editorial.dart';
import 'price_text.dart';

/// Carte produit éditoriale : grande image plein cadre, nom en serif, prix
/// en chiffres tabulaires, tag promo doré, mention rupture. Image prête pour
/// une transition héro partagée vers la fiche produit.
class ProductCard extends StatelessWidget {
  const ProductCard({
    super.key,
    required this.product,
    required this.onTap,
    this.aspectRatio = 3 / 4,
    this.heroPrefix = 'card',
  });

  final ProductListItem product;
  final VoidCallback onTap;
  final double aspectRatio;

  /// Préfixe du tag héro (évite les collisions entre listes : home vs catalog).
  final String heroPrefix;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    return PressableScale(
      onTap: onTap,
      semanticLabel: product.name,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            child: AspectRatio(
              aspectRatio: aspectRatio,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Hero(
                    tag: '$heroPrefix-${product.id}',
                    child: AppNetworkImage(url: product.primaryImageUrl),
                  ),
                  // Voile dégradé bas pour ancrer d'éventuels badges.
                  if (product.hasDiscount || !product.inStock)
                    const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.transparent, Color(0x22000000)],
                        ),
                      ),
                    ),
                  if (product.hasDiscount)
                    Positioned(
                      top: 10,
                      left: 10,
                      child: _Tag(
                        text: '-${_discountPercent(product)}%',
                        background: AppColors.terracotta,
                        foreground: AppColors.paper,
                      ),
                    ),
                  if (!product.inStock)
                    Positioned(
                      top: 10,
                      right: 10,
                      child: _Tag(
                        text: l10n.t('product.outOfStock'),
                        background: AppColors.charcoal.withValues(alpha: 0.78),
                        foreground: AppColors.cream,
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            product.name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleMedium?.copyWith(
              fontSize: 16,
              height: 1.15,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            l10n.t(product.gender.l10nKey).toUpperCase(),
            style: theme.textTheme.labelSmall?.copyWith(
              color: AppColors.taupe,
              letterSpacing: 1.6,
            ),
          ),
          const SizedBox(height: 6),
          PriceText(
            amount: product.basePrice,
            compareAt: product.compareAtPrice,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  static int _discountPercent(ProductListItem p) {
    if (p.compareAtPrice == null || p.compareAtPrice! <= p.basePrice) return 0;
    final diff = p.compareAtPrice! - p.basePrice;
    return ((diff / p.compareAtPrice!) * 100).round();
  }
}

class _Tag extends StatelessWidget {
  const _Tag({
    required this.text,
    required this.background,
    required this.foreground,
  });

  final String text;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: foreground,
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.6,
        ),
      ),
    );
  }
}
