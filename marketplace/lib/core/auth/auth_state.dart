import '../models/user.dart';

/// Phase d'authentification de l'application.
enum AuthStatus {
  /// Démarrage : on vérifie la présence d'une session.
  unknown,

  /// Utilisateur connecté.
  authenticated,

  /// Aucun utilisateur connecté.
  unauthenticated,
}

/// État d'authentification immuable exposé par `AuthController`.
class AuthState {
  const AuthState({required this.status, this.user});

  final AuthStatus status;
  final User? user;

  const AuthState.unknown() : status = AuthStatus.unknown, user = null;

  const AuthState.unauthenticated()
    : status = AuthStatus.unauthenticated,
      user = null;

  const AuthState.authenticated(this.user) : status = AuthStatus.authenticated;

  bool get isAuthenticated => status == AuthStatus.authenticated;
  bool get isUnknown => status == AuthStatus.unknown;

  AuthState copyWith({AuthStatus? status, User? user}) =>
      AuthState(status: status ?? this.status, user: user ?? this.user);
}
