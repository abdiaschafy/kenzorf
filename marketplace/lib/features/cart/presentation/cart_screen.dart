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
import '../../../core/widgets/state_views.dart';
import '../application/cart_controller.dart';

/// Panier : lignes, quantités modifiables, sous-total, accès au checkout.
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
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.t('common.delete')),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(cartControllerProvider.notifier).clear();
    }
  }
}

class _CartContent extends ConsumerWidget {
  const _CartContent({required this.cart});
  final Cart cart;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    return Column(
      children: [
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: cart.items.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, i) => _CartLine(item: cart.items[i]),
          ),
        ),
        _CartSummary(cart: cart, l10n: l10n),
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
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppNetworkImage(
              url: item.imageUrl,
              width: 76,
              height: 96,
              borderRadius: BorderRadius.circular(10),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.productName,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (item.variantLabel.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      item.variantLabel,
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: AppColors.stone),
                    ),
                  ],
                  const SizedBox(height: 8),
                  PriceText(amount: item.lineTotal),
                  const SizedBox(height: 8),
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
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CartSummary extends StatelessWidget {
  const _CartSummary({required this.cart, required this.l10n});
  final Cart cart;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          border: Border(top: BorderSide(color: AppColors.line)),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  l10n.t('cart.subtotal'),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                PriceText(
                  amount: cart.subtotal,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                ),
              ],
            ),
            const SizedBox(height: 14),
            PrimaryButton(
              label: l10n.t('cart.checkout'),
              icon: Icons.lock_outline,
              onPressed: () => context.push(AppRoutes.checkout),
            ),
          ],
        ),
      ),
    );
  }
}
