import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../l10n/app_localizations.dart';
import '../theme/app_theme.dart';
import 'brand_monogram.dart';
import 'editorial.dart';

/// En-tête éditorial des écrans d'authentification : panneau charbon, monogramme
/// doré en filigrane, titre serif et filet doré. Cohérent login / register.
class AuthHeader extends StatelessWidget {
  const AuthHeader({
    super.key,
    required this.title,
    required this.subtitle,
    this.showBack = true,
  });

  final String title;
  final String subtitle;
  final bool showBack;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(
        bottom: Radius.circular(AppSpacing.radiusLg),
      ),
      child: Container(
        width: double.infinity,
        color: AppColors.charcoal,
        child: Stack(
          children: [
            const Positioned(
              right: -24,
              bottom: -28,
              child: MonogramWatermark(
                size: 170,
                opacity: 0.10,
                color: AppColors.gold,
              ),
            ),
            SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.md,
                  AppSpacing.lg,
                  AppSpacing.xl,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (showBack)
                          IconButton(
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(
                              minWidth: 44,
                              minHeight: 44,
                            ),
                            icon: const Icon(
                              Icons.arrow_back,
                              color: AppColors.cream,
                            ),
                            tooltip:
                                MaterialLocalizations.of(
                                  context,
                                ).backButtonTooltip,
                            onPressed: () => context.pop(),
                          ),
                        const Spacer(),
                        const BrandMonogram(size: 22),
                        const SizedBox(width: 8),
                        Text(
                          l10n.t('app.name'),
                          style: const TextStyle(
                            color: AppColors.cream,
                            letterSpacing: 3,
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    Text(
                      title,
                      style: theme.textTheme.displaySmall?.copyWith(
                        color: AppColors.cream,
                        fontSize: 32,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const GoldRule(width: 40),
                    const SizedBox(height: 12),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: AppColors.cream.withValues(alpha: 0.75),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
