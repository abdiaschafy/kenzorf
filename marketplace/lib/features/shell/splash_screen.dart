import 'package:flutter/material.dart';

import '../../core/l10n/app_localizations.dart';
import '../../core/theme/app_theme.dart';

/// Écran de démarrage affiché pendant la restauration de session
/// (statut d'authentification `unknown`).
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      backgroundColor: AppColors.ink,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              l10n.t('app.name'),
              style: const TextStyle(
                color: AppColors.paper,
                fontSize: 34,
                fontWeight: FontWeight.w800,
                letterSpacing: 4,
              ),
            ),
            const SizedBox(height: 24),
            const SizedBox(
              width: 26,
              height: 26,
              child: CircularProgressIndicator(
                strokeWidth: 2.4,
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.accent),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
