import type { AppEnvironment } from './environment.type';

export const environment: AppEnvironment = {
  production: true,
  // En prod, le SPA est servi par Nginx qui proxifie /api vers le service API.
  // URL relative => fonctionne en local Docker comme derrière un vrai domaine.
  apiUrl: '/api',
  defaultLocale: 'fr',
};
