import { HttpErrorResponse, HttpRequest } from '@angular/common/http';
import type { HttpEvent, HttpHandlerFn } from '@angular/common/http';
import { inject } from '@angular/core';
import { Router } from '@angular/router';
import { Observable, throwError } from 'rxjs';
import { catchError } from 'rxjs/operators';
import { ROUTE_SEGMENT } from '@app/core/constants/routes.constants';
import { AuthService } from '@app/core/services/auth.service';
import type { ApiError } from '@app/core/interfaces/common.interfaces';

/** Mappe un statut HTTP brut vers une clé i18n d'erreur générique. */
function fallbackMessageKey(status: number): string {
  switch (status) {
    case 0:
      return 'error.network';
    case 401:
      return 'error.unauthorized';
    case 403:
      return 'error.forbidden';
    case 404:
      return 'error.notFound';
    case 400:
    case 422:
      return 'error.validation';
    default:
      return status >= 500 ? 'error.server' : 'error.unknown';
  }
}

/** Normalise toute erreur HTTP vers le format ApiError (spec §3). */
function toApiError(error: HttpErrorResponse): ApiError {
  const body = error.error as Partial<ApiError> | string | null;
  if (body && typeof body === 'object' && typeof body.messageKey === 'string') {
    return {
      code: body.code ?? body.messageKey,
      messageKey: body.messageKey,
      params: body.params ?? {},
      status: error.status,
    };
  }
  const key = fallbackMessageKey(error.status);
  return { code: key, messageKey: key, params: {}, status: error.status };
}

/**
 * Convertit les erreurs HTTP en ApiError exploitable par l'UI et déconnecte
 * sur 401 définitif (refresh déjà tenté en amont par le tokenInterceptor).
 */
export function errorInterceptor(
  req: HttpRequest<unknown>,
  next: HttpHandlerFn,
): Observable<HttpEvent<unknown>> {
  const router = inject(Router);
  const auth = inject(AuthService);

  return next(req).pipe(
    catchError((error: unknown) => {
      if (error instanceof HttpErrorResponse) {
        const apiError = toApiError(error);
        if (apiError.status === 401) {
          auth.clearSession();
          void router.navigate([`/${ROUTE_SEGMENT.Login}`]);
        }
        return throwError(() => apiError);
      }
      return throwError(() => error);
    }),
  );
}
