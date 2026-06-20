import type { UserRole } from '@app/core/constants/role.constants';

/** Identifiants de connexion (spec : LoginRequest). */
export interface LoginRequest {
  email: string;
  password: string;
}

/** Demande de rafraîchissement du token. */
export interface RefreshRequest {
  refreshToken: string;
}

/** Demande de déconnexion (révoque le refresh token). */
export interface LogoutRequest {
  refreshToken: string;
}

/** Utilisateur courant (spec : UserDto). */
export interface UserDto {
  readonly id: string;
  readonly email: string;
  readonly firstName: string;
  readonly lastName: string;
  readonly phoneNumber?: string;
  readonly role: UserRole;
}

/** Réponse d'authentification (spec : AuthResponse). */
export interface AuthResponse {
  readonly accessToken: string;
  readonly refreshToken: string;
  readonly expiresAt: string;
  readonly user: UserDto;
}

/**
 * Session courante en mémoire.
 *
 * Durcissement sécurité (audit E2) : `accessToken` reste en mémoire et n'est
 * jamais persisté. Il vaut `null` juste après restauration depuis sessionStorage
 * (au démarrage), tant que le silent-refresh n'a pas rejoué `/auth/refresh`.
 * Seuls `refreshToken`, `expiresAt` et `user` sont persistés (sessionStorage).
 */
export interface AuthSession {
  readonly accessToken: string | null;
  readonly refreshToken: string;
  readonly expiresAt: string;
  readonly user: UserDto;
}
