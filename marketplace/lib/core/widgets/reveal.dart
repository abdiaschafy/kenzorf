import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Apparition soignée d'un élément : fondu + léger glissement vers le haut.
///
/// - Respecte `prefers-reduced-motion` (via `MediaQuery.disableAnimations`) :
///   l'élément apparaît alors instantanément, sans déplacement.
/// - [delay] permet d'échelonner l'apparition d'une liste (effet "stagger").
/// - N'anime que `opacity` et `transform` (pas de reflow / CLS).
class Reveal extends StatefulWidget {
  const Reveal({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.offset = 18,
  });

  final Widget child;

  /// Décalage avant le démarrage (pour échelonner plusieurs Reveal).
  final Duration delay;

  /// Distance de glissement initiale (px, vers le haut).
  final double offset;

  @override
  State<Reveal> createState() => _RevealState();
}

class _RevealState extends State<Reveal> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: AppMotion.enter,
  );

  late final Animation<double> _fade = CurvedAnimation(
    parent: _controller,
    curve: AppMotion.easeEnter,
  );

  bool _started = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _maybeStart() {
    if (_started) return;
    _started = true;
    // Démarrage différé pour l'effet d'échelonnement.
    Future<void>.delayed(widget.delay, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (reduceMotion) {
      // Accessibilité : pas d'animation, contenu immédiatement lisible.
      return widget.child;
    }

    _maybeStart();

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Opacity(
          opacity: _fade.value,
          child: Transform.translate(
            offset: Offset(0, widget.offset * (1 - _fade.value)),
            child: child,
          ),
        );
      },
      child: widget.child,
    );
  }
}
