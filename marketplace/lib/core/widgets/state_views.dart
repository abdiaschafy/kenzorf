import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../theme/app_theme.dart';

/// Indicateur de chargement centré, réutilisable.
class LoadingView extends StatelessWidget {
  const LoadingView({super.key, this.message});

  final String? message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(strokeWidth: 2.4),
          if (message != null) ...[
            const SizedBox(height: 16),
            Text(message!, style: Theme.of(context).textTheme.bodyMedium),
          ],
        ],
      ),
    );
  }
}

/// Vue d'erreur générique avec bouton "Réessayer".
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
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 56, color: AppColors.stone),
            const SizedBox(height: 16),
            Text(
              title ?? l10n.t('state.error.title'),
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message ?? l10n.t('state.error.message'),
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.stone),
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 20),
              OutlinedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: Text(l10n.t('common.retry')),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Vue "état vide" avec icône, titre, message et action optionnelle.
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
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 64, color: AppColors.stone),
            const SizedBox(height: 16),
            Text(
              title ?? l10n.t('state.empty.title'),
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message ?? l10n.t('state.empty.message'),
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.stone),
              textAlign: TextAlign.center,
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 20),
              ElevatedButton(onPressed: onAction, child: Text(actionLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}
