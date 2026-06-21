import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../config.dart';

/// Abstracción de autenticación. Dos implementaciones:
///  - [LocalAuthService]: modo desarrollo, sin Firebase.
///  - [FirebaseAuthService]: valida con Firebase Authentication.
abstract class AuthService extends ChangeNotifier {
  bool get isAuthenticated;
  String get userLabel;

  /// Token a enviar en la cabecera Authorization de la API.
  Future<String?> getToken();

  Future<void> signIn(String email, String password);
  Future<void> signOut();
}

/// Modo local: siempre autenticado con el token de desarrollo.
class LocalAuthService extends ChangeNotifier implements AuthService {
  @override
  bool get isAuthenticated => true;

  @override
  String get userLabel => 'Operador (modo local)';

  @override
  Future<String?> getToken() async => AppConfig.localDevToken;

  @override
  Future<void> signIn(String email, String password) async {}

  @override
  Future<void> signOut() async {}
}

/// Modo Firebase: autenticación por correo y contraseña.
class FirebaseAuthService extends ChangeNotifier implements AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  FirebaseAuthService() {
    _auth.authStateChanges().listen((_) => notifyListeners());
  }

  @override
  bool get isAuthenticated => _auth.currentUser != null;

  @override
  String get userLabel => _auth.currentUser?.email ?? 'Sin sesión';

  @override
  Future<String?> getToken() async => _auth.currentUser?.getIdToken();

  @override
  Future<void> signIn(String email, String password) async {
    await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    notifyListeners();
  }

  @override
  Future<void> signOut() async {
    await _auth.signOut();
    notifyListeners();
  }
}
