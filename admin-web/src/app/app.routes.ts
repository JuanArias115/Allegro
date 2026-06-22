import { Routes } from '@angular/router';
import { authGuard, roleGuard } from './core/auth/auth.guards';

export const routes: Routes = [
  {
    path: 'login',
    loadComponent: () => import('./features/auth/login').then((m) => m.Login),
  },
  {
    path: 'forbidden',
    loadComponent: () => import('./features/auth/forbidden').then((m) => m.Forbidden),
  },
  {
    path: '',
    canActivate: [authGuard],
    loadComponent: () => import('./layout/shell').then((m) => m.Shell),
    children: [
      { path: '', pathMatch: 'full', redirectTo: 'dashboard' },
      {
        path: 'dashboard',
        loadComponent: () => import('./features/dashboard/dashboard').then((m) => m.Dashboard),
      },
      {
        path: 'calendario',
        loadComponent: () => import('./features/calendar/calendar').then((m) => m.Calendar),
      },
      {
        path: 'reservas',
        loadComponent: () =>
          import('./features/reservations/reservations').then((m) => m.Reservations),
      },
      {
        path: 'domos',
        canActivate: [roleGuard('admin')],
        loadComponent: () => import('./features/domes/domes').then((m) => m.Domes),
      },
      {
        path: 'productos',
        loadComponent: () => import('./features/products/products').then((m) => m.Products),
      },
      {
        path: 'usuarios',
        canActivate: [roleGuard('admin')],
        loadComponent: () => import('./features/users/users').then((m) => m.Users),
      },
      {
        path: 'reportes',
        canActivate: [roleGuard('admin')],
        loadComponent: () => import('./features/reports/reports').then((m) => m.Reports),
      },
      {
        path: 'configuracion',
        canActivate: [roleGuard('admin')],
        loadComponent: () => import('./features/settings/settings').then((m) => m.Settings),
      },
    ],
  },
  { path: '**', redirectTo: '' },
];
