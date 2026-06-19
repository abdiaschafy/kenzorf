/**
 * Chemins relatifs des endpoints (concaténés à `environment.apiUrl`).
 * Source de vérité : .claude/specs/kenzorf-mvp.md §4.
 */
export const API_ENDPOINTS = {
  auth: {
    login: '/auth/login',
    refresh: '/auth/refresh',
    logout: '/auth/logout',
    me: '/auth/me',
  },
  admin: {
    dashboard: '/admin/dashboard',
    products: '/admin/products',
    product: (id: string) => `/admin/products/${id}`,
    productVariants: (id: string) => `/admin/products/${id}/variants`,
    productVariant: (id: string, variantId: string) => `/admin/products/${id}/variants/${variantId}`,
    productImages: (id: string) => `/admin/products/${id}/images`,
    categories: '/admin/categories',
    category: (id: string) => `/admin/categories/${id}`,
    orders: '/admin/orders',
    order: (id: string) => `/admin/orders/${id}`,
    orderStatus: (id: string) => `/admin/orders/${id}/status`,
    customers: '/admin/customers',
    uploads: '/admin/uploads',
  },
  categories: '/categories',
} as const;
