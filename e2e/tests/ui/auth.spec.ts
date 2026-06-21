import { test, expect } from '@playwright/test';
import { ACCOUNTS } from '../../support/constants';
import { loginThroughUi } from '../../support/ui-fixtures';

test.describe('UI · Authentification', () => {
  test('connexion admin valide → redirige vers le tableau de bord', async ({ page }) => {
    await loginThroughUi(page, ACCOUNTS.admin.email, ACCOUNTS.admin.password);
    await expect(page).toHaveURL(/\/dashboard$/);
    await expect(page.getByRole('heading', { name: 'Tableau de bord' })).toBeVisible();
  });

  test('identifiants invalides → message d\'erreur, reste sur /login', async ({ page }) => {
    await loginThroughUi(page, ACCOUNTS.admin.email, 'MauvaisMotDePasse!');
    await expect(page.getByRole('alert')).toContainText('E-mail ou mot de passe incorrect');
    await expect(page).toHaveURL(/\/login$/);
  });

  test('un client (non-admin) est refusé à l\'accès du back-office', async ({ page }) => {
    await loginThroughUi(page, ACCOUNTS.customer.email, ACCOUNTS.customer.password);
    await expect(page.getByRole('alert')).toContainText('Accès réservé aux administrateurs');
    await expect(page).toHaveURL(/\/login$/);
  });

  test('validation : email invalide bloque la soumission', async ({ page }) => {
    await page.goto('/login');
    await page.getByLabel('Adresse e-mail').fill('pasunemail');
    await page.getByLabel('Mot de passe').fill('Password123!');
    await page.getByRole('button', { name: 'Se connecter' }).click();
    // Reste sur login (le formulaire Signal Forms bloque l'envoi).
    await expect(page).toHaveURL(/\/login$/);
  });
});

test.describe('UI · Guards', () => {
  test('accès non authentifié à /dashboard → redirige vers /login', async ({ page }) => {
    await page.goto('/dashboard');
    await expect(page).toHaveURL(/\/login$/);
  });

  test('accès non authentifié à /products → redirige vers /login', async ({ page }) => {
    await page.goto('/products');
    await expect(page).toHaveURL(/\/login$/);
  });

  test('accès non authentifié à /orders → redirige vers /login', async ({ page }) => {
    await page.goto('/orders');
    await expect(page).toHaveURL(/\/login$/);
  });

  test('route inconnue → redirige (puis login si non authentifié)', async ({ page }) => {
    await page.goto('/route-inexistante');
    await expect(page).toHaveURL(/\/login$/);
  });
});
