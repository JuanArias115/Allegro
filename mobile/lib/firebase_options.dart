// Opciones de Firebase para el proyecto allegro-95408.
//
// Valores de configuración de CLIENTE (no secretos): los mismos que vienen en
// android/app/google-services.json y ios/Runner/GoogleService-Info.plist, y que
// quedan embebidos en la app compilada. No incluye credenciales administrativas.
//
// Equivalente a lo que genera `flutterfire configure`. Se mantiene sincronizado
// con los archivos nativos del proyecto.
//
// ignore_for_file: type=lint
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError(
        'Allegro no está configurado para Web. Ejecuta flutterfire configure para añadirlo.',
      );
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions no está configurado para $defaultTargetPlatform.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBg7N0wbcQOU50ZeLm4wqbTAgM-UFa-HvE',
    appId: '1:54207387771:android:affbc64888261d21232ade',
    messagingSenderId: '54207387771',
    projectId: 'allegro-95408',
    storageBucket: 'allegro-95408.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyCzdB0HBjpN_zW6RMKsu6_NKACrHOrIw28',
    appId: '1:54207387771:ios:9755fd21f832a053232ade',
    messagingSenderId: '54207387771',
    projectId: 'allegro-95408',
    storageBucket: 'allegro-95408.firebasestorage.app',
    iosClientId:
        '54207387771-5c6j1lj7kgv9io4ig1i7cou6smd6paul.apps.googleusercontent.com',
    iosBundleId: 'com.allegro.allegro',
  );
}
