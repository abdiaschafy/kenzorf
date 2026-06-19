import 'package:flutter/material.dart';

/// Conversion d'un code couleur hexadécimal (`#RRGGBB` ou `RRGGBB`) en [Color].
/// Retourne null si la valeur est absente ou invalide.
Color? colorFromHex(String? hex) {
  if (hex == null || hex.isEmpty) return null;
  var value = hex.trim().replaceFirst('#', '');
  if (value.length == 6) value = 'FF$value'; // alpha opaque
  if (value.length != 8) return null;
  final parsed = int.tryParse(value, radix: 16);
  if (parsed == null) return null;
  return Color(parsed);
}
