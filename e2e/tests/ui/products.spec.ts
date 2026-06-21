import { test, expect } from '../../support/ui-fixtures';

/** Génère un suffixe unique pour éviter les collisions de SKU/slug entre exécutions. */
function uniq(): string {
  return `${Date.now()}${Math.floor(Math.random() * 1000)}`;
}

test.describe('UI · Produits', () => {
  test('la liste des produits affiche le catalogue', async ({ adminPage: page }) => {
    await page.goto('/products');
    await expect(page.getByRole('heading', { name: 'Produits' })).toBeVisible();
    await expect(page.getByRole('link', { name: 'Nouveau produit' })).toBeVisible();
    // En-têtes de colonnes + au moins une ligne produit (prix en FCFA dans le tableau).
    await expect(page.getByRole('columnheader', { name: 'Produit' })).toBeVisible();
    const table = page.getByRole('table');
    await expect(table.getByText(/FCFA/).first()).toBeVisible();
  });

  /**
   * BUG (rouge volontaire) — voir rapport « Recherche produits (back-office) inopérante ».
   * GET /api/admin/products ignore le paramètre ?search (il ne bind que page/pageSize),
   * alors que la page back-office expose un champ de recherche câblé dessus. Le catalogue
   * public GET /api/products?search=… fonctionne, lui, correctement.
   * Attendu : saisir "hoodie" doit restreindre la liste aux produits correspondants.
   */
  test('recherche produit (back-office) DEVRAIT filtrer la liste', async ({ adminPage: page }) => {
    await page.goto('/products');
    const searchBox = page.getByPlaceholder('Rechercher un produit…');
    const table = page.getByRole('table');

    await searchBox.fill('hoodie');
    // Attendu : un hoodie visible, et aucun produit non-hoodie comme la Casquette.
    await expect(table.getByText(/hoodie/i).first()).toBeVisible();
    await expect(table.getByText('Casquette Logo KENZORF')).toHaveCount(0);
  });

  test('création d\'un produit avec variante et image', async ({ adminPage: page }) => {
    const sku = `E2E-SKU-${uniq()}`;
    const name = `Produit E2E ${uniq()}`;

    await page.goto('/products');
    await page.getByRole('link', { name: 'Nouveau produit' }).click();
    await expect(page).toHaveURL(/\/products\/new$/);
    await expect(page.getByRole('heading', { name: 'Nouveau produit' })).toBeVisible();

    // Champs généraux (kz-text-input rend un <input> lié au <label>).
    await page.getByLabel('Nom du produit').fill(name);
    await page.getByLabel('Catégorie').selectOption({ label: 'Homme' });
    await page.getByLabel('Rayon').selectOption({ label: 'Homme' });
    await page.getByLabel('Description', { exact: true }).fill('Description du produit E2E.');

    // Prix de base.
    await page.getByLabel('Prix de base (FCFA)').fill('15000');

    // Image (au moins une URL requise).
    await page.getByRole('button', { name: 'Ajouter une image' }).click();
    await page.getByLabel("URL de l'image").fill('https://example.com/e2e.jpg');

    // Variante (une variante par défaut est présente — on la remplit).
    await page.getByLabel('SKU').fill(sku);
    await page.getByLabel('Taille').fill('M');
    await page.getByLabel('Couleur', { exact: true }).fill('Noir');
    await page.getByLabel('Stock').fill('10');

    await page.getByRole('button', { name: 'Enregistrer' }).click();

    // Retour à la liste + le produit apparaît.
    await expect(page).toHaveURL(/\/products$/);
    await page.getByPlaceholder('Rechercher un produit…').fill(name);
    await expect(page.getByText(name).first()).toBeVisible();
  });

  test('édition d\'un produit existant met à jour son nom', async ({ adminPage: page }) => {
    // On crée d'abord un produit dédié pour ne pas perturber le seed.
    const original = `Edit Source ${uniq()}`;
    const renamed = `Edit Cible ${uniq()}`;
    await createMinimalProduct(page, original, `E2E-EDIT-${uniq()}`);

    await page.goto('/products');
    await page.getByPlaceholder('Rechercher un produit…').fill(original);
    const row = page.getByRole('row', { name: new RegExp(original) });
    await row.getByRole('link', { name: 'Modifier' }).click();

    await expect(page.getByRole('heading', { name: 'Modifier le produit' })).toBeVisible();
    const nameField = page.getByLabel('Nom du produit');
    await expect(nameField).toHaveValue(original);
    await nameField.fill(renamed);
    await page.getByRole('button', { name: 'Enregistrer' }).click();

    await expect(page).toHaveURL(/\/products$/);
    await page.getByPlaceholder('Rechercher un produit…').fill(renamed);
    await expect(page.getByText(renamed).first()).toBeVisible();
  });

  test('suppression d\'un produit le retire de la liste', async ({ adminPage: page }) => {
    const name = `Suppr E2E ${uniq()}`;
    await createMinimalProduct(page, name, `E2E-DEL-${uniq()}`);

    await page.goto('/products');
    await page.getByPlaceholder('Rechercher un produit…').fill(name);
    const row = page.getByRole('row', { name: new RegExp(name) });
    await expect(row).toBeVisible();
    await row.getByRole('button', { name: 'Supprimer' }).click();

    // Confirme la suppression dans la boîte de dialogue.
    const dialog = page.getByRole('dialog');
    await expect(dialog).toBeVisible();
    await dialog.getByRole('button', { name: 'Supprimer' }).click();

    // Après reload de la ressource, le produit n'apparaît plus.
    await page.getByPlaceholder('Rechercher un produit…').fill(name);
    await expect(page.getByText(name)).toHaveCount(0);
  });
});

/** Crée un produit minimal valide via l'UI (helper réutilisable). */
async function createMinimalProduct(page: import('@playwright/test').Page, name: string, sku: string): Promise<void> {
  await page.goto('/products/new');
  await page.getByLabel('Nom du produit').fill(name);
  await page.getByLabel('Catégorie').selectOption({ label: 'Homme' });
  await page.getByLabel('Rayon').selectOption({ label: 'Homme' });
  await page.getByLabel('Description', { exact: true }).fill('Produit créé pour test E2E.');
  await page.getByLabel('Prix de base (FCFA)').fill('9000');
  await page.getByRole('button', { name: 'Ajouter une image' }).click();
  await page.getByLabel("URL de l'image").fill('https://example.com/e2e.jpg');
  await page.getByLabel('SKU').fill(sku);
  await page.getByLabel('Taille').fill('M');
  await page.getByLabel('Couleur', { exact: true }).fill('Noir');
  await page.getByLabel('Stock').fill('5');
  await page.getByRole('button', { name: 'Enregistrer' }).click();
  await expect(page).toHaveURL(/\/products$/);
}
