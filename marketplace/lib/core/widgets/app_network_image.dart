import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Image réseau mise en cache, avec placeholder et fallback uniformes.
///
/// Gère le cas d'une URL nulle/vide (affiche un visuel de remplacement).
class AppNetworkImage extends StatelessWidget {
  const AppNetworkImage({
    super.key,
    required this.url,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.width,
    this.height,
  });

  final String? url;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final double? width;
  final double? height;

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? BorderRadius.zero;

    Widget content;
    if (url == null || url!.isEmpty) {
      content = _placeholder(context, isError: false);
    } else {
      content = CachedNetworkImage(
        imageUrl: url!,
        fit: fit,
        width: width,
        height: height,
        placeholder: (context, _) => _placeholder(context, isError: false),
        errorWidget: (ctx, _, _) => _placeholder(ctx, isError: true),
      );
    }

    return ClipRRect(borderRadius: radius, child: content);
  }

  Widget _placeholder(BuildContext context, {required bool isError}) {
    return Container(
      width: width,
      height: height,
      color: AppColors.sand,
      alignment: Alignment.center,
      child: Icon(
        isError ? Icons.broken_image_outlined : Icons.checkroom_outlined,
        color: AppColors.gold.withValues(alpha: 0.5),
        size: 34,
      ),
    );
  }
}
