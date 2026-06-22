import {
  ApplicationConfig,
  LOCALE_ID,
  provideBrowserGlobalErrorListeners,
} from '@angular/core';
import { provideRouter, withComponentInputBinding } from '@angular/router';
import { provideHttpClient, withInterceptors } from '@angular/common/http';
import { registerLocaleData } from '@angular/common';
import localeEsCo from '@angular/common/locales/es-CO';

import { routes } from './app.routes';
import { authInterceptor } from './core/http/auth.interceptor';

registerLocaleData(localeEsCo);

// Angular Material 21 funciona sin el módulo de animaciones (sin transiciones de
// entrada/salida). Se evita así depender de @angular/animations en este proyecto zoneless.
export const appConfig: ApplicationConfig = {
  providers: [
    provideBrowserGlobalErrorListeners(),
    provideRouter(routes, withComponentInputBinding()),
    provideHttpClient(withInterceptors([authInterceptor])),
    { provide: LOCALE_ID, useValue: 'es-CO' },
  ],
};
