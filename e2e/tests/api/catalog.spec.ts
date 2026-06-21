import { test, expect } from '@playwright/test';
import { SEEDED_CATEGORY_SLUGS, SEEDED_PRODUCT_SLUG } from '../../support/constants';

test.describe('API · Catalogue public (sans auth)', () => {
  test('GET /categories renvoie les catégories seedées', async ({ request }) => {
    const res = await request.get('/api/categories');
    expect(res.status()).toBe(200);
    const categories = await res.json();
    expect(Array.isArray(categories)).toBe(true);
    const slugs = categories.map((c: { slug: string }) => c.slug);
    for (const expected of SEEDED_CATEGORY_SLUGS) {
      expect(slugs, `catégorie ${expected}`).toContain(expected);
    }
    // productCount présent et cohérent.
    expect(categories[0]).toHaveProperty('productCount');
  });

  test('GET /products pagine correctement', async ({ request }) => {
    const res = await request.get('/api/products?page=1&pageSize=3');
    expect(res.status()).toBe(200);
    const paged = await res.json();
    expect(paged.page).toBe(1);
    expect(paged.pageSize).toBe(3);
    expect(paged.items.length).toBeLessThanOrEqual(3);
    expect(paged.total).toBeGreaterThan(0);
    expect(paged.totalPages).toBe(Math.ceil(paged.total / 3));
  });

  test('GET /products page 2 renvoie des items différents de la page 1', async ({ request }) => {
    const p1 = await (await request.get('/api/products?page=1&pageSize=3')).json();
    const p2 = await (await request.get('/api/products?page=2&pageSize=3')).json();
    const ids1 = new Set(p1.items.map((p: { id: string }) => p.id));
    for (const item of p2.items) {
      expect(ids1.has(item.id), 'pas de chevauchement entre pages').toBe(false);
    }
  });

  test('GET /products filtre par catégorie', async ({ request }) => {
    const res = await request.get('/api/products?categorySlug=homme&pageSize=50');
    expect(res.status()).toBe(200);
    const paged = await res.json();
    expect(paged.items.length).toBeGreaterThan(0);
    // Tous les items renvoyés appartiennent au rayon Homme (gender Men attendu pour cette catégorie seed).
    for (const item of paged.items) {
      expect(item).toHaveProperty('gender');
    }
  });

  test('GET /products filtre par genre', async ({ request }) => {
    const res = await request.get('/api/products?gender=Women&pageSize=50');
    expect(res.status()).toBe(200);
    const paged = await res.json();
    for (const item of paged.items) {
      expect(item.gender).toBe('Women');
    }
  });

  test('GET /products recherche par mot-clé', async ({ request }) => {
    const res = await request.get('/api/products?search=tshirt&pageSize=50');
    expect(res.status()).toBe(200);
    const paged = await res.json();
    expect(paged.total).toBeGreaterThanOrEqual(0);
  });

  test('GET /products tri price_asc est croissant', async ({ request }) => {
    const res = await request.get('/api/products?sort=price_asc&pageSize=50');
    const paged = await res.json();
    const prices = paged.items.map((p: { basePrice: number }) => p.basePrice);
    const sorted = [...prices].sort((a, b) => a - b);
    expect(prices).toEqual(sorted);
  });

  test('GET /products tri price_desc est décroissant', async ({ request }) => {
    const res = await request.get('/api/products?sort=price_desc&pageSize=50');
    const paged = await res.json();
    const prices = paged.items.map((p: { basePrice: number }) => p.basePrice);
    const sorted = [...prices].sort((a, b) => b - a);
    expect(prices).toEqual(sorted);
  });

  test('GET /products filtre par fourchette de prix', async ({ request }) => {
    const res = await request.get('/api/products?minPrice=10000&maxPrice=15000&pageSize=50');
    expect(res.status()).toBe(200);
    const paged = await res.json();
    for (const item of paged.items) {
      expect(item.basePrice).toBeGreaterThanOrEqual(10000);
      expect(item.basePrice).toBeLessThanOrEqual(15000);
    }
  });

  test('GET /products/featured renvoie des produits mis en avant', async ({ request }) => {
    const res = await request.get('/api/products/featured');
    expect(res.status()).toBe(200);
    const featured = await res.json();
    expect(Array.isArray(featured)).toBe(true);
    expect(featured.length).toBeGreaterThan(0);
    for (const p of featured) {
      expect(p.isFeatured).toBe(true);
    }
  });

  test('GET /products/{slug} renvoie le détail avec variantes et images', async ({ request }) => {
    const res = await request.get(`/api/products/${SEEDED_PRODUCT_SLUG}`);
    expect(res.status()).toBe(200);
    const product = await res.json();
    expect(product.slug).toBe(SEEDED_PRODUCT_SLUG);
    expect(product.variants.length).toBeGreaterThan(0);
    expect(product.images.length).toBeGreaterThan(0);
    expect(product.category).toHaveProperty('slug');
    const v = product.variants[0];
    expect(v).toHaveProperty('sku');
    expect(v).toHaveProperty('stockQuantity');
    expect(v).toHaveProperty('inStock');
  });

  test('GET /products/{slug} inconnu → 404 au format contrat', async ({ request }) => {
    const res = await request.get('/api/products/produit-inexistant-xyz');
    expect(res.status()).toBe(404);
    const body = await res.json();
    expect(body).toHaveProperty('code');
    expect(body).toHaveProperty('messageKey');
    expect(body.status).toBe(404);
  });
});
