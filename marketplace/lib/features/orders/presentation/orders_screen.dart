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
import '../../../core/widgets/editorial.dart';
import '../../../core/widgets/price_text.dart';
import '../../../core/widgets/reveal.dart';
import '../../../core/widgets/state_views.dart';
import '../../../core/widgets/status_badge.dart';
import '../application/orders_providers.dart';

/// Liste des commandes du client — cartes éditoriales.
class OrdersScreen extends ConsumerWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final ordersAsync = ref.watch(ordersListProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.t('orders.title'))),
      body: ordersAsync.when(
        loading: () => const LoadingView(),
        error: (e, _) => ErrorView(
          message: l10n.describeError(e),
          onRetry: () => ref.invalidate(ordersListProvider),
        ),
        data: (orders) {
          if (orders.isEmpty) {
            return EmptyView(
              icon: Icons.receipt_long_outlined,
              title: l10n.t('orders.empty.title'),
              message: l10n.t('orders.empty.message'),
              actionLabel: l10n.t('orders.empty.cta'),
              onAction: () => context.go(AppRoutes.catalog),
            );
          }
          return RefreshIndicator(
            color: AppColors.gold,
            onRefresh: () async => ref.invalidate(ordersListProvider),
            child: ListView.separated(
              padding: const EdgeInsets.all(AppSpacing.md),
              itemCount: orders.length,
              separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
              itemBuilder: (context, i) => Reveal(
                delay: AppMotion.stagger * (i.clamp(0, 6)),
                child: _OrderCard(order: orders[i]),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _OrderCard extends ConsumerWidget {
  const _OrderCard({required this.order});
  final OrderSummary order;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final locale = ref.watch(localeControllerProvider).languageCode;

    return PressableScale(
      onTap: () => context.push(AppRoutes.orderDetailPath(order.id)),
      semanticLabel: l10n.t('orders.number', {'number': order.orderNumber}),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(color: AppColors.line),
        ),
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    l10n.t('orders.number', {'number': order.orderNumber}),
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                OrderStatusBadge(status: order.status),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              order.placedAt == null
                  ? ''
                  : l10n.t('orders.placedAt', {
                      'date': AppDateFormatter.date(order.placedAt, locale),
                    }),
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.taupe,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            const Divider(height: 1),
            const SizedBox(height: AppSpacing.md),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  l10n.t('orders.itemCount', {'count': order.itemCount}),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppColors.taupe,
                  ),
                ),
                PriceText(
                  amount: order.total,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
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
