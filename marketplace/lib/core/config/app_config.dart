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
