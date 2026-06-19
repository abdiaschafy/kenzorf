import 'package:dio/dio.dart';

import '../auth/token_store.dart';

/// Intercepteur Dio gérant :
/// - l'ajout du header `Authorization: Bearer <accessToken>` ;
/// - le header `Accept-Language` (fr/en) ;
/// - le **refresh automatique sur 401** via `POST /auth/refresh`, avec mise en
///   file d'attente des requêtes concurrentes pendant le rafraîchissement ;
/// - la notification d'expiration de session (déconnexion) si le refresh
///   échoue.
///
/// L'appel de refresh utilise un client Dio **séparé** ([_refreshDio]) pour ne
/// pas re-déclencher l'intercepteur de façon récursive.
class AuthInterceptor extends QueuedInterceptor {
  AuthInterceptor({
    required TokenStore tokenStore,
    required Dio refreshDio,
    required String Function() languageCode,
    required Future<void> Function() onSessionExpired,
  }) : _tokenStore = tokenStore,
       _refreshDio = refreshDio,
       _languageCode = languageCode,
       _onSessionExpired = onSessionExpired;

  final TokenStore _tokenStore;
  final Dio _refreshDio;
  final String Function() _languageCode;
  final Future<void> Function() _onSessionExpired;

  /// Marqueur sur les requêtes déjà rejouées après un refresh, pour éviter une
  /// boucle infinie.
  static const String _retriedFlag = 'x-retried';

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    options.headers['Accept-Language'] = _languageCode();
    final token = _tokenStore.accessToken;
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final response = err.response;
    final isAuthError = response?.statusCode == 401;
    final alreadyRetried = err.requestOptions.extra[_retriedFlag] == true;
    final hasRefresh =
        _tokenStore.refreshToken != null &&
        _tokenStore.refreshToken!.isNotEmpty;

    // Ne pas tenter de rafraîchir l'appel de refresh lui-même.
    final isRefreshCall = err.requestOptions.path.contains('/auth/refresh');

    if (!isAuthError || alreadyRetried || !hasRefresh || isRefreshCall) {
      return handler.next(err);
    }

    // Tentative de rafraîchissement du token.
    final refreshed = await _tryRefresh();
    if (!refreshed) {
      await _onSessionExpired();
      return handler.next(err);
    }

    // Rejoue la requête initiale avec le nouveau token.
    try {
      final options = err.requestOptions;
      options.extra[_retriedFlag] = true;
      options.headers['Authorization'] = 'Bearer ${_tokenStore.accessToken}';
      final clone = await _refreshDio.fetch<dynamic>(options);
      return handler.resolve(clone);
    } on DioException catch (e) {
      return handler.next(e);
    }
  }

  /// Appelle `POST /auth/refresh` et persiste le nouveau couple de jetons.
  /// Retourne `true` en cas de succès.
  Future<bool> _tryRefresh() async {
    final refreshToken = _tokenStore.refreshToken;
    if (refreshToken == null || refreshToken.isEmpty) return false;
    try {
      final res = await _refreshDio.post<Map<String, dynamic>>(
        '/auth/refresh',
        data: {'refreshToken': refreshToken},
        options: Options(headers: {'Accept-Language': _languageCode()}),
      );
      final data = res.data;
      if (data == null) return false;
      final access = data['accessToken'] as String?;
      final refresh = data['refreshToken'] as String?;
      if (access == null || access.isEmpty) return false;
      await _tokenStore.save(
        accessToken: access,
        refreshToken: refresh ?? refreshToken,
      );
      return true;
    } catch (_) {
      return false;
    }
  }
}
