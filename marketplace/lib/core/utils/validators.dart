import '../l10n/app_localizations.dart';

/// Fabriques de validateurs de formulaire localisés.
///
/// Chaque méthode retourne une fonction `String? Function(String?)`
/// compatible avec `TextFormField.validator`.
class Validators {
  Validators(this.l10n);

  final AppLocalizations l10n;

  static final RegExp _emailRegex = RegExp(r'^[\w.+-]+@[\w-]+\.[\w.-]+$');

  String? Function(String?) required() => (value) {
    if (value == null || value.trim().isEmpty) {
      return l10n.t('validation.required');
    }
    return null;
  };

  String? Function(String?) email() => (value) {
    if (value == null || value.trim().isEmpty) {
      return l10n.t('validation.required');
    }
    if (!_emailRegex.hasMatch(value.trim())) {
      return l10n.t('validation.email');
    }
    return null;
  };

  String? Function(String?) password({int min = 6}) => (value) {
    if (value == null || value.isEmpty) {
      return l10n.t('validation.required');
    }
    if (value.length < min) {
      return l10n.t('validation.password.min');
    }
    return null;
  };

  String? Function(String?) phone() => (value) {
    if (value == null || value.trim().isEmpty) {
      return l10n.t('validation.required');
    }
    final digits = value.replaceAll(RegExp(r'[\s\-+()]'), '');
    if (digits.length < 6 || !RegExp(r'^\d+$').hasMatch(digits)) {
      return l10n.t('validation.phone');
    }
    return null;
  };
}
