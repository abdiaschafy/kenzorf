import 'package:intl/intl.dart';

/// Formatage de dates localisé (fr/en).
class AppDateFormatter {
  const AppDateFormatter._();

  /// Date courte localisée (ex. `19 juin 2026` / `Jun 19, 2026`).
  static String date(DateTime? value, String localeCode) {
    if (value == null) return '';
    return DateFormat.yMMMMd(localeCode).format(value);
  }

  /// Date + heure localisée.
  static String dateTime(DateTime? value, String localeCode) {
    if (value == null) return '';
    return DateFormat.yMMMMd(localeCode).add_Hm().format(value);
  }
}
