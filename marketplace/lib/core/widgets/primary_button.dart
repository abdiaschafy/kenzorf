import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Variantes visuelles du bouton principal KENZORF.
enum ButtonVariant {
  /// Aplat charbon (action principale par défaut).
  solid,

  /// Contour fin (action secondaire).
  outline,

  /// Aplat doré (mise en avant chaleureuse).
  gold,
}

/// Bouton principal KENZORF, avec état de chargement intégré, léger retour
/// d'échelle au press et hauteur conforme aux cibles tactiles (≥ 54).
///
/// Quand [loading] est vrai, le bouton est désactivé et affiche un indicateur.
class PrimaryButton extends StatefulWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
    this.icon,
    this.variant = ButtonVariant.solid,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final IconData? icon;
  final ButtonVariant variant;

  @override
  State<PrimaryButton> createState() => _PrimaryButtonState();
}

class _PrimaryButtonState extends State<PrimaryButton> {
  bool _pressed = false;

  void _set(bool v) {
    if (_pressed != v) setState(() => _pressed = v);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final disabled = widget.loading || widget.onPressed == null;

    final (Color bg, Color fg, BorderSide side) = switch (widget.variant) {
      ButtonVariant.solid => (scheme.primary, scheme.onPrimary, BorderSide.none),
      ButtonVariant.gold => (
        AppColors.gold,
        AppColors.charcoal,
        BorderSide.none,
      ),
      ButtonVariant.outline => (
        Colors.transparent,
        scheme.primary,
        BorderSide(color: scheme.primary, width: 1.3),
      ),
    };

    final spinnerColor = widget.variant == ButtonVariant.outline
        ? scheme.primary
        : fg;

    final Widget child = widget.loading
        ? SizedBox(
            height: 22,
            width: 22,
            child: CircularProgressIndicator(
              strokeWidth: 2.4,
              valueColor: AlwaysStoppedAnimation<Color>(spinnerColor),
            ),
          )
        : (widget.icon != null
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(widget.icon, size: 20),
                    const SizedBox(width: 10),
                    Flexible(
                      child: Text(
                        widget.label,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                )
              : Text(widget.label, overflow: TextOverflow.ellipsis));

    return Semantics(
      button: true,
      enabled: !disabled,
      label: widget.label,
      child: GestureDetector(
        onTapDown: disabled ? null : (_) => _set(true),
        onTapUp: disabled ? null : (_) => _set(false),
        onTapCancel: disabled ? null : () => _set(false),
        onTap: disabled ? null : widget.onPressed,
        child: AnimatedScale(
          scale: _pressed ? 0.98 : 1,
          duration: AppMotion.micro,
          curve: Curves.easeOut,
          child: AnimatedOpacity(
            opacity: disabled && !widget.loading ? 0.5 : 1,
            duration: AppMotion.micro,
            child: Container(
              height: 54,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: bg,
                border: side == BorderSide.none ? null : Border.fromBorderSide(side),
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              ),
              child: DefaultTextStyle.merge(
                style: TextStyle(
                  color: fg,
                  fontWeight: FontWeight.w600,
                  fontSize: 15.5,
                  letterSpacing: 0.4,
                ),
                child: IconTheme.merge(
                  data: IconThemeData(color: fg),
                  child: child,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
