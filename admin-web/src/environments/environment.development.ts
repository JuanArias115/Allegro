/**
 * Configuración de DESARROLLO. La autenticación siempre es Firebase (la web no
 * usa el token local del backend). Para desarrollo apunta a un backend en
 * AUTH_MODE=firebase (local con credenciales, o el backend de producción).
 */
export const environment = {
  production: false,
  apiBaseUrl: 'http://localhost:8080',
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
