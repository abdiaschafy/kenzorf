import { test as base, expect, Page } from '@playwright/test';
import { ACCOUNTS, AUTH_STORAGE, UI_BASE_URL } from './constants';
import { loginAdmin, newApiContext } from './api';

/**
 * Fixtures UI back-office.
 *
 * `adminPage` : une page déjà authentifiée en Admin.
 *
 * Mécanique : on obtient un couple de jetons via l'API, on charge l'app une 1re fois
 * (page légère), on écrit le refresh token + le profil en sessionStorage (mêmes clés
 * que le SPA), puis on RECHARGE une fois. Au boot, `silentRefresh()` échange le refresh
 * token contre un access token et persiste le NOUVEAU refresh token tourné en storage.
 *
 * Important : on n'utilise PAS `addInitScript` (qui ré-écrirait le storage à CHAQUE
 * navigation et réinjecterait un refresh token déjà tourné → silent-refresh en échec,
 * donc déconnexion). On injecte une seule fois et on laisse l'app gérer la rotation.
 */
export const test = base.extend<{ adminPage: Page }>({
  adminPage: async ({ page }, use) => {
    await seedAdminSession(page);
    await use(page);
  },
});

export { expect };

/** Établit une session admin persistée puis vérifie qu'on atteint le tableau de bord. */
export async function seedAdminSession(page: Page): Promise<void> {
  const api = await newApiContext();
  const auth = await loginAdmin(api);
  await api.dispose();

  // 1) Charger l'app (sans session) pour disposer d'un origin où écrire le storage.
  await page.goto(`${UI_BASE_URL}/login`);

  // 2) Injecter la session (une seule fois).
  await page.evaluate(
    ([keys, session]) => {
      window.sessionStorage.setItem(keys.RefreshToken, session.refreshToken);
      window.sessionStorage.setItem(keys.ExpiresAt, session.expiresAt);
      window.sessionStorage.setItem(keys.User, JSON.stringify(session.user));
    },
    [AUTH_STORAGE, { refreshToken: auth.refreshToken, expiresAt: auth.expiresAt, user: auth.user }] as const,
  );

  // 3) Recharger : silentRefresh() restaure l'access token et persiste le token tourné.
  await page.goto(`${UI_BASE_URL}/dashboard`);
  await expect(page.getByRole('heading', { name: 'Tableau de bord' })).toBeVisible();
}

/** Connexion via le vrai formulaire de login (flux utilisateur complet). */
export async function loginThroughUi(
  page: Page,
  email: string = ACCOUNTS.admin.email,
  password: string = ACCOUNTS.admin.password,
): Promise<void> {
  await page.goto(`${UI_BASE_URL}/login`);
  await page.getByLabel('Adresse e-mail').fill(email);
  await page.getByLabel('Mot de passe').fill(password);
  await page.getByRole('button', { name: 'Se connecter' }).click();
}
