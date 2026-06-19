import { inject } from '@angular/core';
import { Router, type CanActivateFn } from '@angular/router';
import { ROUTE_SEGMENT } from '@app/core/constants/routes.constants';
import { AuthService } from '@app/core/services/auth.service';

/**
 * Réserve le back-office au rôle Admin (KENZORF mono-tenant).
 * Non authentifié → /login ; authentifié mais non-admin → /login (fail-closed).
 */
export const adminGuard: CanActivateFn = () => {
  const auth = inject(AuthService);
  const router = inject(Router);

  if (auth.isAuthenticated() && auth.isAdmin()) {
    return true;
  }
  if (auth.isAuthenticated() && !auth.isAdmin()) {
    auth.clearSession();
  }
  return router.createUrlTree([`/${ROUTE_SEGMENT.Login}`]);
};

/** Empêche un utilisateur déjà connecté d'accéder à /login. */
export const guestGuard: CanActivateFn = () => {
  const auth = inject(AuthService);
  const router = inject(Router);

  if (auth.isAuthenticated() && auth.isAdmin()) {
    return router.createUrlTree([`/${ROUTE_SEGMENT.Dashboard}`]);
  }
  return true;
};
