import 'package:flutter/material.dart';

import '../../core/l10n/app_localizations.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/brand_monogram.dart';

/// Écran de démarrage affiché pendant la restauration de session
/// (statut d'authentification `unknown`). Fond charbon, monogramme doré animé,
/// mot-symbole en serif — prolonge le splash natif sans rupture.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  );

  @override
  void initState() {
    super.initState();
    _c.repeat(reverse: true);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final reduce = MediaQuery.maybeOf(context)?.disableAnimations ?? false;

    return Scaffold(
      backgroundColor: AppColors.charcoal,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.gold, width: 1.4),
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              ),
              alignment: Alignment.center,
              child: const BrandMonogram(size: 52, color: AppColors.goldLight),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              l10n.t('app.name').toUpperCase(),
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: AppColors.cream,
                letterSpacing: 8,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              l10n.t('brand.tagline'),
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: AppColors.gold,
                letterSpacing: 3,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            SizedBox(
              width: 64,
              child: reduce
                  ? const LinearProgressIndicator(
                      minHeight: 2,
                      backgroundColor: Color(0x33C99A3F),
                      color: AppColors.gold,
                    )
                  : AnimatedBuilder(
                      animation: _c,
                      builder: (context, _) => LinearProgressIndicator(
                        value: null,
                        minHeight: 2,
                        backgroundColor: const Color(0x33C99A3F),
                        color: AppColors.gold,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
