import { HttpClient } from '@angular/common/http';
import { Injectable, computed, inject, signal } from '@angular/core';
import { Observable, of, firstValueFrom, tap, timeout, catchError } from 'rxjs';
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

/** Délai max (ms) accordé au logout serveur avant de purger localement quand même. */
const LOGOUT_TIMEOUT_MS = 3000;

/**
 * Authentification du back-office.
 * État exposé par signaux ; le rafraîchissement d'access token est piloté par
 * le TokenInterceptor.
 *
 * Durcissement sécurité (audit E2) :
 * - L'access token vit UNIQUEMENT en mémoire (signal `_session`). Il n'est jamais
 *   écrit dans le storage : un rechargement d'onglet le perd, puis `silentRefresh()`
 *   le restaure via `/auth/refresh` à partir du refresh token.
 * - Le refresh token (+ expiresAt + user) est persisté en `sessionStorage`, donc
 *   effacé à la fermeture de l'onglet (fenêtre d'exposition réduite vs localStorage).
 *
 * Durcissement futur recommandé (NE PAS implémenter ici, voir storage.constants.ts) :
 * refresh token en cookie HttpOnly/Secure/SameSite, inaccessible au JS. Nécessite
 * un support API ; le client mobile consomme le refresh par body → ne pas casser
 * le contrat API partagé.
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

  /** Token d'accès courant (en mémoire ; null avant silent-refresh). */
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

  /**
   * Restaure la session au démarrage de l'app.
   *
   * Si un refresh token subsiste en sessionStorage mais que l'access token est
   * absent (cas normal : il n'est jamais persisté), rejoue `/auth/refresh` pour
   * récupérer un access token frais. Échec → purge et exige une reconnexion.
   * Résout toujours (best-effort), ne propage jamais d'erreur.
   */
  async silentRefresh(): Promise<void> {
    const session = this._session();
    // Pas de session restaurée, ou access token déjà présent : rien à faire.
    if (!session || session.accessToken) {
      return;
    }
    try {
      const res = await firstValueFrom(
        this.http.post<AuthResponse>(`${this.base}${API_ENDPOINTS.auth.refresh}`, {
          refreshToken: session.refreshToken,
        }),
      );
      this.persistSession(res);
    } catch {
      // Refresh token expiré/révoqué → session inutilisable : on purge.
      this.clearSession();
    }
  }

  /**
   * Déconnexion : révoque le refresh token côté serveur PUIS purge la session.
   *
   * Durcissement sécurité (audit M5) : on attend la réponse de `/auth/logout`
   * (best-effort, borné par {@link LOGOUT_TIMEOUT_MS}) AVANT de purger localement,
   * pour garantir que le refresh token est bien révoqué côté serveur même si le
   * réseau est lent. En cas d'échec/timeout, on purge quand même (fail-safe local).
   */
  logout(): Observable<void> {
    const token = this.refreshToken;
    if (!token) {
      this.clearSession();
      return of(void 0);
    }
    return this.http
      .post<void>(`${this.base}${API_ENDPOINTS.auth.logout}`, { refreshToken: token })
      .pipe(
        timeout(LOGOUT_TIMEOUT_MS),
        catchError(() => of(void 0)),
        tap(() => this.clearSession()),
      );
  }

  /** Met à jour la session après un refresh réussi (appelé par l'intercepteur). */
  applyRefreshedSession(res: AuthResponse): void {
    this.persistSession(res);
  }

  /** Purge la session locale (mémoire + sessionStorage), sans appel réseau. */
  clearSession(): void {
    this._session.set(null);
    for (const key of Object.values(AUTH_STORAGE)) {
      try {
        sessionStorage.removeItem(key);
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
    // L'access token reste en mémoire (signal) : on ne le persiste jamais.
    try {
      sessionStorage.setItem(AUTH_STORAGE.RefreshToken, session.refreshToken);
      sessionStorage.setItem(AUTH_STORAGE.ExpiresAt, session.expiresAt);
      sessionStorage.setItem(AUTH_STORAGE.User, JSON.stringify(session.user));
    } catch {
      // ignore
    }
  }

  private restoreSession(): AuthSession | null {
    try {
      const refreshToken = sessionStorage.getItem(AUTH_STORAGE.RefreshToken);
      const expiresAt = sessionStorage.getItem(AUTH_STORAGE.ExpiresAt);
      const userRaw = sessionStorage.getItem(AUTH_STORAGE.User);
      if (!refreshToken || !expiresAt || !userRaw) {
        return null;
      }
      const user = JSON.parse(userRaw) as UserDto;
      // accessToken null : restauré par silentRefresh() au démarrage.
      return { accessToken: null, refreshToken, expiresAt, user };
    } catch {
      return null;
    }
  }
}
