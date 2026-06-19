import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../theme/app_theme.dart';
import '../utils/price_formatter.dart';

/// Affiche un prix FCFA, avec éventuellement un prix barré (promo).
class PriceText extends StatelessWidget {
  const PriceText({
    super.key,
    required this.amount,
    this.compareAt,
    this.style,
    this.compareStyle,
  });

  final int amount;
  final int? compareAt;
  final TextStyle? style;
  final TextStyle? compareStyle;

  @override
  Widget build(BuildContext context) {
    final currency = context.l10n.t('common.currency');
    final base =
        style ??
        Theme.of(
          context,
        ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700);

    final hasDiscount = compareAt != null && compareAt! > amount;

    if (!hasDiscount) {
      return Text(
        PriceFormatter.format(amount, currency: currency),
        style: base,
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(PriceFormatter.format(amount, currency: currency), style: base),
        const SizedBox(width: 8),
        Text(
          PriceFormatter.format(compareAt!, currency: currency),
          style:
              compareStyle ??
              Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.stone,
                decoration: TextDecoration.lineThrough,
              ),
        ),
      ],
    );
  }
}
