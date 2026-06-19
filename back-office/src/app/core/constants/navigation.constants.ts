import { ROUTE_SEGMENT } from './routes.constants';
import type { NavGroup } from '@app/core/interfaces/navigation.interfaces';

/** Structure du menu latéral du back-office. */
export const NAV_GROUPS: readonly NavGroup[] = [
  {
    labelKey: 'nav.menu',
    items: [{ path: `/${ROUTE_SEGMENT.Dashboard}`, labelKey: 'nav.dashboard', icon: 'dashboard' }],
  },
  {
    labelKey: 'nav.section.catalog',
    items: [
      { path: `/${ROUTE_SEGMENT.Products}`, labelKey: 'nav.products', icon: 'products' },
      { path: `/${ROUTE_SEGMENT.Categories}`, labelKey: 'nav.categories', icon: 'categories' },
    ],
  },
  {
    labelKey: 'nav.section.sales',
    items: [
      { path: `/${ROUTE_SEGMENT.Orders}`, labelKey: 'nav.orders', icon: 'orders' },
      { path: `/${ROUTE_SEGMENT.Customers}`, labelKey: 'nav.customers', icon: 'customers' },
    ],
  },
];
