import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/product.dart';
import '../theme/app_theme.dart';
import 'app_network_image.dart';
import 'price_text.dart';

/// Carte produit affichée dans la vitrine et le catalogue.
class ProductCard extends StatelessWidget {
  const ProductCard({super.key, required this.product, required this.onTap});

  final ProductListItem product;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 3 / 4,
            child: Stack(
              fit: StackFit.expand,
              children: [
                AppNetworkImage(
                  url: product.primaryImageUrl,
                  borderRadius: BorderRadius.circular(14),
                ),
                if (product.hasDiscount)
                  Positioned(
                    top: 8,
                    left: 8,
                    child: _badge(
                      context,
                      '-${_discountPercent(product)}%',
                      AppColors.accent,
                    ),
                  ),
                if (!product.inStock)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: _badge(
                      context,
                      l10n.t('product.outOfStock'),
                      AppColors.stone,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            product.name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 4),
          PriceText(
            amount: product.basePrice,
            compareAt: product.compareAtPrice,
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
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

  Widget _badge(BuildContext context, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
