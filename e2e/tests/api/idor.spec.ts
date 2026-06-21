import { test, expect } from '@playwright/test';
import {
  authHeaders,
  createPendingOrder,
  getInStockVariant,
  registerFreshCustomer,
} from '../../support/api';

/**
 * IDOR / scoping : un client ne doit JAMAIS accéder aux ressources d'un autre client.
 * Attendu : 404 (fail-closed, sans révéler l'existence de la ressource), pas 200.
 *
 * Victime ET attaquant sont des clients fraîchement inscrits → isolation totale, pas de
 * panier/commande partagés entre tests parallèles.
 */
test.describe('API · IDOR (isolation entre clients)', () => {
  test('un client ne peut pas lire la commande d\'un autre client → 404', async ({ request }) => {
    const { auth: victim } = await registerFreshCustomer(request);
    const variant = await getInStockVariant(request);
    const victimOrder = await createPendingOrder(request, victim.accessToken, variant.id, 1);

    const { auth: attacker } = await registerFreshCustomer(request);
    const res = await request.get(`/api/orders/${victimOrder.id}`, {
      headers: authHeaders(attacker.accessToken),
    });
    expect(res.status(), 'lecture commande d\'autrui doit renvoyer 404').toBe(404);
  });

  test('un client ne peut pas annuler la commande d\'un autre client → 404', async ({ request }) => {
    const { auth: victim } = await registerFreshCustomer(request);
    const variant = await getInStockVariant(request);
    const victimOrder = await createPendingOrder(request, victim.accessToken, variant.id, 1);

    const { auth: attacker } = await registerFreshCustomer(request);
    const res = await request.post(`/api/orders/${victimOrder.id}/cancel`, {
      headers: authHeaders(attacker.accessToken),
    });
    expect(res.status()).toBe(404);

    // La commande de la victime reste intacte (toujours Pending).
    const check = await request.get(`/api/orders/${victimOrder.id}`, {
      headers: authHeaders(victim.accessToken),
    });
    const stillThere = await check.json();
    expect(stillThere.status).toBe('Pending');
  });

  test('un client ne peut pas modifier/supprimer l\'adresse d\'un autre client → 404', async ({ request }) => {
    const { auth: victim } = await registerFreshCustomer(request);
    const created = await request.post('/api/addresses', {
      headers: authHeaders(victim.accessToken),
      data: {
        fullName: 'Victime',
        phoneNumber: '+2250500000000',
        line1: 'Rue privée',
        city: 'Abidjan',
        country: 'CI',
      },
    });
    const victimAddress = await created.json();

    const { auth: attacker } = await registerFreshCustomer(request);
    const update = await request.put(`/api/addresses/${victimAddress.id}`, {
      headers: authHeaders(attacker.accessToken),
      data: {
        fullName: 'Hacked',
        phoneNumber: '+2250000000000',
        line1: 'Pwned',
        city: 'X',
        country: 'CI',
      },
    });
    expect(update.status()).toBe(404);

    const del = await request.delete(`/api/addresses/${victimAddress.id}`, {
      headers: authHeaders(attacker.accessToken),
    });
    expect(del.status()).toBe(404);
  });

  test('un client ne peut pas poller le paiement d\'un autre client → 404', async ({ request }) => {
    const { auth: victim } = await registerFreshCustomer(request);
    const variant = await getInStockVariant(request);
    const victimOrder = await createPendingOrder(request, victim.accessToken, variant.id, 1);
    const reference = victimOrder.payment!.reference;

    const { auth: attacker } = await registerFreshCustomer(request);
    const res = await request.get(`/api/payments/${reference}/status`, {
      headers: authHeaders(attacker.accessToken),
    });
    expect(res.status(), 'poll paiement d\'autrui doit renvoyer 404').toBe(404);
  });
});
