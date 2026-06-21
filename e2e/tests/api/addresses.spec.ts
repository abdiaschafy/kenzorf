import { test, expect } from '@playwright/test';
import { authHeaders, loginCustomer } from '../../support/api';

const sampleAddress = {
  label: 'Maison',
  fullName: 'Awa Koné',
  phoneNumber: '+2250500000000',
  line1: 'Rue des Jardins 12',
  line2: 'Appartement 3',
  city: 'Abidjan',
  region: 'Lagunes',
  country: 'CI',
  landmark: 'Près de la pharmacie',
};

test.describe('API · Adresses (Customer)', () => {
  test('GET /addresses sans token → 401', async ({ request }) => {
    const res = await request.get('/api/addresses');
    expect(res.status()).toBe(401);
  });

  test('CRUD complet adresse', async ({ request }) => {
    const { accessToken } = await loginCustomer(request);
    const headers = authHeaders(accessToken);

    // Create
    const create = await request.post('/api/addresses', { headers, data: sampleAddress });
    expect(create.status()).toBe(201);
    const created = await create.json();
    expect(created.id).toBeTruthy();
    expect(created.city).toBe('Abidjan');

    // Read (list contient l'adresse)
    const list = await request.get('/api/addresses', { headers });
    expect(list.status()).toBe(200);
    const addresses = await list.json();
    expect(addresses.some((a: { id: string }) => a.id === created.id)).toBe(true);

    // Update
    const update = await request.put(`/api/addresses/${created.id}`, {
      headers,
      data: { ...sampleAddress, city: 'Bouaké' },
    });
    expect(update.status()).toBe(200);
    const updated = await update.json();
    expect(updated.city).toBe('Bouaké');

    // Delete
    const del = await request.delete(`/api/addresses/${created.id}`, { headers });
    expect(del.status()).toBe(204);

    const afterList = await request.get('/api/addresses', { headers });
    const remaining = await afterList.json();
    expect(remaining.some((a: { id: string }) => a.id === created.id)).toBe(false);
  });

  test('création d\'adresse incomplète → erreur 4xx', async ({ request }) => {
    const { accessToken } = await loginCustomer(request);
    const res = await request.post('/api/addresses', {
      headers: authHeaders(accessToken),
      data: { fullName: '', line1: '', city: '', country: '' },
    });
    expect(res.status()).toBeGreaterThanOrEqual(400);
    expect(res.status()).toBeLessThan(500);
  });
});
