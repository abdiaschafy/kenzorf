import { HttpClient } from '@angular/common/http';
import { Injectable, computed, inject, signal } from '@angular/core';
import { Observable, tap } from 'rxjs';
import { environment } from '@env/environment';
import { API_ENDPOINTS } from '@app/core/constants/api-endpoints.constants';
import { AUTH_STORAGE } from '@app/core/constants/storage.constants';
import { USER_ROLE } from '@app/core/constants/role.constants';
import type {
  AuthResponse,
  AuthSession,
  LoginRequest,
  UserDto,
} from '@app/core/interfaces/auth.interfaces';

/**
 * Authentification du back-office.
 * État exposé par signaux ; tokens persistés en localStorage.
 * Le rafraîchissement d'access token est piloté par le TokenInterceptor.
 */
@Injectable({ providedIn: 'root' })
export class AuthService {
  private readonly http = inject(HttpClient);
  private readonly base = environment.apiUrl;

  private readonly _session = signal<AuthSession | null>(this.restoreSession());

  /** Utilisateur courant (ou null). */
  readonly user = computed<UserDto | null>(() => this._session()?.user ?? null);

  /** Vrai si une session est active. */
  readonly isAuthenticated = computed<boolean>(() => this._session() !== null);

  /** Vrai si l'utilisateur courant est administrateur. */
  readonly isAdmin = computed<boolean>(() => this.user()?.role === USER_ROLE.Admin);

  /** Initiales pour l'avatar. */
  readonly initials = computed<string>(() => {
    const u = this.user();
    if (!u) {
      return '';
    }
    return `${u.firstName.charAt(0)}${u.lastName.charAt(0)}`.toUpperCase();
  });

  /** Token d'accès courant (lecture synchrone pour l'intercepteur). */
  get accessToken(): string | null {
    return this._session()?.accessToken ?? null;
  }

  /** Refresh token courant. */
  get refreshToken(): string | null {
    return this._session()?.refreshToken ?? null;
  }

  /** Connexion : renvoie l'AuthResponse, persiste la session si succès. */
  login(credentials: LoginRequest): Observable<AuthResponse> {
    return this.http
      .post<AuthResponse>(`${this.base}${API_ENDPOINTS.auth.login}`, credentials)
      .pipe(tap((res) => this.persistSession(res)));
  }

  /** Déconnexion : révoque le refresh token côté serveur (best-effort) puis purge. */
  logout(): Observable<void> {
    const token = this.refreshToken;
    this.clearSession();
    if (!token) {
      return new Observable<void>((subscriber) => {
        subscriber.next();
        subscriber.complete();
      });
    }
    return this.http.post<void>(`${this.base}${API_ENDPOINTS.auth.logout}`, {
      refreshToken: token,
    });
  }

  /** Met à jour la session après un refresh réussi (appelé par l'intercepteur). */
  applyRefreshedSession(res: AuthResponse): void {
    this.persistSession(res);
  }

  /** Purge la session locale (sans appel réseau). */
  clearSession(): void {
    this._session.set(null);
    for (const key of Object.values(AUTH_STORAGE)) {
      try {
        localStorage.removeItem(key);
      } catch {
        // ignore
      }
    }
  }

  private persistSession(res: AuthResponse): void {
    const session: AuthSession = {
      accessToken: res.accessToken,
      refreshToken: res.refreshToken,
      expiresAt: res.expiresAt,
      user: res.user,
    };
    this._session.set(session);
    try {
      localStorage.setItem(AUTH_STORAGE.AccessToken, session.accessToken);
      localStorage.setItem(AUTH_STORAGE.RefreshToken, session.refreshToken);
      localStorage.setItem(AUTH_STORAGE.ExpiresAt, session.expiresAt);
      localStorage.setItem(AUTH_STORAGE.User, JSON.stringify(session.user));
    } catch {
      // ignore
    }
  }

  private restoreSession(): AuthSession | null {
    try {
      const accessToken = localStorage.getItem(AUTH_STORAGE.AccessToken);
      const refreshToken = localStorage.getItem(AUTH_STORAGE.RefreshToken);
      const expiresAt = localStorage.getItem(AUTH_STORAGE.ExpiresAt);
      const userRaw = localStorage.getItem(AUTH_STORAGE.User);
      if (!accessToken || !refreshToken || !expiresAt || !userRaw) {
        return null;
      }
      const user = JSON.parse(userRaw) as UserDto;
      return { accessToken, refreshToken, expiresAt, user };
    } catch {
      return null;
    }
  }
}
