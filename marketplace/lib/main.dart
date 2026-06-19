import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/auth/auth_controller.dart';
import 'core/l10n/app_localizations.dart';
import 'core/l10n/locale_controller.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/shell/splash_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: KenzorfApp()));
}

/// Racine de l'application KENZORF Marketplace.
class KenzorfApp extends ConsumerWidget {
  const KenzorfApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final locale = ref.watch(localeControllerProvider);
    // Déclenche le bootstrap d'auth et permet d'afficher un splash tant que
    // l'état n'est pas résolu.
    final authStatus = ref.watch(authControllerProvider);

    final localizationsDelegates = <LocalizationsDelegate<dynamic>>[
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ];

    // Pendant la restauration de session, on affiche un splash (sans routeur)
    // pour éviter un flash d'écran protégé/non protégé.
    if (authStatus.isUnknown) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'KENZORF',
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        locale: locale,
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: localizationsDelegates,
        home: const SplashScreen(),
      );
    }

    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'KENZORF',
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.light,
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: localizationsDelegates,
      routerConfig: router,
    );
  }
}
