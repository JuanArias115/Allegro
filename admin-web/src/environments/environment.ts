/**
 * Configuración de PRODUCCIÓN.
 *
 * La configuración pública de Firebase Web NO es secreta, pero igualmente debes
 * reemplazar estos placeholders con los valores reales de tu proyecto Firebase
 * (Consola Firebase > Configuración del proyecto > Tus apps > SDK de Firebase).
 * NUNCA pongas aquí credenciales administrativas ni archivos service-account.
 */
export const environment = {
  production: true,
  apiBaseUrl: 'https://allegro.juanariasdev.com',
  googleAuthEnabled: true,
  firebase: {
    apiKey: 'REPLACE_WITH_FIREBASE_WEB_API_KEY',
    authDomain: 'REPLACE_WITH_PROJECT.firebaseapp.com',
    projectId: 'REPLACE_WITH_PROJECT_ID',
    storageBucket: 'REPLACE_WITH_PROJECT.appspot.com',
    messagingSenderId: 'REPLACE_WITH_SENDER_ID',
    appId: 'REPLACE_WITH_APP_ID',
  },
};
