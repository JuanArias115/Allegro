import { inject } from '@angular/core';
import { CanActivateFn, Router } from '@angular/router';
import { AuthService } from './auth.service';
import type { Role } from '../models/models';

/** Exige sesión iniciada. Redirige a /login conservando la URL de retorno. */
export const authGuard: CanActivateFn = async (_route, state) => {
  const auth = inject(AuthService);
  const router = inject(Router);
  await auth.waitUntilReady();

  if (auth.isAuthenticated()) return true;
  return router.createUrlTree(['/login'], { queryParams: { returnUrl: state.url } });
};

/**
 * Exige un rol concreto. La comprobación real ocurre en el backend; esto solo
 * mejora la navegación y oculta lo que el usuario no puede usar.
 */
export function roleGuard(required: Role): CanActivateFn {
  return async () => {
    const auth = inject(AuthService);
    const router = inject(Router);
    await auth.waitUntilReady();

    if (!auth.isAuthenticated()) {
      return router.createUrlTree(['/login']);
    }
    const role = auth.role();
    // admin tiene acceso completo; operator solo a lo suyo.
    if (role === 'admin' || role === required) return true;
    return router.createUrlTree(['/forbidden']);
  };
}
