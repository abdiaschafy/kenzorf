/** Constantes partagées des tests E2E (comptes seedés, URLs). */

export const API_BASE_URL = process.env.E2E_API_URL ?? 'http://localhost:8090';
export const UI_BASE_URL = process.env.E2E_BASE_URL ?? 'http://localhost:4400';

export const DEFAULT_PASSWORD = 'Password123!';

export const ACCOUNTS = {
  admin: { email: 'admin@kenzorf.com', password: DEFAULT_PASSWORD },
  customer: { email: 'client@kenzorf.com', password: DEFAULT_PASSWORD },
  /** Deuxième client démo (seed DemoDataSeeder) — utile pour les tests IDOR. */
  customer2: { email: 'aboubacar@kenzorf.com', password: DEFAULT_PASSWORD },
} as const;

/** Slug d'un produit seedé riche en variantes (T-shirt Signature, 12 variantes). */
export const SEEDED_PRODUCT_SLUG = 'tshirt-signature-kenzorf';

export const SEEDED_CATEGORY_SLUGS = ['homme', 'femme', 'unisexe', 'accessoires'] as const;

/** Clés de session sessionStorage utilisées par le back-office (storage.constants.ts). */
export const AUTH_STORAGE = {
  RefreshToken: 'kenzorf.admin.refreshToken',
  ExpiresAt: 'kenzorf.admin.expiresAt',
  User: 'kenzorf.admin.user',
} as const;
