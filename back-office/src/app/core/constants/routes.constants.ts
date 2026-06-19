/** Segments de routes centralisés (évite les chaînes magiques dans le code). */
export const APP_ROUTE = {
  Login: 'login',
  Dashboard: 'dashboard',
  Products: 'products',
  ProductNew: 'products/new',
  Categories: 'categories',
  Orders: 'orders',
  Customers: 'customers',
} as const;

export const ROUTE_SEGMENT = {
  Login: 'login',
  Dashboard: 'dashboard',
  Products: 'products',
  Categories: 'categories',
  Orders: 'orders',
  Customers: 'customers',
  New: 'new',
} as const;
