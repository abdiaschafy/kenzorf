import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../storage/secure_storage.dart';

/// Persiste et expose les jetons d'authentification (access + refresh) dans le
/// stockage sécurisé. Garde aussi une copie en mémoire pour un accès synchrone
/// rapide par l'intercepteur Dio.
class TokenStore {
  TokenStore(this._storage);

  final SecureStorage _storage;

  static const String _accessKey = 'auth_access_token';
  static const String _refreshKey = 'auth_refresh_token';

  String? _accessTokenCache;
  String? _refreshTokenCache;
  bool _loaded = false;

  /// Accès synchrone au token courant (après [load]).
  String? get accessToken => _accessTokenCache;
  String? get refreshToken => _refreshTokenCache;

  /// Charge les jetons depuis le stockage chiffré (au démarrage).
  Future<void> load() async {
    if (_loaded) return;
    _accessTokenCache = await _storage.read(_accessKey);
    _refreshTokenCache = await _storage.read(_refreshKey);
    _loaded = true;
  }

  /// Enregistre un nouveau couple de jetons.
  Future<void> save({
    required String accessToken,
    required String refreshToken,
  }) async {
    _accessTokenCache = accessToken;
    _refreshTokenCache = refreshToken;
    _loaded = true;
    await _storage.write(_accessKey, accessToken);
    await _storage.write(_refreshKey, refreshToken);
  }

  /// Efface les jetons (déconnexion / refresh échoué).
  Future<void> clear() async {
    _accessTokenCache = null;
    _refreshTokenCache = null;
    await _storage.delete(_accessKey);
    await _storage.delete(_refreshKey);
  }

  bool get hasTokens =>
      (_accessTokenCache != null && _accessTokenCache!.isNotEmpty);
}

/// Provider singleton du magasin de jetons.
final tokenStoreProvider = Provider<TokenStore>(
  (ref) => TokenStore(ref.read(secureStorageProvider)),
);
