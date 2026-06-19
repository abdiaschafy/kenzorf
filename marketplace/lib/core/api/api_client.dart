import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/token_store.dart';
import '../config/app_config.dart';
import '../l10n/locale_controller.dart';
import 'auth_interceptor.dart';

/// Construit l'instance Dio partagée de l'application :
/// `baseUrl`, timeouts, intercepteur JWT + refresh, et logging léger.
///
/// L'intercepteur lit la locale courante (header `Accept-Language`) et notifie
/// l'expiration de session via [sessionExpiredProvider].
final dioProvider = Provider<Dio>((ref) {
  final tokenStore = ref.read(tokenStoreProvider);

  final baseOptions = BaseOptions(
    baseUrl: AppConfig.apiBaseUrl,
    connectTimeout: const Duration(milliseconds: AppConfig.connectTimeoutMs),
    receiveTimeout: const Duration(milliseconds: AppConfig.receiveTimeoutMs),
    contentType: 'application/json',
    responseType: ResponseType.json,
    // On gère nous-mêmes les statuts d'erreur via l'intercepteur.
    validateStatus: (status) => status != null && status < 400,
  );

  final dio = Dio(baseOptions);

  // Client séparé pour l'appel /auth/refresh et le rejeu (pas d'intercepteur
  // d'auth dessus, pour éviter la récursion).
  final refreshDio = Dio(baseOptions);

  dio.interceptors.add(
    AuthInterceptor(
      tokenStore: tokenStore,
      refreshDio: refreshDio,
      languageCode: () {
        // Lecture non réactive : on veut juste la valeur courante.
        return ref.read(localeControllerProvider).languageCode;
      },
      onSessionExpired: () async {
        await tokenStore.clear();
        ref.read(sessionExpiredProvider.notifier).bump();
      },
    ),
  );

  return dio;
});

/// Compteur incrémenté à chaque expiration de session détectée par
/// l'intercepteur. Le contrôleur d'auth l'écoute pour basculer en état
/// déconnecté et rediriger vers la connexion.
class SessionExpiredNotifier extends Notifier<int> {
  @override
  int build() => 0;

  /// Signale une nouvelle expiration de session.
  void bump() => state = state + 1;
}

final sessionExpiredProvider = NotifierProvider<SessionExpiredNotifier, int>(
  SessionExpiredNotifier.new,
);
