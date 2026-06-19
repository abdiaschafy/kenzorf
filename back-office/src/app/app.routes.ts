import { Routes } from '@angular/router';
import { ROUTE_SEGMENT } from '@app/core/constants/routes.constants';
import { adminGuard, guestGuard } from '@app/core/guards/admin.guard';

export const routes: Routes = [
  {
    path: ROUTE_SEGMENT.Login,
    canActivate: [guestGuard],
    loadComponent: () =>
      import('@app/features/auth/login/login.component').then((m) => m.LoginComponent),
  },
  {
    path: '',
    canActivate: [adminGuard],
    canActivateChild: [adminGuard],
    loadComponent: () =>
      import('@app/layouts/admin/admin-layout.component').then((m) => m.AdminLayoutComponent),
    children: [
      { path: '', pathMatch: 'full', redirectTo: ROUTE_SEGMENT.Dashboard },
      {
        path: ROUTE_SEGMENT.Dashboard,
        loadComponent: () =>
          import('@app/features/dashboard/dashboard.component').then((m) => m.DashboardComponent),
      },
      {
        path: ROUTE_SEGMENT.Products,
        loadChildren: () =>
          import('@app/features/products/products.routes').then((m) => m.PRODUCTS_ROUTES),
      },
      {
        path: ROUTE_SEGMENT.Categories,
        loadComponent: () =>
          import('@app/features/categories/categories.component').then((m) => m.CategoriesComponent),
      },
      {
        path: ROUTE_SEGMENT.Orders,
        loadChildren: () => import('@app/features/orders/orders.routes').then((m) => m.ORDERS_ROUTES),
      },
      {
        path: ROUTE_SEGMENT.Customers,
        loadComponent: () =>
          import('@app/features/customers/customers.component').then((m) => m.CustomersComponent),
      },
    ],
  },
  { path: '**', redirectTo: '' },
];
