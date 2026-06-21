import { test, expect } from '@playwright/test';
import { authHeaders, freshCustomerToken, getInStockVariant } from '../../support/api';

/**
 * Chaque test utilise un client fraîchement inscrit → panier isolé, pas de course
 * d'écriture entre tests parallèles.
 */
test.describe('API · Panier (Customer)', () => {
  test('GET /cart sans token → 401', async ({ request }) => {
    const res = await request.get('/api/cart');
    expect(res.status()).toBe(401);
  });

  test('cycle complet add / update / remove', async ({ request }) => {
    const token = await freshCustomerToken(request);
    const variant = await getInStockVariant(request);

    // Add
    const add = await request.post('/api/cart/items', {
      headers: authHeaders(token),
      data: { productVariantId: variant.id, quantity: 2 },
    });
    expect(add.status()).toBe(200);
    let cart = await add.json();
    expect(cart.items.length).toBe(1);
    expect(cart.totalQuantity).toBe(2);
    const itemId = cart.items[0].id;
    expect(cart.subtotal).toBe(cart.items[0].unitPrice * 2);

    // Update
    const upd = await request.put(`/api/cart/items/${itemId}`, {
      headers: authHeaders(token),
      data: { quantity: 3 },
    });
    expect(upd.status()).toBe(200);
    cart = await upd.json();
    expect(cart.items[0].quantity).toBe(3);

    // Remove
    const del = await request.delete(`/api/cart/items/${itemId}`, {
      headers: authHeaders(token),
    });
    expect(del.status()).toBe(200);
    cart = await del.json();
    expect(cart.items.length).toBe(0);
  });

  test('add variante inexistante → erreur de validation (422)', async ({ request }) => {
    const token = await freshCustomerToken(request);
    const res = await request.post('/api/cart/items', {
      headers: authHeaders(token),
      data: { productVariantId: '00000000-0000-0000-0000-000000000000', quantity: 1 },
    });
    expect(res.status()).toBe(422);
    const body = await res.json();
    expect(body).toHaveProperty('messageKey');
  });

  test('add quantité supérieure au stock → 422 (stock dépassé)', async ({ request }) => {
    const token = await freshCustomerToken(request);
    const variant = await getInStockVariant(request);

    const res = await request.post('/api/cart/items', {
      headers: authHeaders(token),
      data: { productVariantId: variant.id, quantity: 99999 },
    });
    expect(res.status()).toBe(422);
    const body = await res.json();
    expect(body.status).toBe(422);
    expect(body).toHaveProperty('messageKey');
  });

  test('DELETE /cart vide le panier (204)', async ({ request }) => {
    const token = await freshCustomerToken(request);
    const variant = await getInStockVariant(request);
    await request.post('/api/cart/items', {
      headers: authHeaders(token),
      data: { productVariantId: variant.id, quantity: 1 },
    });
    const res = await request.delete('/api/cart', { headers: authHeaders(token) });
    expect(res.status()).toBe(204);

    const after = await request.get('/api/cart', { headers: authHeaders(token) });
    const cart = await after.json();
    expect(cart.items.length).toBe(0);
  });
});
