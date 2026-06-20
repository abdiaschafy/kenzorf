import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../../core/models/cart.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/error_localizer.dart';
import '../../../core/widgets/app_network_image.dart';
import '../../../core/widgets/price_text.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/quantity_stepper.dart';
import '../../../core/widgets/reveal.dart';
import '../../../core/widgets/state_views.dart';
import '../application/cart_controller.dart';

/// Panier : lignes raffinées, quantités modifiables, sous-total, checkout.
class CartScreen extends ConsumerWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final cartAsync = ref.watch(cartControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.t('cart.title')),
        actions: [
          cartAsync.maybeWhen(
            data: (cart) => cart.isEmpty
                ? const SizedBox.shrink()
                : IconButton(
                    icon: const Icon(Icons.delete_sweep_outlined),
                    tooltip: l10n.t('cart.clear'),
                    onPressed: () => _confirmClear(context, ref),
                  ),
            orElse: () => const SizedBox.shrink(),
          ),
        ],
      ),
      body: cartAsync.when(
        loading: () => const LoadingView(),
        error: (e, _) => ErrorView(
          message: l10n.describeError(e),
          onRetry: () => ref.read(cartControllerProvider.notifier).refresh(),
        ),
        data: (cart) {
          if (cart.isEmpty) {
            return EmptyView(
              icon: Icons.shopping_bag_outlined,
              title: l10n.t('cart.empty.title'),
              message: l10n.t('cart.empty.message'),
              actionLabel: l10n.t('cart.empty.cta'),
              onAction: () => context.go(AppRoutes.catalog),
            );
          }
          return _CartContent(cart: cart);
        },
      ),
    );
  }

  Future<void> _confirmClear(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.t('cart.clear')),
        content: Text(l10n.t('cart.empty.message')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.t('common.cancel')),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: AppColors.terracotta),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.t('common.delete')),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    // Vidage robuste : `clear()` relève une ApiException localisable en cas
    // d'échec — on l'attrape pour afficher un toast, jamais d'écran rouge.
    try {
      await ref.read(cartControllerProvider.notifier).clear();
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.describeError(e))));
      }
    }
  }
}

class _CartContent extends StatelessWidget {
  const _CartContent({required this.cart});
  final Cart cart;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.all(AppSpacing.md),
            itemCount: cart.items.length,
            separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
            itemBuilder: (context, i) => Reveal(
              delay: AppMotion.stagger * (i.clamp(0, 6)),
              child: _CartLine(item: cart.items[i]),
            ),
          ),
        ),
        _CartSummary(cart: cart),
      ],
    );
  }
}

class _CartLine extends ConsumerWidget {
  const _CartLine({required this.item});
  final CartItem item;

  Future<void> _update(WidgetRef ref, BuildContext context, int qty) async {
    final l10n = context.l10n;
    try {
      await ref
          .read(cartControllerProvider.notifier)
          .updateQuantity(itemId: item.id, quantity: qty);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.describeError(e))));
      }
    }
  }

  Future<void> _remove(WidgetRef ref, BuildContext context) async {
    final l10n = context.l10n;
    try {
      await ref.read(cartControllerProvider.notifier).removeItem(item.id);
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.t('cart.itemRemoved'))));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.describeError(e))));
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.line),
      ),
      padding: const EdgeInsets.all(AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppNetworkImage(
            url: item.imageUrl,
            width: 84,
            height: 104,
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.productName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (item.variantLabel.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    item.variantLabel,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.taupe,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                PriceText(
                  amount: item.lineTotal,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    QuantityStepper(
                      value: item.quantity,
                      min: 1,
                      max: item.stockQuantity > 0 ? item.stockQuantity : 1,
                      onChanged: (q) => _update(ref, context, q),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline),
                      color: AppColors.taupe,
                      tooltip: l10n.t('cart.remove'),
                      onPressed: () => _remove(ref, context),
                    ),
                  ],
                ),
                if (item.atMaxStock)
                  Text(
                    l10n.t('cart.maxStock'),
                    style: const TextStyle(
                      color: AppColors.warning,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
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

class _CartSummary extends StatelessWidget {
  const _CartSummary({required this.cart});
  final Cart cart;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.cream,
        border: Border(top: BorderSide(color: AppColors.line)),
        boxShadow: [
          BoxShadow(
            color: Color(0x12000000),
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
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    l10n.t('cart.subtotal'),
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: AppColors.taupe,
                    ),
                  ),
                  PriceText(
                    amount: cart.subtotal,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              PrimaryButton(
                label: l10n.t('cart.checkout'),
                icon: Icons.lock_outline,
                onPressed: () => context.push(AppRoutes.checkout),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
