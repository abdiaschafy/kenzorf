import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../../core/l10n/locale_controller.dart';
import '../../../core/models/order.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/utils/error_localizer.dart';
import '../../../core/utils/price_formatter.dart';
import '../../../core/widgets/app_network_image.dart';
import '../../../core/widgets/order_timeline.dart';
import '../../../core/widgets/price_text.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/state_views.dart';
import '../../../core/widgets/status_badge.dart';
import '../application/orders_providers.dart';
import '../data/orders_repository.dart';

/// Détail d'une commande : statut en timeline, articles, livraison, paiement.
class OrderDetailScreen extends ConsumerWidget {
  const OrderDetailScreen({super.key, required this.orderId});

  final String orderId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final orderAsync = ref.watch(orderDetailProvider(orderId));

    return Scaffold(
      appBar: AppBar(title: Text(l10n.t('orders.detail.title'))),
      body: orderAsync.when(
        loading: () => const LoadingView(),
        error: (e, _) => ErrorView(
          message: l10n.describeError(e),
          onRetry: () => ref.invalidate(orderDetailProvider(orderId)),
        ),
        data: (order) => _OrderDetailBody(order: order),
      ),
    );
  }
}

class _OrderDetailBody extends ConsumerStatefulWidget {
  const _OrderDetailBody({required this.order});
  final Order order;

  @override
  ConsumerState<_OrderDetailBody> createState() => _OrderDetailBodyState();
}

class _OrderDetailBodyState extends ConsumerState<_OrderDetailBody> {
  bool _cancelling = false;

  Order get order => widget.order;

  Future<void> _cancel() async {
    final l10n = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.t('orders.cancel')),
        content: Text(l10n.t('orders.number', {'number': order.orderNumber})),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.t('common.no')),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: AppColors.terracotta),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.t('common.yes')),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _cancelling = true);
    try {
      await ref.read(ordersRepositoryProvider).cancel(order.id);
      ref.invalidate(orderDetailProvider(order.id));
      ref.invalidate(ordersListProvider);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.t('orders.cancelled'))));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.describeError(e))));
      }
    } finally {
      if (mounted) setState(() => _cancelling = false);
    }
  }

  void _payNow() => context.push(AppRoutes.payment, extra: order);

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final locale = ref.watch(localeControllerProvider).languageCode;

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              // En-tête : numéro + badge statut.
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.t('orders.number', {
                            'number': order.orderNumber,
                          }),
                          style: theme.textTheme.headlineSmall,
                        ),
                        if (order.placedAt != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            l10n.t('orders.placedAt', {
                              'date': AppDateFormatter.dateTime(
                                order.placedAt,
                                locale,
                              ),
                            }),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: AppColors.taupe,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  OrderStatusBadge(status: order.status),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),

              // Timeline de suivi.
              _Card(
                title: l10n.t('orders.timeline'),
                child: OrderTimeline(status: order.status),
              ),

              // Articles.
              _Card(
                title: l10n.t('orders.detail.items'),
                child: Column(
                  children: order.items
                      .map((item) => _OrderItemTile(item: item))
                      .toList(),
                ),
              ),

              // Récapitulatif montants.
              _Card(
                title: l10n.t('orders.detail.summary'),
                child: Column(
                  children: [
                    _amountRow(
                      context,
                      l10n.t('checkout.summary.subtotal'),
                      order.subtotal,
                    ),
                    if (order.shippingFee > 0)
                      _amountRow(
                        context,
                        l10n.t('checkout.summary.shipping'),
                        order.shippingFee,
                      ),
                    if (order.discount > 0)
                      _amountRow(
                        context,
                        l10n.t('checkout.summary.discount'),
                        -order.discount,
                      ),
                    const Divider(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          l10n.t('cart.total'),
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        PriceText(
                          amount: order.total,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              if (order.shippingAddress != null)
                _Card(
                  title: l10n.t('orders.detail.shipping'),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        order.shippingAddress!.fullName,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(order.shippingAddress!.phoneNumber),
                      const SizedBox(height: 2),
                      Text(
                        order.shippingAddress!.oneLine,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: AppColors.taupe,
                        ),
                      ),
                    ],
                  ),
                ),

              if (order.payment != null)
                _Card(
                  title: l10n.t('orders.detail.payment'),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            order.payment!.provider.isEmpty
                                ? l10n.t('orders.detail.payment')
                                : order.payment!.provider,
                          ),
                          Text(
                            l10n.t(order.payment!.status.l10nKey),
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                      if (order.payment!.paymentMethod != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          l10n.t(order.payment!.paymentMethod!.l10nKey),
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: AppColors.taupe,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

              if (order.customerNote != null && order.customerNote!.isNotEmpty)
                _Card(
                  title: l10n.t('orders.detail.note'),
                  child: Text(order.customerNote!),
                ),
            ],
          ),
        ),
        if (order.status.isCancellable || order.status.isPayable)
          _ActionBar(
            cancelling: _cancelling,
            onCancel: order.status.isCancellable ? _cancel : null,
            onPay:
                order.status.isPayable &&
                    order.payment?.checkoutUrl != null
                ? _payNow
                : null,
          ),
      ],
    );
  }

  Widget _amountRow(BuildContext context, String label, int amount) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.taupe,
            ),
          ),
          PriceText(amount: amount, style: Theme.of(context).textTheme.bodyLarge),
        ],
      ),
    );
  }
}

/// Bloc de détail encadré, avec titre en capitales.
class _Card extends StatelessWidget {
  const _Card({required this.title, required this.child});
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.line),
      ),
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
          const SizedBox(height: AppSpacing.md),
          child,
        ],
      ),
    );
  }
}

class _OrderItemTile extends StatelessWidget {
  const _OrderItemTile({required this.item});
  final OrderItem item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppNetworkImage(
            url: item.imageUrl,
            width: 56,
            height: 70,
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.productName,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (item.variantLabel.isNotEmpty)
                  Text(
                    item.variantLabel,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.taupe,
                    ),
                  ),
                const SizedBox(height: 4),
                Text(
                  '${item.quantity} × ${PriceFormatter.format(item.unitPrice, currency: context.l10n.t('common.currency'))}',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
          PriceText(amount: item.lineTotal, style: theme.textTheme.bodyLarge),
        ],
      ),
    );
  }
}

class _ActionBar extends StatelessWidget {
  const _ActionBar({required this.cancelling, this.onCancel, this.onPay});

  final bool cancelling;
  final VoidCallback? onCancel;
  final VoidCallback? onPay;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.cream,
        border: Border(top: BorderSide(color: AppColors.line)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              if (onCancel != null)
                Expanded(
                  child: OutlinedButton(
                    onPressed: cancelling ? null : onCancel,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.terracotta,
                      side: const BorderSide(color: AppColors.terracotta),
                      minimumSize: const Size.fromHeight(52),
                    ),
                    child: cancelling
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.terracotta,
                            ),
                          )
                        : Text(l10n.t('orders.cancel')),
                  ),
                ),
              if (onCancel != null && onPay != null)
                const SizedBox(width: AppSpacing.md),
              if (onPay != null)
                Expanded(
                  child: PrimaryButton(
                    label: l10n.t('orders.payNow'),
                    variant: ButtonVariant.gold,
                    onPressed: onPay,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
