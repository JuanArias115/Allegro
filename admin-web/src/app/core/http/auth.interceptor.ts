import { HttpInterceptorFn } from '@angular/common/http';
import { inject } from '@angular/core';
import { from, switchMap } from 'rxjs';
import { AuthService } from '../auth/auth.service';
import { runtimeConfig } from '../config/runtime-config';

/**
 * Adjunta el ID token de Firebase como Bearer a las llamadas al backend. Solo a
 * las peticiones dirigidas a apiBaseUrl (no a Firebase ni a terceros).
 */
export const authInterceptor: HttpInterceptorFn = (req, next) => {
  if (!req.url.startsWith(runtimeConfig.apiBaseUrl)) {
    return next(req);
  }
  const auth = inject(AuthService);
  return from(auth.getToken()).pipe(
    switchMap((token) =>
      next(token ? req.clone({ setHeaders: { Authorization: `Bearer ${token}` } }) : req),
    ),
  );
};
