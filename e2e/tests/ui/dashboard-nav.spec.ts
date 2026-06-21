import { test, expect } from '../../support/ui-fixtures';

test.describe('UI · Dashboard & navigation', () => {
  test('le dashboard affiche les KPIs', async ({ adminPage: page }) => {
    await page.goto('/dashboard');
    await expect(page.getByRole('heading', { name: 'Tableau de bord' })).toBeVisible();
    await expect(page.getByText("Chiffre d'affaires total")).toBeVisible();
    await expect(page.getByText('CA ce mois-ci')).toBeVisible();
    await expect(page.getByText('Variantes en stock bas')).toBeVisible();
    // Sections.
    await expect(page.getByText('Commandes par statut')).toBeVisible();
    await expect(page.getByText('Commandes récentes')).toBeVisible();
  });

  test('navigation latérale vers chaque section', async ({ adminPage: page }) => {
    await page.goto('/dashboard');
    const nav = page.getByRole('navigation');

    await nav.getByRole('link', { name: 'Produits' }).click();
    await expect(page).toHaveURL(/\/products$/);
    await expect(page.getByRole('heading', { name: 'Produits' })).toBeVisible();

    await nav.getByRole('link', { name: 'Catégories' }).click();
    await expect(page).toHaveURL(/\/categories$/);
    await expect(page.getByRole('heading', { name: 'Catégories' })).toBeVisible();

    await nav.getByRole('link', { name: 'Commandes' }).click();
    await expect(page).toHaveURL(/\/orders$/);
    await expect(page.getByRole('heading', { name: 'Commandes' })).toBeVisible();

    await nav.getByRole('link', { name: 'Clients' }).click();
    await expect(page).toHaveURL(/\/customers$/);
    await expect(page.getByRole('heading', { name: 'Clients' })).toBeVisible();
  });

  test('déconnexion → retour au login, accès dashboard re-protégé', async ({ adminPage: page }) => {
    await page.goto('/dashboard');
    await page.getByRole('button', { name: 'Se déconnecter' }).click();
    await expect(page).toHaveURL(/\/login$/);

    // Après logout, la session est purgée : /dashboard renvoie au login.
    await page.goto('/dashboard');
    await expect(page).toHaveURL(/\/login$/);
  });
});
