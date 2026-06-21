import { test, expect } from '../../support/ui-fixtures';
import { createPendingOrder, freshCustomerToken, getInStockVariant, newApiContext } from '../../support/api';

test.describe('UI · Commandes', () => {
  test('la liste affiche des commandes (seed démo)', async ({ adminPage: page }) => {
    await page.goto('/orders');
    await expect(page.getByRole('heading', { name: 'Commandes' })).toBeVisible();
    // Au moins une commande KZF-… (seed : 30 commandes).
    await expect(page.getByText(/KZF-/).first()).toBeVisible();
  });

  test('le filtre par statut restreint la liste', async ({ adminPage: page }) => {
    await page.goto('/orders');
    await expect(page.getByText(/KZF-/).first()).toBeVisible();

    // Filtre "Livrée" (select natif avec aria-label "Statut").
    await page.getByLabel('Statut').selectOption({ label: 'Livrée' });

    // On scope les assertions au tableau pour ne pas matcher les <option> du select.
    const table = page.getByRole('table');
    await expect(table.getByText(/KZF-/).first()).toBeVisible();
    // Le tableau filtré contient au moins un badge "Livrée"…
    await expect(table.getByText('Livrée').first()).toBeVisible();
    // …et plus aucune ligne d'un autre statut (ex. "En attente", "Expédiée").
    await expect(table.getByText('En attente')).toHaveCount(0);
    await expect(table.getByText('Expédiée')).toHaveCount(0);
  });

  test('ouverture du détail d\'une commande', async ({ adminPage: page }) => {
    await page.goto('/orders');
    const firstOrderLink = page.getByRole('link', { name: /KZF-/ }).first();
    const orderNumber = (await firstOrderLink.textContent())?.trim() ?? '';
    await firstOrderLink.click();

    await expect(page).toHaveURL(/\/orders\/[0-9a-f-]+$/);
    await expect(page.getByRole('heading', { name: orderNumber })).toBeVisible();
    // Sections du détail (titres de cartes = headings).
    await expect(page.getByRole('heading', { name: 'Récapitulatif' })).toBeVisible();
    await expect(page.getByRole('heading', { name: 'Livraison' })).toBeVisible();
    await expect(page.getByRole('heading', { name: 'Paiement' })).toBeVisible();
  });

  test('changement de statut d\'une commande Pending', async ({ adminPage: page }) => {
    // On crée une commande Pending fraîche via l'API (client isolé) pour un test déterministe.
    const api = await newApiContext();
    const token = await freshCustomerToken(api);
    const variant = await getInStockVariant(api);
    const order = await createPendingOrder(api, token, variant.id, 1);
    await api.dispose();

    await page.goto(`/orders/${order.id}`);
    await expect(page.getByRole('heading', { name: order.orderNumber })).toBeVisible();
    // Statut courant : En attente.
    await expect(page.getByText('Changer le statut')).toBeVisible();

    // Transition Pending → Processing/Paid/Cancelled : on choisit "Annulée" (toujours dispo).
    await page.locator('#status-select').selectOption({ label: 'Annulée' });
    await page.getByRole('button', { name: 'Appliquer' }).click();

    // Le badge de statut passe à "Annulée".
    await expect(page.getByText('Annulée').first()).toBeVisible();
  });
});

test.describe('UI · Clients', () => {
  test('la liste des clients affiche des lignes clients', async ({ adminPage: page }) => {
    await page.goto('/customers');
    await expect(page.getByRole('heading', { name: 'Clients' })).toBeVisible();
    // En-têtes de colonnes attendus.
    await expect(page.getByRole('columnheader', { name: 'E-mail' })).toBeVisible();
    await expect(page.getByRole('columnheader', { name: 'Téléphone' })).toBeVisible();
    // Au moins une ligne client (un email visible dans le tableau).
    const table = page.getByRole('table');
    await expect(table.getByText(/@/).first()).toBeVisible();
  });

  /**
   * BUG (rouge volontaire) — voir rapport « Recherche clients inopérante ».
   * La page Clients affiche un champ de recherche et le front envoie ?search=…, mais
   * l'endpoint GET /api/admin/customers ignore totalement le paramètre (il ne bind que
   * page/pageSize). La recherche ne filtre donc rien.
   * Attendu : saisir l'email d'un client connu doit restreindre la liste à ce client.
   */
  test('recherche client DEVRAIT filtrer la liste', async ({ adminPage: page }) => {
    await page.goto('/customers');
    await expect(page.getByRole('table').getByText(/@/).first()).toBeVisible();

    await page.getByPlaceholder('Rechercher…').fill('aboubacar');

    // Attendu : seules les lignes correspondant à "aboubacar" subsistent.
    const table = page.getByRole('table');
    await expect(table.getByText('aboubacar@kenzorf.com')).toBeVisible();
    await expect(table.getByText('client@kenzorf.com')).toHaveCount(0);
  });
});
