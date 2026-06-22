import { environment } from '../../../environments/environment';

/**
 * Configuración resuelta en runtime. Permite reutilizar la misma imagen Docker
 * apuntando a distintos backends sin recompilar: el contenedor escribe
 * `config.json` (ver entrypoint) y se carga antes de arrancar la app. Si no existe,
 * se usa el valor compilado en environment.
 */
export const runtimeConfig = {
  apiBaseUrl: environment.apiBaseUrl,
};

/** Carga config.json (si existe) y sobreescribe apiBaseUrl. Usado por provideAppInitializer. */
export async function loadRuntimeConfig(): Promise<void> {
  try {
    const res = await fetch('config.json', { cache: 'no-store' });
    if (res.ok) {
      const cfg = (await res.json()) as { apiBaseUrl?: string };
      if (cfg.apiBaseUrl) runtimeConfig.apiBaseUrl = cfg.apiBaseUrl;
    }
  } catch {
    // Sin config.json: se conserva el valor de environment.
  }
}
