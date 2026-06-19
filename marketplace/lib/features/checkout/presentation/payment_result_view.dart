import 'package:flutter/material.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/primary_button.dart';

/// Écran de résultat de paiement : succès, échec ou en attente (timeout).
class PaymentResultView extends StatelessWidget {
  const PaymentResultView({
    super.key,
    required this.succeeded,
    required this.orderId,
    required this.onViewOrder,
    required this.onRetry,
  }) : _pending = false;

  /// Variante "en attente" (statut non encore confirmé après timeout).
  const PaymentResultView.pending({
    super.key,
    required this.orderId,
    required this.onViewOrder,
  }) : succeeded = false,
       onRetry = null,
       _pending = true;

  final bool succeeded;
  final String orderId;
  final VoidCallback onViewOrder;
  final VoidCallback? onRetry;
  final bool _pending;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    final IconData icon;
    final Color color;
    final String title;
    final String message;

    if (_pending) {
      icon = Icons.hourglass_bottom;
      color = AppColors.warning;
      title = l10n.t('checkout.pending.title');
      message = l10n.t('checkout.pending.message');
    } else if (succeeded) {
      icon = Icons.check_circle;
      color = AppColors.success;
      title = l10n.t('checkout.success.title');
      message = l10n.t('checkout.success.message');
    } else {
      icon = Icons.cancel;
      color = AppColors.danger;
      title = l10n.t('checkout.failure.title');
      message = l10n.t('checkout.failure.message');
    }

    return Scaffold(
      appBar: AppBar(automaticallyImplyLeading: false),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Icon(icon, size: 88, color: color),
              const SizedBox(height: 24),
              Text(
                title,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                message,
                textAlign: TextAlign.center,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: AppColors.stone),
              ),
              const SizedBox(height: 40),
              PrimaryButton(
                label: l10n.t('checkout.success.cta'),
                onPressed: onViewOrder,
              ),
              if (onRetry != null && !succeeded) ...[
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: onRetry,
                  child: Text(l10n.t('checkout.failure.cta')),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
