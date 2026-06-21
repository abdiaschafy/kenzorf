import { APIRequestContext, expect, request } from '@playwright/test';
import { ACCOUNTS, API_BASE_URL, SEEDED_PRODUCT_SLUG } from './constants';

/** Sous-ensemble typé des DTOs API utiles aux tests (alignés .claude/specs §5). */
export interface AuthResponse {
  accessToken: string;
  refreshToken: string;
  expiresAt: string;
  user: { id: string; email: string; firstName: string; lastName: string; role: 'Customer' | 'Admin' };
}

export interface VariantDto {
  id: string;
  sku: string;
  size: string;
  color: string;
  stockQuantity: number;
  inStock: boolean;
  price: number;
}

export interface ProductDetailDto {
  id: string;
  name: string;
  slug: string;
  variants: VariantDto[];
  category: { id: string; name: string; slug: string };
}

export interface OrderDto {
  id: string;
  orderNumber: string;
  status: string;
  total: number;
  payment?: { reference: string; status: string; checkoutUrl?: string; provider: string };
}

const JSON_HEADERS = { 'Content-Type': 'application/json', 'Accept-Language': 'fr' };

/** Crée un request context autonome (utile hors des fixtures, p.ex. global helpers). */
export async function newApiContext(): Promise<APIRequestContext> {
  return request.newContext({ baseURL: API_BASE_URL, extraHTTPHeaders: JSON_HEADERS });
}

export function authHeaders(token: string): Record<string, string> {
  return { Authorization: `Bearer ${token}`, ...JSON_HEADERS };
}

export async function login(
  api: APIRequestContext,
  email: string,
  password: string,
): Promise<AuthResponse> {
  const res = await api.post('/api/auth/login', { data: { email, password } });
  expect(res.status(), `login ${email}`).toBe(200);
  return res.json();
}

export async function loginAdmin(api: APIRequestContext): Promise<AuthResponse> {
  return login(api, ACCOUNTS.admin.email, ACCOUNTS.admin.password);
}

export async function loginCustomer(api: APIRequestContext): Promise<AuthResponse> {
  return login(api, ACCOUNTS.customer.email, ACCOUNTS.customer.password);
}

/** Inscrit un client unique (email horodaté) et renvoie l'AuthResponse. */
export async function registerFreshCustomer(api: APIRequestContext): Promise<{ email: string; auth: AuthResponse }> {
  const email = `e2e+${Date.now()}-${Math.floor(Math.random() * 1e6)}@kenzorf.test`;
  const res = await api.post('/api/auth/register', {
    data: { email, password: 'Password123!', firstName: 'E2E', lastName: 'Tester', phoneNumber: '+2250700000001' },
  });
  expect(res.status(), 'register fresh customer').toBe(200);
  return { email, auth: await res.json() };
}

/** Inscrit un client frais et renvoie directement son access token (isolation par test). */
export async function freshCustomerToken(api: APIRequestContext): Promise<string> {
  const { auth } = await registerFreshCustomer(api);
  return auth.accessToken;
}

export async function getProductDetail(api: APIRequestContext, slug = SEEDED_PRODUCT_SLUG): Promise<ProductDetailDto> {
  const res = await api.get(`/api/products/${slug}`);
  expect(res.status()).toBe(200);
  return res.json();
}

/** Première variante en stock d'un produit seedé. */
export async function getInStockVariant(api: APIRequestContext, slug = SEEDED_PRODUCT_SLUG): Promise<VariantDto> {
  const product = await getProductDetail(api, slug);
  const variant = product.variants.find((v) => v.inStock && v.stockQuantity > 2);
  expect(variant, 'variante en stock trouvée').toBeTruthy();
  return variant!;
}

export async function clearCart(api: APIRequestContext, token: string): Promise<void> {
  await api.delete('/api/cart', { headers: authHeaders(token) });
}

/** Vide le panier, ajoute une variante, crée une commande Pending et renvoie l'OrderDto. */
export async function createPendingOrder(
  api: APIRequestContext,
  token: string,
  variantId: string,
  quantity = 1,
): Promise<OrderDto> {
  await clearCart(api, token);
  const add = await api.post('/api/cart/items', {
    headers: authHeaders(token),
    data: { productVariantId: variantId, quantity },
  });
  expect(add.status(), 'ajout panier').toBe(200);

  const res = await api.post('/api/orders', {
    headers: authHeaders(token),
    data: {
      shippingAddress: {
        fullName: 'E2E Acheteur',
        phoneNumber: '+2250500000000',
        line1: 'Rue des Tests 1',
        city: 'Abidjan',
        country: 'CI',
      },
      paymentMethod: 'wave',
    },
  });
  expect(res.status(), 'création commande').toBe(201);
  return res.json();
}
