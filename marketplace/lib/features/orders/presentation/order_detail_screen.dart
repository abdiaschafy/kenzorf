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
import '../../../core/widgets/price_text.dart';
import '../../../core/widgets/state_views.dart';
import '../../../core/widgets/status_badge.dart';
import '../application/orders_providers.dart';
import '../data/orders_repository.dart';

/// Détail d'une commande : statut, articles, livraison, paiement, actions.
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

  void _payNow() {
    // Relance la page de paiement pour une commande encore en attente.
    context.push(AppRoutes.payment, extra: order);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final locale = ref.watch(localeControllerProvider).languageCode;

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              // En-tête statut
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      l10n.t('orders.number', {'number': order.orderNumber}),
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  OrderStatusBadge(status: order.status),
                ],
              ),
              if (order.placedAt != null) ...[
                const SizedBox(height: 6),
                Text(
                  l10n.t('orders.placedAt', {
                    'date': AppDateFormatter.dateTime(order.placedAt, locale),
                  }),
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: AppColors.stone),
                ),
              ],
              const Divider(height: 32),

              // Articles
              _SectionTitle(l10n.t('orders.detail.items')),
              ...order.items.map((item) => _OrderItemTile(item: item)),
              const Divider(height: 32),

              // Récapitulatif montants
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
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    l10n.t('cart.total'),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  PriceText(
                    amount: order.total,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),

              // Livraison
              if (order.shippingAddress != null) ...[
                const Divider(height: 32),
                _SectionTitle(l10n.t('orders.detail.shipping')),
                Text(
                  order.shippingAddress!.fullName,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                Text(order.shippingAddress!.phoneNumber),
                const SizedBox(height: 2),
                Text(order.shippingAddress!.oneLine),
              ],

              // Paiement
              if (order.payment != null) ...[
                const Divider(height: 32),
                _SectionTitle(l10n.t('orders.detail.payment')),
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
                  Text(l10n.t(order.payment!.paymentMethod!.l10nKey)),
                ],
              ],

              if (order.customerNote != null &&
                  order.customerNote!.isNotEmpty) ...[
                const Divider(height: 32),
                _SectionTitle(l10n.t('checkout.note.label')),
                Text(order.customerNote!),
              ],
            ],
          ),
        ),
        if (order.status.isCancellable || order.status.isPayable)
          _ActionBar(
            order: order,
            cancelling: _cancelling,
            onCancel: order.status.isCancellable ? _cancel : null,
            onPay: order.status.isPayable && order.payment?.checkoutUrl != null
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
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
          PriceText(
            amount: amount,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
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
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppNetworkImage(
            url: item.imageUrl,
            width: 56,
            height: 70,
            borderRadius: BorderRadius.circular(8),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.productName,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                if (item.variantLabel.isNotEmpty)
                  Text(
                    item.variantLabel,
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: AppColors.stone),
                  ),
                const SizedBox(height: 4),
                Text(
                  '${item.quantity} × ${PriceFormatter.format(item.unitPrice, currency: context.l10n.t('common.currency'))}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          PriceText(
            amount: item.lineTotal,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ],
      ),
    );
  }
}

class _ActionBar extends StatelessWidget {
  const _ActionBar({
    required this.order,
    required this.cancelling,
    this.onCancel,
    this.onPay,
  });

  final Order order;
  final bool cancelling;
  final VoidCallback? onCancel;
  final VoidCallback? onPay;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          border: Border(top: BorderSide(color: AppColors.line)),
        ),
        child: Row(
          children: [
            if (onCancel != null)
              Expanded(
                child: OutlinedButton(
                  onPressed: cancelling ? null : onCancel,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.danger,
                    side: const BorderSide(color: AppColors.danger),
                  ),
                  child: cancelling
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(l10n.t('orders.cancel')),
                ),
              ),
            if (onCancel != null && onPay != null) const SizedBox(width: 12),
            if (onPay != null)
              Expanded(
                child: ElevatedButton(
                  onPressed: onPay,
                  child: Text(l10n.t('orders.payNow')),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title);
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: Theme.of(
          context,
        ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
      ),
    );
  }
}
