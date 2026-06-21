import type { AppEnvironment } from './environment.type';

/**
 * Environnement dédié aux tests E2E Playwright (stack locale isolée).
 * Pointe vers l'API E2E (DB kenzorf_e2e) servie sur le port 8090, distincte du
 * conteneur de démonstration (8080). Ne pas utiliser en production.
 */
export const environment: AppEnvironment = {
  production: false,
  apiUrl: 'http://localhost:8090/api',
  defaultLocale: 'fr',
};
