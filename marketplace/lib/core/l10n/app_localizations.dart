import 'package:flutter/widgets.dart';

import 'app_strings.dart';

/// Fournit l'accès aux traductions via `AppLocalizations.of(context)`.
///
/// Le français est la langue par défaut ; l'anglais est pris en charge.
/// Les clés inconnues retournent la clé elle-même (utile en dev pour repérer
/// un libellé manquant).
class AppLocalizations {
  AppLocalizations(this.locale);

  /// Locale active (`fr` ou `en`).
  final Locale locale;

  /// Locales supportées par l'application.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('fr'),
    Locale('en'),
  ];

  /// Délégué à enregistrer dans `MaterialApp.localizationsDelegates`.
  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  Map<String, String> get _table =>
      locale.languageCode == 'en' ? kStringsEn : kStringsFr;

  /// Récupère un libellé pour [key].
  ///
  /// [params] permet l'interpolation de marqueurs `{nom}`.
  /// Exemple : `t('orders.number', {'number': 'KZ-001'})`.
  String t(String key, [Map<String, Object?>? params]) {
    var value = _table[key] ?? kStringsFr[key] ?? key;
    if (params != null) {
      params.forEach((name, dynamic v) {
        value = value.replaceAll('{$name}', '${v ?? ''}');
      });
    }
    return value;
  }

  /// Helper pratique : `AppLocalizations.of(context)`.
  static AppLocalizations of(BuildContext context) {
    final l10n = Localizations.of<AppLocalizations>(context, AppLocalizations);
    // Fallback sûr si le délégué n'est pas encore monté (ex. tests isolés).
    return l10n ?? AppLocalizations(const Locale('fr'));
  }
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) =>
      <String>['fr', 'en'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async =>
      AppLocalizations(locale);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

/// Sucre syntaxique : `context.l10n.t('key')`.
extension AppLocalizationsX on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}
