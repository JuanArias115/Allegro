# Firebase Authentication

La app usa **Firebase Authentication** (proyecto `allegro-95408`). La configuración
de cliente ya está integrada y **versionada** en el repositorio.

## Qué se versiona y qué NO

Los archivos de configuración de **cliente** se incluyen en Git porque de todas
formas quedan embebidos dentro de la app compilada (no son secretos; sus claves
son públicas y están restringidas por Firebase):

- `mobile/lib/firebase_options.dart`
- `mobile/android/app/google-services.json`
- `mobile/ios/Runner/GoogleService-Info.plist`

**NUNCA** se versionan credenciales **administrativas** ni secretos del servidor:

- JSON de **cuenta de servicio** (service account) de Firebase/Google.
- Claves privadas (`*.pem`, `*.p12`).
- Archivos `.env` reales.
- Tokens y contraseñas.

> El backend valida los tokens de Firebase contra Google usando solo el
> `FIREBASE_PROJECT_ID`. **No** requiere ni debe contener una cuenta de servicio.

## Proyecto y aplicaciones

| Dato | Valor |
|---|---|
| Firebase Project ID | `allegro-95408` |
| Android `applicationId` | `com.allegro.allegro` |
| iOS bundle id | `com.allegro.allegro` |
| Proveedores habilitados | Correo/contraseña, Google |

Requisitos mínimos de plataforma para `firebase_core` 3.x / `firebase_auth` 5.x:
**Android** `minSdk` ≥ 23 (el proyecto usa 24) y **iOS** ≥ 13 (`platform :ios, '13.0'`).

## Regenerar la configuración (opcional)

`firebase_options.dart` está sincronizado con los archivos nativos. Para
regenerarlo con FlutterFire (requiere haber iniciado sesión con `firebase login`):

```bash
dart pub global activate flutterfire_cli
cd mobile
flutterfire configure --project=allegro-95408
```

Esto reescribe `firebase_options.dart`, `google-services.json` y
`GoogleService-Info.plist` con los mismos valores de cliente.

## Inicialización

`mobile/lib/main.dart` inicializa Firebase solo en modo Firebase:

```dart
if (AppConfig.isFirebaseAuth) {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
}
```

Android aplica además el plugin `com.google.gms.google-services` (en
`android/settings.gradle.kts` y `android/app/build.gradle.kts`) para leer
`google-services.json`.

## Modos de ejecución

- **Producción / Firebase:** ver [config de producción](../mobile/config/production.json).
  ```bash
  cd mobile
  flutter run   --dart-define-from-file=config/production.json
  flutter build apk --release --dart-define-from-file=config/production.json
  ```
  Producción usa `AUTH_MODE=firebase` y `API_BASE_URL=https://allegro.juanariasdev.com`.
  Nunca usa `AUTH_MODE=local` ni `LOCAL_DEV_TOKEN`.

- **Desarrollo local (sin Firebase):** `AUTH_MODE=local` con el backend local. No
  debe usarse en producción (el backend lo rechaza en `Production`).

## Google Sign-In

El proveedor Google está habilitado en Firebase. En la app, el inicio de sesión
con Google **solo debe mostrarse cuando esté completamente configurado en la
plataforma** (en Android requiere registrar las huellas SHA‑1/SHA‑256 del
certificado y volver a descargar `google-services.json`; en iOS, el URL scheme
con el `REVERSED_CLIENT_ID`). Mientras esa configuración no esté completa, la app
usa correo y contraseña y no expone el botón de Google.
