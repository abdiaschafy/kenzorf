/// Configuration globale de l'application KENZORF Marketplace.
///
/// La `baseUrl` est surchargeable au build via `--dart-define=API_BASE_URL=...`.
///
/// Valeur par défaut : `http://10.0.2.2:8080/api`
/// (l'émulateur Android atteint la machine hôte via l'IP spéciale 10.0.2.2).
///
/// Alternative iOS / simulateur :
///   `http://localhost:8080/api`
/// (à passer en `--dart-define=API_BASE_URL=http://localhost:8080/api`).
class AppConfig {
  const AppConfig._();

  /// URL de base de l'API .NET (préfixe `/api`).
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:8080/api',
    // iOS / simulateur : http://localhost:8080/api
  );

  /// Origine (schéma + hôte + port) de [apiBaseUrl], sans le chemin `/api`.
  ///
  /// Sert à résoudre une URL **relative** renvoyée par le serveur (ex. un
  /// `checkoutUrl` `/dev/checkout.html?...` émis par la passerelle de paiement
  /// factice en Development) vers une URL absolue chargeable par la WebView.
  /// Retourne une chaîne vide si [apiBaseUrl] est mal formée.
  static String get apiOrigin {
    final uri = Uri.tryParse(apiBaseUrl);
    if (uri == null || !uri.hasScheme || uri.host.isEmpty) return '';
    final origin = Uri(
      scheme: uri.scheme,
      host: uri.host,
      port: uri.hasPort ? uri.port : null,
    );
    return origin.toString();
  }

  /// Résout [url] en URL absolue chargeable par la WebView de paiement.
  ///
  /// - URL absolue (avec schéma) : renvoyée telle quelle.
  /// - URL relative : résolue contre [apiOrigin] (un chemin commençant par `/`
  ///   est rattaché à l'autorité de l'API, hors préfixe `/api`).
  /// - `null` / vide / non résoluble : renvoie `null`.
  ///
  /// L'API renvoie désormais une URL absolue ; cette résolution reste une
  /// défense pour ne jamais planter la WebView sur une URL relative.
  static String? resolveCheckoutUrl(String? url) {
    if (url == null) return null;
    final trimmed = url.trim();
    if (trimmed.isEmpty) return null;

    final parsed = Uri.tryParse(trimmed);
    if (parsed == null) return null;
    if (parsed.hasScheme) return trimmed; // déjà absolue

    final origin = Uri.tryParse(apiOrigin);
    if (origin == null || !origin.hasScheme) return null;
    return origin.resolveUri(parsed).toString();
  }

  /// Délai de connexion réseau (ms).
  static const int connectTimeoutMs = 15000;

  /// Délai de réception réseau (ms).
  static const int receiveTimeoutMs = 20000;

  /// Intervalle de polling du statut de paiement KPay (ms).
  static const int paymentPollIntervalMs = 3000;

  /// Nombre maximum de tentatives de polling avant abandon.
  static const int paymentPollMaxAttempts = 40;

  /// Taille de page par défaut pour la pagination du catalogue.
  static const int defaultPageSize = 20;
}
