import { inject } from '@angular/core';
import { Router, type CanActivateFn } from '@angular/router';
import { ROUTE_SEGMENT } from '@app/core/constants/routes.constants';
import { AuthService } from '@app/core/services/auth.service';

/** Bloque l'accès si aucune session active ; redirige vers /login. */
export const authGuard: CanActivateFn = () => {
  const auth = inject(AuthService);
  const router = inject(Router);

  if (auth.isAuthenticated()) {
    return true;
  }
  return router.createUrlTree([`/${ROUTE_SEGMENT.Login}`]);
};
