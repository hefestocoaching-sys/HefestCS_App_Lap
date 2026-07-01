import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Firebase App Check static contract', () {
    final mainFile = File('lib/main.dart');
    final optionsFile = File('lib/firebase_options.dart');
    final bootstrapFile = File('lib/core/firebase/firebase_bootstrap.dart');
    final libFiles = _dartFilesIn(Directory('lib'));

    test('firebase bootstrap files exist and main imports them', () {
      expect(mainFile.existsSync(), isTrue);
      expect(optionsFile.existsSync(), isTrue);
      expect(bootstrapFile.existsSync(), isTrue);

      final mainSource = mainFile.readAsStringSync();
      expect(
        mainSource.contains(
          'package:hcs_app_lap/core/firebase/firebase_bootstrap.dart',
        ),
        isTrue,
      );
      expect(mainSource.contains('bootstrapFirebase();'), isTrue);
      expect(mainSource.contains('Firebase.initializeApp'), isFalse);
      expect(
        mainSource.contains('FirebaseAppCheck.instance.activate'),
        isFalse,
      );
    });

    test(
      'debug App Check providers are guarded and have release providers',
      () {
        final offenders = <String>[];

        for (final file in libFiles) {
          final source = file.readAsStringSync();
          final usesAndroidDebug =
              source.contains('AndroidDebugProvider') ||
              source.contains('AndroidProvider.debug');
          final usesAppleDebug =
              source.contains('AppleDebugProvider') ||
              source.contains('AppleProvider.debug');

          if (usesAndroidDebug) {
            if (!_hasDebugOrLocalGuard(source) ||
                !_hasAndroidReleaseProvider(source)) {
              offenders.add(_relativePath(file));
            }
          }

          if (usesAppleDebug) {
            if (!_hasDebugOrLocalGuard(source) ||
                !_hasAppleReleaseProvider(source)) {
              offenders.add(_relativePath(file));
            }
          }
        }

        expect(offenders, isEmpty);
      },
    );

    test('Firebase emulators are guarded for local/debug only', () {
      final offenders = <String>[];

      for (final file in libFiles) {
        final source = file.readAsStringSync();
        final usesEmulator =
            source.contains('useFirestoreEmulator') ||
            source.contains('useAuthEmulator') ||
            source.contains('useStorageEmulator');

        if (usesEmulator && !_hasDebugOrLocalGuard(source)) {
          offenders.add(_relativePath(file));
        }
      }

      expect(offenders, isEmpty);
    });

    test(
      'no App Check debug token or Firebase localhost is hardcoded in lib',
      () {
        final offenders = <String>[];

        for (final file in libFiles) {
          final source = file.readAsStringSync();
          final hasDebugToken = source.contains('debugToken');
          final hasFirebaseLocalhost =
              source.contains('localhost') &&
              (source.contains('Firebase') ||
                  source.contains('Firestore') ||
                  source.contains('Storage') ||
                  source.contains('Auth') ||
                  source.contains('Emulator'));

          if (hasDebugToken ||
              (hasFirebaseLocalhost && !_hasDebugOrLocalGuard(source))) {
            offenders.add(_relativePath(file));
          }
        }

        expect(offenders, isEmpty);
      },
    );

    test('Firebase initializeApp is not duplicated in lib', () {
      var initializeAppCount = 0;

      for (final file in libFiles) {
        final source = file.readAsStringSync();
        initializeAppCount += 'Firebase.initializeApp'
            .allMatches(source)
            .length;
      }

      expect(initializeAppCount, 1);
    });

    test(
      'firebase_options.dart only declares real desktop options and blocks unsupported platforms',
      () {
        final source = optionsFile.readAsStringSync();

        expect(source.contains('TargetPlatform.windows'), isTrue);
        expect(source.contains('TargetPlatform.macOS'), isTrue);
        expect(source.contains('TargetPlatform.android'), isTrue);
        expect(source.contains('TargetPlatform.iOS'), isTrue);
        expect(source.contains('TargetPlatform.linux'), isTrue);
        expect(source.contains('kIsWeb'), isTrue);

        expect(source.contains('Run flutterfire configure'), isTrue);
        expect(
          source.contains(
            'return windows; // Usamos la misma config web/windows',
          ),
          isFalse,
        );
        expect(
          source.contains(
            'return windows; // Usaremos estas mismas llaves para probar rápido',
          ),
          isFalse,
        );
        expect(
          source.contains("throw UnsupportedError('iOS no configurado')"),
          isFalse,
        );
        expect(
          source.contains('Firebase is not configured for Android.'),
          isTrue,
        );
        expect(source.contains('Firebase is not configured for Web.'), isTrue);
        expect(source.contains('Firebase is not configured for iOS.'), isTrue);
      },
    );

    test(
      'main bootstrap leaves App Check policy in the helper, not in main',
      () {
        final source = mainFile.readAsStringSync();
        expect(source.contains('bootstrapFirebase();'), isTrue);
        expect(
          source.contains('Platform.isAndroid || Platform.isIOS'),
          isFalse,
        );
        expect(source.contains('AndroidDebugProvider'), isFalse);
        expect(source.contains('AppleDebugProvider'), isFalse);
      },
    );
  });
}

List<File> _dartFilesIn(Directory directory) {
  return directory
      .listSync(recursive: true)
      .whereType<File>()
      .where((file) => file.path.endsWith('.dart'))
      .toList();
}

bool _hasDebugOrLocalGuard(String source) {
  return source.contains('kDebugMode') ||
      source.contains('assert(') ||
      source.contains('bool.fromEnvironment') ||
      source.contains('String.fromEnvironment');
}

bool _hasAndroidReleaseProvider(String source) {
  return source.contains('AndroidPlayIntegrityProvider') ||
      source.contains('AndroidProvider.playIntegrity');
}

bool _hasAppleReleaseProvider(String source) {
  return source.contains('AppleDeviceCheckProvider') ||
      source.contains('AppleAppAttestProvider') ||
      source.contains('AppleAppAttestWithDeviceCheckFallbackProvider') ||
      source.contains('AppleProvider.deviceCheck') ||
      source.contains('AppleProvider.appAttest');
}

String _relativePath(File file) {
  return file.path.replaceAll('\\', '/');
}
