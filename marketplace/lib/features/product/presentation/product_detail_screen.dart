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
import '../../../core/widgets/editorial.dart';
import '../../../core/widgets/price_text.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/state_views.dart';
import '../../cart/application/cart_controller.dart';
import '../application/product_providers.dart';

/// Fiche produit éditoriale : galerie plein cadre (transition héro), infos,
/// sélecteurs de variante (pastilles taille/couleur), barre « Ajouter au
/// panier » collante et premium, matière / entretien.
class ProductDetailScreen extends ConsumerWidget {
  const ProductDetailScreen({super.key, required this.slug});

  final String slug;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final detail = ref.watch(productDetailProvider(slug));

    return Scaffold(
      body: detail.when(
        loading: () => const LoadingView(),
        error: (e, _) => SafeArea(
          child: Column(
            children: [
              const _FloatingBackBar(),
              Expanded(
                child: ErrorView(
                  message: l10n.describeError(e),
                  onRetry: () => ref.invalidate(productDetailProvider(slug)),
                ),
              ),
            ],
          ),
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
    if (_product.sizes.length == 1) _selectedSize = _product.sizes.first;
    if (_product.colors.length == 1) _selectedColor = _product.colors.first;
  }

  ProductVariant? get _selectedVariant {
    final size = _product.sizes.isEmpty ? null : _selectedSize;
    final color = _product.colors.isEmpty ? null : _selectedColor;
    if ((_product.sizes.isNotEmpty && size == null) ||
        (_product.colors.isNotEmpty && color == null)) {
      return null;
    }
    return _product.variantFor(size: size, color: color);
  }

  bool _sizeHasStock(String size) => _product.variants.any(
    (v) =>
        v.size == size &&
        (_selectedColor == null || v.color == _selectedColor) &&
        v.inStock,
  );

  bool _colorHasStock(String color) => _product.variants.any(
    (v) =>
        v.color == color &&
        (_selectedSize == null || v.size == _selectedSize) &&
        v.inStock,
  );

  void _toast(String message, {SnackBarAction? action}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message), action: action));
  }

  Future<void> _addToCart() async {
    final l10n = context.l10n;
    final auth = ref.read(authControllerProvider);
    if (!auth.isAuthenticated) {
      context.push(AppRoutes.login);
      return;
    }

    final variant = _selectedVariant;
    if (variant == null) {
      _toast(l10n.t('product.selectVariant'));
      return;
    }
    if (!variant.inStock) {
      _toast(l10n.t('product.variantOutOfStock'));
      return;
    }

    setState(() => _adding = true);
    try {
      await ref
          .read(cartControllerProvider.notifier)
          .addItem(productVariantId: variant.id);
      if (mounted) {
        _toast(
          l10n.t('product.added'),
          action: SnackBarAction(
            label: l10n.t('product.viewCart'),
            onPressed: () => context.go(AppRoutes.cart),
          ),
        );
      }
    } catch (e) {
      // Le contrôleur ne corrompt jamais le panier : on affiche un toast
      // localisé, jamais d'écran d'erreur.
      if (mounted) _toast(l10n.describeError(e));
    } finally {
      if (mounted) setState(() => _adding = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final variant = _selectedVariant;
    final images = _product.images;
    final canAdd = variant != null && variant.inStock;
    final displayPrice = variant?.price ?? _product.basePrice;

    return Stack(
      children: [
        CustomScrollView(
          slivers: [
            // Galerie plein cadre, transition héro depuis la grille.
            SliverToBoxAdapter(
              child: _Gallery(
                heroId: _product.id,
                images: images,
                index: _imageIndex,
                fallback: _product.primaryImageUrl,
                onChanged: (i) => setState(() => _imageIndex = i),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.lg,
                  AppSpacing.lg,
                  140,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.t(_product.gender.l10nKey).toUpperCase(),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: AppColors.gold,
                        letterSpacing: 2.4,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _product.name,
                      style: theme.textTheme.headlineMedium?.copyWith(
                        height: 1.08,
                      ),
                    ),
                    const SizedBox(height: 12),
                    PriceText(
                      amount: displayPrice,
                      compareAt: _product.compareAtPrice,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _StockHint(variant: variant, product: _product),
                    const SizedBox(height: AppSpacing.lg),

                    if (_product.sizes.isNotEmpty) ...[
                      _AttributeLabel(text: l10n.t('product.size')),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          for (final size in _product.sizes)
                            _SizePill(
                              label: size,
                              selected: _selectedSize == size,
                              enabled: _sizeHasStock(size),
                              onTap: () => setState(() => _selectedSize = size),
                            ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.lg),
                    ],

                    if (_product.colors.isNotEmpty) ...[
                      _AttributeLabel(text: l10n.t('product.color')),
                      Wrap(
                        spacing: 12,
                        runSpacing: 10,
                        children: [
                          for (final color in _product.colors)
                            _ColorPill(
                              color: color,
                              hex: _hexFor(color),
                              selected: _selectedColor == color,
                              enabled: _colorHasStock(color),
                              onTap: () =>
                                  setState(() => _selectedColor = color),
                            ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.lg),
                    ],

                    const GoldRule(width: 36),
                    const SizedBox(height: AppSpacing.lg),

                    _Section(
                      title: l10n.t('product.description'),
                      child: Text(
                        _product.description,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          height: 1.6,
                          color: AppColors.ink,
                        ),
                      ),
                    ),
                    if (_product.material != null &&
                        _product.material!.isNotEmpty)
                      _Section(
                        title: l10n.t('product.material'),
                        child: Text(
                          _product.material!,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            height: 1.6,
                          ),
                        ),
                      ),
                    if (_product.careInstructions != null &&
                        _product.careInstructions!.isNotEmpty)
                      _Section(
                        title: l10n.t('product.care'),
                        child: Text(
                          _product.careInstructions!,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            height: 1.6,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const _FloatingBackBar(),
        Align(
          alignment: Alignment.bottomCenter,
          child: _StickyAddBar(
            enabled: canAdd,
            loading: _adding,
            price: displayPrice,
            compareAt: _product.compareAtPrice,
            label: canAdd
                ? l10n.t('product.addToCart')
                : (variant == null
                      ? l10n.t('product.selectVariant')
                      : l10n.t('product.outOfStock')),
            onPressed: _addToCart,
          ),
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

/// Bouton retour flottant translucide posé sur la galerie.
class _FloatingBackBar extends StatelessWidget {
  const _FloatingBackBar();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Align(
          alignment: Alignment.topLeft,
          child: Material(
            color: AppColors.charcoal.withValues(alpha: 0.55),
            shape: const CircleBorder(),
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: AppColors.cream),
              tooltip: MaterialLocalizations.of(context).backButtonTooltip,
              onPressed: () => context.pop(),
            ),
          ),
        ),
      ),
    );
  }
}

class _Gallery extends StatelessWidget {
  const _Gallery({
    required this.heroId,
    required this.images,
    required this.index,
    required this.onChanged,
    this.fallback,
  });

  final String heroId;
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
      aspectRatio: 0.84,
      child: Stack(
        children: [
          PageView.builder(
            itemCount: urls.isEmpty ? 1 : urls.length,
            onPageChanged: onChanged,
            itemBuilder: (context, i) {
              final image = AppNetworkImage(
                url: urls.isEmpty ? null : urls[i],
              );
              // Le 1er visuel porte le héros partagé (cohérence avec la grille).
              return i == 0
                  ? Hero(tag: 'catalog-$heroId', child: image)
                  : image;
            },
          ),
          if (urls.length > 1)
            Positioned(
              bottom: 14,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var i = 0; i < urls.length; i++)
                    AnimatedContainer(
                      duration: AppMotion.micro,
                      width: i == index ? 22 : 7,
                      height: 7,
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4),
                        color: i == index
                            ? AppColors.gold
                            : AppColors.cream.withValues(alpha: 0.6),
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
      if (!product.inStock) {
        return _chip(l10n.t('product.outOfStock'), AppColors.terracotta);
      }
      return const SizedBox.shrink();
    }
    if (!variant!.inStock) {
      return _chip(l10n.t('product.outOfStock'), AppColors.terracotta);
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
        Icon(Icons.circle, size: 8, color: color),
        const SizedBox(width: 7),
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
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        text.toUpperCase(),
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          fontWeight: FontWeight.w600,
          letterSpacing: 1.6,
          color: AppColors.taupe,
        ),
      ),
    );
  }
}

/// Pastille de taille (rectangle arrondi, sélection charbon, désactivée barrée).
class _SizePill extends StatelessWidget {
  const _SizePill({
    required this.label,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: enabled,
      selected: selected,
      label: label,
      child: Opacity(
        opacity: enabled ? 1 : 0.4,
        child: InkWell(
          onTap: enabled ? onTap : null,
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          child: Container(
            constraints: const BoxConstraints(minWidth: 48, minHeight: 44),
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: selected ? AppColors.charcoal : AppColors.paper,
              border: Border.all(
                color: selected ? AppColors.charcoal : AppColors.line,
                width: selected ? 1.5 : 1,
              ),
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            ),
            child: Text(
              label,
              style: TextStyle(
                color: selected ? AppColors.cream : AppColors.ink,
                fontWeight: FontWeight.w600,
                decoration: enabled ? null : TextDecoration.lineThrough,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Pastille de couleur : swatch + libellé, anneau doré si sélectionnée.
class _ColorPill extends StatelessWidget {
  const _ColorPill({
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
    return Semantics(
      button: true,
      enabled: enabled,
      selected: selected,
      label: color,
      child: Opacity(
        opacity: enabled ? 1 : 0.4,
        child: InkWell(
          onTap: enabled ? onTap : null,
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          child: Container(
            constraints: const BoxConstraints(minHeight: 44),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.paper,
              border: Border.all(
                color: selected ? AppColors.gold : AppColors.line,
                width: selected ? 1.8 : 1,
              ),
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (swatch != null) ...[
                  Container(
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      color: swatch,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.line),
                    ),
                  ),
                  const SizedBox(width: 9),
                ],
                Text(
                  color,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ],
            ),
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
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w600,
              letterSpacing: 1.6,
              color: AppColors.taupe,
            ),
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}

/// Barre collante premium « Ajouter au panier » : prix à gauche, CTA à droite.
class _StickyAddBar extends StatelessWidget {
  const _StickyAddBar({
    required this.enabled,
    required this.loading,
    required this.label,
    required this.price,
    required this.onPressed,
    this.compareAt,
  });

  final bool enabled;
  final bool loading;
  final String label;
  final int price;
  final int? compareAt;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.cream,
        border: Border(top: BorderSide(color: AppColors.line)),
        boxShadow: [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 16,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.md,
            AppSpacing.lg,
            AppSpacing.md,
          ),
          child: Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    context.l10n.t('cart.total').toUpperCase(),
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppColors.taupe,
                      letterSpacing: 1.4,
                    ),
                  ),
                  const SizedBox(height: 2),
                  PriceText(
                    amount: price,
                    compareAt: compareAt,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: PrimaryButton(
                  label: label,
                  loading: loading,
                  variant: ButtonVariant.gold,
                  icon: enabled ? Icons.shopping_bag_outlined : null,
                  onPressed: enabled ? onPressed : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
