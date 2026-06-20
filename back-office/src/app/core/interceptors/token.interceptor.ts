import { HttpClient, HttpErrorResponse, HttpRequest } from '@angular/common/http';
import type { HttpEvent, HttpHandlerFn } from '@angular/common/http';
import { inject } from '@angular/core';
import { BehaviorSubject, Observable, throwError } from 'rxjs';
import { catchError, filter, switchMap, take } from 'rxjs/operators';
import { environment } from '@env/environment';
import { API_ENDPOINTS } from '@app/core/constants/api-endpoints.constants';
import { AuthService } from '@app/core/services/auth.service';
import type { AuthResponse } from '@app/core/interfaces/auth.interfaces';

/** Verrou partagé : un seul refresh à la fois, les requêtes concurrentes attendent. */
let isRefreshing = false;
const refreshedToken$ = new BehaviorSubject<string | null>(null);

function isAuthEndpoint(url: string): boolean {
  return (
    url.includes(API_ENDPOINTS.auth.login) ||
    url.includes(API_ENDPOINTS.auth.refresh) ||
    url.includes(API_ENDPOINTS.auth.logout)
  );
}

function withBearer(req: HttpRequest<unknown>, token: string): HttpRequest<unknown> {
  return req.clone({ setHeaders: { Authorization: `Bearer ${token}` } });
}

/**
 * Ajoute le Bearer sur les appels API et tente un refresh transparent sur 401.
 * Les requêtes d'auth (login/refresh/logout) ne sont pas réauthentifiées.
 *
 * Durcissement E2 : `auth.accessToken` est lu en mémoire (jamais persisté). Au
 * démarrage, le silent-refresh (provideAppInitializer) le restaure depuis le
 * refresh token avant tout appel applicatif ; un éventuel 401 (token absent ou
 * expiré) déclenche le refresh transparent ci-dessous via le refresh token.
 */
export function tokenInterceptor(
  req: HttpRequest<unknown>,
  next: HttpHandlerFn,
): Observable<HttpEvent<unknown>> {
  const auth = inject(AuthService);
  const http = inject(HttpClient);

  const isApiCall = req.url.startsWith(environment.apiUrl);
  const token = auth.accessToken;

  const authReq =
    isApiCall && token && !isAuthEndpoint(req.url) ? withBearer(req, token) : req;

  return next(authReq).pipe(
    catchError((error: unknown) => {
      if (
        error instanceof HttpErrorResponse &&
        error.status === 401 &&
        isApiCall &&
        !isAuthEndpoint(req.url) &&
        auth.refreshToken
      ) {
        return handle401(req, next, auth, http);
      }
      return throwError(() => error);
    }),
  );
}

function handle401(
  req: HttpRequest<unknown>,
  next: HttpHandlerFn,
  auth: AuthService,
  http: HttpClient,
): Observable<HttpEvent<unknown>> {
  if (isRefreshing) {
    // Un refresh est déjà en cours : on attend le nouveau token puis on rejoue.
    return refreshedToken$.pipe(
      filter((t): t is string => t !== null),
      take(1),
      switchMap((newToken) => next(withBearer(req, newToken))),
    );
  }

  isRefreshing = true;
  refreshedToken$.next(null);

  const refreshToken = auth.refreshToken as string;

  return http
    .post<AuthResponse>(`${environment.apiUrl}${API_ENDPOINTS.auth.refresh}`, { refreshToken })
    .pipe(
      switchMap((res) => {
        auth.applyRefreshedSession(res);
        isRefreshing = false;
        refreshedToken$.next(res.accessToken);
        return next(withBearer(req, res.accessToken));
      }),
      catchError((refreshError: unknown) => {
        isRefreshing = false;
        refreshedToken$.next(null);
        auth.clearSession();
        return throwError(() => refreshError);
      }),
    );
}
