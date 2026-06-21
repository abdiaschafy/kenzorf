import { test, expect } from '@playwright/test';
import {
  authHeaders,
  createPendingOrder,
  freshCustomerToken,
  getInStockVariant,
} from '../../support/api';

test.describe('API · Commandes & paiement (Customer)', () => {
  test('POST /orders crée une commande Pending et initie le paiement KPay', async ({ request }) => {
    const accessToken = await freshCustomerToken(request);
    const variant = await getInStockVariant(request);
    const order = await createPendingOrder(request, accessToken, variant.id, 1);

    expect(order.orderNumber).toMatch(/^KZF-/);
    expect(order.status).toBe('Pending');
    expect(order.total).toBeGreaterThan(0);
    expect(order.payment).toBeTruthy();
    expect(order.payment!.checkoutUrl, 'checkoutUrl KPay présent').toBeTruthy();
    expect(order.payment!.reference).toBeTruthy();
    // Le paiement est seulement initié, jamais "Paid" sur le simple retour client.
    expect(['Pending', 'Initiated']).toContain(order.payment!.status);
  });

  test('GET /orders liste les commandes du client', async ({ request }) => {
    const accessToken = await freshCustomerToken(request);
    const variant = await getInStockVariant(request);
    const created = await createPendingOrder(request, accessToken, variant.id, 1);

    const res = await request.get('/api/orders', { headers: authHeaders(accessToken) });
    expect(res.status()).toBe(200);
    const orders = await res.json();
    expect(Array.isArray(orders)).toBe(true);
    expect(orders.some((o: { id: string }) => o.id === created.id)).toBe(true);
  });

  test('GET /orders/{id} renvoie le détail de ma commande', async ({ request }) => {
    const accessToken = await freshCustomerToken(request);
    const variant = await getInStockVariant(request);
    const created = await createPendingOrder(request, accessToken, variant.id, 1);

    const res = await request.get(`/api/orders/${created.id}`, { headers: authHeaders(accessToken) });
    expect(res.status()).toBe(200);
    const order = await res.json();
    expect(order.id).toBe(created.id);
    expect(order.orderNumber).toBe(created.orderNumber);
  });

  test('POST /orders/{id}/cancel annule une commande Pending', async ({ request }) => {
    const accessToken = await freshCustomerToken(request);
    const variant = await getInStockVariant(request);
    const created = await createPendingOrder(request, accessToken, variant.id, 1);

    const res = await request.post(`/api/orders/${created.id}/cancel`, {
      headers: authHeaders(accessToken),
    });
    expect(res.status()).toBe(200);
    const cancelled = await res.json();
    expect(cancelled.status).toBe('Cancelled');
  });

  test('GET /payments/{reference}/status (poll) renvoie le statut du paiement', async ({ request }) => {
    const accessToken = await freshCustomerToken(request);
    const variant = await getInStockVariant(request);
    const order = await createPendingOrder(request, accessToken, variant.id, 1);
    const reference = order.payment!.reference;

    const res = await request.get(`/api/payments/${reference}/status`, {
      headers: authHeaders(accessToken),
    });
    expect(res.status()).toBe(200);
    const status = await res.json();
    expect(status).toHaveProperty('status');
    expect(status).toHaveProperty('orderId');
    expect(status.orderId).toBe(order.id);
    expect(status).toHaveProperty('orderStatus');
  });

  test('GET /payments/{reference}/status sans token → 401', async ({ request }) => {
    const res = await request.get('/api/payments/KPY-UNKNOWN/status');
    expect(res.status()).toBe(401);
  });

  test('création de commande avec panier vide → erreur (422 ou 409)', async ({ request }) => {
    const accessToken = await freshCustomerToken(request);
    // Vider le panier puis tenter une commande.
    await request.delete('/api/cart', { headers: authHeaders(accessToken) });

    const res = await request.post('/api/orders', {
      headers: authHeaders(accessToken),
      data: {
        shippingAddress: {
          fullName: 'Vide',
          phoneNumber: '+2250500000000',
          line1: 'Rue 1',
          city: 'Abidjan',
          country: 'CI',
        },
        paymentMethod: 'wave',
      },
    });
    expect(res.status(), 'commande sur panier vide doit échouer').toBeGreaterThanOrEqual(400);
    expect(res.status()).toBeLessThan(500);
  });
});
