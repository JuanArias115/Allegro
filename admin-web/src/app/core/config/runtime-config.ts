import { environment } from '../../../environments/environment';

export interface FirebaseWebConfig {
  apiKey: string;
  authDomain: string;
  projectId: string;
  storageBucket: string;
  messagingSenderId: string;
  appId: string;
}

/**
 * Configuración resuelta en runtime. Permite reutilizar la misma imagen Docker
 * apuntando a distintos backends sin recompilar: el contenedor escribe
 * `config.json` (ver entrypoint) y se carga antes de arrancar la app. Si no existe,
 * se usa el valor compilado en environment.
 */
export const runtimeConfig = {
  apiBaseUrl: environment.apiBaseUrl,
  googleAuthEnabled: environment.googleAuthEnabled,
  firebase: { ...environment.firebase } as FirebaseWebConfig,
};

/** Carga config.json antes de inicializar Firebase y los servicios HTTP. */
export async function loadRuntimeConfig(): Promise<void> {
  try {
    const res = await fetch('config.json', { cache: 'no-store' });
    if (res.ok) {
      const cfg = (await res.json()) as {
        apiBaseUrl?: string;
        googleAuthEnabled?: boolean;
        firebase?: Partial<FirebaseWebConfig>;
      };
      if (cfg.apiBaseUrl) runtimeConfig.apiBaseUrl = cfg.apiBaseUrl;
      if (typeof cfg.googleAuthEnabled === 'boolean') {
        runtimeConfig.googleAuthEnabled = cfg.googleAuthEnabled;
      }
      if (cfg.firebase) {
        runtimeConfig.firebase = { ...runtimeConfig.firebase, ...cfg.firebase };
      }
    }
  } catch {
    // Sin config.json: se conserva el valor de environment.
  }

  const missing = Object.entries(runtimeConfig.firebase)
    .filter(([, value]) => !value || value.startsWith('REPLACE_WITH_'))
    .map(([key]) => key);
  if (missing.length > 0) {
    throw new Error(`Falta configuración pública de Firebase: ${missing.join(', ')}`);
  }
}
