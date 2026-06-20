import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/enums.dart';
import '../theme/app_theme.dart';

/// Timeline verticale du statut d'une commande (Pending → … → Delivered).
///
/// Les étapes atteintes sont marquées d'une pastille dorée pleine ; l'étape
/// courante est mise en valeur ; les suivantes restent estompées. Les états
/// terminaux négatifs (annulée / remboursée) affichent une étape distincte.
class OrderTimeline extends StatelessWidget {
  const OrderTimeline({super.key, required this.status});

  final OrderStatus status;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    if (status.isTerminalNegative) {
      return _StepRow(
        label: l10n.t(status.l10nKey),
        reached: true,
        current: true,
        isLast: true,
        color: AppColors.terracotta,
        textStyle: theme.textTheme.bodyLarge,
      );
    }

    final steps = OrderStatus.timeline;
    final currentIndex = status.timelineIndex;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < steps.length; i++)
          _StepRow(
            label: l10n.t(steps[i].l10nKey),
            reached: i <= currentIndex,
            current: i == currentIndex,
            isLast: i == steps.length - 1,
            color: AppColors.gold,
            textStyle: theme.textTheme.bodyLarge,
          ),
      ],
    );
  }
}

class _StepRow extends StatelessWidget {
  const _StepRow({
    required this.label,
    required this.reached,
    required this.current,
    required this.isLast,
    required this.color,
    this.textStyle,
  });

  final String label;
  final bool reached;
  final bool current;
  final bool isLast;
  final Color color;
  final TextStyle? textStyle;

  @override
  Widget build(BuildContext context) {
    final dotColor = reached ? color : AppColors.line;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: current ? 16 : 12,
                height: current ? 16 : 12,
                margin: EdgeInsets.only(top: current ? 2 : 4),
                decoration: BoxDecoration(
                  color: reached ? dotColor : Colors.transparent,
                  shape: BoxShape.circle,
                  border: Border.all(color: dotColor, width: 2),
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    margin: const EdgeInsets.symmetric(vertical: 2),
                    color: reached ? color.withValues(alpha: 0.4) : AppColors.line,
                  ),
                ),
            ],
          ),
          const SizedBox(width: AppSpacing.md),
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: Text(
              label,
              style: textStyle?.copyWith(
                fontWeight: current ? FontWeight.w600 : FontWeight.w400,
                color: reached ? AppColors.ink : AppColors.taupe,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
