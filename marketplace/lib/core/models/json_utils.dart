/// Helpers de parsing JSON tolérants pour les DTOs de l'API.
///
/// Les montants (FCFA) sont des `decimal` côté .NET et peuvent arriver en
/// `int` ou `double` dans le JSON ; on les normalise en `int` (montants
/// entiers — pas de centimes en XOF).
library;

/// Convertit une valeur JSON en `int` (montant FCFA). Tolère int, double,
/// string. Retourne [fallback] si null/illisible.
int asInt(Object? value, {int fallback = 0}) {
  if (value == null) return fallback;
  if (value is int) return value;
  if (value is num) return value.round();
  if (value is String) {
    final parsed = num.tryParse(value);
    if (parsed != null) return parsed.round();
  }
  return fallback;
}

/// Variante nullable de [asInt].
int? asIntOrNull(Object? value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.round();
  if (value is String) return num.tryParse(value)?.round();
  return null;
}

/// Convertit une valeur JSON en `bool`. Tolère bool, "true"/"false", 0/1.
bool asBool(Object? value, {bool fallback = false}) {
  if (value is bool) return value;
  if (value is num) return value != 0;
  if (value is String) return value.toLowerCase() == 'true';
  return fallback;
}

/// Convertit une valeur JSON en `String` non nulle.
String asString(Object? value, {String fallback = ''}) {
  if (value == null) return fallback;
  return value.toString();
}

/// Parse une date ISO 8601 ; retourne null si absente/invalide.
DateTime? asDate(Object? value) {
  if (value is String && value.isNotEmpty) {
    return DateTime.tryParse(value)?.toLocal();
  }
  return null;
}

/// Mappe une liste JSON en liste typée via [fromJson], en ignorant les
/// éléments non conformes.
List<T> asList<T>(Object? value, T Function(Map<String, dynamic>) fromJson) {
  if (value is List) {
    return value
        .whereType<Map<String, dynamic>>()
        .map(fromJson)
        .toList(growable: false);
  }
  return const [];
}
