import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError(
        'Firebase is not configured for Web. Run flutterfire configure to generate web options and a reCAPTCHA site key.',
      );
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.windows:
        return windows;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.android:
        throw UnsupportedError(
          'Firebase is not configured for Android. Run flutterfire configure to generate Android options before enabling production Android builds.',
        );
      case TargetPlatform.iOS:
        throw UnsupportedError(
          'Firebase is not configured for iOS. Run flutterfire configure to generate iOS options before enabling production iOS builds.',
        );
      case TargetPlatform.linux:
        throw UnsupportedError('Firebase is not configured for Linux.');
      default:
        throw UnsupportedError(
          'Plataforma no soportada: $defaultTargetPlatform',
        );
    }
  }

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyDRwwUvK21r6EsxfSNKODO0mpAHFe7br3Y',
    appId: '1:791397230720:web:dbdd42f2e2fcdadffade65',
    messagingSenderId: '791397230720',
    projectId: 'hcseco-55882',
    authDomain: 'hcseco-55882.firebaseapp.com',
    storageBucket: 'hcseco-55882.firebasestorage.app',
    measurementId: 'G-N4KN6D010N',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyA1y8N1zhFO7V0PPYEgfQIogvxrbuyPEwE',
    appId: '1:791397230720:ios:16553f0eadad8a83fade65',
    messagingSenderId: '791397230720',
    projectId: 'hcseco-55882',
    storageBucket: 'hcseco-55882.firebasestorage.app',
    iosBundleId: 'com.example.hcsAppLap',
  );
}
