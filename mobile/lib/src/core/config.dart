import 'dart:io' show Platform;

/// Configuración de la aplicación, sobreescribible con --dart-define.
///
/// Ejemplos:
///   flutter run --dart-define=API_BASE_URL=http://192.168.1.10:8080
///   flutter run --dart-define=AUTH_MODE=firebase
class AppConfig {
  /// Modo de autenticación: 'local' (desarrollo) o 'firebase'.
  static const String authMode = String.fromEnvironment(
    'AUTH_MODE',
    defaultValue: 'local',
  );

  /// Token estático usado en modo local (debe coincidir con LOCAL_DEV_TOKEN del backend).
  static const String localDevToken = String.fromEnvironment(
    'LOCAL_DEV_TOKEN',
    defaultValue: 'allegro-dev-token',
  );

  static const String _overrideBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: '',
  );

  static bool get isFirebaseAuth => authMode.toLowerCase() == 'firebase';

  /// URL base del backend, SIN slash final (el cliente concatena rutas como
  /// "/api/..."). En el emulador de Android, localhost del host es 10.0.2.2.
  static String get apiBaseUrl => _stripTrailingSlash(_resolveBaseUrl());

  static String _resolveBaseUrl() {
    if (_overrideBaseUrl.isNotEmpty) return _overrideBaseUrl;
    try {
      if (Platform.isAndroid) return 'http://10.0.2.2:8080';
    } catch (_) {
      // Platform no disponible (p. ej. web): usamos localhost.
    }
    return 'http://localhost:8080';
  }

  static String _stripTrailingSlash(String url) {
    var u = url.trim();
    while (u.endsWith('/')) {
      u = u.substring(0, u.length - 1);
    }
    return u;
  }
}
