import 'package:dio/dio.dart';

/// Erreur applicative normalisée issue de l'API ou du réseau.
///
/// L'API renvoie toujours le format (spec §3) :
/// `{ code, messageKey, params, status }`.
///
/// On conserve [messageKey] pour permettre la traduction côté UI via le
/// dictionnaire i18n. Les widgets ne doivent jamais afficher [rawMessage]
/// directement : ils résolvent `messageKey` en libellé local.
class ApiException implements Exception {
  const ApiException({
    required this.code,
    required this.messageKey,
    this.params = const {},
    this.status,
    this.rawMessage,
  });

  /// Code stable de l'erreur (ex. `orders.notFound`).
  final String code;

  /// Clé de traduction (généralement identique à [code]).
  final String messageKey;

  /// Paramètres d'interpolation éventuels.
  final Map<String, Object?> params;

  /// Code HTTP associé.
  final int? status;

  /// Message brut (debug uniquement, jamais affiché tel quel).
  final String? rawMessage;

  bool get isUnauthorized => status == 401;
  bool get isForbidden => status == 403;
  bool get isNotFound => status == 404;

  /// Construit une [ApiException] à partir d'une [DioException].
  factory ApiException.fromDio(DioException e) {
    // Erreurs réseau / timeout (pas de réponse serveur).
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const ApiException(
          code: 'error.timeout',
          messageKey: 'error.timeout',
        );
      case DioExceptionType.connectionError:
      case DioExceptionType.unknown:
        if (e.response == null) {
          return ApiException(
            code: 'error.network',
            messageKey: 'error.network',
            rawMessage: e.message,
          );
        }
        break;
      default:
        break;
    }

    final response = e.response;
    final status = response?.statusCode;
    final data = response?.data;

    // Format d'erreur standard de l'API : { code, messageKey, params, status }.
    if (data is Map) {
      final map = data.cast<String, dynamic>();
      final code = (map['code'] ?? map['messageKey'])?.toString();

      // Erreurs de validation FluentValidation (422) : la clé i18n utile est
      // au niveau du champ (`errors: { quantity: ["cart.quantity.max"] }`),
      // pas dans `params`. On remonte la première clé exploitable pour offrir
      // un message précis à l'utilisateur (ex. stock maximum atteint).
      final fieldKey = _firstFieldErrorKey(map['errors']);

      if (code != null && code.isNotEmpty) {
        return ApiException(
          code: code,
          // Préfère la clé de champ quand elle ressemble à une clé i18n,
          // sinon repli sur le messageKey/code générique.
          messageKey: fieldKey ?? (map['messageKey'] ?? code).toString(),
          params: (map['params'] as Map?)?.cast<String, Object?>() ?? const {},
          status: status ?? (map['status'] as int?),
          rawMessage: map['message']?.toString(),
        );
      }

      // Cas ProblemDetails ASP.NET (model binding 400) : pas de `code`, mais
      // un `errors` exploitable et/ou un `title`.
      if (fieldKey != null) {
        return ApiException(
          code: fieldKey,
          messageKey: fieldKey,
          status: status,
          rawMessage: map['title']?.toString(),
        );
      }
    }

    // Repli sur des clés génériques selon le code HTTP.
    return ApiException(
      code: _fallbackKey(status),
      messageKey: _fallbackKey(status),
      status: status,
      rawMessage: e.message,
    );
  }

  /// Extrait la première clé de traduction exploitable d'un dictionnaire
  /// `errors` (`{ champ: [clé, ...] }`). Ne retient qu'une valeur ressemblant à
  /// une **clé i18n** (`a.b.c`, sans espace) pour éviter d'afficher un message
  /// brut anglais issu d'un ProblemDetails ASP.NET.
  static String? _firstFieldErrorKey(Object? errors) {
    if (errors is! Map) return null;
    for (final value in errors.values) {
      if (value is List && value.isNotEmpty) {
        final first = value.first?.toString();
        if (first != null && _looksLikeKey(first)) return first;
      } else if (value is String && _looksLikeKey(value)) {
        return value;
      }
    }
    return null;
  }

  /// Heuristique : une clé i18n contient un point, pas d'espace, et reste
  /// courte (ex. `cart.quantity.max`). Les phrases humaines sont ignorées.
  static bool _looksLikeKey(String value) {
    return value.contains('.') &&
        !value.contains(' ') &&
        value.length <= 60 &&
        RegExp(r'^[a-zA-Z][a-zA-Z0-9_.]*$').hasMatch(value);
  }

  static String _fallbackKey(int? status) {
    switch (status) {
      case 401:
        return 'error.unauthorized';
      case 403:
        return 'error.forbidden';
      case 404:
        return 'error.unknown';
      case 422:
        return 'validation.failed';
      case null:
        return 'error.network';
      default:
        // `status` est non nul ici (le cas null est traité ci-dessus).
        if (status >= 500) return 'error.server';
        return 'error.unknown';
    }
  }

  @override
  String toString() => 'ApiException($code, status: $status)';
}
