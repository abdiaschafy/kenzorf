import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../theme/app_theme.dart';
import 'brand_monogram.dart';
import 'primary_button.dart';

/// Indicateur de chargement KENZORF : monogramme doré en pulsation douce.
class LoadingView extends StatefulWidget {
  const LoadingView({super.key, this.message});

  final String? message;

  @override
  State<LoadingView> createState() => _LoadingViewState();
}

class _LoadingViewState extends State<LoadingView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduce = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (reduce)
            const BrandMonogram(size: 40)
          else
            FadeTransition(
              opacity: Tween<double>(begin: 0.35, end: 1).animate(_c),
              child: const BrandMonogram(size: 40),
            ),
          if (widget.message != null) ...[
            const SizedBox(height: AppSpacing.md),
            Text(
              widget.message!,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ],
      ),
    );
  }
}

/// Vue d'erreur générique, sobre et localisée, avec action « Réessayer ».
class ErrorView extends StatelessWidget {
  const ErrorView({
    super.key,
    this.title,
    this.message,
    this.onRetry,
    this.icon = Icons.error_outline,
  });

  final String? title;
  final String? message;
  final VoidCallback? onRetry;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: AppColors.terracotta),
            const SizedBox(height: AppSpacing.md),
            Text(
              title ?? l10n.t('state.error.title'),
              style: theme.textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              message ?? l10n.t('state.error.message'),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.taupe,
              ),
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: AppSpacing.lg),
              OutlinedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh, size: 18),
                label: Text(l10n.t('common.retry')),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, 48),
                  padding: const EdgeInsets.symmetric(horizontal: 22),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Vue « état vide » éditoriale : monogramme filigrané, titre serif, action.
class EmptyView extends StatelessWidget {
  const EmptyView({
    super.key,
    this.title,
    this.message,
    this.icon = Icons.inbox_outlined,
    this.actionLabel,
    this.onAction,
  });

  final String? title;
  final String? message;
  final IconData icon;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 96,
              width: 96,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  const MonogramWatermark(size: 96, opacity: 0.12),
                  Icon(icon, size: 40, color: AppColors.gold),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              title ?? l10n.t('state.empty.title'),
              style: theme.textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            if ((message ?? l10n.t('state.empty.message')).isNotEmpty) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                message ?? l10n.t('state.empty.message'),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppColors.taupe,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: AppSpacing.lg),
              SizedBox(
                width: 220,
                child: PrimaryButton(
                  label: actionLabel!,
                  onPressed: onAction,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
