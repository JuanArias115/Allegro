# Configurar Firebase Authentication

La app y el backend están preparados para Firebase, pero **no se incluyen credenciales** en el repositorio. Mientras no configures Firebase, usa el **modo local** (`AUTH_MODE=local`), pensado solo para desarrollo.

> ⚠️ El modo local **nunca** debe usarse en producción. El backend rechaza arrancar con `AUTH_MODE=local` cuando `ASPNETCORE_ENVIRONMENT=Production`.

## 1. Crear el proyecto de Firebase

1. Entra a la [consola de Firebase](https://console.firebase.google.com/) y crea un proyecto.
2. En **Authentication → Sign-in method**, habilita **Correo electrónico/Contraseña** (la app usa email + contraseña).
3. Crea el usuario operador en **Authentication → Users**.

## 2. Configurar la app Flutter

La forma recomendada es usar FlutterFire CLI:

```bash
dart pub global activate flutterfire_cli
cd mobile
flutterfire configure
```

Esto genera:

- `mobile/lib/firebase_options.dart`
- `mobile/android/app/google-services.json`
- `mobile/ios/Runner/GoogleService-Info.plist`

Los tres archivos están en `.gitignore` y **no deben subirse**.

Si `flutterfire configure` genera `firebase_options.dart`, ajusta `mobile/lib/main.dart` para pasar las opciones:

```dart
import 'firebase_options.dart';
// ...
await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
```

(Por defecto `main.dart` llama a `Firebase.initializeApp()` sin opciones, lo que funciona en Android/iOS cuando existen `google-services.json` / `GoogleService-Info.plist`.)

### Android

`flutterfire`/el plugin de Google Services aplican la configuración automáticamente. Si lo haces manualmente, añade el plugin `com.google.gms.google-services` en `mobile/android` y coloca `google-services.json` en `mobile/android/app/`. Asegúrate de `minSdkVersion >= 23`.

### Ejecutar en modo Firebase

```bash
flutter run --dart-define=AUTH_MODE=firebase
```

## 3. Configurar el backend

El backend valida los **ID tokens** de Firebase contra Google (issuer `https://securetoken.google.com/<projectId>`, audience `<projectId>`). Solo necesita el ID del proyecto:

```env
AUTH_MODE=firebase
FIREBASE_PROJECT_ID=tu-proyecto-firebase
```

No se requiere un archivo de cuenta de servicio para validar tokens. Si en el futuro necesitas operaciones administrativas (Firebase Admin SDK), coloca el JSON de la cuenta de servicio en `backend/secrets/` (ignorado por Git) y referencialo por variable de entorno; nunca lo subas al repositorio.

## 4. Verificar

1. Inicia el backend con `AUTH_MODE=firebase` y `FIREBASE_PROJECT_ID`.
2. Inicia la app con `--dart-define=AUTH_MODE=firebase`.
3. Inicia sesión con el usuario creado; la app enviará el ID token y el backend lo validará.

## Resumen de archivos sensibles (nunca versionar)

- `mobile/lib/firebase_options.dart`
- `mobile/android/app/google-services.json`
- `mobile/ios/Runner/GoogleService-Info.plist`
- `backend/secrets/*.json`
- `.env`
