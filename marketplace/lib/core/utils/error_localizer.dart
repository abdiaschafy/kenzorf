import '../api/api_exception.dart';
import '../l10n/app_localizations.dart';

/// Traduit une erreur en message lisible via le dictionnaire i18n.
///
/// - Une [ApiException] est résolue via sa `messageKey` (+ `params`).
/// - Toute autre erreur retombe sur `error.unknown`.
extension ErrorLocalizer on AppLocalizations {
  String describeError(Object? error) {
    if (error is ApiException) {
      // Si la clé est connue du dictionnaire, on la traduit ; sinon repli.
      final translated = t(error.messageKey, error.params);
      if (translated != error.messageKey) return translated;
      // Clé inconnue : repli sur une famille générique selon le statut.
      if (error.isUnauthorized) return t('error.unauthorized');
      if (error.isForbidden) return t('error.forbidden');
      if ((error.status ?? 0) >= 500) return t('error.server');
      return t('error.unknown');
    }
    return t('error.unknown');
  }
}
