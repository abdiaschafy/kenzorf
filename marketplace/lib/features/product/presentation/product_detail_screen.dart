import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/auth/auth_controller.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/models/product.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/color_utils.dart';
import '../../../core/utils/error_localizer.dart';
import '../../../core/widgets/app_network_image.dart';
import '../../../core/widgets/price_text.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/state_views.dart';
import '../../cart/application/cart_controller.dart';
import '../application/product_providers.dart';

/// Fiche produit : galerie d'images, infos, sélection de variante
/// (taille/couleur) et ajout au panier selon le stock.
class ProductDetailScreen extends ConsumerWidget {
  const ProductDetailScreen({super.key, required this.slug});

  final String slug;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final detail = ref.watch(productDetailProvider(slug));

    return Scaffold(
      appBar: AppBar(),
      body: detail.when(
        loading: () => const LoadingView(),
        error: (e, _) => ErrorView(
          message: l10n.describeError(e),
          onRetry: () => ref.invalidate(productDetailProvider(slug)),
        ),
        data: (product) => _ProductBody(product: product),
      ),
    );
  }
}

class _ProductBody extends ConsumerStatefulWidget {
  const _ProductBody({required this.product});
  final ProductDetail product;

  @override
  ConsumerState<_ProductBody> createState() => _ProductBodyState();
}

class _ProductBodyState extends ConsumerState<_ProductBody> {
  String? _selectedSize;
  String? _selectedColor;
  int _imageIndex = 0;
  bool _adding = false;

  ProductDetail get _product => widget.product;

  @override
  void initState() {
    super.initState();
    // Présélection si une seule taille / couleur.
    if (_product.sizes.length == 1) _selectedSize = _product.sizes.first;
    if (_product.colors.length == 1) _selectedColor = _product.colors.first;
  }

  ProductVariant? get _selectedVariant {
    // Si l'attribut n'existe pas pour le produit, on l'ignore dans le matching.
    final size = _product.sizes.isEmpty ? null : _selectedSize;
    final color = _product.colors.isEmpty ? null : _selectedColor;
    if ((_product.sizes.isNotEmpty && size == null) ||
        (_product.colors.isNotEmpty && color == null)) {
      return null;
    }
    return _product.variantFor(size: size, color: color);
  }

  bool _sizeHasStock(String size) {
    return _product.variants.any(
      (v) =>
          v.size == size &&
          (_selectedColor == null || v.color == _selectedColor) &&
          v.inStock,
    );
  }

  bool _colorHasStock(String color) {
    return _product.variants.any(
      (v) =>
          v.color == color &&
          (_selectedSize == null || v.size == _selectedSize) &&
          v.inStock,
    );
  }

  Future<void> _addToCart() async {
    final l10n = context.l10n;
    final auth = ref.read(authControllerProvider);
    if (!auth.isAuthenticated) {
      context.go(AppRoutes.login);
      return;
    }

    final variant = _selectedVariant;
    if (variant == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.t('product.selectVariant'))));
      return;
    }
    if (!variant.inStock) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.t('product.variantOutOfStock'))),
      );
      return;
    }

    setState(() => _adding = true);
    try {
      await ref
          .read(cartControllerProvider.notifier)
          .addItem(productVariantId: variant.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.t('product.added')),
            action: SnackBarAction(
              label: l10n.t('nav.cart'),
              onPressed: () => context.go(AppRoutes.cart),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.describeError(e))));
      }
    } finally {
      if (mounted) setState(() => _adding = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final variant = _selectedVariant;
    final images = _product.images;
    final canAdd = variant != null && variant.inStock;

    final displayPrice = variant?.price ?? _product.basePrice;

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              // Galerie
              _Gallery(
                images: images,
                index: _imageIndex,
                fallback: _product.primaryImageUrl,
                onChanged: (i) => setState(() => _imageIndex = i),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _product.name,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 8),
                    PriceText(
                      amount: displayPrice,
                      compareAt: _product.compareAtPrice,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    _StockHint(variant: variant, product: _product),
                    const SizedBox(height: 20),

                    // Tailles
                    if (_product.sizes.isNotEmpty) ...[
                      _AttributeLabel(text: l10n.t('product.size')),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final size in _product.sizes)
                            ChoiceChip(
                              label: Text(size),
                              selected: _selectedSize == size,
                              onSelected: _sizeHasStock(size)
                                  ? (_) => setState(() => _selectedSize = size)
                                  : null,
                            ),
                        ],
                      ),
                      const SizedBox(height: 20),
                    ],

                    // Couleurs
                    if (_product.colors.isNotEmpty) ...[
                      _AttributeLabel(text: l10n.t('product.color')),
                      Wrap(
                        spacing: 10,
                        runSpacing: 8,
                        children: [
                          for (final color in _product.colors)
                            _ColorOption(
                              color: color,
                              hex: _hexFor(color),
                              selected: _selectedColor == color,
                              enabled: _colorHasStock(color),
                              onTap: () =>
                                  setState(() => _selectedColor = color),
                            ),
                        ],
                      ),
                      const SizedBox(height: 20),
                    ],

                    const Divider(height: 32),

                    // Description
                    _Section(
                      title: l10n.t('product.description'),
                      child: Text(
                        _product.description,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                    if (_product.material != null &&
                        _product.material!.isNotEmpty)
                      _Section(
                        title: l10n.t('product.material'),
                        child: Text(_product.material!),
                      ),
                    if (_product.careInstructions != null &&
                        _product.careInstructions!.isNotEmpty)
                      _Section(
                        title: l10n.t('product.care'),
                        child: Text(_product.careInstructions!),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
        _BottomBar(
          enabled: canAdd,
          loading: _adding,
          label: canAdd
              ? l10n.t('product.addToCart')
              : l10n.t('product.outOfStock'),
          onPressed: _addToCart,
        ),
      ],
    );
  }

  String? _hexFor(String color) {
    for (final v in _product.variants) {
      if (v.color == color && v.colorHex != null) return v.colorHex;
    }
    return null;
  }
}

class _Gallery extends StatelessWidget {
  const _Gallery({
    required this.images,
    required this.index,
    required this.onChanged,
    this.fallback,
  });

  final List<ProductImage> images;
  final int index;
  final ValueChanged<int> onChanged;
  final String? fallback;

  @override
  Widget build(BuildContext context) {
    final urls = images.isNotEmpty
        ? images.map((e) => e.url).toList()
        : (fallback != null ? [fallback!] : <String>[]);

    return AspectRatio(
      aspectRatio: 1,
      child: Stack(
        children: [
          PageView.builder(
            itemCount: urls.isEmpty ? 1 : urls.length,
            onPageChanged: onChanged,
            itemBuilder: (context, i) => AppNetworkImage(
              url: urls.isEmpty ? null : urls[i],
              fit: BoxFit.cover,
            ),
          ),
          if (urls.length > 1)
            Positioned(
              bottom: 12,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var i = 0; i < urls.length; i++)
                    Container(
                      width: 8,
                      height: 8,
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: i == index
                            ? AppColors.ink
                            : AppColors.ink.withValues(alpha: 0.3),
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _StockHint extends StatelessWidget {
  const _StockHint({required this.variant, required this.product});
  final ProductVariant? variant;
  final ProductDetail product;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    if (variant == null) {
      // Aucune variante sélectionnée : indication globale.
      if (!product.inStock) {
        return _chip(l10n.t('product.outOfStock'), AppColors.danger);
      }
      return const SizedBox.shrink();
    }
    if (!variant!.inStock) {
      return _chip(l10n.t('product.outOfStock'), AppColors.danger);
    }
    if (variant!.isLowStock) {
      return _chip(
        l10n.t('product.lowStock', {'count': variant!.stockQuantity}),
        AppColors.warning,
      );
    }
    return _chip(l10n.t('product.inStock'), AppColors.success);
  }

  Widget _chip(String text, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.circle, size: 9, color: color),
        const SizedBox(width: 6),
        Text(
          text,
          style: TextStyle(color: color, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}

class _AttributeLabel extends StatelessWidget {
  const _AttributeLabel({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        text,
        style: Theme.of(
          context,
        ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _ColorOption extends StatelessWidget {
  const _ColorOption({
    required this.color,
    required this.hex,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  final String color;
  final String? hex;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final swatch = colorFromHex(hex);
    return Opacity(
      opacity: enabled ? 1 : 0.35,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(30),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
              color: selected ? AppColors.ink : AppColors.line,
              width: selected ? 2 : 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (swatch != null) ...[
                Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: swatch,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.line),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Text(color),
            ],
          ),
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          child,
        ],
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  const _BottomBar({
    required this.enabled,
    required this.loading,
    required this.label,
    required this.onPressed,
  });

  final bool enabled;
  final bool loading;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          border: Border(top: BorderSide(color: AppColors.line)),
        ),
        child: PrimaryButton(
          label: label,
          loading: loading,
          icon: enabled ? Icons.shopping_bag_outlined : null,
          onPressed: enabled ? onPressed : null,
        ),
      ),
    );
  }
}
