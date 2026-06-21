import { test, expect } from '../../support/ui-fixtures';

function uniq(): string {
  return `${Date.now()}${Math.floor(Math.random() * 1000)}`;
}

test.describe('UI · Catégories', () => {
  test('la liste affiche les catégories seedées', async ({ adminPage: page }) => {
    await page.goto('/categories');
    await expect(page.getByRole('heading', { name: 'Catégories' })).toBeVisible();
    await expect(page.getByRole('cell', { name: 'Homme', exact: true })).toBeVisible();
    await expect(page.getByRole('cell', { name: 'Femme', exact: true })).toBeVisible();
  });

  test('création d\'une catégorie', async ({ adminPage: page }) => {
    const name = `Cat E2E ${uniq()}`;
    await page.goto('/categories');
    await page.getByRole('button', { name: 'Nouvelle catégorie' }).click();

    const dialog = page.getByRole('dialog');
    await expect(dialog).toBeVisible();
    await dialog.getByLabel('Nom').fill(name);
    await dialog.getByRole('button', { name: 'Enregistrer' }).click();

    await expect(dialog).toBeHidden();
    await expect(page.getByRole('cell', { name, exact: true })).toBeVisible();
  });

  test('édition d\'une catégorie', async ({ adminPage: page }) => {
    const name = `Cat Edit ${uniq()}`;
    const renamed = `${name} MAJ`;
    await page.goto('/categories');

    // Créer d'abord.
    await page.getByRole('button', { name: 'Nouvelle catégorie' }).click();
    let dialog = page.getByRole('dialog');
    await dialog.getByLabel('Nom').fill(name);
    await dialog.getByRole('button', { name: 'Enregistrer' }).click();
    await expect(page.getByRole('cell', { name, exact: true })).toBeVisible();

    // Éditer la ligne créée.
    const row = page.getByRole('row', { name: new RegExp(name) });
    await row.getByRole('button', { name: 'Modifier' }).click();
    dialog = page.getByRole('dialog');
    await expect(dialog).toBeVisible();
    await dialog.getByLabel('Nom').fill(renamed);
    await dialog.getByRole('button', { name: 'Enregistrer' }).click();

    await expect(page.getByRole('cell', { name: renamed, exact: true })).toBeVisible();
  });

  test('suppression d\'une catégorie', async ({ adminPage: page }) => {
    const name = `Cat Suppr ${uniq()}`;
    await page.goto('/categories');
    await page.getByRole('button', { name: 'Nouvelle catégorie' }).click();
    const dialog = page.getByRole('dialog');
    await dialog.getByLabel('Nom').fill(name);
    await dialog.getByRole('button', { name: 'Enregistrer' }).click();
    await expect(page.getByRole('cell', { name, exact: true })).toBeVisible();

    const row = page.getByRole('row', { name: new RegExp(name) });
    await row.getByRole('button', { name: 'Supprimer' }).click();

    const confirm = page.getByRole('dialog');
    await expect(confirm).toBeVisible();
    await confirm.getByRole('button', { name: 'Supprimer' }).click();

    await expect(page.getByRole('cell', { name, exact: true })).toHaveCount(0);
  });
});
