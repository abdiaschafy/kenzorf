import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/data/auth_repository.dart';
import '../api/api_client.dart';
import '../models/user.dart';
import 'auth_state.dart';
import 'token_store.dart';

/// Contrôleur central d'authentification.
///
/// - Au démarrage : charge les jetons persistés ; s'ils existent, tente
///   `GET /auth/me` pour restaurer la session (sinon → déconnecté).
/// - Expose `login`, `register`, `logout`.
/// - Écoute [sessionExpiredProvider] : si l'intercepteur Dio détecte une
///   session expirée (refresh échoué), bascule en déconnecté.
///
/// La logique réseau passe par [AuthRepository] (jamais d'appel Dio direct).
class AuthController extends Notifier<AuthState> {
  late final TokenStore _tokenStore;
  late final AuthRepository _repo;

  @override
  AuthState build() {
    _tokenStore = ref.read(tokenStoreProvider);
    _repo = ref.read(authRepositoryProvider);

    // Réagit aux expirations de session signalées par l'intercepteur.
    ref.listen<int>(sessionExpiredProvider, (previous, next) {
      if (next > (previous ?? 0)) {
        state = const AuthState.unauthenticated();
      }
    });

    // Bootstrap asynchrone.
    _bootstrap();
    return const AuthState.unknown();
  }

  Future<void> _bootstrap() async {
    await _tokenStore.load();
    if (!_tokenStore.hasTokens) {
      state = const AuthState.unauthenticated();
      return;
    }
    try {
      final user = await _repo.me();
      state = AuthState.authenticated(user);
    } catch (_) {
      // Token invalide / refresh impossible : on nettoie.
      await _tokenStore.clear();
      state = const AuthState.unauthenticated();
    }
  }

  /// Connexion. Lève une `ApiException` en cas d'échec (à gérer par l'appelant).
  Future<void> login({required String email, required String password}) async {
    final auth = await _repo.login(
      LoginRequest(email: email, password: password),
    );
    await _tokenStore.save(
      accessToken: auth.accessToken,
      refreshToken: auth.refreshToken,
    );
    state = AuthState.authenticated(auth.user);
  }

  /// Inscription (rôle `Customer`). Lève une `ApiException` en cas d'échec.
  Future<void> register({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    String? phoneNumber,
  }) async {
    final auth = await _repo.register(
      RegisterRequest(
        email: email,
        password: password,
        firstName: firstName,
        lastName: lastName,
        phoneNumber: phoneNumber,
      ),
    );
    await _tokenStore.save(
      accessToken: auth.accessToken,
      refreshToken: auth.refreshToken,
    );
    state = AuthState.authenticated(auth.user);
  }

  /// Déconnexion : révoque le refresh token côté serveur (best-effort) puis
  /// nettoie l'état local.
  Future<void> logout() async {
    final refresh = _tokenStore.refreshToken;
    if (refresh != null && refresh.isNotEmpty) {
      try {
        await _repo.logout(refresh);
      } catch (_) {
        // On déconnecte localement quoi qu'il arrive.
      }
    }
    await _tokenStore.clear();
    state = const AuthState.unauthenticated();
  }
}

/// Provider de l'état d'authentification.
final authControllerProvider = NotifierProvider<AuthController, AuthState>(
  AuthController.new,
);

/// Raccourci : l'utilisateur courant (ou null).
final currentUserProvider = Provider<User?>(
  (ref) => ref.watch(authControllerProvider).user,
);
