import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../storage/secure_storage.dart';

/// Contrôleur de la locale active de l'application.
///
/// Charge la préférence depuis le stockage sécurisé au démarrage (fr par
/// défaut) et la persiste à chaque changement.
class LocaleController extends Notifier<Locale> {
  static const String _storageKey = 'app_locale';

  @override
  Locale build() {
    _restore();
    return const Locale('fr');
  }

  Future<void> _restore() async {
    final storage = ref.read(secureStorageProvider);
    final code = await storage.read(_storageKey);
    if (code == 'en' || code == 'fr') {
      state = Locale(code!);
    }
  }

  /// Change la langue active et la persiste.
  Future<void> setLocale(Locale locale) async {
    if (locale.languageCode == state.languageCode) return;
    state = locale;
    final storage = ref.read(secureStorageProvider);
    await storage.write(_storageKey, locale.languageCode);
  }
}

/// Provider exposant la locale courante.
final localeControllerProvider = NotifierProvider<LocaleController, Locale>(
  LocaleController.new,
);
