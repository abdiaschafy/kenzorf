import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Monogramme KENZORF — la lettre « K » dessinée (barre verticale + chevron),
/// rendue en vectoriel via [CustomPainter] pour rester nette à toute taille et
/// se teinter selon le contexte (accent doré, filigrane, etc.).
///
/// Utilisé comme accent de marque (en-têtes, filigrane d'écran, splash custom).
class BrandMonogram extends StatelessWidget {
  const BrandMonogram({
    super.key,
    this.size = 40,
    this.color = AppColors.gold,
    this.strokeWidthFactor = 0.20,
    this.semanticLabel,
  });

  /// Côté du carré de dessin.
  final double size;

  /// Couleur du trait.
  final Color color;

  /// Épaisseur du trait, proportion de [size] (0.20 ≈ proportions de la marque).
  final double strokeWidthFactor;

  /// Libellé d'accessibilité éventuel (sinon décoratif/masqué aux lecteurs).
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final monogram = CustomPaint(
      size: Size.square(size),
      painter: _MonogramPainter(
        color: color,
        strokeWidthFactor: strokeWidthFactor,
      ),
    );
    if (semanticLabel == null) {
      return ExcludeSemantics(child: monogram);
    }
    return Semantics(label: semanticLabel, image: true, child: monogram);
  }
}

class _MonogramPainter extends CustomPainter {
  _MonogramPainter({required this.color, required this.strokeWidthFactor});

  final Color color;
  final double strokeWidthFactor;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final sw = w * strokeWidthFactor;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = sw
      ..strokeCap = StrokeCap.square
      ..strokeJoin = StrokeJoin.miter
      ..isAntiAlias = true;

    // Coordonnées normalisées sur le même canon que l'icône (viewBox 1024,
    // tracé 312..712 / barre x=372 / chevron apex x=452 à droite x=700).
    double nx(double v) => (v / 1024) * w;
    double ny(double v) => (v / 1024) * size.height;

    // Barre verticale.
    canvas.drawLine(Offset(nx(372), ny(312)), Offset(nx(372), ny(712)), paint);

    // Chevron (haut → apex → bas).
    final chevron = Path()
      ..moveTo(nx(700), ny(312))
      ..lineTo(nx(452), ny(512))
      ..lineTo(nx(700), ny(712));
    canvas.drawPath(chevron, paint);
  }

  @override
  bool shouldRepaint(_MonogramPainter old) =>
      old.color != color || old.strokeWidthFactor != strokeWidthFactor;
}

/// Filigrane discret du monogramme (grand, très transparent) à poser en fond
/// d'un en-tête ou d'une section pour signer la marque sans surcharger.
class MonogramWatermark extends StatelessWidget {
  const MonogramWatermark({
    super.key,
    this.size = 220,
    this.opacity = 0.06,
    this.color = AppColors.charcoal,
  });

  final double size;
  final double opacity;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: ExcludeSemantics(
        child: Opacity(
          opacity: opacity,
          child: BrandMonogram(
            size: size,
            color: color,
            strokeWidthFactor: 0.14,
          ),
        ),
      ),
    );
  }
}
