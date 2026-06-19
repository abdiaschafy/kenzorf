import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Sélecteur de quantité (- valeur +), borné entre [min] et [max].
class QuantityStepper extends StatelessWidget {
  const QuantityStepper({
    super.key,
    required this.value,
    required this.onChanged,
    this.min = 1,
    this.max = 99,
    this.enabled = true,
  });

  final int value;
  final ValueChanged<int> onChanged;
  final int min;
  final int max;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final canDecrement = enabled && value > min;
    final canIncrement = enabled && value < max;

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.line),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _btn(
            icon: Icons.remove,
            onTap: canDecrement ? () => onChanged(value - 1) : null,
          ),
          Container(
            constraints: const BoxConstraints(minWidth: 40),
            alignment: Alignment.center,
            child: Text(
              '$value',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          _btn(
            icon: Icons.add,
            onTap: canIncrement ? () => onChanged(value + 1) : null,
          ),
        ],
      ),
    );
  }

  Widget _btn({required IconData icon, VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Icon(
          icon,
          size: 20,
          color: onTap == null ? AppColors.line : AppColors.ink,
        ),
      ),
    );
  }
}
