import { Routes } from '@angular/router';
import { ROUTE_SEGMENT } from '@app/core/constants/routes.constants';

export const PRODUCTS_ROUTES: Routes = [
  {
    path: '',
    loadComponent: () =>
      import('./product-list/product-list.component').then((m) => m.ProductListComponent),
  },
  {
    path: ROUTE_SEGMENT.New,
    loadComponent: () =>
      import('./product-form/product-form.component').then((m) => m.ProductFormComponent),
  },
  {
    path: ':id',
    loadComponent: () =>
      import('./product-form/product-form.component').then((m) => m.ProductFormComponent),
  },
];
