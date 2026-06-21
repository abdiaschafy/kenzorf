import { defineConfig, devices } from '@playwright/test';

/**
 * Suite E2E KENZORF — back-office (UI) + API (request context).
 *
 * Stack LOCALE ISOLEE (jamais la prod) :
 *  - API .NET (Development, FakePaymentGateway, DB `kenzorf_e2e`) sur 8090.
 *  - Back-office Angular servi par `ng serve` sur 4400 (env override → apiUrl 8090).
 *
 * Les URLs sont surchargeables par variables d'environnement pour la CI :
 *  - E2E_BASE_URL (UI)     défaut http://localhost:4400
 *  - E2E_API_URL  (API)    défaut http://localhost:8090
 */
const UI_BASE_URL = process.env.E2E_BASE_URL ?? 'http://localhost:4400';
const API_BASE_URL = process.env.E2E_API_URL ?? 'http://localhost:8090';

export default defineConfig({
  testDir: './tests',
  /* Un seul retry local pour absorber une éventuelle latence de démarrage Angular. */
  retries: process.env.CI ? 2 : 1,
  /* Pas de .only oublié en CI. */
  forbidOnly: !!process.env.CI,
  /* Parallélisme prudent : l'API partage une seule DB ; on évite les courses d'écriture. */
  workers: process.env.CI ? 2 : 4,
  fullyParallel: true,
  timeout: 30_000,
  expect: { timeout: 10_000 },
  reporter: [['list'], ['html', { open: 'never', outputFolder: 'playwright-report' }]],
  use: {
    baseURL: UI_BASE_URL,
    trace: 'retain-on-failure',
    screenshot: 'only-on-failure',
    video: 'retain-on-failure',
    actionTimeout: 10_000,
    navigationTimeout: 20_000,
    /* Le SPA force le français par défaut ; on l'aligne pour des assertions de texte stables. */
    locale: 'fr-FR',
    extraHTTPHeaders: { 'Accept-Language': 'fr' },
  },
  /* Exposé aux tests via testInfo.project.metadata + helpers. */
  metadata: { apiBaseURL: API_BASE_URL, uiBaseURL: UI_BASE_URL },
  projects: [
    {
      name: 'api',
      testDir: './tests/api',
      use: {
        // Le request context tape directement l'API .NET, sans navigateur.
        baseURL: API_BASE_URL,
        extraHTTPHeaders: { 'Accept-Language': 'fr', 'Content-Type': 'application/json' },
      },
    },
    {
      name: 'ui',
      testDir: './tests/ui',
      use: { ...devices['Desktop Chrome'], baseURL: UI_BASE_URL },
    },
  ],
});
